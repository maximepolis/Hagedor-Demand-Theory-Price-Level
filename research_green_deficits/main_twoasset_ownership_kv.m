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
% OUTPUT  output/twoasset_ownership_kv.mat, output/tables/twoasset_ownership_kv.txt
% STATUS: scaffolded, untested pending a MATLAB run.

clearvars -except FAST KMV ZETA LADDER WTARGET; close all; clc;
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

D0 = 0.06; r_b = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom = pg.Bnom; Kbar = 1.0; d_base = 0.12;
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
function [chi_star, eq0] = calib_chi(rb, d, D, g, lv, Bnom, Kbar, btH, iota, p, q_ref, chi0, t0)
    % coarse pre-scan (log-spaced around chi0) to bracket the target before
    % the secant. The KV household holds more bonds per unit chi than the
    % frictionless one, so the target lives at SMALL chi -- start low and
    % stay in the feasible region (high chi -> S_b overshoot -> low P ->
    % high tax -> infeasible-poor states).
    chi_grid = chi0 * [0.25 0.5 1 2 4];
    eq0 = []; chi_star = chi0; best = Inf;
    lc = log(chi0); lc_p = NaN; e_p = NaN;
    for k = 1:numel(chi_grid)
        pk = p; pk.chi_b = chi_grid(k);
        eqk = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pk, q_ref, false);
        if ~eqk.ok
            fprintf('[%5.0fs] pre-scan chi=%.5f FAILED (%s)\n', toc(t0), chi_grid(k), eqk.msg);
            continue;
        end
        err = log(eqk.Sb) - log(btH);
        fprintf('[%5.0fs] pre-scan chi=%.5f S_b=%.4f err=%+.4f (min_c=%.3f)\n', ...
            toc(t0), chi_grid(k), eqk.Sb, err, eqk.min_c);
        if abs(err) < best, best = abs(err); eq0 = eqk; chi_star = chi_grid(k); lc = log(chi_grid(k)); end
    end
    if isempty(eq0), return; end                 % nothing solved -- report to caller
    % secant refinement from the best pre-scan point
    err = log(eq0.Sb) - log(btH);
    nfail = 0;                                    % consecutive-failure guard
    for itc = 1:8
        if abs(err) < 8e-3, break; end
        if isfinite(e_p) && abs(err-e_p) > 1e-9
            step = -err*(lc-lc_p)/(err-e_p); step = max(min(step,1.0),-1.0);
        else, step = -sign(err)*0.3; end
        lc_p_try = lc; lc = lc + step;
        pk = p; pk.chi_b = exp(lc);
        eqk = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pk, q_ref, false);
        if ~eqk.ok
            fprintf('[%5.0fs] secant chi=%.4f FAILED (%s)\n', toc(t0), exp(lc), eqk.msg);
            nfail = nfail + 1;
            % Target below the KV solvable floor: the household solve breaks
            % down as bond demand approaches its no-liquidity-premium corner.
            % Stop after two consecutive failures and report the closest
            % FEASIBLE equilibrium rather than burning hours in the cliff.
            if nfail >= 2
                fprintf(['[calib] direct-liquid target %.2f is below the KV solvable ' ...
                    'floor (best feasible S_b=%.4f at chi=%.5f); stopping secant.\n'], ...
                    btH, eq0.Sb, chi_star);
                break;
            end
            lc = lc_p_try;                        % step back to the feasible side
            continue;
        end
        nfail = 0;
        lc_p = lc_p_try; e_p = err;
        eq0 = eqk; chi_star = exp(lc); err = log(eqk.Sb) - log(btH);
        fprintf('[%5.0fs] secant chi=%.5f S_b=%.4f err=%+.4f (min_c=%.3f)\n', ...
            toc(t0), chi_star, eqk.Sb, err, eqk.min_c);
    end
end

