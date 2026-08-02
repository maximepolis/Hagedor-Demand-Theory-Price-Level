% MAIN_TWOASSET_OWNERSHIP_KV  The combination that should finally produce
% WEALTHY HAND-TO-MOUTH households: the ownership recalibration (R2) --
% intermediation wedge, realistic direct liquid target, superstar income
% state -- run ON the infrequent-adjustment (Kaplan-Violante) household.
%
% The frictionless ownership run (main_twoasset_ownership) fixed wealth
% concentration and the liquid share but left WHtM = 0, because without an
% adjustment friction no household is stuck with low liquid + high illiquid.
% This driver supplies the friction: k rebalances only with probability
% lambda, so households accumulate illiquid wealth they cannot instantly
% convert -- the wealthy-hand-to-mouth configuration -- while the
% intermediation wedge keeps the DIRECT liquid claim (the revaluation base)
% at a realistic, skewed level.
%
% Equilibrium (as in main_twoasset_ownership, KV household/distribution):
%   bond:  int b dOmega = iota_H * B / P     (pins P)
%   fund dividend:  div(P) = d + r_b (1-iota_H)(B/P)/Kbar   (endogenous)
%   tree:  int k dOmega = Kbar               (pins q)
%
% USAGE   >> parpool; clear; FAST = true; main_twoasset_ownership_kv
%         >> clear; REGRID = true; main_twoasset_ownership_kv
%            recalibrates beta and chi_b ON the widened grids the residual
%            scan settled on, instead of transplanting a calibration that was
%            fitted at kmax = 60 onto a grid with kmax = 360.
% OUTPUT  output/twoasset_ownership_kv.mat, output/tables/twoasset_ownership_kv.txt
% STATUS: scaffolded, untested pending a MATLAB run.

