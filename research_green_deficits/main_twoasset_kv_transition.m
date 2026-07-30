% MAIN_TWOASSET_KV_TRANSITION  The announcement path of the ownership +
% illiquidity economy, and the transition-inclusive incidence on initial
% portfolios -- the computation MC3 was blocked on.
%
% THE QUESTION. The paper's principal welfare object is transition-inclusive
% incidence: the consumption-equivalent transfer that makes a household
% indifferent between staying in the no-program steady state forever and
% entering date one of the announced path, announcement-date revaluation
% included. It is computed for the one-asset economy, where the transition
% DEEPENS the regressivity of lump-sum finance. But the paper's portfolio
% results say the revaluation's sign and incidence depend on who holds the
% debt and how easily they rebalance -- so the object that answers the
% title question in the disciplined economy is this one: the same
% announcement, solved in the KV (infrequent-adjustment) economy with the
% intermediation wedge and the superstar state, with both markets clearing
% at every date.
%
% THE METHOD (why this was previously "blocked" and now is not). The KV
% household carries a second endogenous state (illiquid k), so the
% cash-on-hand EGM transition of the frictionless economy does not apply.
% But the VALUE-FUNCTION formulation needs only ONE Bellman application per
% date on the (b,k,e) grid (twoasset_kv_bellman_step) -- the steady-state
% VFI's expensive fixed-point iteration is a property of stationarity, not
% of backward induction -- and the asset-state timing makes the push and
% the dating unambiguous. The path solver is the same Anderson-accelerated
% fixed point as the one-asset tier-2 transition, on the STACKED log-price
% system [Phat_path; q_path] with the terminal pinned at the program steady
% state. Nothing is reportable unless the fixed point converges AND the
% horizon is adequate (both terminal residuals small).
%
% VALIDATION. Four gates, all EXECUTED (an earlier version of this header
% advertised gates that no code performed, and reported the terminal price
% as "reproducing the independent steady-state experiment" -- which is an
% identity, since the terminal price is read from that experiment and
% pinned, so it agrees for any path whatsoever and cannot fail):
%   GATE 1  one Bellman step at the terminal prices returns V_term (the
%           stationary V must be a fixed point of the per-date operator)
%   GATE 2  one forward push at the terminal prices returns the stationary
%           distribution
%   GATE 3  the kernel's own aggregates match agg_kv's independent
%           construction from the steady-state policies
%   GATE 4  end-to-end: with NO program and prices constant at the
%           baseline, the whole recursion reproduces the baseline steady
%           state, so the residual vanishes at every date. This is the test
%           that catches a transposed lottery weight or a mis-dated flow --
%           failures that leave the system with no solution at all, which
%           looks like slow convergence in a solver trace but is immediate
%           here. It is the analogue of the frictionless driver's check.
% All four feed `reportable`; the path is not quotable unless they pass.
%
% COST. One residual evaluation = T Bellman sweeps + T sparse pushes on the
% (b,k,e) tensor: roughly 10-20 s at the full grid, T = 60. Expect
% O(40-90) Anderson iterations: ~15-45 min. TKV overrides the horizon.
%
% USAGE   >> clear; main_twoasset_kv_transition
%         >> clear; FAST = true; main_twoasset_kv_transition   (T = 40)
%         >> clear; TKV = 80; main_twoasset_kv_transition
%
% REQUIRES output/twoasset_ownership_kv.mat (the calibrated benchmark and
% its lump-sum experiment) -- run main_twoasset_ownership_kv first. The
% saved grids are used as-is: FAST here shortens the horizon only, because
% the initial distribution lives on the saved grids.
%
% OUTPUT  output/tables/twoasset_kv_transition.txt
%         output/twoasset_kv_transition.mat