function [beta_star, chi_star, eq0] = calib_beta_chi(rb, d, D, g, lv, Bnom, Kbar, ...
                                          btH, Wt, iota, p, q_ref, t0)
    % TWO-INSTRUMENT calibration (referee item M3): beta and chi_b jointly
    % target total household wealth W and the liquid share omega.
    %
    % WHY THIS PAIRING. Both instruments raise the direct liquid holding
    % S_b, so targeting (W, S_b) with (beta, chi) is a near-collinear system
    % and the Newton is ill-conditioned. The economics is triangular
    % instead: beta sets the LEVEL of precautionary wealth (patience), chi
    % sets the SHARE held liquid (the convenience yield). Targeting
    % (W, omega) exploits that, and since S_b = omega * W, hitting both
    % delivers the direct-holding target as a by-product -- the residuals
    % satisfy r_W + r_omega = log S_b - log btH exactly.
    %
    % Solved by damped Broyden in (log beta, log chi) with a finite-
    % difference seed. beta is clamped below the 1/(1+r) boundary, where
    % aggregate asset demand diverges and the calibration stops being
    % economically identified rather than merely numerically hard.
    om_t   = btH / Wt;                          % implied liquid-share target
    lb_max = log(0.999/(1 + rb));               % patience boundary
    x  = [min(log(p.beta), lb_max); log(max(p.chi_b, 1e-8))];
    ev = @(xx) eval_own(rb, d, D, g, lv, Bnom, Kbar, iota, ...
                        setfield(setfield(p, 'beta', exp(min(xx(1), lb_max))), ...
                                 'chi_b', exp(xx(2))), q_ref); %#ok<SFLD>
    beta_star = p.beta; chi_star = p.chi_b; eq0 = [];

    [r, eqx] = resid_of(ev(x), Wt, om_t);
    if isempty(eqx), fprintf('  2D calibration: initial point infeasible\n'); return; end
    eq0 = eqx; beta_star = exp(min(x(1), lb_max)); chi_star = exp(x(2));
    report2d(t0, 0, x, eqx, r, lb_max);

    % finite-difference seed for the Jacobian (2 extra solves)
    h = 0.02; J = zeros(2,2);
    for j = 1:2
        xp = x; xp(j) = xp(j) + h;
        [rp, eqp] = resid_of(ev(xp), Wt, om_t);
        if isempty(eqp), rp = r + h*[1;1]; end   % crude fallback: keep it invertible
        J(:,j) = (rp - r)/h;
    end
    if abs(det(J)) < 1e-8, J = J + 1e-3*eye(2); end

    best = norm(r);
    for it = 1:12
        if norm(r, Inf) < 2e-2, break; end
        dx = -(J \ r);
        st = min(1, 0.35/max(abs(dx)));          % trust region in logs
        accepted = false;
        for bt = 1:5                             % backtracking
            xn = x + st*dx; xn(1) = min(xn(1), lb_max);
            [rn, eqn] = resid_of(ev(xn), Wt, om_t);
            if ~isempty(eqn) && norm(rn) < norm(r)
                dr = rn - r; s = xn - x;
                J = J + ((dr - J*s) * s.') / max(s.'*s, 1e-12);   % Broyden
                x = xn; r = rn;
                if norm(r) < best
                    best = norm(r); eq0 = eqn;
                    beta_star = exp(min(x(1), lb_max)); chi_star = exp(x(2));
                end
                accepted = true; break;
            end
            st = st/2;
        end
        report2d(t0, it, x, eq0, r, lb_max);
        if ~accepted
            fprintf('  2D calibration: no improving step; keeping the best point\n');
            break;
        end
    end
end

function [r, eqx] = resid_of(eqx, Wt, om_t)
    if isempty(eqx) || ~eqx.ok, r = [NaN; NaN]; eqx = []; return; end
    W  = eqx.Sb + eqx.q * eqx.Kbar;
    om = eqx.Sb / max(W, 1e-12);
    r  = [log(max(W,1e-12)) - log(Wt); log(max(om,1e-12)) - log(om_t)];
    if ~all(isfinite(r)), r = [NaN; NaN]; eqx = []; end
end

function report2d(t0, it, x, eqx, r, lb_max)
    if isempty(eqx), return; end
    W = eqx.Sb + eqx.q * eqx.Kbar;
    fprintf(['[%5.0fs] 2D %2d: beta=%.5f chi=%.5f | W=%.3f omega=%.3f ' ...
             'S_b=%.4f q=%.3f | rW=%+.4f rom=%+.4f\n'], ...
            toc(t0), it, exp(min(x(1), lb_max)), exp(x(2)), W, ...
            eqx.Sb/max(W,1e-12), eqx.Sb, eqx.q, r(1), r(2));
end

function eqx = eval_own(rb, d, D, g, lv, Bnom, Kbar, iota, pp, q_ref)
    eqx = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pp, q_ref, false);
    if isstruct(eqx) && eqx.ok, eqx.Kbar = Kbar; end
end

