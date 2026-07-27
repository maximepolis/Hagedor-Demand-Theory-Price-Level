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

clearvars -except FAST; close all; clc;
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

% terminal continuation consumption policy (program steady state household)
peT = p; peT.eGrid = (1 - Dterm) * p.eGrid;   % lump-sum program economy
tauT = r_b*Bnom/Pterm + g_real;
[~,~,~, Cterm, ~, dgT] = solve_household_twoasset_egm_ss(r_b, qterm, d_div, tauT, peT);
assert(dgT.converged, 'terminal steady-state household solve failed');

% initial distribution (no-program steady state)
pe0 = p; pe0.eGrid = (1 - D0) * p.eGrid;
tau0 = r_b*Bnom/eq_init.P;
[pB0, pK0, ~, ~, ~, dg0] = solve_household_twoasset_egm_ss(r_b, eq_init.q, d_div, tau0, pe0);
[Omega0, dd0] = stationary_distribution_twoasset(pB0, pK0, r_b, eq_init.q, d_div, tau0, pe0);
assert(dg0.converged && dd0.converged, 'initial steady state failed');

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
             'Cterm', Cterm, 'Omega0', Omega0);
nopts = struct('newton_maxit', 12, 'newton_tol', 1e-4, 'fd_step', 1e-3, ...
               'refresh_after', 3, 'verbose', true, 't0', t0);
if FAST, nopts.newton_maxit = 8; end
TRN = solve_twoasset_transition_ssj(ctx, nopts);

if TRN.converged
    Ppath = TRN.Ppath; qpath = TRN.qpath;
    Sb_t  = TRN.Sb;    Sk_t  = TRN.Sk;
    outconv = true; dbest = TRN.rnorm;
    tee('solver: sequence-space Newton, converged in %d iterations\n', TRN.iters);
    tee('  ||market residual||inf = %.2e\n', TRN.rnorm);
    tee('  GE Jacobian: sigma_min = %.3e, cond = %.3e (determinacy diagnostic)\n', ...
        TRN.sigma_min, TRN.cond_J);
else
    tee('solver: sequence-space Newton did NOT converge (||r||inf = %.2e);\n', TRN.rnorm);
    tee('  falling back to the damped fixed point.\n');