clearvars -except FAST TKV MAXIT; close all; clc;
rng(20260730, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
T = 60; if FAST, T = 40; end
if exist('TKV','var') && ~isempty(TKV), T = TKV; end

mf = fullfile(projdir, 'output', 'twoasset_ownership_kv.mat');
assert(exist(mf, 'file') == 2, ...
    'twoasset_ownership_kv.mat not found -- run main_twoasset_ownership_kv first');
S = load(mf);
assert(isfield(S,'eq0') && S.eq0.ok, 'saved benchmark equilibrium not ok');
p = S.p; iota = S.iota_H;
r_b = S.r_b; d_base = S.d_base; D0 = S.D0; Gg = S.Gg;
pgtmp = setup_params_green(); Bnom = pgtmp.Bnom; Kbar = 1.0;
eq0 = S.eq0;
ils = find(strcmp({S.EXK.name}, 'lump-sum'), 1);
assert(~isempty(ils), 'lump-sum experiment missing from saved EXK');
Pterm = S.EXK(ils).P; qterm = S.EXK(ils).q;
g_real = Gg / eq0.P;

if ~isfolder(pgtmp.tabdir), mkdir(pgtmp.tabdir); end
sf = fullfile(pgtmp.tabdir, 'twoasset_kv_transition.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('KV TWO-ASSET ANNOUNCEMENT TRANSITION (ownership + illiquidity)\n');
tee('grids: nb=%d nk=%d ne=%d (saved); T=%d; lambda=%.2f iota_H=%.3f\n', ...
    numel(p.bGrid), numel(p.kGrid), numel(p.eGrid), T, p.lambda_adj, iota);
tee('boundary: P %.4f -> %.4f (dlnP %+0.4f), q %.4f -> %.4f\n\n', ...
    eq0.P, Pterm, log(Pterm/eq0.P), eq0.q, qterm);

pe0 = p; pe0.eGrid = (1 - D0) * p.eGrid;

% ---- terminal objects: V at the program steady state + consistency gate ----
tau_term = r_b * (Bnom / Pterm) + g_real;
div_term = d_base + r_b * (1 - iota) * (Bnom / Pterm) / Kbar;
tee('terminal household solve (program steady state)...\n');
[solT, dgT] = solve_household_twoasset_kv(r_b, qterm, div_term, tau_term, pe0, []);
assert(dgT.converged, 'terminal VFI failed (dV=%.1e)', dgT.supnorm);
Vterm = solT.V;
[dsT, ddT] = stationary_distribution_twoasset_kv(solT, r_b, qterm, div_term, tau_term, pe0);
assert(ddT.converged, 'terminal distribution failed');
[SbT, SkT] = agg_kv(solT, dsT, r_b, qterm, div_term, tau_term, pe0);
tee('  terminal clearing check: Sb*P/(iota B) = %.4f, Sk/Kbar = %.4f (both ~1)\n', ...
    SbT * Pterm / (iota * Bnom), SkT / Kbar);
tee('  (this uses only the STEADY-STATE routines: it checks the boundary flow\n');
tee('   formulas tau_term/div_term/iota, NOT the new per-date kernels.)\n');

% ---- GATES ON THE NEW KERNELS ------------------------------------------
% An earlier version of this driver advertised a terminal consistency gate
% that no code performed, and reported "terminal dlnP reproduces the
% steady-state experiment" as a validation. That comparison is an IDENTITY:
% Pterm is read from the saved experiment and pinned into the path, so the
% two printed numbers are the same quantity and agree for ANY path,
% converged or not, and for any residual function. It is not reported as a
% check any more. These three gates are the real ones -- each can fail, and
% each exercises code that the steady-state routines do not.
%
% At the terminal steady state prices are constant, so the one-step
% operators must have the stationary objects as fixed points.
[Vchk, polchk] = twoasset_kv_bellman_step(Vterm, r_b, qterm, div_term, tau_term, pe0);
dV_step = max(abs(Vchk(:) - Vterm(:))) / max(1, max(abs(Vterm(:))));
Omchk   = push_forward_twoasset_kv(dsT, polchk, r_b, qterm, div_term, tau_term, pe0);
dOm     = max(abs(Omchk(:) - dsT(:)));
SbC     = sum(polchk.bch(:) .* dsT(:));
SkC     = sum(polchk.kch(:) .* dsT(:));
tolV = max(10 * dgT.supnorm, 1e-6);
g1 = dV_step < tolV;  g2 = dOm < 1e-6;  g3 = max(abs(SbC-SbT), abs(SkC-SkT)) < 1e-8;
tee('  GATE 1 Bellman step is a fixed point of V_term: rel %.2e (tol %.1e) %s\n', ...
    dV_step, tolV, ternstr(g1, 'PASS', 'FAIL'));
tee('  GATE 2 forward push is a fixed point of the stationary dist: %.2e %s\n', ...
    dOm, ternstr(g2, 'PASS', 'FAIL'));
tee('  GATE 3 kernel aggregates match agg_kv: |dSb| %.2e |dSk| %.2e %s\n', ...
    abs(SbC-SbT), abs(SkC-SkT), ternstr(g3, 'PASS', 'FAIL'));

% TREE-PRICE PRECISION. Only a fraction lambda of tree demand is
% q-responsive in any period (non-adjusters hold k fixed), so a given
% tree-market residual maps into a LARGER price error than in a
% frictionless economy. Measure the local semi-elasticity numerically and
% report the implied bound, so tree magnitudes are never quoted to more
% precision than the solve supports.
dlq = 0.01;
[~, polE] = twoasset_kv_bellman_step(Vterm, r_b, qterm*exp(dlq), div_term, tau_term, pe0);
SkE  = sum(polE.kch(:) .* dsT(:));
elas = (log(max(SkE,1e-12)) - log(max(SkC,1e-12))) / dlq;
tee('  tree demand semi-elasticity dlnSk/dlnq = %+.3f (lambda = %.2f)\n', elas, p.lambda_adj);

% ---- baseline stay-put objects: V0 and the consumption-utility part Uc0 ----
tau0 = r_b * (Bnom / eq0.P);
div0 = eq0.div;
tee('baseline household solve (stay-put values)...\n');
[sol0, dg0] = solve_household_twoasset_kv(r_b, eq0.q, div0, tau0, pe0, []);
assert(dg0.converged, 'baseline VFI failed');
V0 = sol0.V;
% The KV VFI SOFT-accepts a grid-limited fixed point at a relative tolerance
% of 3e-3. The CE table differences V1 against V0, so a soft-accepted value
% LEVEL propagates straight into the welfare numbers; report it rather than
% letting it pass silently.
soft0 = isfield(dg0,'soft') && dg0.soft;  softT = isfield(dgT,'soft') && dgT.soft;
tee('  VFI acceptance: terminal supnorm %.2e%s, baseline %.2e%s\n', ...
    dgT.supnorm, ternstr(softT, ' (SOFT)', ''), ...
    dg0.supnorm, ternstr(soft0, ' (SOFT)', ''));
if soft0 || softT
    tee('  NOTE: a soft-accepted value level feeds the CE table; treat welfare\n');
    tee('  magnitudes as accurate to about the VFI tolerance, not to 0.01%%.\n');
end
tee('  policy-evaluating the consumption-utility component Uc0...\n');
Uc0 = uc_policy_eval(sol0, r_b, eq0.q, div0, tau0, pe0, 600, 1e-8);

% ---- the path: Anderson-accelerated fixed point on [log P; log q] ----
ctx = struct('T', T, 'p', p, 'r_b', r_b, 'd_base', d_base, 'iota', iota, ...
    'Bnom', Bnom, 'Kbar', Kbar, 'g_real', g_real, 'Dpath', D0 * ones(1, T), ...
    'P0', eq0.P, 'Pterm', Pterm, 'qterm', qterm, 'Vterm', Vterm, ...
    'dist0', eq0.dist, 'want_V1', false);
n = T - 1;

% GATE 4 (end-to-end, the analogue of the frictionless driver's check).
% With NO program and prices constant at the baseline, the whole pipeline --
% backward Bellman recursion, forward push, aggregation, clearing -- must
% reproduce the baseline steady state, so the residual must vanish at every
% date. This is the one test that exercises both new kernels together
% against an object neither of them produced, and it is the test that would
% catch a transposed lottery weight or a mis-dated flow: those leave the
% system with no solution at all, which is invisible in a solver trace (it
% looks like slow convergence) but immediate here.
ctx0 = ctx; ctx0.g_real = 0; ctx0.Pterm = eq0.P; ctx0.qterm = eq0.q;
ctx0.Vterm = V0; ctx0.want_V1 = false;
x_ss = [log(eq0.P)*ones(n,1); log(eq0.q)*ones(n,1)];
[f_ss, aux_ss] = twoasset_kv_transition_residual(x_ss, ctx0);
g4 = aux_ss.feas && max(abs(f_ss)) < 5e-3;
tee('  GATE 4 no-program constant-price recursion reproduces the baseline:\n');
tee('         ||r||inf = %.2e (bond %.2e, tree %.2e) %s\n', max(abs(f_ss)), ...
    max(abs(f_ss(1:n))), max(abs(f_ss(n+1:end))), ternstr(g4, 'PASS', 'FAIL'));
gates_ok = g1 && g2 && g3 && g4;
if ~gates_ok
    tee('\n  *** ONE OR MORE KERNEL GATES FAILED -- the path below is NOT reportable\n');
    tee('  *** regardless of its residual. Fix the kernels first.\n\n');
end

x = [log(Pterm) * ones(n,1); log(qterm) * ones(n,1)];  % flat-at-terminal seed

% tol is the REPORTABLE gate; ttgt is the refinement target the loop
% actually chases. Breaking at the first crossing of tol (as an earlier
% version did) makes the achieved margin uninformative -- it reports
% whatever value happened to first dip under, not a converged floor.
tol = 2e-3; ttgt = 4e-4; maxit = 140; if FAST, maxit = 90; end
if exist('MAXIT','var') && ~isempty(MAXIT), maxit = MAXIT; end
% MEASURED SOLVER FLOOR. Three runs at different budgets (140 and 300
% iterations, with and without adaptive damping) put the best interior
% residual between 7.9e-4 and 9.5e-4, with the BOND block binding
% throughout. The impact price varied over [-0.0181, -0.0172] across them:
% a spread of 9e-4, the same order as the residual. So this Anderson
% iteration pins d ln P_1 to about +-5e-4 and the front-loading share to
% about +-0.02, and no statistic derived from the path should be quoted
% finer than that. Reaching 1e-6 here needs a sequence-space Newton with
% the two-market Jacobian, not more iterations of this map: damping alone
% cannot fix it, and over-damping makes it worse (halving xi to 0.016
% produced a WORSE final residual than leaving it at 0.5).
xi0 = 0.5; mAnd = 5;
stall = 0; stall_cap = 20;
Xh = {}; Fh = {};
best = struct('resnorm', Inf);
tee('\nsolving the path (tol %.0e, maxit %d)...\n', tol, maxit);
for it = 1:maxit
    [fv, aux] = twoasset_kv_transition_residual(x, ctx);
    if ~aux.feas
        tee('  iter %2d: INFEASIBLE trial path (healed nodes %d) -- damping\n', ...
            it, aux.n_nonfin);
        x = best_or_seed(best, x);   % retreat toward the best known iterate
        xi0 = 0.5 * xi0;  Xh = {}; Fh = {};
        if xi0 < 0.02, break; end
        continue;
    end
    resnorm = max(abs(fv));
    res_term = max(abs([aux.resid_b(T), aux.resid_k(T)]));
    if resnorm < best.resnorm
        best = struct('resnorm', resnorm, 'x', x, 'aux', aux, ...
                      'res_term', res_term, 'it', it);
    end
    tee('  iter %2d: interior max|f| = %.5f (bond %.5f tree %.5f), terminal = %.5f (mem=%d)\n', ...
        it, resnorm, max(abs(fv(1:n))), max(abs(fv(n+1:end))), res_term, ...
        min(numel(Fh), mAnd));
    if resnorm < ttgt, break; end     % refinement target, not the gate
    if it == maxit, break; end
    % ADAPTIVE DAMPING. The bond block oscillates rather than descending
    % when Anderson over-steps: the residual bounces within a band while
    % `best` improves only occasionally. Detect that (no improvement in the
    % best iterate for `stall_cap` steps), then retreat to the best point,
    % halve the relaxation and clear the memory. Without this the loop
    % spends its budget cycling, and statistics that depend on the achieved
    % residual -- the front-loading share moved 4pp between 1.9e-3 and
    % 7.9e-4 -- are reported from wherever the cycle happened to be.
    if resnorm < best.resnorm - 1e-12, stall = 0; else, stall = stall + 1; end
    if stall >= stall_cap && xi0 > 0.12
        xi0 = 0.5 * xi0; stall = 0;
        x = best.x; Xh = {}; Fh = {};
        tee('    [adaptive] stalled: xi -> %.3f, restarting from the best iterate\n', xi0);
        continue;
    end
    Xh{end+1} = x; Fh{end+1} = fv; %#ok<AGROW>
    if numel(Fh) > mAnd + 1, Fh = Fh(end-mAnd:end); Xh = Xh(end-mAnd:end); end
    m = numel(Fh) - 1;
    if m < 1
        xn = x + xi0 * fv;
    else
        F = [Fh{:}]; X = [Xh{:}];
        dF = diff(F, 1, 2); dX = diff(X, 1, 2);
        ws = warning('off', 'MATLAB:rankDeficientMatrix');
        gamma = dF \ fv;
        warning(ws);
        xn = x + xi0 * fv - (dX + xi0 * dF) * gamma;
        if ~all(isfinite(xn)) || norm(gamma) > 1e3
            xn = x + xi0 * fv; Xh = Xh(end); Fh = Fh(end);
        end
    end
    step = max(min(xn - x, log(1.10)), log(0.90));    % per-date trust region
    x = x + step;
end

assert(isfinite(best.resnorm) && isfield(best, 'aux'), ...
    ['no feasible iterate was ever found: every trial path was infeasible, ' ...
     'so there is nothing to report. Check the grids and the terminal pin.']);
converged  = best.resnorm < tol;
horizon_ok = best.res_term < max(tol, 5e-3);
reportable = converged && horizon_ok && gates_ok;
tee('\nfixed point %s (interior %.2e, gate %.0e, margin %.1fx), horizon %s (terminal %.2e)\n', ...
    ternstr(converged, 'CONVERGED', 'NOT CONVERGED'), best.resnorm, tol, ...
    tol / max(best.resnorm, eps), ternstr(horizon_ok, 'OK', 'INADEQUATE'), best.res_term);
tee('kernel gates %s; REPORTABLE = %d\n', ternstr(gates_ok, 'PASS', 'FAIL'), reportable);
% tree-price precision implied by the achieved tree residual and the
% measured semi-elasticity (only lambda of demand is q-responsive)
if isfinite(elas) && abs(elas) > 1e-6
    rk = max(abs(best.aux.resid_k(1:T-1)));
    tee('tree-price precision: |resid_k| %.2e / |dlnSk/dlnq| %.3f => |dln q| < %.2e\n', ...
        rk, abs(elas), rk / abs(elas));
    tee('  (quote tree magnitudes only to this precision)\n');
end

% ---- path statistics + the welfare block, at the best iterate ----
ctx.want_V1 = true;
[~, auxb] = twoasset_kv_transition_residual(best.x, ctx);
Pp = auxb.Ppath; qp = auxb.qpath;
tee('\nimpact:   dlnP_1 = %+0.4f, dln q_1 = %+0.4f\n', ...
    log(Pp(1)/eq0.P), log(qp(1)/eq0.q));
% NOT a validation: Pterm is read from the saved steady-state experiment and
% PINNED, so this equals that experiment's dlnP by construction. Printed as
% the boundary condition it is.
tee('terminal: dlnP   = %+0.4f (PINNED boundary = the steady-state experiment\n', ...
    log(Pp(T)/eq0.P));
tee('                    by construction; the real checks are GATES 1-4 above)\n');
denomP = log(Pp(T)/eq0.P);
if abs(denomP) > 1e-6
    tee('front-loading share of the long-run price move: %.3f\n', ...
        log(Pp(1)/eq0.P) / denomP);
end
tee('k-grid top mass along the path (max): %.4f; healed nodes (max): %d\n', ...
    auxb.ksat, auxb.n_nonfin);

% save the PATH results immediately: a failure in the welfare block below
% must never discard a converged solve
KVTR = struct('Ppath', Pp, 'qpath', qp, 'resid_b', auxb.resid_b, ...
    'resid_k', auxb.resid_k, 'Sb', auxb.Sb, 'Sk', auxb.Sk, ...
    'converged', converged, 'horizon_ok', horizon_ok, 'reportable', reportable, ...
    'resnorm', best.resnorm, 'res_term', best.res_term, 'iters', best.it, 'T', T);
save(fullfile(projdir, 'output', 'twoasset_kv_transition.mat'), ...
     'KVTR', 'V0', 'Uc0', 'Vterm', 'eq0', 'p', 'iota', 'g_real', 'T');

tee('\n----- transition-inclusive incidence on initial portfolios -----\n');
if ~reportable
    tee('PATH NOT REPORTABLE -- the numbers below are diagnostics, not results.\n');
end
sig = p.sigma;
V1 = auxb.V1;
base_tr  = (V1 - V0) ./ Uc0 + 1;         % stay-put consumption scaling, path
base_ss  = (Vterm - V0) ./ Uc0 + 1;      % entering the program ss directly
ok_tr = isfinite(base_tr) & base_tr > 0 & Uc0 < 0;
ok_ss = isfinite(base_ss) & base_ss > 0 & Uc0 < 0;
CEtr = nan(size(V0)); CEss = nan(size(V0));
CEtr(ok_tr) = base_tr(ok_tr).^(1/(1-sig)) - 1;
CEss(ok_ss) = base_ss(ok_ss).^(1/(1-sig)) - 1;
% flatten for the group table: masks below are (nb*nk*ne) x 1 vectors in
% (b fastest, then k, then e) order -- the same linearization as (:)
CEtrv = CEtr(:); CEssv = CEss(:);

w  = eq0.dist(:) / sum(eq0.dist(:));
[BB, KK] = ndgrid(p.bGrid(:), p.kGrid(:));
bv = repmat(BB(:), numel(p.eGrid), 1);
kv = repmat(KK(:), numel(p.eGrid), 1);
wealth = bv + eq0.q * kv;
% CE is undefined where the guards fail; report the mass that carries so a
% large silent drop cannot hide behind plausible-looking group averages
drop_tr = sum(w(~isfinite(CEtrv)));  drop_ss = sum(w(~isfinite(CEssv)));
tee('CE defined on %.4f of mass (transition) and %.4f (steady state)\n', ...
    1 - drop_tr, 1 - drop_ss);
if max(drop_tr, drop_ss) > 1e-3
    tee('  WARNING: %.2f%% of mass dropped by the CE guards -- group means are\n', ...
        100 * max(drop_tr, drop_ss));
    tee('  conditional on the defined set and may not be comparable across groups.\n');
end
tee('%-22s %8s %14s %14s\n', 'group (baseline)', 'mass', 'CE transition', 'CE steady-state');
grp = {
    'bottom quintile',     in_wealth_band(wealth, w, 0.00, 0.20)
    'bottom half',         in_wealth_band(wealth, w, 0.00, 0.50)
    'middle 50-90',        in_wealth_band(wealth, w, 0.50, 0.90)
    'top decile',          in_wealth_band(wealth, w, 0.90, 1.00)
    'top 1 percent',       in_wealth_band(wealth, w, 0.99, 1.00)
    'constrained b<=0.02', w .* (bv <= 0.02)
    'wealthy HtM',         w .* ((bv <= 0.02) & (eq0.q * kv >= 0.50))
    'ALL',                 w
};
for i = 1:size(grp, 1)
    wb = grp{i,2};
    tee('%-22s %8.4f %+13.2f%% %+13.2f%%\n', grp{i,1}, sum(wb), ...
        100 * wmean(CEtrv, wb), 100 * wmean(CEssv, wb));
end
tee(['\nreading: the one-asset transition DEEPENED the regressivity of\n' ...
     'lump-sum finance (windfall at the top, front-loaded taxes at the\n' ...
     'constrained bottom). Whether that survives realistic ownership and\n' ...
     'illiquidity -- where the top holds most of the revaluation base but\n' ...
     'cannot instantly rebalance -- is exactly what the two columns above\n' ...
     'decide. SCOPE: this path holds damages at D0 and varies only the tax\n' ...
     '(matching the steady-state experiment it is anchored to), so it is the\n' ...
     'incidence of the FINANCING announcement. The one-asset transition also\n' ...
     'carries the damage dividend, so the two are not the same experiment and\n' ...
     'their levels are not directly comparable -- the comparable object is the\n' ...
     'within-economy transition-vs-steady-state CONTRAST in the two columns.\n']);

KVTR.CEtr = CEtr; KVTR.CEss = CEss;    % append welfare to the saved results
save(fullfile(projdir, 'output', 'twoasset_kv_transition.mat'), ...
     'KVTR', 'V0', 'Uc0', 'Vterm', 'eq0', 'p', 'iota', 'g_real', 'T');
tee('\n[main_twoasset_kv_transition] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% ========================================================================
function v = getf(s, f, d)
    if isfield(s, f), v = s.(f); else, v = d; end
end

function x = best_or_seed(best, x0)
    if isfinite(best.resnorm), x = best.x; else, x = x0; end
end

function [Sb, Sk] = agg_kv(sol, dist, rb, q, d, tau, pe)
    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb; ynet = pe.eGrid(:)' - tau;
    Sb = 0; Sk = 0;
    for ie = 1:ne
        xbk = min(max(ynet(ie) + Rb*bG + (q+d)*kG', pe.xGridA(1)), pe.xGridA(end));
        bpa = interp1(pe.xGridA, sol.polBa(:,ie), xbk, 'linear');
        kpa = interp1(pe.xGridA, sol.polKa(:,ie), xbk, 'linear');
        knon = kG'; if isfield(sol, 'kNon'), knon = sol.kNon(:)'; end
        bch = lam*bpa + (1-lam)*squeeze(sol.polBn(:,:,ie));
        kch = lam*kpa + (1-lam)*repmat(knon, nb, 1);
        Sb = Sb + sum(sum(bch .* dist(:,:,ie)));
        Sk = Sk + sum(sum(kch .* dist(:,:,ie)));
    end
end

function Uc = uc_policy_eval(sol, rb, q, dvd, tau, pe, maxit, tol)
% Consumption-utility component of the value under the SOLVED policies:
%   Uc(b,k,e) = lam*[u(c_a) + beta E Uc(b'_a,k'_a)]
%             + (1-lam)*[u(c_n) + beta E Uc(b'_n, k'_non)],
% iterated to its fixed point (a linear operator: contraction at rate beta).
% Needed because consumption-equivalent transfers scale u(c) but not the
% convenience utility chi v(b), so CE = (V-ratio)^(1/(1-sigma)) would be
% exact only if the two curvatures coincided. Uc isolates the scalable part.
    bG = pe.bGrid(:); kG = pe.kGrid(:); xG = pe.xGridA(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; sig = pe.sigma; Rb = 1 + rb;
    ynet = pe.eGrid(:)' - tau;
    if isfield(pe,'div_payout'), phi = min(max(pe.div_payout,0),1); else, phi = 1; end
    ua = ucrra(max(sol.polCa, 1e-10), sig);         % nx x ne
    Uc = ucrra(max(sol.polCn, 1e-10), sig) / (1 - pe.beta);  % warm start
    knon = kG; if isfield(sol, 'kNon'), knon = sol.kNon(:); end
    ikn = discretize(min(max(knon, kG(1)), kG(end)), kG); ikn = min(max(ikn,1), nk-1);
    wkn = min(max((knon - kG(ikn))./(kG(ikn+1)-kG(ikn)), 0), 1);
    for it = 1:maxit
        EU = zeros(nb, nk, ne);
        for ie = 1:ne
            for jep = 1:ne
                EU(:,:,ie) = EU(:,:,ie) + pe.Pi(ie, jep) * Uc(:,:,jep);
            end
        end
        Un = zeros(nb, nk, ne);
        for ie = 1:ne
            Ee = EU(:,:,ie);
            % adjuster: continuation at the chosen (b',k') via bilinear interp
            bpa = min(max(sol.polBa(:,ie), bG(1)), bG(end));
            kpa = min(max(sol.polKa(:,ie), kG(1)), kG(end));
            ib = discretize(bpa, bG); ib = min(max(ib,1), nb-1);
            ik = discretize(kpa, kG); ik = min(max(ik,1), nk-1);
            wb = min(max((bpa - bG(ib))./(bG(ib+1)-bG(ib)), 0), 1);
            wk = min(max((kpa - kG(ik))./(kG(ik+1)-kG(ik)), 0), 1);
            EUa = (1-wb).*(1-wk).*Ee(ib+(ik-1)*nb) + wb.*(1-wk).*Ee(ib+1+(ik-1)*nb) ...
                + (1-wb).*wk.*Ee(ib+ik*nb)         + wb.*wk.*Ee(ib+1+ik*nb);
            UcaX = ua(:,ie) + pe.beta * EUa;         % on xGridA
            for ik2 = 1:nk
                jb = sol.polBnIdx(:,ik2,ie);
                Eek = (1-wkn(ik2))*Ee(:, ikn(ik2)) + wkn(ik2)*Ee(:, min(ikn(ik2)+1, nk));
                un = ucrra(max(sol.polCn(:,ik2,ie), 1e-10), sig);
                % adjuster branch evaluated at this slice's cash-on-hand
                xaa = min(max(ynet(ie) + Rb*bG + (q + dvd)*kG(ik2), xG(1)), xG(end));
                UaI = interp1(xG, UcaX, xaa, 'linear');
                Un(:,ik2,ie) = lam * UaI + (1 - lam) * (un + pe.beta * Eek(jb));
            end
        end
        dU = max(abs(Un(:) - Uc(:))) / max(1, max(abs(Un(:))));
        Uc = Un;
        if dU < tol, break; end
    end
end

function u = ucrra(c, sig)
    if sig == 1, u = log(c); else, u = (c.^(1-sig))/(1-sig); end
end

function wb = in_wealth_band(wealth, w, qlo, qhi)
% WEIGHT VECTOR (not a boolean mask) for the baseline-wealth rank band
% (qlo, qhi]. Returns each state's mass lying inside the band.
%
% Why not a value cutoff. Wealth here is b + q*k, which does NOT depend on
% the income state, so every (b,k) node is repeated ne times at EXACTLY the
% same wealth. A threshold rule (wealth > lo & wealth <= hi) therefore
% includes or excludes whole ne-fold ties together, and a tie straddling a
% band edge throws the band's mass off by up to ne times a node's weight --
% silently, while still printing plausible numbers. Splitting each atom by
% the fraction of its mass inside [qlo,qhi] is exact and tie-safe, and it
% makes the bands sum to the whole distribution by construction.
    [~, io] = sort(wealth);
    ws = w(io);
    cw_hi = cumsum(ws);            % cumulative mass at the TOP of each atom
    cw_lo = cw_hi - ws;            % ... and at the bottom
    inside = min(cw_hi, qhi) - max(cw_lo, qlo);
    inside = max(inside, 0);       % mass of this atom inside the band
    wb = zeros(size(w));
    wb(io) = inside;
end

function m = wmean(x, wb)
% weighted mean over a WEIGHT VECTOR (mass per state), restricted to states
% where x is defined
    v = isfinite(x) & wb > 0;
    if ~any(v), m = NaN; return; end
    m = sum(x(v) .* wb(v)) / sum(wb(v));
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
