% MAIN_PREFERRED_DECOMPOSITION  The mechanism of the PREFERRED calibration,
% decomposed in its own economy, plus validation of the two-market
% Schur-complement price derivative.
%
% WHY. The paper's mechanism result -- that the stationary response of
% nominal-liability demand to a regressive financing tilt is carried by
% movement of the wealth distribution rather than by the direct saving
% response at the initial distribution -- is established in the ONE-ASSET
% economy. It cannot be imported into the preferred two-asset calibration,
% which restores the level sign through additional margins: an illiquid
% price that feeds back, an intermediated share of the debt whose dividend
% moves with the price level, and an adjustment friction that decides who
% can act at all. This driver asks whether the preferred model reproduces
% the same economics or merely the same sign through different forces.
%
% STATUS: DIAGNOSTIC, not final. The calibration is frozen at the current
% benchmark; the illiquid market clears by bisection; and none of the
% numbers here are quotable until the gates below pass and the calibration
% questions (liability balance sheet, payout convention) are settled.
%
% =====================================================================
% WHAT IS COMPUTED
%
% (A) EXACT FINITE-CHANGE DECOMPOSITION of the move from lump-sum
%     (alpha = 0) to levy (alpha = 1) financing. Writing aggregate bond
%     demand as S_b = int b'(s; X) dOmega(s; X) with X = (tau, q, div),
%     the two-way split is exact and needs no approximation:
%
%       dS_b = int [b'(X1) - b'(X0)] dOmega(X0)      POLICY
%            + int b'(X0) d[Omega(X1) - Omega(X0)]   DISTRIBUTION
%            + int [b'(X1)-b'(X0)] d[Omega1-Omega0]  INTERACTION
%
%     Each of the first two is then split by DRIVER -- the financing
%     instrument tau, the illiquid price q, and the intermediary dividend
%     div -- by an exact Shapley value over the three drivers (2^3 = 8
%     household solves per block). Shapley is used rather than sequential
%     shutdown because the order of shutdown is arbitrary and the channels
%     interact: Shapley is the unique attribution that is efficient
%     (components sum to the total), symmetric, and null-player-consistent.
%     The resulting five components are the referee's:
%       direct policy (tau) | distribution | q-feedback | intermediation | interaction
%
% (B) LOCAL JACOBIAN DECOMPOSITION at the baseline: each of
%     dS_b/dtau, dS_b/dq, dS_b/dP is split into a POLICY part (distribution
%     held at baseline) and a DISTRIBUTION part (policies held at
%     baseline), by central differences.
%
% (C) TWO-MARKET SCHUR-COMPLEMENT VALIDATION (Proposition 8). With
%       F_b(P,q;alpha) = S_b - iota*B/P,   F_k(P,q;alpha) = S_k - Kbar,
%     the price derivative is
%       dP/dalpha = -N_alpha / M,
%       N_alpha = F_b,alpha - F_bq F_k,alpha / F_kq,
%       M       = F_bP      - F_bq F_kP      / F_kq,
%     computed from central differences of the two residuals, and compared
%     against a SOLVED central difference in which the full equilibrium
%     (P and q jointly) is re-solved at alpha +- h.
%
% GATES (all must pass before any number is used, and before the full
% climate transition is attempted):
%   G1 RECONSTRUCTION  the five components sum to the measured dS_b
%   G2 SHAPLEY EFFICIENCY  each block's driver split sums to that block
%   G3 FINITE DIFFERENCE  the Schur prediction matches the solved
%      derivative; the achieved relative error is reported, and the gate is
%      set at the level the underlying solvers can actually support
%   G4 GRID  the qualitative split (which component dominates, and the sign
%      of each) is unchanged on coarser grids, and the LEVEL sequence over
%      three grids is reported so convergence can be distinguished from
%      mere movement
%
% PARALLELISM. Independent equilibria run concurrently: the eight Shapley
% coalitions, and the alternative-grid rebuilds (one grid per worker, each
% running its own alpha = 0 -> alpha = 1 continuation serially). The
% continuation itself, the bisection inside it, the (P,tau,div) fixed point
% and the household VFI are chains and stay serial -- as does the Schur
% finite-difference ladder, whose three alpha solves warm-start from one
% another. parfor degrades to a for-loop without the toolbox, so the
% computed result does not depend on whether a pool exists.
%
% USAGE   >> clear; main_preferred_decomposition
%         >> clear; FAST = true; main_preferred_decomposition   (coarse only)
%         >> clear; SKIPGRID = true; main_preferred_decomposition
%         >> clear; PARALLEL = false; main_preferred_decomposition
%         >> clear; NWORKERS = 8; main_preferred_decomposition
%
% REQUIRES output/twoasset_ownership_kv.mat
% OUTPUT   output/tables/preferred_decomposition.txt
%          output/preferred_decomposition.mat

