% MAIN_TWOASSET_TRANSITION  Nonlinear announcement transition of the two-asset
% DTPL economy: the joint perfect-foresight paths {P_t, q_t} of the price
% level and the tree price, pinned at every date by TWO market-clearing
% conditions, with no Phillips curve anywhere. This is the two-asset
% counterpart of Section 6.3 and the paper's most novel computation: nonlinear
% (not linearized) two-asset price-level determination along a transition.
%
% EXPERIMENT. At t=1 the government unexpectedly and permanently announces a
% real green appropriation g (financed lump-sum); thereafter foresight is
% perfect. The economy starts at the pre-announcement (no-program) two-asset
% steady state and converges to the program steady state. Damages D_t fall as
% green capital K_{g,t} accumulates along a known path (read from the one-asset
% transition if available, else a geometric glide to terminal D).
%
% UNKNOWNS. Two price paths {P_t}_{t=1}^T and {q_t}_{t=1}^T. At each date:
%   nominal-bond market:  int b'_t dOmega_t = B / P_t
%   tree market:          int k'_t dOmega_t = Kbar
% The nominal bond's realized stationarized real gross return is
% R^b_t = (1+r_b) Phat_{t-1}/Phat_t with Phat_0 the pre-announcement price
% (DTPL Fisher block, trend inflation inside r_b); the tree pays dividend d
% and trades at q_t, real gross return R^k_{t+1} = (q_{t+1} + d)/q_t.
%
% METHOD. Sequence-space Newton on the joint path. Each residual evaluation
% is (i) a backward pass solving household consumption policies from the
% terminal steady state with a single-step frictionless two-asset EGM
% operator under the time-varying returns/taxes/damages, and (ii) a forward
% pass rolling the distribution from the initial steady state; the two market
% residuals are then read off in logs. The Newton step inverts the
% sequence-space (GE) Jacobian of Auclert et al. (2021), whose off-diagonal
% blocks carry the portfolio-substitution channel between the two markets.
%
% A damped fixed point on this system DIVERGES: P_t enters both the
% stationarized bond return and the tax, so bond demand is far too elastic
% for any scalar relaxation to both converge and move. That map is retained
% only as a fallback if the Newton solve fails.
%
% USAGE   >> FAST = true; main_twoasset_transition
%         >> main_twoasset_transition
% REQUIRES output/twoasset_step0.mat (run main_twoasset_step0 first) for the
%          initial and terminal steady states and the calibrated chi.
% OUTPUT  output/twoasset_transition.mat, output/tables/twoasset_transition.txt
% STATUS: scaffolded, untested pending a MATLAB run.

clearvars -except FAST TT; close all; clc;
rng(20260723, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();

s0f = fullfile(projdir, 'output', 'twoasset_step0.mat');
assert(exist(s0f,'file') == 2, ['run main_twoasset_step0 first: ' s0f ' missing']);
S0 = load(s0f);
p = S0.p;                                       % grids + calibrated chi_b
r_b = S0.r_b; d_div = S0.d_div; D0 = S0.D0; Gg = S0.Gg;
Bnom = pg.Bnom; Kbar = 1.0;

% ensure EGM grids present (step0 stored them)
if ~isfield(p,'xGrid'), error('twoasset_step0.mat lacks EGM grids'); end
if ~isfield(p,'aGrid2'), nx=numel(p.xGrid); u2=linspace(0,1,180)'; p.aGrid2 = 1e-4+(0.92*max(p.xGrid)-1e-4)*(u2.^2.2); end
p.tol_pol = 1e-7; p.maxit_pol = 1;              % SINGLE backward step per date

T = 80; if FAST, T = 40; end
% TT overrides the horizon from the workspace. The terminal date carries no
% clearing condition, so a horizon too short to let the distribution settle
% leaves a gap there that contaminates the front-loading share; the gap falls
% by roughly an order of magnitude per doubling of T.
if exist('TT','var') && ~isempty(TT), T = TT; end

% ---- terminal (program) and initial (no-program) steady states ----
% Terminal: lump-sum program steady state; read P,q,tau from step0 EX(1) if
% present, else recompute is required (flagged).
% EX holds only equilibria that converged (fields: name/P/q/Sb/dlnP/dlnq --
% no 'ok' field; presence implies success)
haveEX = isfield(S0,'EX') && numel(S0.EX) >= 1 && ...
         isfield(S0.EX, 'P') && isfinite(S0.EX(1).P);
eq_init = S0.eqb;                               % no-program baseline
assert(eq_init.ok, 'initial steady state missing');
if haveEX
    Pterm = S0.EX(1).P; qterm = S0.EX(1).q;
else
    error(['need the lump-sum program steady state; rerun main_twoasset_step0 ' ...
           'so EX(1) is saved']);
end
g_real = Gg / eq_init.P;                        % real appropriation

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'twoasset_transition.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('TWO-ASSET NONLINEAR TRANSITION. T=%d nx=%d ne=%d FAST=%d\n', ...
    T, numel(p.xGrid), numel(p.eGrid), FAST);