function [beta_star, eq0] = calib_beta(rb, d, D, g, lv, Bnom, Kbar, btH, iota, p, q_ref, t0)
    % LEVEL calibration: beta targets the direct liquid holding S_b.
    %
    % Why beta and not chi. Household liquid wealth factors as S_b = omega*W,
    % where omega is the liquid SHARE and W total wealth. chi moves only
    % omega. The infrequent-adjustment friction raises W sharply (the tree is
    % a poor buffer, so households self-insure with more of everything: at the
    % frictionless-calibrated beta, W = 3.3 -> 6.8 x income) AND raises
    % omega's floor (absent a liquidity premium an illiquid asset is dominated
    % as a buffer, so bond demand cannot be squeezed below it). Both moves
    % push S_b UP, and chi -> 0 merely asymptotes to omega_min*W. beta is the
    % instrument that moves W, hence the only one that reaches the level.
    %
    % Monotone: lower beta -> less patient -> lower W -> lower S_b. Lowering
    % beta also deflates q (raising the tree's dividend yield toward a
    % plausible value) and thins liquid buffers, which is what generates the
    % wealthy-hand-to-mouth mass the friction is there to deliver.
    b0 = p.beta;
    beta_grid = b0 * [0.95 0.97 0.985 1.00];
    eq0 = []; beta_star = b0; best = Inf;
    bb = b0; bb_p = NaN; e_p = NaN;
    for k = 1:numel(beta_grid)
        pk = p; pk.beta = beta_grid(k);
        eqk = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pk, q_ref, false);
        if ~eqk.ok
            fprintf('[%5.0fs] pre-scan beta=%.5f FAILED (%s)\n', toc(t0), beta_grid(k), eqk.msg);
            continue;
        end
        err = log(eqk.Sb) - log(btH);
        fprintf('[%5.0fs] pre-scan beta=%.5f S_b=%.4f q=%.3f W=%.3f err=%+.4f (min_c=%.3f)\n', ...
            toc(t0), beta_grid(k), eqk.Sb, eqk.q, eqk.Sb + eqk.q*Kbar, err, eqk.min_c);
        if abs(err) < best
            best = abs(err); eq0 = eqk; beta_star = beta_grid(k); bb = beta_grid(k);
        end
    end
    if isempty(eq0), return; end
    % secant in beta from the best pre-scan point
    err = log(eq0.Sb) - log(btH);
    nfail = 0; damp = 1;
    for itc = 1:8
        if abs(err) < 2e-2, break; end
        if isfinite(e_p) && abs(err - e_p) > 1e-9
            step = -err*(bb - bb_p)/(err - e_p);
        else
            step = -sign(err) * 0.015 * b0;      % err>0 (S_b too high) -> beta down
        end
        step = damp * max(min(step, 0.02*b0), -0.02*b0);   % damped trust region
        bb_try = min(max(bb + step, 0.80), 0.9995); % keep beta admissible
        if abs(bb_try - bb) < 1e-6, break; end
        pk = p; pk.beta = bb_try;
        eqk = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pk, q_ref, false);
        if ~eqk.ok
            fprintf('[%5.0fs] secant beta=%.5f FAILED (%s)\n', toc(t0), bb_try, eqk.msg);
            nfail = nfail + 1; damp = 0.4*damp;  % retry closer to the feasible point
            if nfail >= 3
                fprintf(['[calib] beta secant stalled; reporting best feasible ' ...
                    'S_b=%.4f at beta=%.5f.\n'], eq0.Sb, beta_star);
                break;
            end
            continue;                            % keep (bb, err); retry a shorter step
        end
        nfail = 0; damp = min(1, 2*damp);
        bb_p = bb; e_p = err; bb = bb_try;
        eq0 = eqk; beta_star = bb_try; err = log(eqk.Sb) - log(btH);
        fprintf('[%5.0fs] secant beta=%.5f S_b=%.4f q=%.3f W=%.3f err=%+.4f (min_c=%.3f)\n', ...
            toc(t0), beta_star, eqk.Sb, eqk.q, eqk.Sb + eqk.q*Kbar, err, eqk.min_c);
    end
end