clearvars -except FAST SKIPGRID PARALLEL NWORKERS; close all; clc;
rng(20260731, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
if ~exist('SKIPGRID','var'), SKIPGRID = false; end
if ~exist('PARALLEL','var') || isempty(PARALLEL), PARALLEL = true; end
if ~exist('NWORKERS','var'), NWORKERS = []; end

mf = fullfile(projdir, 'output', 'twoasset_ownership_kv.mat');
assert(exist(mf,'file')==2, 'run main_twoasset_ownership_kv first');
S = load(mf);
assert(isfield(S,'eq0') && S.eq0.ok, 'saved benchmark equilibrium not ok');
p = S.p; iota = S.iota_H; r_b = S.r_b; d_base = S.d_base; D0 = S.D0; Gg = S.Gg;
pg = setup_params_green(); Bnom = pg.Bnom; Kbar = 1.0;
eq0 = S.eq0;
g_real = Gg / eq0.P;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'preferred_decomposition.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});
tee('PREFERRED-CALIBRATION MECHANISM DECOMPOSITION  (DIAGNOSTIC)\n');
tee('grids nb=%d nk=%d ne=%d; lambda=%.2f iota_H=%.3f; g_real=%.5f\n\n', ...
    numel(p.bGrid), numel(p.kGrid), numel(p.eGrid), p.lambda_adj, iota, g_real);

if ~isfield(p,'acGrid') || ~isfield(p,'sGrid')
    error('saved calibration lacks the adjuster candidate grids');
end

% FAST genuinely coarsens the STATE grids so gates can be debugged in about
% an hour rather than the ten hours the full run takes. It rebuilds them from
% the curvature the CALIBRATION used, not from a literal 2.4, so a coarse run
% is a subsample of the benchmark grid rather than a different grid.
if FAST
    nbF = max(28, round(numel(p.bGrid)*0.5));
    nkF = max(16, round(numel(p.kGrid)*0.5));
    [blo,bhi,gbF] = kv_grid_curv(p.bGrid); p.bGrid = kv_grid_build(blo,bhi,gbF,nbF);
    [klo,khi,gkF] = kv_grid_curv(p.kGrid); p.kGrid = kv_grid_build(klo,khi,gkF,nkF);
    tee('*** FAST: state grids coarsened to nb=%d nk=%d (DEBUG ONLY) ***\n\n', nbF, nkF);
end

% BOUNDARY REPAIR. main_kv_residual_scan found the reduced tree residual to
% be a genuine function of q (zero hysteresis) with converged households, and
% located the defect at the grid ceilings: 2.8e-3 of mass in the top two
% nodes of both the k- and the b-grid, ~29x the 1e-4 tolerance. Mass against
% a wall does not respond to q, so no widening means no differentiable
% equilibrium map and no admissible Schur derivative.
%
% The factors are NOT re-derived here. They are read from the scan that
% verified them, so the decomposition and the diagnosis run on the same
% grids; the hard-coded fallback is only for a decomposition run made before
% any scan exists, and it is labelled as unverified when it is used.
WID = struct('changed',false); kfac = 1; bfac = 1;
scf = fullfile(projdir, 'output', 'kv_residual_scan.mat');
if exist(scf,'file')==2
    Sc = load(scf, 'kfac', 'bfac', 'V');
    kfac = Sc.kfac; bfac = Sc.bfac;
    vpass = isfield(Sc,'V') && isfield(Sc.V,'boundary_pass') && Sc.V.boundary_pass;
    tee('boundary factors from kv_residual_scan: kfac=%.1f bfac=%.1f (scan gate: %s)\n', ...
        kfac, bfac, ternstr(vpass, 'PASSED', 'NOT PASSED'));
    if ~vpass
        tee('  WARNING: the scan did not clear the 1e-4 boundary gate at these\n');
        tee('  factors. Every number below inherits that truncation.\n');
    end
else
    kfac = 12;
    tee('*** no kv_residual_scan.mat: falling back to kfac=%.1f UNVERIFIED ***\n', kfac);
end
% TARGET STATE, NOT OPERATION. This used to call kv_widen_grids directly on
% the p loaded from twoasset_ownership_kv.mat, which was right until REGRID
% began saving the WIDENED p to that file. From then on the factors were
% applied a second time (kmax 60 -> 360 -> 2160, bmax 12 -> 96 -> 768) with
% nothing to warn that they had been. kv_ensure_widened is idempotent: it
% no-ops when the grid is already at the target and errors when it is at
% neither the target nor the base.
[p, GR] = kv_ensure_widened(p, kfac, bfac, ...
             struct('r_b',r_b,'q',eq0.q,'d',d_base,'kref',5,'bref',3), tee);
if strcmp(GR.action,'APPLIED')
    tee('  CAVEAT beta and chi_b were calibrated on the pre-widening grids.\n');
    tee('  These results stay DIAGNOSTIC until main_twoasset_ownership_kv is\n');
    tee('  recalibrated on the widened grid.\n');
elseif strcmp(GR.action,'ALREADY')
    tee('  The loaded calibration is ALREADY on these grids, so beta and chi_b\n');
    tee('  belong to them and the pre-widening caveat does not apply.\n');
end
WID = GR.W;
tee('\n');

% CANDIDATE-GRID REFINEMENT. The adjuster's portfolio choice is an argmax
% over a discrete candidate set (acGrid x sGrid, 100 x 22 as calibrated).
% That set is a NUMERICAL discretization of a continuous choice, not an
% economic parameter, and it is what makes S_k(q) a step function: as q
% moves, the argmax jumps between candidates, so the tree market has no
% exact zero and bisection lands on a discontinuity (the alpha = 1 failure).
% Refining it here smooths the market residual without touching the
% economics. It runs AFTER the widening so it refines the widened outlay
% grid, and it inherits that grid's curvature instead of resetting it.
nac0 = numel(p.acGrid); nsh0 = numel(p.sGrid);
REF = 3;                       % candidate-grid refinement factor
if FAST, REF = 1; end
if REF > 1
    [aclo, achi, gac] = kv_grid_curv(p.acGrid);
    p.acGrid = kv_grid_build(aclo, achi, gac, REF*nac0);
    nsh = REF*nsh0;  p.sGrid = linspace(1/nsh, 1, nsh);
    tee('candidate grid refined %dx: acGrid %d -> %d, sGrid %d -> %d (curvature %.2f)\n', ...
        REF, nac0, numel(p.acGrid), nsh0, numel(p.sGrid), gac);
    tee('  (a numerical discretization of the portfolio choice; the tree\n');
    tee('   market residual is a step function at the coarse setting)\n\n');
end

CTX = struct('p',p,'iota',iota,'r_b',r_b,'d_base',d_base,'D0',D0, ...
             'Bnom',Bnom,'Kbar',Kbar,'g_real',g_real,'qref',eq0.q, ...
             'Pseed',eq0.P,'W0',[]);

% PARALLELISM. Brought up once, here, so the Shapley coalitions and the grid
% rebuilds below find a pool rather than each paying to start one. What is
% parallelised is only work that is INDEPENDENT: the eight Shapley
% coalitions, and the alternative-grid equilibria. What is not, and must not
% be, is the alpha = 0 and alpha = 1 solve immediately below -- alpha = 1
% continues from alpha = 0's tree price and shares its value function as a
% warm start, so running them concurrently would change what is computed, not
% just how fast. Inside each equilibrium the bisection, the (P,tau,div) fixed
% point and the household VFI are all chains and stay serial.
NWP = kv_parpool(PARALLEL, NWORKERS, true, tee, ...
                 {fullfile(rootdir,'src'), fullfile(projdir,'src_project')});
tee('parallel: %s\n\n', ternstr(NWP>0, sprintf(['%d workers for the Shapley ' ...
    'coalitions and the grid rebuilds'], NWP), 'serial'));

% ---------------------------------------------------------------- (A)+(B)
% ALPHA-CONTINUATION. alpha = 1 is not solved from the alpha = 0 guess in one
% jump any more. The widened k-grid moved the admissible q region, and a
% single long step lands the bracket search outside it -- which is how the
% scan ended up reporting a NaN endpoint as a bracket. Stepping
% 0 -> 0.5 -> 1, each seeded with the previous converged tree price, value
% function and price level, keeps every search centred inside the region
% where the model is defined. alpha = 0.5 is a stepping stone; only E0 and E1
% enter the decomposition.
tee('===== solving the financing equilibria by alpha-continuation =====\n');
E0 = solve_alpha(0.0, CTX, eq0.q, true, tee);   % lump-sum
assert(E0.ok, 'alpha=0 equilibrium failed: %s', E0.msg);
CTX.W0 = E0.sol.V;                              % shared warm start (Shapley/FD)
CTX.Wseed = E0.sol.V; CTX.Pseed = E0.P;         % continuation seed
Eh = solve_alpha(0.5, CTX, E0.q, true, tee);    % stepping stone
qg = E0.q;
if Eh.ok
    CTX.Wseed = Eh.sol.V; CTX.Pseed = Eh.P; qg = Eh.q;
else
    tee('  alpha=0.5 failed (%s); stepping straight to alpha=1\n', Eh.msg);
end
E1 = solve_alpha(1.0, CTX, qg, true, tee);      % levy
assert(E1.ok, 'alpha=1 equilibrium failed: %s', E1.msg);
% The finite differences and the Shapley coalitions must all start from ONE
% place, or the soft-accepted VFI settles on different plateaus and the
% difference of two equilibria picks up the difference of two warm starts.
CTX.Wseed = E0.sol.V; CTX.Pseed = E0.P;
tee('  alpha=0 (lump-sum): P=%.6f q=%.6f Sb=%.6f Sk=%.6f\n', E0.P,E0.q,E0.Sb,E0.Sk);
tee('  alpha=1 (levy)    : P=%.6f q=%.6f Sb=%.6f Sk=%.6f\n', E1.P,E1.q,E1.Sb,E1.Sk);
tee('  dlnP = %+0.5f (solved, equilibrium-to-equilibrium)\n\n', log(E1.P/E0.P));

DEC = finite_decomposition(E0, E1, CTX, tee);

% ---------------------------------------------------------------- (C)
tee('\n===== two-market Schur-complement validation (Prop 8) =====\n');
SCH = schur_validate(E0, CTX, tee);

% ---------------------------------------------------------------- gates
tee('\n===== gates =====\n');
% G0. S_k(q) is a step function at fine scales (discrete adjuster choices),
% so bisection can collapse its bracket onto a DISCONTINUITY rather than a
% zero. When that happens the "equilibrium" does not clear the tree market
% and every derivative taken around it is meaningless. Gate on it.
clr0 = abs(E0.Sk - Kbar); clr1 = abs(E1.Sk - Kbar);
g0 = max(clr0, clr1) < 1e-4;
tee('G0 tree clearing   : |Sk-K| alpha=0 %.2e, alpha=1 %.2e  %s\n', ...
    clr0, clr1, ternstr(g0,'PASS','FAIL'));
if ~g0
    tee('   the bisection converged on a discontinuity of S_k(q), not a zero;\n');
    tee('   derivatives taken around this point are not interpretable.\n');
end
g1 = abs(DEC.recon_err) < 1e-9 * max(1, abs(DEC.dSb));
tee('G1 reconstruction  : residual %.3e  %s\n', DEC.recon_err, ternstr(g1,'PASS','FAIL'));
% G2 SPLIT. A single aggregate efficiency check hid a real defect: the
% policy block added exactly while the distribution block's printed terms
% did not sum to the printed block. Each displayed block now has its own
% gate, and each must add EXACTLY as displayed.
tolS = 1e-9 * max(1, abs(DEC.dSb));
g2a = abs(DEC.shap_err(1)) < tolS;                       % policy block
g2b = abs(DEC.shap_err(2)) < tolS;                       % distribution block
g2c = abs(sum(DEC.comp) - DEC.dSb) < tolS;               % five components
g2 = g2a && g2b && g2c;
tee('G2a policy shapley  : residual %.3e  %s\n', DEC.shap_err(1), ternstr(g2a,'PASS','FAIL'));
tee('G2b distrib shapley : residual %.3e  %s\n', DEC.shap_err(2), ternstr(g2b,'PASS','FAIL'));
tee('G2c component sum   : residual %.3e  %s\n', sum(DEC.comp)-DEC.dSb, ternstr(g2c,'PASS','FAIL'));
if ~g2b
    tee('   the distribution Shapley endpoints are not the displayed block:\n');
    tee('   the all-switched subset re-solves its own stationary distribution,\n');
    tee('   while the block uses the solved alpha=1 equilibrium distribution.\n');
end
g3 = isfinite(SCH.relerr) && SCH.relerr < SCH.tol;
tee('G3 finite difference : rel err %.3e vs tol %.1e  %s\n', SCH.relerr, SCH.tol, ternstr(g3,'PASS','FAIL'));

g4 = NaN; GRD = struct('fac',[],'dSb',[],'ok',[]);
if ~SKIPGRID && ~FAST
    % THREE grids, not two. The previous version compared the benchmark
    % against a single 0.7x rebuild and, when the levels disagreed, said in
    % its own output that "a third grid is needed before any level enters the
    % paper". A two-point comparison can say the level MOVED; it cannot say
    % whether it is converging, and that is the question. The grids are
    % independent equilibria, so they run one per worker -- each solving its
    % own alpha = 0 -> alpha = 1 continuation SERIALLY, which is the only way
    % that continuation may be run.
    GF = [0.85 0.70];
    tee('\n----- G4 grid check (%d independent rebuilds at %s of the node count) -----\n', ...
        numel(GF), strtrim(sprintf('%.2fx ', GF)));
    nwG = kv_parpool(PARALLEL, NWORKERS, true, tee, ...
                     {fullfile(rootdir,'src'), fullfile(projdir,'src_project')});
    tee('  solving %d grids on %s\n', numel(GF), ...
        ternstr(nwG>0, sprintf('%d workers', nwG), 'one worker (serial)'));
    CTXs = cell(1,numel(GF)); ES = cell(1,numel(GF)); qref = eq0.q;
    for i = 1:numel(GF), Ci = CTX; Ci.p = coarsen(p, GF(i)); CTXs{i} = Ci; end
    parfor i = 1:numel(GF)
        Ci = CTXs{i};
        E0i = kv_solve_alpha(0.0, Ci, qref, false, []);
        if ~E0i.ok, ES{i} = []; continue; end
        E1i = kv_solve_alpha(1.0, Ci, E0i.q, false, []);   % serial continuation
        if ~E1i.ok, ES{i} = []; continue; end
        ES{i} = {E0i, E1i};
    end
    % The decompositions run on the client: finite_decomposition is a local
    % function of this script and workers cannot see it, and it is cheap
    % relative to the equilibrium solves that were just parallelised.
    DECs = cell(1,numel(GF));
    for i = 1:numel(GF)
        if isempty(ES{i}), continue; end
        DECs{i} = finite_decomposition(ES{i}{1}, ES{i}{2}, CTXs{i}, @(varargin) []);
    end
    good = find(~cellfun(@isempty, DECs));
    GRD.fac = GF; GRD.ok = ~cellfun(@isempty, DECs);
    GRD.dSb = nan(1,numel(GF));
    for i = good, GRD.dSb(i) = DECs{i}.dSb; end

    if isempty(good)
        tee('G4 grid            : every coarse equilibrium failed -- INCONCLUSIVE\n');
    else
        % The decomposition's CLAIM is about which channel carries the
        % response, i.e. about SHARES. Gate on those, against the COARSEST
        % grid that solved -- the hardest comparison available. Levels are a
        % separate quantity, reported as a sequence below.
        ic = good(end);
        shF = DEC.comp        / max(abs(DEC.dSb), eps);
        shC = DECs{ic}.comp   / max(abs(DECs{ic}.dSb), eps);
        FLOOR = 0.05;                       % below 5% of the total is noise
        big = (abs(shF) > FLOOR) | (abs(shC) > FLOOR);
        same_sign = all(sign(shF(big)) == sign(shC(big)));
        close_sh  = max(abs(shF(big) - shC(big))) < 0.15;
        [~,iF] = max(abs(shF)); [~,iC] = max(abs(shC));
        g4 = same_sign && close_sh && (iF == iC);
        tee('  fine    shares: %s\n', vecstr(100*shF));
        tee('  coarsest shares (%.2fx): %s\n', GF(ic), vecstr(100*shC));
        tee('  components below the %.0f%% floor on both grids are exempt: %s\n', ...
            100*FLOOR, mat2str(find(~big)'));
        tee('G4 grid (shares)   : dominant %s, signs %s, max share gap %.1fpp  %s\n', ...
            ternstr(iF==iC,'same','DIFFER'), ternstr(same_sign,'match','DIFFER'), ...
            100*max(abs(shF(big)-shC(big))), ternstr(g4,'PASS','FAIL'));
        % LEVEL sequence: benchmark first, then coarser. Monotone AND
        % shrinking increments is what convergence looks like; anything else
        % is a level that has not settled.
        seq = [DEC.dSb, GRD.dSb(good)];
        tee('  LEVEL sequence dS_b (1.00x, then %s): %s\n', ...
            strtrim(sprintf('%.2fx ', GF(good))), vecstr(seq));
        d = abs(diff(seq));
        lvl = max(d)/max(abs(DEC.dSb), eps);
        if numel(d) >= 2
            tee('  successive |changes|: %s  -> increments %s\n', vecstr(d), ...
                ternstr(all(diff(d) < 0), 'SHRINKING', 'NOT shrinking'));
        end
        if lvl > 0.15
            tee('  *** The LEVEL of dS_b is NOT grid-converged (worst step %.0f%%).\n', 100*lvl);
            tee('  *** The share split may be quoted as a diagnostic; the magnitude\n');
            tee('  *** of dS_b may not.\n');
        end
    end
else
    tee('G4 grid            : skipped\n');
end

% ---------------------------------------------------- global finite-only gate
% Nothing that is not a finite number computed at an ADMISSIBLE point may
% enter a derivative, a Shapley value, a convergence comparison or a table. A
% NaN that reaches an average or a share silently becomes a claim.
fin = @(x) all(isfinite(x(:)));
gfparts = [fin([E0.Fk E0.Fb E1.Fk E1.Fb]), fin(DEC.comp), fin(DEC.dSb), ...
           fin([getf(SCH,'dP_pred') getf(SCH,'dP_sol')]), (isnan(g4) || fin(GRD.dSb(GRD.ok)))];
gf = all(gfparts);
tee('GF finite-only      : residuals %d  components %d  total %d  schur %d  grids %d  %s\n', ...
    gfparts(1), gfparts(2), gfparts(3), gfparts(4), gfparts(5), ternstr(gf,'PASS','FAIL'));
if ~gf
    tee('  A non-finite value reached a reported quantity. That is a feasibility\n');
    tee('  failure, not a small number: find the (alpha,q) point that produced it\n');
    tee('  with main_kv_residual_scan before reading anything below.\n');
end

allpass = gf && g0 && g1 && g2 && g3 && (isnan(g4) || g4);
tee('\nGATES %s. %s\n', ternstr(allpass,'PASS','FAIL'), ternstr(allpass, ...
   'The decomposition may be interpreted (as a diagnostic at the frozen calibration).', ...
   'DO NOT interpret the components, and do not begin the full climate transition.'));

save(fullfile(projdir,'output','preferred_decomposition.mat'), ...
     'DEC','SCH','E0','E1','Eh','CTX','g0','g1','g2','g3','g4','gf','GRD');
tee('\n[main_preferred_decomposition] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
% The pricing, tax, dividend and equilibrium-solver primitives now live in
% src_project as kv_* files rather than as locals here, because parallel
% workers cannot see a script's local functions. These are thin wrappers so
% the call sites below are unchanged and there is still exactly ONE
% definition of each.
function pe = prices_to_pe(alpha, CTX)
    pe = kv_prices_to_pe(alpha, CTX);
end

function tau = tau_of(alpha, P, CTX)
    tau = kv_tau_of(alpha, P, CTX);
end

function dvd = div_of(P, CTX)
    dvd = kv_div_of(P, CTX);
end

function E = solve_alpha(alpha, CTX, q_guess, verbose, tee)
% Wrapper. The solver itself lives in src_project/kv_solve_alpha.m so that a
% worker solving one alternative grid can call it. It is and stays SERIAL:
% the bisection is a sequential search and the inner (P,tau,div) fixed point
% and the household VFI are contractions. Parallelism in this project sits
% one level up, across independent equilibria.
    E = kv_solve_alpha(alpha, CTX, q_guess, verbose, tee);
end

function D = finite_decomposition(E0, E1, CTX, tee)
% exact two-way split, then an exact Shapley split of each block by driver
    p0 = struct('tau',E0.tau,'q',E0.q,'dvd',E0.dvd,'alpha',E0.alpha);
    p1 = struct('tau',E1.tau,'q',E1.q,'dvd',E1.dvd,'alpha',E1.alpha);

    % --- policy block: b'(X1) vs b'(X0), both against Omega0
    Sb_X1_O0 = agg_at(p1, E0.dist, CTX);
    Sb_X0_O0 = E0.Sb;
    Sb_X0_O1 = agg_at(p0, E1.dist, CTX);
    Sb_X1_O1 = E1.Sb;
    POL  = Sb_X1_O0 - Sb_X0_O0;
    DIST = Sb_X0_O1 - Sb_X0_O0;
    INTER= (Sb_X1_O1 - Sb_X0_O1) - (Sb_X1_O0 - Sb_X0_O0);
    dSb  = Sb_X1_O1 - Sb_X0_O0;

    % --- Shapley split of the POLICY block over drivers {tau, q, div}
    [shP, errP] = shapley3(p0, p1, E0.dist, CTX);
    % --- and of the DISTRIBUTION block: the same drivers, but the object is
    % the change in the aggregate induced by moving Omega, holding policies
    % at baseline. Only the distribution argument switches, so the driver
    % attribution is over which price moved the distribution; we obtain it
    % by re-solving the stationary distribution under each driver subset.
    [shD, errD] = shapley3_dist(p0, p1, CTX, DIST);

    % DIST is itself the distribution component; shD attributes THAT block
    % across drivers and is reported separately -- it must not be added
    % here, or the distribution effect would be counted twice.
    comp = [shP(1); DIST; shP(2); shP(3); INTER];
    names = {'direct policy (tau)','distribution','q-feedback', ...
             'intermediation (div)','interaction'};

    D = struct('dSb',dSb,'POL',POL,'DIST',DIST,'INTER',INTER, ...
               'shP',shP,'shD',shD,'comp',comp,'names',{names}, ...
               'recon_err', sum(comp)-dSb, 'shap_err',[errP errD], ...
               'Sb_X1_O0',Sb_X1_O0,'Sb_X0_O1',Sb_X0_O1);

    if ~isempty(tee) && isa(tee,'function_handle')
        tee('\n===== (A) exact finite-change decomposition of S_b =====\n');
        tee('total dS_b = %+0.6f  (lump-sum -> levy)\n', dSb);
        tee('  two-way : policy %+0.6f | distribution %+0.6f | interaction %+0.6f\n', ...
            POL, DIST, INTER);
        tee('  Shapley split of the policy block by driver:\n');
        tee('    tau %+0.6f | q %+0.6f | div %+0.6f  (sum %+0.6f vs %+0.6f)\n', ...
            shP(1), shP(2), shP(3), sum(shP), POL);
        tee('  Shapley split of the DISTRIBUTION block by driver (reported,\n');
        tee('  not added -- it attributes the same mass movement):\n');
        tee('    tau %+0.6f | q %+0.6f | div %+0.6f  (sum %+0.6f vs %+0.6f)\n', ...
            shD(1), shD(2), shD(3), sum(shD), DIST);
        tee('\n  FIVE-COMPONENT DECOMPOSITION (shares of |dS_b|):\n');
        for i = 1:numel(comp)
            tee('    %-22s %+0.6f  (%+6.1f%%)\n', names{i}, comp(i), ...
                100*comp(i)/max(abs(dSb),eps));
        end
        tee('    %-22s %+0.6f\n', 'SUM', sum(comp));
        tee('\n  reading: the one-asset economy attributes the response almost\n');
        tee('  entirely to the distribution term. If "direct policy" or\n');
        tee('  "q-feedback" dominates here, the preferred model reproduces the\n');
        tee('  SIGN through different forces, and the mechanism sentence in the\n');
        tee('  abstract cannot be carried over to it.\n');
    end
end

function v = agg_at(pr, dist, CTX)
% aggregate bond demand with policies solved at pr, evaluated against dist.
% The warm start matters here as well as in the derivatives: all 8 Shapley
% subsets sit near the baseline, and cold-starting each one lets the
% soft-accepted VFI settle on different plateau points, which shows up as
% noise in differences that are themselves small.
    pe = prices_to_pe(pr.alpha, CTX);
    W = []; if isfield(CTX,'W0'), W = CTX.W0; end
    out = kv_stationary_block(CTX.r_b, pr.q, pr.dvd, pr.tau, pe, W, dist);
    if out.ok, v = out.Sb; else, v = NaN; end
end

% The driver-subset mixer used to live here as well. It now lives ONLY in
% kv_shapley_coalition, because that is where the coalitions are evaluated:
% two copies of "which fields does subset T switch on" is precisely the kind
% of duplication that drifts silently and turns a Shapley decomposition into
% an arbitrary one. agg_stat went with it -- it had no remaining caller.

function [sh, err] = shapley3(p0, p1, dist0, CTX)
% exact Shapley values over three drivers for the POLICY block (distribution
% held at dist0). 8 evaluations; weights (|T|!(n-|T|-1)!)/n! with n=3.
%
% The eight coalitions are independent -- each re-solves the household
% problem at its own driver vector, sharing only the fixed warm start
% CTX.W0 -- so they run concurrently. parfor is a plain for-loop when there
% is no pool, so this is identical work either way; the only requirement is
% that the body call a FILE function, since a worker cannot see this
% script's local functions.
    M = dec2bin(0:7,3) - '0';                    % 8 x 3 masks
    V = zeros(8,1);
    parfor i = 1:8
        V(i) = kv_shapley_coalition(logical(M(i,:)), p0, p1, dist0, CTX, 'policy');
    end
    base = V(1);
    sh = zeros(3,1);
    w = @(s) factorial(s)*factorial(3-s-1)/factorial(3);
    for j = 1:3
        for i = 1:8
            if M(i,j) == 1, continue; end
            m1 = M(i,:); m1(j) = 1;
            i1 = bin2idx(m1);
            sh(j) = sh(j) + w(sum(M(i,:))) * (V(i1) - V(i));
        end
    end
    err = sum(sh) - (V(8) - base);
end

function [sh, err] = shapley3_dist(p0, p1, CTX, DIST_target)
% DIST_target is the DISPLAYED distribution block. The previous version
% measured its own efficiency against its own endpoints V(8)-V(1), which
% are NOT the displayed block: the all-switched subset re-solves the
% stationary distribution at (tau1,q1,div1), whereas the displayed block
% uses the actual alpha=1 equilibrium distribution, and the two differ
% because the equilibrium also solved for P. That is why the printed
% Shapley terms summed to -0.005500 against a block of -0.005611 while G2
% still reported machine-zero. Efficiency is now measured against the
% displayed target, and the endpoint gap is returned so it is visible.
% Shapley attribution of the DISTRIBUTION block by driver: each subset's
% stationary distribution is formed under that subset's prices, and the
% aggregate is taken with BASELINE policies.
    M = dec2bin(0:7,3) - '0';
    V = zeros(8,1);
    parfor i = 1:8
        V(i) = kv_shapley_coalition(logical(M(i,:)), p0, p1, [], CTX, 'dist');
    end
    sh = zeros(3,1);
    w = @(s) factorial(s)*factorial(3-s-1)/factorial(3);
    for j = 1:3
        for i = 1:8
            if M(i,j) == 1, continue; end
            m1 = M(i,:); m1(j) = 1;
            sh(j) = sh(j) + w(sum(M(i,:))) * (V(bin2idx(m1)) - V(i));
        end
    end
    if nargin >= 4 && ~isempty(DIST_target)
        err = sum(sh) - DIST_target;          % against the DISPLAYED block
    else
        err = sum(sh) - (V(8) - V(1));
    end
end

function i = bin2idx(m)
    i = m(1)*4 + m(2)*2 + m(3) + 1;
end

function SCH = schur_validate(E0, CTX, tee)
% Central differences of the two market residuals, the Schur components, and
% a solved central difference for comparison.
%
% THREE THINGS THE FIRST VERSION GOT WRONG, all fixed here.
%
% (1) BOUNDARY CLAMP. Evaluating at alpha = 0 with max(0, alpha-h) turns the
%     central difference into a FORWARD difference while still dividing by
%     2h, halving F_balpha, F_kalpha and the solved derivative alike. The
%     validation now runs at an INTERIOR alpha (default 0.5) so both sides
%     are genuine.
% (2) COLD STARTS. Each perturbed evaluation re-solved the VFI from scratch.
%     The KV solver soft-accepts a grid-limited fixed point, so the two
%     sides of a difference could land on different plateau points -- pure
%     noise, and at h = 1e-4 that noise swamps the signal. All perturbed
%     evaluations now share one warm start taken from the base equilibrium.
% (3) STEP SIZE. h = 1e-4 relative is far inside the granularity of the
%     discrete-choice policies, so the quotient measured jumps rather than
%     the smooth envelope. We now sweep several relative steps and report
%     the derivative at each, so step-dependence is visible instead of
%     hidden; the reported value is taken at the step where consecutive
%     estimates agree most closely.
    if isfield(CTX,'alpha_mid') && ~isempty(CTX.alpha_mid)
        am = CTX.alpha_mid;
    else
        am = 0.5;
    end
    tee('  evaluating at an interior alpha = %.2f (central differences are\n', am);
    tee('  one-sided at a boundary, which halves every alpha-derivative)\n');
    Em0 = solve_alpha(am, CTX, E0.q, false, []);
    if ~Em0.ok
        SCH = struct('relerr',NaN,'tol',NaN,'msg','interior equilibrium failed');
        tee('  interior equilibrium FAILED: %s\n', Em0.msg); return;
    end
    tee('  interior base: P=%.6f q=%.6f |Sk-K|=%.2e\n', Em0.P, Em0.q, abs(Em0.Sk-CTX.Kbar));
    W = Em0.sol.V;                                   % shared warm start

    hs = [3e-3 1e-2 3e-2];                           % relative steps
    rows = zeros(numel(hs), 7);
    for i = 1:numel(hs)
        hr = hs(i);
        hP = hr*Em0.P; hq = hr*Em0.q; ha = hr;
        FbP = (resid_b(Em0.P+hP,Em0.q,am,CTX,W) - resid_b(Em0.P-hP,Em0.q,am,CTX,W))/(2*hP);
        Fbq = (resid_b(Em0.P,Em0.q+hq,am,CTX,W) - resid_b(Em0.P,Em0.q-hq,am,CTX,W))/(2*hq);
        Fba = (resid_b(Em0.P,Em0.q,am+ha,CTX,W)  - resid_b(Em0.P,Em0.q,am-ha,CTX,W))/(2*ha);
        FkP = (resid_k(Em0.P+hP,Em0.q,am,CTX,W) - resid_k(Em0.P-hP,Em0.q,am,CTX,W))/(2*hP);
        Fkq = (resid_k(Em0.P,Em0.q+hq,am,CTX,W) - resid_k(Em0.P,Em0.q-hq,am,CTX,W))/(2*hq);
        Fka = (resid_k(Em0.P,Em0.q,am+ha,CTX,W)  - resid_k(Em0.P,Em0.q,am-ha,CTX,W))/(2*ha);
        N = Fba - Fbq*Fka/Fkq;  M = FbP - Fbq*FkP/Fkq;
        rows(i,:) = [hr FbP Fbq Fba Fkq N -N/M];
        tee('    h=%.1e : F_bP %+9.3e F_bq %+9.3e F_ba %+9.3e F_kq %+9.3e -> dP/da %+9.4f\n', ...
            hr, FbP, Fbq, Fba, Fkq, -N/M);
    end
    % pick the step whose estimate is closest to its neighbour (most stable)
    d = abs(diff(rows(:,7)));
    [~, ib] = min(d); ib = ib + 1;
    hr = rows(ib,1);
    dP_pred = rows(ib,7);
    spread = max(rows(:,7)) - min(rows(:,7));

    % solved central difference at the SAME interior point and step
    Ep = solve_alpha(am+hr, CTX, Em0.q, false, []);
    Em = solve_alpha(am-hr, CTX, Em0.q, false, []);
    if Ep.ok && Em.ok
        dP_sol = (Ep.P - Em.P)/(2*hr);
        clr = max(abs(Ep.Sk-CTX.Kbar), abs(Em.Sk-CTX.Kbar));
    else
        dP_sol = NaN; clr = NaN;
    end
    relerr = abs(dP_pred - dP_sol)/max(abs(dP_sol),eps);
    % Gate from the achievable budget: the VFI soft-accepts near 1e-6
    % relative and the tree market clears only to the bisection's own
    % tolerance, so a difference quotient inherits roughly (noise)/(h).
    % At h ~ 1e-2 that is ~1e-4 relative on the residuals but the Schur
    % ratio compounds four of them, so 5e-2 is the defensible gate here.
    % A tighter one requires analytic Jacobians, not smaller steps.
    tol = 5e-2;
    SCH = struct('alpha',am,'h',hr,'rows',rows,'spread',spread, ...
                 'FbP',rows(ib,2),'Fbq',rows(ib,3),'Fba',rows(ib,4), ...
                 'Fkq',rows(ib,5),'N',rows(ib,6), ...
                 'M',rows(ib,2)-rows(ib,3)*0, ...
                 'dP_pred',dP_pred,'dP_sol',dP_sol,'relerr',relerr,'tol',tol, ...
                 'tree_clear',clr);
    if ~isempty(tee) && isa(tee,'function_handle')
        tee('  step-dependence of dP/dalpha across h: spread %.3e\n', spread);
        tee('  chosen h = %.1e (most stable pair)\n', hr);
        tee('  dP/dalpha  predicted %+0.6f | solved %+0.6f | rel err %.3e\n', ...
            dP_pred, dP_sol, relerr);
        tee('  solved-difference tree clearing |Sk-K| = %.2e\n', clr);
        cs = abs(rows(ib,3))*abs(rows(ib,5));
        tee('  NOTE the sign check: the finite move alpha 0 -> 1 raises P, so a\n');
        tee('  local derivative of the opposite sign indicates the difference is\n');
        tee('  measuring solver noise rather than the envelope.\n');
    end
end

function v = resid_b(P, q, alpha, CTX, W)
    if nargin < 5, W = []; end
    pe = prices_to_pe(alpha, CTX);
    o = kv_stationary_block(CTX.r_b, q, div_of(P,CTX), tau_of(alpha,P,CTX), pe, W);
    if o.ok, v = o.Sb - CTX.iota*CTX.Bnom/P; else, v = NaN; end
end

function v = resid_k(P, q, alpha, CTX, W)
    if nargin < 5, W = []; end
    pe = prices_to_pe(alpha, CTX);
    o = kv_stationary_block(CTX.r_b, q, div_of(P,CTX), tau_of(alpha,P,CTX), pe, W);
    if o.ok, v = o.Sk - CTX.Kbar; else, v = NaN; end
end

function pc = coarsen(p, fac)
% The nested-grid check must vary ONLY the node count. Rebuilding with a
% literal 2.4 would also move the curvature once the grids have been widened
% (the widening re-solves the exponent), so what looked like a resolution
% test would be a resolution-and-shape test. Take the curvature, and both
% endpoints, from the grid being coarsened.
    if nargin < 2, fac = 0.7; end
    pc = p;
    nb = max(30, round(numel(p.bGrid)*fac));
    nk = max(18, round(numel(p.kGrid)*fac));
    [blo,bhi,gb] = kv_grid_curv(p.bGrid); pc.bGrid = kv_grid_build(blo,bhi,gb,nb);
    [klo,khi,gk] = kv_grid_curv(p.kGrid); pc.kGrid = kv_grid_build(klo,khi,gk,nk);
end

function s = vecstr(v)
    s = sprintf('%+0.5f ', v);
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function v = getf(S, f)
% Read an optional field as NaN when absent, so the finite-only gate can be
% evaluated even on a struct that a failed stage returned in short form.
    if isfield(S, f), v = S.(f); else, v = NaN; end
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