tee('P0=%.4f -> P_term=%.4f ; q0=%.4f -> q_term=%.4f ; g=%.4f\n\n', ...
    eq_init.P, Pterm, eq_init.q, qterm, g_real);

% ---- damage path D_t (glide from D0 to terminal program damages) ----
% Use the one-asset transition K_g path if present; else geometric glide.
Dterm = D0;                                     % (endowment benchmark: D fixed
% across the financing experiment; kept as a slow state hook for the coordinated
% program variant). Damages enter via endowment scaling (1-D_t).
Dpath = D0 * ones(1, T);

% ---- initial guess: linear glide of both prices ----
Ppath = linspace(eq_init.P, Pterm, T);
qpath = linspace(eq_init.q, qterm, T);
Ppath(T) = Pterm; qpath(T) = qterm;

% ---- boundary steady states, re-solved to the transition's own accuracy ----
% The path is pinned at these two endpoints, so its market residual can never
% be smaller than their error. Step 0 returns them at its bisection tolerance
% (about 1e-4 in the clearing conditions), and that -- not the path solver --
% was the floor under every date's residual. Re-solving both here with the
% same household solver and forward operator the residual uses removes it.
tee('refining boundary steady states under the transition operators...\n');
pe0 = p; pe0.eGrid = (1 - D0)    * p.eGrid;
peT = p; peT.eGrid = (1 - Dterm) * p.eGrid;

g_real = Gg / eq_init.P;                        % real appropriation (initial P)
SS0 = refine_twoasset_steady_state(r_b, d_div, 0,      Bnom, Kbar, pe0, ...
                                   eq_init.P, eq_init.q, 1e-11, false);
tee('  initial : P = %.8f  q = %.8f  ||r|| = %.2e  (%d its, converged %d)\n', ...
    SS0.P, SS0.q, max(abs(SS0.resid)), SS0.iters, SS0.converged);
g_real = Gg / SS0.P;                            % restate g at the refined P
SST = refine_twoasset_steady_state(r_b, d_div, g_real, Bnom, Kbar, peT, ...
                                   Pterm, qterm, 1e-11, false);
tee('  terminal: P = %.8f  q = %.8f  ||r|| = %.2e  (%d its, converged %d)\n', ...
    SST.P, SST.q, max(abs(SST.resid)), SST.iters, SST.converged);

eq_init.P = SS0.P; eq_init.q = SS0.q;
Pterm = SST.P;     qterm = SST.q;
pB0 = SS0.polB; pK0 = SS0.polK; C0 = SS0.C; Omega0 = SS0.dist;
Cterm = SST.C;
tee('P0=%.6f -> P_term=%.6f ; q0=%.6f -> q_term=%.6f ; g=%.6f (refined)\n\n', ...
    eq_init.P, Pterm, eq_init.q, qterm, g_real);

% =====================================================================
% SEQUENCE-SPACE NEWTON on the joint path (Ppath, qpath)
% =====================================================================
% The damped fixed point below diverges on this system (P_t enters both the
% revaluation return and the tax, so bond demand is far too elastic for any
% scalar relaxation). The Newton solve uses the actual Jacobian, including
% the cross-market blocks a scalar update cannot see. The damped map is
% retained underneath as a fallback and as an independent check.
ctx = struct('T', T, 'p', p, 'r_b', r_b, 'd_div', d_div, 'Bnom', Bnom, ...
             'Kbar', Kbar, 'Dpath', Dpath, 'g_real', g_real, ...
             'P0', eq_init.P, 'q0', eq_init.q, 'Pterm', Pterm, 'qterm', qterm, ...
             'Cterm', Cterm, 'Psi0', Omega0, 'pB0', pB0, 'pK0', pK0);