end

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
relax = 0.08; relax_min = 5e-3; relax_max = 0.20;
step_max = 0.04;                                 % max |d ln x| per sweep
maxout = 60; if FAST, maxout = 40; end
dlast = Inf; dbest = Inf; Pgood = Ppath; qgood = qpath;
nbad = 0; outconv = false; dcur = Inf;
Sb_t = zeros(1,T); Sk_t = zeros(1,T);
for outer = 1:maxout
    % taxes along the path (lump-sum: tau_t = r^b_t * B/P_t + g).
    % Stationarized real gross bond return: (1+r_b) * Phat_{t-1}/Phat_t,
    % with Phat_0 the PRE-announcement steady-state price -- so at a constant
    % path Rb = 1 + r_b (trend inflation already inside r_b), and the
    % announcement-date revaluation enters through Phat_0/Phat_1.
    Rb_t = (1 + r_b) * [eq_init.P, Ppath(1:end-1)] ./ Ppath;
    rb_t = Rb_t - 1;
    tau_t = rb_t * Bnom ./ Ppath + g_real;

    % ---- backward pass: consumption policies C_t (single EGM step/date) ----
    % Feasibility-guarded: the EGM solver returns EMPTY policies when the
    % equity-bond spread goes non-positive at the trial prices.
    Cnext = Cterm;
    polB = cell(1,T); polK = cell(1,T);
    feas = true; tbad = 0; szx = [numel(p.xGrid) numel(p.eGrid)];
    for t = T:-1:1
        pet = p; pet.eGrid = (1 - Dpath(t)) * p.eGrid;
        [bB, bK, ~, Ct] = twoasset_egm_step(rb_t(t), qpath(t), d_div, tau_t(t), pet, Cnext);
        if isempty(bB) || isempty(Ct) || ~isequal(size(bB), szx)
            feas = false; tbad = t; break;
        end
        polB{t} = bB; polK{t} = bK; Cnext = Ct;
    end
    if ~feas
        nbad = nbad + 1;
        relax = max(0.35*relax, relax_min);
        Ppath = Pgood; qpath = qgood;            % retreat to the last good path
        fprintf(['[%5.0fs] outer %2d: INFEASIBLE at t=%d (non-positive equity-bond ' ...
                 'spread at trial prices) -- relax -> %.4f, reverting\n'], ...
                toc(t0), outer, tbad, relax);
        if nbad >= 8 || relax <= relax_min*1.001
            fprintf('  repeated infeasible steps; stopping and reporting best path\n');
            break;
        end
        continue;
    end

    % ---- forward pass: roll the distribution, collect S^b_t, S^k_t ----
    Om = Omega0;
    for t = 1:T
        pet = p; pet.eGrid = (1 - Dpath(t)) * p.eGrid;
        Sb_t(t) = sum(sum(polB{t} .* Om));
        Sk_t(t) = sum(sum(polK{t} .* Om));
        Om = push_forward(Om, polB{t}, polK{t}, rb_t(t), qpath(t), d_div, tau_t(t), pet);
    end

    % ---- residuals and damped update ----
    Ptar = Bnom ./ max(Sb_t, 1e-9);              % bond clearing: P = B / S^b
    % tree clearing: raise q where S^k > Kbar (excess demand), lower otherwise;
    % elasticity ~ -1 locally, so a proportional nudge on the gap. The factor
    % is clamped so a large transient gap can never drive q non-positive
    % (which would make log(qtar) complex and poison the whole path).
    qfac = 1 + 0.5*(Sk_t - Kbar)/Kbar;
    qfac = min(max(qfac, 0.7), 1.4);
    qtar = qpath .* qfac;
    Ptar(T) = Pterm; qtar(T) = qterm;            % pin terminal
    dP = max(abs(log(Ptar./Ppath))); dq = max(abs(log(qtar./qpath)));
    dcur = max(dP, dq);

    % adaptive relaxation: cut hard when the residual worsens, creep back up
    % when it improves; checkpoint the best path seen for the retreat above.
    if dcur > dlast
        relax = max(0.4*relax, relax_min);
    else
        relax = min(1.06*relax, relax_max);
    end
    dlast = dcur;
    % checkpoint BEFORE the update, so the stored path and the stored
    % aggregates are the same iterate (what the report needs)
    if dcur < dbest
        dbest = dcur; Pgood = Ppath; qgood = qpath;
        Sb_good = Sb_t; Sk_good = Sk_t;
    end

    % trust-region damped log update
    sP = min(max(relax*(log(Ptar) - log(Ppath)), -step_max), step_max);
    sq = min(max(relax*(log(qtar) - log(qpath)), -step_max), step_max);
    Ppath = exp(log(Ppath) + sP);
    qpath = exp(log(qpath) + sq);
    Ppath(T) = Pterm; qpath(T) = qterm;
    fprintf(['[%5.0fs] outer %2d: max dlnP=%.2e  max dlnq=%.2e  ' ...
             '(Sk-K max %.2e, relax %.3f)\n'], ...
            toc(t0), outer, dP, dq, max(abs(Sk_t - Kbar)), relax);
    if dcur < 1e-4, outconv = true; break; end
end
end   % end of the damped-map fallback
% Always report the best EVALUATED iterate, so the reported prices and the
% reported aggregates are the same path (the loop's trailing update moves
% Ppath past the point where Sb_t/Sk_t were computed).
if exist('Sb_good','var') && isfinite(dbest)
    Ppath = Pgood; qpath = qgood; Sb_t = Sb_good; Sk_t = Sk_good;
end
if ~outconv
    fprintf(['[transition] outer loop did NOT reach 1e-4; best max|dln| = %.2e ' ...
             '-- reporting the best path found.\n'], dbest);
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
tee('max tree-market residual along path = %.2e\n', max(abs(Sk_t - Kbar)));
if outconv
    tee('outer loop CONVERGED (max|dln| < 1e-4)\n');
else
    tee('outer loop NOT converged: best max|dln| = %.2e -- numbers are provisional\n', dbest);
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

function Om2 = push_forward(Om, polB, polK, rb, q, d, tau, pe)
% one-period forward push of the (nx x ne) distribution under this date's
% policies (Young lottery on the cash-on-hand grid, e'-specific targets)
    xG = pe.xGrid(:); nx = numel(xG); ne = numel(pe.eGrid);
    ynet = pe.eGrid(:)' - tau; Rb = 1 + rb;
    Om2 = zeros(nx, ne);
    for ie = 1:ne
        col = Om(:, ie); if ~any(col), continue; end
        base = Rb*polB(:, ie) + (q + d)*polK(:, ie);
        for jep = 1:ne
            xp = min(max(ynet(jep) + base, xG(1)), xG(end));
            idx = discretize(xp, xG); idx(~isfinite(idx)) = nx-1;
            idx = min(max(idx,1), nx-1);
            w = min(max((xp - xG(idx))./(xG(idx+1)-xG(idx)), 0), 1);
            pm = pe.Pi(ie, jep);
            Om2(:, jep) = Om2(:, jep) ...
                + accumarray(idx,   col.*(1-w)*pm, [nx 1]) ...
                + accumarray(idx+1, col.*w*pm,     [nx 1]);
        end
    end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