function eq = solve_own_kv(rb, d, D, g, use_levy, Bnom, Kbar, iota, p, q_ref, verbose, qwin)
% (P, q, tau, div) equilibrium with the KV household + intermediation wedge.
% q-bracket anchored on q_ref (the known frictionless-ownership tree price);
% expands adaptively if the tree market does not bracket on the first pass.
    if nargin < 11 || isempty(q_ref), q_ref = d/max(rb,5e-3); end
    if nargin < 12 || isempty(verbose), verbose = false; end
    % qwin: relative [lo hi] multipliers on q_ref for the initial tree-price
    % bracket. The BASELINE searches wide (the level is unknown); a FINANCING
    % EXPERIMENT is a small perturbation of a known baseline, so it searches
    % tight. Searching wide there let the bisection settle on a DIFFERENT
    % root: the zeta=1 experiments returned q = 1.56 against a baseline of
    % 3.42, and the KMV/phi=0.25 experiments returned the SAME q for lump-sum
    % and levy -- both branch jumps, not economics.
    if nargin < 13 || isempty(qwin), qwin = [0.55 1.80]; end
    lastwhy = '';                                % last failure reason (nested)
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'tau',NaN, ...
                'div',NaN,'dist',[],'bch',[],'kch',[],'n_infeas',0,'min_c',NaN, ...
                'ksat',NaN);
    pe = p; pe.eGrid = (1 - D) * p.eGrid;
    if use_levy, pe.eGrid = (1 - g/(1-D)) * pe.eGrid; end
    tau = rb*1.10 + (~use_levy)*g;
    div = d + rb*(1-iota)*1.10/Kbar;
    Vc = [];
    lo = qwin(1)*q_ref; hi = qwin(2)*q_ref; qs = linspace(lo, hi, 6); fq = nan(size(qs));
    for i = 1:numel(qs), [fq(i), tau, div, ~, Vc] = evq(qs(i), tau, div, Vc); end
    kk = bracket_finite(fq);
    for expand = 1:3                             % adaptive bracket expansion
        if ~isempty(kk), break; end
        lo = 0.5*lo; hi = 1.6*hi; qs = linspace(lo, hi, 7); fq = nan(size(qs));
        for i = 1:numel(qs), [fq(i), tau, div, ~, Vc] = evq(qs(i), tau, div, Vc); end
        kk = bracket_finite(fq);
    end
    if verbose
        fprintf('    q-scan: q=%s\n              Sk-K=%s\n', ...
            mat2str(qs,3), mat2str(fq,3));
    end
    if isempty(kk)
        nfin = sum(isfinite(fq));
        eq.msg = sprintf('no q bracket (%d/%d finite; Sk-K in [%+.3f,%+.3f]; last fail: %s)', ...
            nfin, numel(fq), min(fq), max(fq), lastwhy);
        return;
    end
    a = qs(kk(1)); b = qs(kk(2)); fa = fq(kk(1)); m = a; Sb = NaN; ninf = 0; mc = NaN; ksat = NaN;
    for it = 1:26
        m = 0.5*(a+b);
        [fm, tau, div, Sb, Vc, dist, bch, kch, ninf, mc, ksat] = evq(m, tau, div, Vc);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 5e-4 || (b-a) < 2e-4*q_ref, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb) || Sb <= 0, eq.msg = 'non-finite end'; return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb; eq.tau = tau; eq.div = div;
    eq.P = iota*Bnom/Sb; eq.dist = dist; eq.bch = bch; eq.kch = kch;
    eq.n_infeas = ninf; eq.min_c = mc; eq.ksat = ksat;

    function [f, tt, dv, Sb, Vc, dist, bch, kch, ninf, mc, ksat] = evq(qq, tinit, dvinit, Vc)
        tt = tinit; dv = dvinit; Sb = NaN; Sk = NaN; rprev = NaN;
        dist = []; bch = []; kch = []; ninf = 0; mc = NaN; ksat = NaN;
        pev = pe;                                % capped sweeps when warm
        if ~isempty(Vc), pev.maxit_vfi = 250; end
        for itt = 1:10
            [sol, dg] = solve_household_twoasset_kv(rb, qq, dv, tt, pev, Vc);
            if ~dg.converged && ~isempty(Vc)
                % the warm start may be poisoned by a distant trial q -- retry
                % ONCE from the analytic cold init before giving up.
                pcold = pev; pcold.maxit_vfi = max(pev.maxit_vfi, 400);
                [sol, dg] = solve_household_twoasset_kv(rb, qq, dv, tt, pcold, []);
            end
            Vc = sol.V;                          % KEEP progress even on failure
            if ~dg.converged
                f = NaN;
                lastwhy = sprintf('household dV=%.1e after %d sweeps', dg.supnorm, dg.iters);
                return;
            end
            [dist, dd] = stationary_distribution_twoasset_kv(sol, rb, qq, dv, tt, pev);
            if ~dd.converged
                f = NaN;
                lastwhy = sprintf('distribution dv=%.1e after %d iters', dd.supnorm, dd.iters);
                return;
            end
            if isfield(dg,'n_infeas'), ninf = dg.n_infeas; end
            msk = dist(:) > 1e-8;                 % min consumption on the support
            if any(msk), cc = sol.polCn(:); mc = min(cc(msk)); end
            % k-grid saturation: with retained dividends the non-adjuster's k
            % drifts UP, so mass can pile against kGrid(end) and make the
            % tree aggregate grid-dependent. Report the share at the top two
            % nodes; a non-trivial value means kmax must be raised.
            kmass = squeeze(sum(sum(dist, 1), 3)); kmass = kmass(:);
            ksat = sum(kmass(max(1,end-1):end)) / max(sum(kmass), eps);
            [Sb, Sk, bch, kch] = kv_agg(sol, dist, rb, qq, dv, tt, pe);
            P = iota*Bnom/max(Sb, 1e-9);
            tgt_tau = rb*(Bnom/P) + (~use_levy)*g;
            tgt_div = d + rb*(1-iota)*(Bnom/P)/Kbar;
            r1 = tgt_tau - tt;
            if abs(r1) < 1e-6 && abs(tgt_div - dv) < 1e-6, break; end
            if isfinite(rprev) && sign(r1)~=sign(rprev) && abs(r1)>abs(rprev)
                tt = 0.5*(tt + tgt_tau);
            else
                tt = tgt_tau;
            end
            dv = tgt_div; rprev = r1;
        end
        f = Sk - Kbar;
    end