% ---- consistency gate ------------------------------------------------
% With NO program and constant prices, the forward recursion must reproduce
% the initial steady state, so the market residual must vanish. This is a
% direct test of the forward-pass timing: a portfolio chosen at t earns its
% return at t+1, and the date-1 state must be the pre-announcement portfolio
% revalued at date-1 prices. Getting either wrong leaves the system with no
% solution at all, which is not visible from a solver trace (it looks like
% slow convergence) but is immediately visible here.
ctx0 = ctx; ctx0.g_real = 0; ctx0.Pterm = eq_init.P; ctx0.qterm = eq_init.q;
ctx0.Cterm = C0;
x_ss  = [log(eq_init.P)*ones(T-1,1); log(eq_init.q)*ones(T-1,1)];
r_ss  = twoasset_transition_residual(x_ss, ctx0);
tee('steady-state consistency check: ||r||inf = %.2e\n', max(abs(r_ss)));
if max(abs(r_ss)) > 5e-3
    tee('  WARNING: the recursion does not reproduce the initial steady state.\n');
    tee('  Treat any transition number below as unvalidated.\n');
end

% The finite-difference step is set FROM the measured noise floor rather than
% fixed: the optimal step for a noisy forward difference scales as the square
% root of the noise, and with the operator mismatch removed the floor is many
% orders smaller, so a much finer (and far more accurate) step is now
% justified. Clamped to a sane range.
% Between full rebuilds the Jacobian is carried by Broyden rank-1 updates,
% so iterations are cheap and refreshes should be rare: an LM step costs one
% residual solve, a rebuild costs 2(T-1) of them.
h_fd = min(max(sqrt(max(max(abs(r_ss)), eps)), 1e-5), 1e-2);
tee('finite-difference step set to h = %.1e (from the measured floor)\n', h_fd);
nopts = struct('newton_maxit', 60, 'newton_tol', 1e-4, 'fd_step', h_fd, ...
               'refresh_after', 10, 'verbose', true, 't0', t0, ...
               'noise_floor', max(abs(r_ss)), 'time_budget', 5400);
if FAST, nopts.newton_maxit = 60; nopts.time_budget = 2400; end
% ---- CONTINUATION IN THE SHOCK SIZE ----------------------------------
% Solving the full program in one go from a log-linear bridge is fragile: at
% T=80 that bridge is far from a path that decays quickly, and the Newton
% stalled at a local minimum of the merit with a well-conditioned Jacobian
% (cond ~ 3e3), which is the signature of a bad starting point rather than a
% bad system. Continuation removes the problem: at g = 0 the constant path is
% the exact solution, and each subsequent step is a small perturbation of an
% already-converged path, so the Newton always starts close.
%
% The terminal steady state moves with g, so it is re-refined at each step.
homot = [0.25 0.5 0.75 1.0];
g_full = g_real; xwarm = [];
for ih = 1:numel(homot)
    g_s = homot(ih) * g_full;
    SSs = refine_twoasset_steady_state(r_b, d_div, g_s, Bnom, Kbar, peT, ...
                                       Pterm, qterm, 1e-11, false);
    ctx.g_real = g_s; ctx.Pterm = SSs.P; ctx.qterm = SSs.q; ctx.Cterm = SSs.C;
    nopts.x0 = xwarm;
    tee('\n--- continuation step %d/%d: g = %.6f (%.0f%% of target)\n', ...
        ih, numel(homot), g_s, 100*homot(ih));
    TRN = solve_twoasset_transition_ssj(ctx, nopts);
    xwarm = TRN.x;
    tee('    ||r||inf = %.2e  (converged %d)\n', TRN.rnorm, TRN.converged);
end
% the final step IS the target economy; keep its endpoints for reporting
Pterm = ctx.Pterm; qterm = ctx.qterm; g_real = ctx.g_real;