clearvars -except FAST KMV ZETA LADDER WTARGET REGRID KFAC BFAC; close all; clc;
rng(20260723, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
% KMV = true runs the FRICTION-ONLY (Kaplan-Moll-Violante limit) variant:
% chi_b -> 0, so liquid demand comes purely from the buffer-stock motive
% created by the adjustment friction, and part of the dividend is retained
% inside the illiquid account. Rationale (see the WHtM remark in the paper):
% with convenience utility the interior liquid FOC u'(c) >= chi v'(b')
% implies b' >= (chi c^sigma)^(1/zeta) - bbar, so hand-to-mouth status is
% possible only below a consumption threshold (~1.06 x mean income at the
% benchmark calibration) and WEALTHY hand-to-mouth is zero BY CONSTRUCTION
% at any beta/lambda/payout. Only chi -> 0 removes the bound. This variant
% writes to *_kmv output files and never touches the benchmark ones.
if ~exist('KMV','var'), KMV = false; end
% LADDER = true runs the MATCHED-PARAMETER decomposition. The 2x2 table in
% the paper compares economies that each carry their own recalibration, so a
% referee can fairly ask whether the restored sign comes from the
% INGREDIENTS or from the discount factor that came with them. This variant
% holds beta, chi and lambda fixed at the benchmark values and switches
% ingredients one at a time, so consecutive cells differ by exactly one
% thing:
%   (i)   benchmark
%   (ii)  no intermediation wedge   (iota_H = 1)
%   (iii) no superstar income state
%   (iv)  no adjustment friction    (lambda -> 1)
% Writes to *_ladder files; the benchmark outputs are never touched.
if ~exist('LADDER','var'), LADDER = false; end
pg = setup_params_green();

p = struct();
p.sigma = pg.sigma; p.beta = pg.beta;
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), p.beta = L.RCAL.beta_star; end
end
% superstar income state
ss = struct('mult', 12, 'p_in', 0.006, 'p_out', 0.06);
wff = fullfile(projdir, 'output', 'wealth_fit_results.mat');
if exist(wff,'file') == 2
    Wf = load(wff, 'best');
    if isfield(Wf,'best')
        if isfield(Wf.best,'mult'),  ss.mult  = Wf.best.mult;  end
        if isfield(Wf.best,'p_in'),  ss.p_in  = Wf.best.p_in;  end
        if isfield(Wf.best,'p_out'), ss.p_out = Wf.best.p_out; end
    end
end
eG_plain = pg.eGrid(:)'; Pi_plain = pg.Pi;      % pre-superstar process (ladder)
[eG2, Pi2, st2] = add_superstar_state(pg.eGrid(:), pg.Pi, ss);
p.eGrid = eG2(:)'; p.Pi = Pi2; p.stationary_e = st2;
% lambda_adj is the per-period free-rebalancing probability. At 1/3
% (adjust every ~3 periods) illiquid wealth is far too fluid to generate
% wealthy hand-to-mouth: households top up their liquid buffer too often,
% so nobody runs down to b~0 while holding large k (WHtM=0, and liquidity
% is so abundant that S_b floors well above the 0.30 target). The KV/KVW
% mechanism needs INFREQUENT adjustment -- households load illiquid k at a
% rebalancing date and draw down b over a long spell, ending low-b/high-k.
p.zeta_b = 2.0; p.chi_b = 0.02; p.lambda_adj = 0.15;
% ZETA workspace override: the KVJ evidence disciplines the convenience
% curvature through the demand-curve log-elasticity dln(spr)/dln(b) ~ -zeta
% (see calibrate_convenience_kvj); the point estimate maps to zeta ~ 1, the
% range to ~[0.55, 2.05]. `ZETA = 1.0` reruns the benchmark at the
% point-disciplined curvature, writing to suffixed output files.
if exist('ZETA','var') && ~isempty(ZETA), p.zeta_b = ZETA; end
% WTARGET workspace override: total household wealth as a multiple of income.
% Empty (the default) keeps the one-instrument calibration in which beta
% carries the direct-holding level and total wealth is whatever it implies;
% a value switches on the two-instrument calibration of referee item M3.
% US data put net worth at roughly 3 to 5 times income; 3.0 is the
% conservative end of that range.
W_targ = [];
if exist('WTARGET','var') && ~isempty(WTARGET), W_targ = WTARGET; end
% STONE-GEARY shift on liquid holdings. With bbar = 0 the convenience
% utility chi*b^(1-zeta)/(1-zeta) has v'(b) = chi*b^(-zeta) -> inf as b -> 0:
% an Inada condition on LIQUIDITY that makes running the liquid buffer to
% zero infinitely costly, so the hand-to-mouth measure is identically zero
% at ANY beta/lambda/q. (Confirmed: HtM was 0.000 in every run except the
% degenerate one where the calibration drove chi -> 0 and switched the Inada
% force off -- that run showed HtM = 0.175.)
%
% bbar > 0 makes v'(0) = chi*bbar^(-zeta) finite. Choose it so the marginal
% liquidity value at b = 0 is well below the marginal utility of consumption
% for a constrained household: chi*bbar^-2 = 0.00223*0.03^-2 ~ 2.5, versus
% u'(c) ~ c^-2 ~ 19 at the observed min_c ~ 0.23. Hitting the liquid
% constraint is then a finite, chosen cost -- the wealthy-hand-to-mouth
% margin the friction is meant to deliver.
p.bbar_liq = 0.03;
% DIVIDEND PAYOUT RATIO. With phi = 1 a non-adjuster collects the whole
% dividend d*k as LIQUID income -- at d = 0.12 that is a 12%-of-income
% liquid flow for the average tree holder and more for the wealthy, so a
% wealthy household never runs its liquid buffer down and WHtM is zero
% regardless of beta, lambda or bbar. phi < 1 retains the rest inside the
% illiquid account (k compounds at (1-phi)*d/q between adjustment dates),
% the Kaplan-Moll-Violante convention that produces households rich in k
% but liquidity-constrained.
%
% BENCHMARK phi = 1: the phi = 0.25 recalibrated economy overshoots wealth
% concentration badly (top1 = 0.75 vs ~0.35 in the data; retained dividends
% compound the superstar tail) and is not an admissible calibration, so the
% payout margin is exercised only in the KMV variant, where the buffer-
% drawdown between adjustment dates is the whole point.
p.div_payout = 1.00;
if KMV
    p.chi_b = 0; p.div_payout = 0.25;           % friction-only liquidity demand
end
p.tol_vfi = 1e-6; p.maxit_vfi = 800;
p.tol_dist = 1e-11; p.maxit_dist = 50000;
p.gold_outer = 0; p.gold_inner = 0;             % unused by the discrete solver
nb = 60; nk = 34; nx = 150; nac = 100; nsh = 22;
bmax = 12; kmax = 60; xmax = 420;   % xGridA MUST cover Rb*bmax+(q+d)*kmax+ymax
if FAST, nb = 40; nk = 22; nx = 100; nac = 70; nsh = 15; end
ub  = linspace(0,1,nb)';  p.bGrid  = 1e-4 + (bmax-1e-4)*(ub.^2.4);
uk  = linspace(0,1,nk)';  p.kGrid  = kmax*(uk.^2.4);
uxA = linspace(0,1,nx)';  p.xGridA = 0.05 + (xmax-0.05)*(uxA.^2.8);  % strong curvature: low-end resolution
uac = linspace(0,1,nac)'; p.acGrid = 1e-4 + (0.92*xmax-1e-4)*(uac.^2.8);
p.sGrid = linspace(1/nsh, 1, nsh);

% PROVENANCE STAMP. These are the calibration-base grids by definition, so
% record that fact in p itself. Everything this driver saves carries the
% stamp, and every downstream driver reads it rather than inferring the
% widening from a ceiling. Without it, a p loaded from disk cannot say
% whether it has already been widened -- which is how three drivers came to
% apply the verified factors to a grid that already carried them.
p.grid_state = struct('kfac', 1, 'bfac', 1, 'kmax', kmax, 'bmax', bmax, ...
                      'xmax', xmax, 'base', kv_grid_base(), ...
                      'stamped_by', 'main_twoasset_ownership_kv:base');
assert(abs(kmax - p.grid_state.base.kmax) < 1e-12 && ...
       abs(bmax - p.grid_state.base.bmax) < 1e-12 && ...
       abs(xmax - p.grid_state.base.xmax) < 1e-12, ...
    ['the base grids built here disagree with kv_grid_base(). Those constants ' ...
     'define what every stored widening FACTOR means; change them in one place ' ...
     'or every factor on disk silently redefines itself.']);


D0 = 0.06; r_b = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom = pg.Bnom; Kbar = 1.0; d_base = 0.12;

% ---------------------------------------------------------------- REGRID
% The diagnostic scan established that kmax = 60 truncates: 2.8e-3 of mass
% sat in the top two k-nodes, a sixth of aggregate tree demand pinned against
% a wall and unable to respond to the tree price. Widening fixed that, but
% every result computed on a widened grid is PROVISIONAL until beta and
% chi_b are recalibrated there, because the calibration targets are wealth
% moments and widening moves them. That is what this switch is for: it
% recalibrates ON the widened grid rather than transplanting a calibration
% across grids.
%
% The factors are read from the scan that verified them, so the calibration
% and the diagnosis run on the same grid by construction. REGRID = false
% reproduces the original calibration exactly.
if ~exist('REGRID','var'), REGRID = false; end
GW = struct('changed', false);
if REGRID
    scf = fullfile(projdir, 'output', 'kv_residual_scan.mat');
    if exist(scf,'file') == 2 && ~exist('KFAC','var')
        Sc = load(scf, 'kfac', 'bfac'); KFAC = Sc.kfac; BFAC = Sc.bfac;
    end
    if ~exist('KFAC','var') || isempty(KFAC), KFAC = 6; end
    if ~exist('BFAC','var') || isempty(BFAC), BFAC = 8; end
    q_seed = d_base / max(r_b, 5e-3);            % crude, pre-solution
    ownf0 = fullfile(projdir, 'output', 'twoasset_ownership.mat');
    if exist(ownf0,'file') == 2
        O0 = load(ownf0, 'eq0');
        if isfield(O0,'eq0') && isstruct(O0.eq0) && O0.eq0.ok, q_seed = O0.eq0.q; end
    end
    [p, GR] = kv_ensure_widened(p, KFAC, BFAC, struct('r_b', r_b, 'q', q_seed, ...
                             'd', d_base, 'kref', 5, 'bref', 3), @(varargin) fprintf(varargin{:}));
    GW = GR.W;
    bmax = p.bGrid(end); kmax = p.kGrid(end); xmax = p.xGridA(end);
    % The saved .mat carries the WIDENED p. Downstream drivers must therefore
    % reconcile rather than re-apply; they call kv_ensure_widened, which reads
    % p.grid_state and no-ops when the grid is already at the target.
end

b_debt = 1.10; b_targ_H = 0.30; iota_H = b_targ_H/b_debt;
Gg = 0.02 * (Bnom / b_debt);
htm_b = 0.02; whtm_k = 0.50;

% anchor the tree-price bracket on the KNOWN frictionless-ownership solution
% (that run converged at q ~ 3.0); falls back to the d/r bound otherwise.
q_ref = d_base / max(r_b, 5e-3); chi_ref = 0.0015;
ownf = fullfile(projdir, 'output', 'twoasset_ownership.mat');
if exist(ownf, 'file') == 2
    Ow = load(ownf, 'eq0', 'p');
    if isfield(Ow,'eq0') && isstruct(Ow.eq0) && Ow.eq0.ok, q_ref = Ow.eq0.q; end
    % chi is now the SHARE instrument, held at the frictionless-calibrated
    % value; beta is recalibrated below to carry the LEVEL. (Previously chi
    % was scaled down to chase the level target and could not reach it.)
    if isfield(Ow,'p') && isfield(Ow.p,'chi_b'), chi_ref = Ow.p.chi_b; end
end
% CURVATURE REPARAMETERIZATION. chi_ref is calibrated at the default
% curvature zeta = 2, and chi and zeta are not separately meaningful: the
% liquid first-order condition chi*(b+bbar)^(-zeta) = u'(c)*spread pins only
% their combination at the calibrated liquid position. Changing zeta at
% FIXED chi therefore moves the level of liquidity preference as well as its
% curvature, which is not the KVJ experiment. Measured: at zeta = 1 it cut
% the marginal value of liquidity at the target position threefold, so the
% economy loaded the difference into the tree -- household wealth 1.8 -> 3.7
% times income, top-1% share 33% -> 65%, hand-to-mouth 6% -> 44% -- and the
% financing experiment returned +27 and +32 log points from a 2%-of-income
% program, on a tree price that had moved outside its own bracket. That is a
% different economy, not a curvature robustness check.
%
% Rescale chi so the marginal value of liquidity AT THE TARGET liquid
% position is unchanged. This is the unique rescaling that isolates
% curvature: it holds the calibrated point of the liquidity demand curve
% fixed and rotates the curve through it, which is exactly what the KVJ
% elasticity dln(spread)/dln(b) ~ -zeta identifies.
if abs(p.zeta_b - 2.0) > 1e-12
    chi_ref = chi_ref * (b_targ_H + p.bbar_liq)^(p.zeta_b - 2.0);
end
if KMV, chi_ref = 0; end                        % friction-only: no convenience utility

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
if KMV, tag = 'twoasset_ownership_kmv'; else, tag = 'twoasset_ownership_kv'; end
if LADDER, tag = [tag '_ladder']; end
if abs(p.zeta_b - 2.0) > 1e-12                  % non-default curvature: suffix
    tag = sprintf('%s_z%02.0f', tag, 10*p.zeta_b);
end
if ~isempty(W_targ)                             % 2D wealth-matched calibration
    tag = sprintf('%s_w%02.0f', tag, 10*W_targ);
end
sf = fullfile(pg.tabdir, [tag '.txt']);
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
if KMV
    tee('OWNERSHIP + FRICTION-ONLY LIQUIDITY (KMV limit, chi_b=0, phi=%.2f).\n', p.div_payout);
end
tee('OWNERSHIP + INFREQUENT ADJUSTMENT. nb=%d nk=%d nx=%d ne=%d lambda=%.2f FAST=%d\n', ...
    nb, nk, nx, numel(p.eGrid), p.lambda_adj, FAST);
if REGRID
    GSN = kv_grid_state(p);
    tee('*** GRID STATE: kfac %.4g, bfac %.4g relative to the calibration base\n', ...
        GSN.kfac, GSN.bfac);
    tee('*** (kmax %.1f, bmax %.2f, xmax %.1f). This p is SAVED widened; every\n', ...
        GSN.kmax, GSN.bmax, GSN.xmax);
    tee('*** downstream driver must reconcile via kv_ensure_widened, not re-apply.\n');
end
if GW.changed
    tee('*** REGRID: kmax %.1f -> %.1f, bmax %.2f -> %.2f, xmax %.1f -> %.1f\n', ...
        GW.kmax0, GW.kmax, GW.bmax0, GW.bmax, GW.xmax0, GW.xmax);
    tee('*** k-curvature %.2f -> %.2f; beta and chi_b are recalibrated HERE, on\n', GW.gk0, GW.gk);
    tee('*** this grid, so the calibration and the diagnostics share one grid.\n');
end
tee('iota_H=%.3f (direct target %.2f of income); superstar mult=%.1f p_in=%.3f\n', ...
    iota_H, b_targ_H, ss.mult, ss.p_in);
tee('liquidity: zeta_b=%.2f, Stone-Geary shift bbar=%.3f (0 => Inada at b=0 => HtM==0)\n', ...
    p.zeta_b, p.bbar_liq);
if abs(p.zeta_b - 2.0) > 1e-12
    tee(['curvature reparameterized: chi rescaled to %.5f so the marginal ' ...
         'value of\n  liquidity at the target position b=%.2f is unchanged ' ...
         '(curvature only)\n'], chi_ref, b_targ_H);
end
tee('dividend payout phi=%.2f (1 => full d*k paid LIQUID => wealthy never run down => WHtM==0)\n\n', ...
    p.div_payout);

% ---- (0) diagnostic single solve: is the household/distribution healthy? ----
tee('----- (0) diagnostic single equilibrium (chi=%.4f) -----\n', chi_ref);
pdiag = p; pdiag.chi_b = chi_ref;
eqd = solve_own_kv(r_b, d_base, D0, 0, 0, Bnom, Kbar, iota_H, pdiag, q_ref, true);
if eqd.ok
    tee('  diagnostic OK: S_b=%.4f q=%.4f P=%.4f min_c=%.4f n_infeas=%d\n', ...
        eqd.Sb, eqd.q, eqd.P, eqd.min_c, eqd.n_infeas);
else
    tee('  diagnostic FAILED: %s\n', eqd.msg);
    tee('  (household/distribution or bracket problem -- see printed q-scan above)\n');
end

% ---- baseline: calibrate BETA to the direct liquid target (chi fixed) ----
% The adjustment friction roughly DOUBLES precautionary wealth relative to
% the frictionless ownership economy at a common beta (W = 3.3 -> 6.8 x
% income), so the level target is out of chi's reach: S_b = omega * W, and
% chi moves only omega, whose floor RISES with the friction. beta is the
% level instrument. This mirrors the borrowing-limit audit, where holding
% beta fixed across economies produced the artifact and the recalibrated
% sweep was the honest one.
p.chi_b = chi_ref;
if ~isempty(W_targ)
    % TWO-DIMENSIONAL CALIBRATION (referee item M3). With chi held at its
    % frictionless value and beta carrying the level, the economy hits the
    % direct-holding target by being POOR: total household wealth is 1.8
    % times income against roughly 3 to 5 in the data, so a referee can ask
    % whether the restored disinflation is a poor-economy artifact. Two
    % instruments answer it. The pairing matters for conditioning: beta and
    % chi both raise S_b, so targeting (W, S_b) is near-collinear, whereas
    % beta moves the LEVEL of wealth and chi the liquid SHARE, so targeting
    % (W, omega) is close to triangular. Since S_b = omega * W, hitting both
    % hits the direct-holding target as well.
    tee('----- (1) baseline (2D: beta -> W=%.2f, chi -> omega=%.3f) -----\n', ...
        W_targ, b_targ_H/W_targ);
    [p.beta, p.chi_b, eq0] = calib_beta_chi(r_b, d_base, D0, 0, 0, Bnom, Kbar, ...
                                 b_targ_H, W_targ, iota_H, p, q_ref, t0);
else
tee('----- (1) baseline (beta recalibrated; chi fixed at %.5f) -----\n', chi_ref);
[p.beta, eq0] = calib_beta(r_b, d_base, D0, 0, 0, Bnom, Kbar, b_targ_H, iota_H, p, q_ref, t0);
end
if isempty(eq0) || ~eq0.ok
    tee('BASELINE CALIBRATION FAILED -- see per-iteration diagnostics above.\n');
    fclose(fid);
    error('ownership-kv baseline failed (diagnostics written to %s)', sf);
end
omega = eq0.Sb/(eq0.Sb + eq0.q*Kbar);
Wtot = eq0.Sb + eq0.q*Kbar;                     % total household wealth/income
tee('beta=%.5f chi_b=%.5f S_b=%.4f (target %.2f) q=%.4f P=%.4f omega=%.3f div=%.4f\n', ...
    p.beta, p.chi_b, eq0.Sb, b_targ_H, eq0.q, eq0.P, omega, eq0.div);
tee('wealth: total %.3f x income (illiquid %.3f, liquid %.3f); tree yield d/q=%.3f\n', ...
    Wtot, eq0.q*Kbar, eq0.Sb, d_base/eq0.q);
tee('feasibility: min consumption %.4f, infeasible states %d, k-grid top mass %.4f\n', ...
    eq0.min_c, eq0.n_infeas, eq0.ksat);
H = htm_bk(eq0.dist, eq0.bch, eq0.kch, eq0.q, htm_b, whtm_k);
tee('HtM (b<%.2f): total %.3f | WEALTHY (qk>%.2f): %.3f | poor: %.3f\n', ...
    htm_b, H.htm, whtm_k, H.whtm, H.phtm);
tee('wealth shares: top10 %.2f top1 %.2f\n\n', H.top10, H.top1);

% ---- financing experiment ----
tee('----- (2) financing incidence (lump-sum vs levy) -----\n');
g_real = Gg / eq0.P;
eLS = solve_own_kv(r_b, d_base, D0, g_real, 0, Bnom, Kbar, iota_H, p, eq0.q, false, [0.85 1.20]);
eLV = solve_own_kv(r_b, d_base, D0, g_real, 1, Bnom, Kbar, iota_H, p, eq0.q, false, [0.85 1.20]);
EXK = struct('name',{},'P',{},'q',{},'dlnP',{});
if eLS.ok
    EXK(end+1) = struct('name','lump-sum','P',eLS.P,'q',eLS.q,'dlnP',log(eLS.P/eq0.P)); %#ok<SAGROW>
    tee('lump-sum P=%.4f dlnP=%+0.4f q=%.4f\n', eLS.P, log(eLS.P/eq0.P), eLS.q);
else, tee('lump-sum FAILED (%s)\n', eLS.msg); end
if eLV.ok
    EXK(end+1) = struct('name','levy','P',eLV.P,'q',eLV.q,'dlnP',log(eLV.P/eq0.P)); %#ok<SAGROW>
    tee('levy     P=%.4f dlnP=%+0.4f q=%.4f\n', eLV.P, log(eLV.P/eq0.P), eLV.q);
else, tee('levy FAILED (%s)\n', eLV.msg); end
if numel(EXK) >= 2
    tee('sign contrast survives: %d\n', sign(EXK(1).dlnP) ~= sign(EXK(2).dlnP));
end
tee(['\nReading: does the ADJUSTMENT FRICTION on top of the ownership wedge\n' ...
     'finally deliver WEALTHY hand-to-mouth households (WHtM > 0)? If so this\n' ...
     'is the calibration for the covariance-on-realistic-bond-ownership\n' ...
     'exercise and the disciplined welfare incidence.\n']);

% =====================================================================
% (3) MATCHED-PARAMETER LADDER (LADDER = true)
% =====================================================================
% Every cell below holds beta, chi_b and the grids at the BENCHMARK values
% calibrated above and switches exactly one ingredient off. That is what the
% paper's 2x2 table cannot do, because each of its cells is separately
% recalibrated: this isolates the ingredient from the recalibration that
% normally accompanies it.
if LADDER
    tee('\n----- (3) matched-parameter ladder (beta, chi, grids FIXED) -----\n');
    tee('beta = %.5f, chi_b = %.5f held at the benchmark throughout\n', p.beta, p.chi_b);
    tee('%-26s %10s %10s %10s %8s\n', 'economy', 'dlnP(ls)', 'dlnP(levy)', 'contrast', 'top1');
    LAD = struct('name',{},'dlnPls',{},'dlnPlevy',{},'contrast',{},'top1',{});
    for cell = 1:4
        pc = p; iota_c = iota_H; nm = '';
        switch cell
            case 1, nm = 'benchmark';
            case 2, nm = 'no intermediation wedge'; iota_c = 1.0;
            case 3, nm = 'no superstar state';
                    pc.eGrid = eG_plain; pc.Pi = Pi_plain;
                    pc = rmfield(pc, 'stationary_e');
            case 4, nm = 'no adjustment friction';  pc.lambda_adj = 1.0;
        end
        e0c = solve_own_kv(r_b, d_base, D0, 0, 0, Bnom, Kbar, iota_c, pc, q_ref, false);
        if ~e0c.ok
            tee('%-26s   baseline FAILED (%s)\n', nm, e0c.msg); continue;
        end
        gc  = Gg / e0c.P;
        eLc = solve_own_kv(r_b, d_base, D0, gc, 0, Bnom, Kbar, iota_c, pc, e0c.q, false, [0.85 1.20]);
        eVc = solve_own_kv(r_b, d_base, D0, gc, 1, Bnom, Kbar, iota_c, pc, e0c.q, false, [0.85 1.20]);
        if ~eLc.ok || ~eVc.ok
            tee('%-26s   experiment FAILED\n', nm); continue;
        end
        dls = log(eLc.P/e0c.P); dlv = log(eVc.P/e0c.P);
        Hc  = htm_bk(e0c.dist, e0c.bch, e0c.kch, e0c.q, htm_b, whtm_k);
        tee('%-26s %+10.4f %+10.4f %10d %8.2f\n', nm, dls, dlv, sign(dls)~=sign(dlv), Hc.top1);
        LAD(end+1) = struct('name',nm,'dlnPls',dls,'dlnPlevy',dlv, ...
                            'contrast',sign(dls)~=sign(dlv),'top1',Hc.top1); %#ok<SAGROW>
    end
    tee(['\nReading: consecutive rows differ by ONE ingredient at fixed\n' ...
         'preferences, so any change in the sign contrast is attributable to\n' ...
         'that ingredient rather than to a recalibration.\n']);
    save(fullfile(projdir,'output',[tag '_ladder.mat']), 'LAD', 'p', 'iota_H');
end

save(fullfile(projdir,'output',[tag '.mat']), 'eq0', 'EXK', ...
     'omega', 'H', 'p', 'iota_H', 'b_targ_H', 'ss', 'r_b', 'd_base', 'D0', 'Gg');
fclose(fid);
fprintf('[main_twoasset_ownership_kv] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