end

function ij = bracket_finite(fq)
% First sign change between CONSECUTIVE FINITE entries of the q-scan,
% BRIDGING any NaN gap between them. The previous test demanded that the
% sign-change pair be grid-ADJACENT, so a single failed q in the middle of
% an otherwise good scan destroyed a bracket that plainly existed (e.g.
% Sk-K running from +57 down to -0.97 with two NaNs in between). Returns
% [i1 i2] with i1 < i2, or [] if the finite points never change sign.
    ij = [];
    fi = find(isfinite(fq));
    for jj = 1:numel(fi)-1
        if sign(fq(fi(jj))) ~= sign(fq(fi(jj+1)))
            ij = [fi(jj), fi(jj+1)];
            return;
        end
    end
end

function [Sb, Sk, bch, kch] = kv_agg(sol, dist, rb, q, d, tau, pe)
    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb; ynet = pe.eGrid(:)' - tau;
    bch = zeros(nb,nk,ne); kch = zeros(nb,nk,ne);
    for ie = 1:ne
        xbk = min(max(ynet(ie) + Rb*bG + (q+d)*kG', pe.xGridA(1)), pe.xGridA(end));
        bpa = interp1(pe.xGridA, sol.polBa(:,ie), xbk, 'linear');
        kpa = interp1(pe.xGridA, sol.polKa(:,ie), xbk, 'linear');
        % non-adjuster illiquid position: k, or the compounded k' when part
        % of the dividend is retained inside the illiquid account (phi < 1)
        knon = kG';
        if isfield(sol, 'kNon'), knon = sol.kNon(:)'; end
        bch(:,:,ie) = lam*bpa + (1-lam)*squeeze(sol.polBn(:,:,ie));
        kch(:,:,ie) = lam*kpa + (1-lam)*repmat(knon, nb, 1);
    end
    Sb = sum(bch(:).*dist(:)); Sk = sum(kch(:).*dist(:));
end

function H = htm_bk(dist, bch, kch, q, htm_b, whtm_k)
    w = dist(:)/sum(dist(:)); bv = bch(:); kv = kch(:);
    isb = bv <= htm_b; isk = q*kv >= whtm_k;
    H = struct('htm',sum(w(isb)),'whtm',sum(w(isb & isk)),'phtm',sum(w(isb & ~isk)));
    wealth = bv + q*kv; [ws, io] = sort(wealth); wsr = w(io);
    cw = cumsum(wsr); tw = sum(ws.*wsr);
    H.top10 = sum(ws(cw>=0.90).*wsr(cw>=0.90))/tw;
    H.top1  = sum(ws(cw>=0.99).*wsr(cw>=0.99))/tw;
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