% ALWAYS adopt the Newton path: it is the best iterate found so far, and the
% fallback below is only allowed to replace it if it does strictly better.
% (Previously an unconverged Newton path was discarded and the fallback's
% own, worse, result was reported instead.)
Ppath = TRN.Ppath; qpath = TRN.qpath;
Sb_t  = TRN.Sb;    Sk_t  = TRN.Sk;
dbest = TRN.rnorm; outconv = TRN.converged;
if outconv
    tee('solver: sequence-space Newton, converged in %d iterations\n', TRN.iters);
else
    tee('solver: sequence-space Newton stopped at %d iterations\n', TRN.iters);
end
tee('  ||market residual||inf = %.2e (target %.1e)\n', ...
    TRN.rnorm, max(1e-4, 5*max(abs(r_ss))));
tee('  GE Jacobian: sigma_min = %.3e, cond = %.3e (determinacy diagnostic)\n', ...
    TRN.sigma_min, TRN.cond_J);

% =====================================================================
% FALLBACK: damped fixed point on (Ppath, qpath)
% =====================================================================
% Damped fixed point with a TRUST REGION and adaptive relaxation.
%
% The plain damped map DIVERGED geometrically (max dlnP 1.7e-2 -> 6.6e-2 ->
% 2.5e-1, a multiplier of ~3.8 per sweep). The destabilizer is the
% revaluation channel: P_t enters BOTH the stationarized bond return
% Rb_t = (1+r_b) Phat_{t-1}/Phat_t and the tax tau_t = rb_t B/P_t, so a rise
% in P_t cuts the tax twice over, raises saving, and the target B/S^b_t
% overshoots downward. The implied local elasticity dln S^b/dln P is ~15,
% which needs relax < 1/(1+15) ~ 0.06 -- far below the 0.3 previously used.
%
% Rather than hard-code a small constant, we (i) cap the per-sweep log-step
% (trust region), (ii) cut relax whenever the residual worsens and let it
% creep back up when it improves, and (iii) treat a household solve that
% returns EMPTY policies as an infeasible trial step to back away from
% rather than an error. That last case was the actual crash: the EGM solver
% guards on a non-positive equity-bond spread (sprd = 1 - Rb/Rk <= 0) by
% returning [], and the diverging path drove Rb_t high enough to trip it,
% so polB{t} .* Om hit a size mismatch.
if ~exist('outconv','var') || ~outconv
% Damped fallback. It now calls the SAME residual as the Newton solve, so the
% two solvers share one timing implementation and cannot silently disagree.
% Update directions come from the two clearing conditions:
%   bonds : P clears at B / S^b, so d log P = -resid_P
%   tree  : excess demand raises q, so d log q = +kappa * resid_q
lpb = log(linspace(eq_init.P, Pterm, T+1)); lpb = lpb(2:end-1);
lqb = log(linspace(eq_init.q, qterm, T+1)); lqb = lqb(2:end-1);
xd = [lpb(:); lqb(:)];
nfree = T - 1; relax = 0.05; step_max = 0.03; kappa = 0.5;
dnewton = dbest;                      % Newton's best, to beat
[rd, auxd] = twoasset_transition_residual(xd, ctx);
dbest = max(abs(rd)); auxbest = auxd; outconv = false;
maxout = 60; if FAST, maxout = 40; end
for outer = 1:maxout
    if dbest < 1e-4, outconv = true; break; end
    dx = [-relax*rd(1:nfree); relax*kappa*rd(nfree+1:end)];
    dx = min(max(dx, -step_max), step_max);
    [rt, auxt] = twoasset_transition_residual(xd + dx, ctx);
    if auxt.feas && max(abs(rt)) < dbest
        xd = xd + dx; rd = rt;
        dbest = max(abs(rt)); auxbest = auxt;
        relax = min(1.10*relax, 0.30);
    else
        relax = 0.40*relax;
        if relax < 1e-4, break; end
    end
    fprintf('[%5.0fs] damped %2d: ||r||inf = %.3e  (relax %.4f)\n', ...
            toc(t0), outer, dbest, relax);
end
if dbest < dnewton
    Ppath = auxbest.Ppath; qpath = auxbest.qpath;
    Sb_t  = auxbest.Sb;    Sk_t  = auxbest.Sk;
    tee('  damped fallback improved on the Newton path (%.2e -> %.2e)\n', ...
        dnewton, dbest);
else
    dbest = dnewton;
    tee('  damped fallback did not improve on the Newton path; keeping Newton\n');
end
if dbest < 1e-4, outconv = true; end
end
if ~outconv
    fprintf(['[transition] did NOT reach the market-clearing tolerance; ' ...
             'best ||r||inf = %.2e -- numbers are provisional.\n'], dbest);
end

% =====================================================================
% REPORT: announcement effect and front-loading
% =====================================================================
piPath = [Ppath(1)/eq_init.P - 1, Ppath(2:end)./Ppath(1:end-1) - 1];  % gross P growth
dlnP_impact = log(Ppath(1)/eq_init.P);
dlnP_total  = log(Pterm/eq_init.P);
frontshare  = dlnP_impact / dlnP_total;
tee('----- results -----\n');
tee('impact d ln P (announcement year) = %+.4f\n', dlnP_impact);
tee('long-run d ln P (across steady states) = %+.4f\n', dlnP_total);
tee('front-loading share (impact / total) = %.3f\n', frontshare);
tee('impact tree repricing d ln q = %+.4f\n', log(qpath(1)/eq_init.q));
tee('max tree-market residual over IMPOSED dates = %.2e\n', ...
    max(abs(Sk_t(1:end-1) - Kbar)));
% The terminal date carries no clearing condition (the path has 2(T-1) free
% prices and 2(T-1) equations, with t=T pinned at the program steady state),
% so any gap there is a HORIZON diagnostic, not a solver residual: it says
% whether the distribution has settled by T. Reporting it inside the path
% maximum, as an earlier version did, made a short horizon look like a failed
% solve.
tee('terminal-date tree gap |S^k_T - Kbar| = %.2e (horizon check, not imposed)\n', ...
    abs(Sk_t(end) - Kbar));
if abs(Sk_t(end) - Kbar) > 1e-2
    tee('  NOTE: the distribution has not settled by T=%d; lengthen the horizon\n', T);
    tee('  before reading the front-loading share as a long-run decomposition.\n');
end
if outconv
    tee('market clearing CONVERGED (||r||inf < 1e-4)\n');
else
    tee('NOT converged: best ||market residual||inf = %.2e -- provisional\n', dbest);
end
% compare to the one-asset nonlinear transition front-loading if available
trf = fullfile(projdir, 'output', 'transition_results.mat');
if exist(trf,'file') == 2
    tee('(compare the one-asset front-loading share reported in Section 6.3)\n');
end
tee(['\nReading: the impact d ln P is the announcement-date revaluation on the\n' ...
     'nominal market with the tree absorbing part of the portfolio shift.\n' ...
     'Front-loading share near the one-asset value would show the timing\n' ...
     'result is portfolio-robust; a lower share would show the tree margin\n' ...
     'spreads the repricing over time.\n']);

save(fullfile(projdir,'output','twoasset_transition.mat'), 'Ppath', 'qpath', ...
     'Sb_t', 'Sk_t', 'piPath', 'dlnP_impact', 'dlnP_total', 'frontshare', ...
     'eq_init', 'Pterm', 'qterm', 'T');
fclose(fid);
fprintf('[main_twoasset_transition] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
% local functions
% =========================================================================
function [polB, polK, polC, C, V, dg] = solve_household_twoasset_egm_ss(rb, q, d, tau, pe)
% steady-state wrapper (iterate the single step to convergence)
    pe.tol_pol = 1e-7; pe.maxit_pol = 800;
    [polB, polK, polC, C, V, dg] = solve_household_twoasset_egm(rb, q, d, tau, pe, []);
end

function [polB, polK, polC, C] = twoasset_egm_step(rb, q, d, tau, pe, Cnext)
% ONE backward EGM step: given next-period consumption policy Cnext, return
% this period's policies. Implemented as a 1-iteration EGM solve seeded with
% Cnext (maxit_pol = 1), so the solver's internal step IS the backward map.
    pe.maxit_pol = 1; pe.tol_pol = 0;            % force exactly one sweep
    [polB, polK, polC, C] = solve_household_twoasset_egm(rb, q, d, tau, pe, Cnext);
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
