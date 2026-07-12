% MAIN_PROJECT_TRANSITION  U7 TIER 2: the nonlinear HANK-DTPL transition.
%
% At t=1 the government unexpectedly announces the permanent green program
% (calibrated scale, medium damages). The PRICE-LEVEL PATH {P_t} is the
% unknown: at every date P_t clears the asset market against exact
% aggregate asset demand computed by backward induction from the green
% terminal steady state and forward iteration of the wealth distribution.
% This is the paper's mechanism in dynamics -- no Phillips curve, no
% policy-rule inflation: the announcement's inflation path IS the repricing
% of the nominal-debt stock against precautionary demand.
%
% TWO REGIMES:
%   NOMINAL  Gg fixed in nominal terms (the anchor-exposed appropriation)
%   INDEXED  real green mandate (the anchor-insulated design)
% Their impact-jump comparison is the DYNAMIC version of the paper's
% anchor-insulation result.
%
% COMPUTATIONAL COST (deliberate -- this is the package's heavy tier):
% each path iteration = T Bellman sweeps (na x na x ne tensors) + T
% distribution pushes; expect O(10) minutes per regime at na=500, T=150.
% Use FAST = true for a first pass (na=150, T=100).
%
% OUTPUT: PFig18_dtpl_transition.{fig,png,pdf}, ../output/transition_
% results.mat, output/tables/transition_dtpl_summary.txt (with residuals
% -- a non-converged path is reported as such, never as a result).
%
% USAGE   >> main_project_transition
%         >> FAST = true; main_project_transition
%
% STATUS: IMPLEMENTED (v1, damped fixed point); numbers are results only
% once a converged run is verified. NONLINEAR HANK-DTPL TRANSITION tier.

clearvars -except FAST; close all; clc;
rng(20260105, 'twister');
t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
opts = struct('T', 80, 'tol', 2e-3, 'maxit', 120, 'xi', 0.5, 'verbose', true);  % T in YEARS
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
    opts.T = 60; opts.maxit = 80;
    fprintf('*** FAST mode: na=%d, T=%d ***\n', pg.na, opts.T);
end

if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'transition_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' U7 TIER 2: NONLINEAR HANK-DTPL TRANSITION (na=%d, T=%d)\n', pg.na, opts.T);
fprintf('==============================================================\n');

% calibrated inputs (same protocol as regimes/channels drivers)
D0_med = 0.06;
r_cal  = (1 + pg.i_ss)/(1 + pg.mu) - 1; %#ok<NASGU>  (recomputed inside)
% beta must be calibrated ON THIS RUN'S GRID: a beta calibrated at another
% na shifts aggregate asset demand by a few percent, so the boundary steady
% states would miss the debt/GDP=1.10 target (first full run: na=100 beta
% on the na=500 grid gave P0=0.8467 instead of ~0.909). Reuse the stored
% calibration only if its grid matches; otherwise recalibrate here.
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
beta_star = [];
if exist(calfile, 'file') == 2
    L = load(calfile);
    if isfield(L.RCAL, 'na') && L.RCAL.na == pg.na
        beta_star = L.RCAL.beta_star;
        Gg_cal    = L.RCAL.Gg_cal;
        fprintf('loaded calibrated inputs (na=%d matches): beta*=%.4f, Gg=%.5f\n', ...
            pg.na, beta_star, Gg_cal);
    else
        fprintf(['stored calibration grid mismatch (this run na=%d) -- ' ...
                 'recalibrating beta on this grid...\n'], pg.na);
    end
else
    fprintf('calibrated_results.mat not found -- recalibrating beta...\n');
end
if isempty(beta_star)
    [beta_star, ~] = calibrate_beta(pg, (1+pg.i_ss)/(1+pg.mu)-1, 1.10, D0_med);
    Gg_cal = 0.02 * (pg.Bnom / 1.10);
    fprintf('recalibrated on na=%d: beta*=%.4f, Gg=%.5f\n', pg.na, beta_star, Gg_cal);
end
pgc = pg;
pgc.beta = beta_star;
pgc.climate_version = 1;
pgc.D0 = D0_med;
opts.Gg_nom = Gg_cal;

% ---- run both regimes ----
fprintf('\n--- NOMINAL appropriation ---\n');
opts.regime = 'nominal';
TRn = solve_hank_dtpl_transition(pgc, opts);
fprintf('  %s\n', TRn.msg);

fprintf('\n--- INDEXED (real) mandate ---\n');
opts.regime = 'indexed';
TRi = solve_hank_dtpl_transition(pgc, opts);
fprintf('  %s\n', TRi.msg);

save(fullfile(projdir, 'output', 'transition_results.mat'), 'TRn', 'TRi', 'pgc', 'opts');

% ---- PFig18 (plotting extracted to src_project/plot_transition_fig so the
% figure can be re-exported from transition_results.mat without re-solving) ----
plot_transition_fig(TRn, TRi, pgc, pg);

% ---- summary ----
sf = fullfile(pg.tabdir, 'transition_dtpl_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER 2: NONLINEAR HANK-DTPL TRANSITION (Anderson-accelerated fixed point)\n');
    fprintf(fid, 'Scope: the price-level path clears the asset market at every date (ANNUAL);\n');
    fprintf(fid, 'no Phillips curve, no policy-rule inflation. na=%d, T=%d, tol=%.0e.\n\n', ...
        pg.na, opts.T, opts.tol);
    for TRc = {TRn, TRi}
        TR = TRc{1};
        if ~isfield(TR, 'phat'), fprintf(fid, 'FAILED: %s\n', TR.msg); continue; end
        fprintf(fid, '%s\n', TR.msg);
        fprintf(fid, ['  impact: phat_1/P0 = %.4f; pi_1 = %+.2f%%/yr; ' ...
            'reval stock = %+.4f (= %+.2f%% of program PV)\n'], ...
            TR.phat(1)/TR.P0, 100*TR.pi_path(1), TR.reval_stock, ...
            100*TR.reval_pv_share);
        fprintf(fid, '  path: pi(4y) %+.2f%%, pi(20y) %+.2f%%, pi(40y) %+.2f%% (per yr, vs trend %.2f%%)\n', ...
            100*TR.pi_path(min(4,end)), 100*TR.pi_path(min(20,end)), ...
            100*TR.pi_path(min(40,end)), 100*pgc.mu);
        rint = max(abs(TR.resid(1:end-1)));
        rter = abs(TR.resid(end));
        rep  = isfield(TR,'reportable') && TR.reportable;
        if isfield(TR, 'frontload')
            fprintf(fid, ['  front-loading: %.1f%% of the long-run price decline ' ...
                'realized in the announcement year; |pi-trend|<25bp from year %d\n'], ...
                100*TR.frontload, TR.trend_return);
        end
        fprintf(fid, ['  residuals: interior(free) max %.5f, terminal(horizon) %.5f, ' ...
            'mean %.5f\n'], rint, rter, mean(abs(TR.resid)));
        fprintf(fid, ['  fixed point converged = %d, horizon adequate = %d, ' ...
            'REPORTABLE = %d (iters %d)\n\n'], TR.converged, ...
            (isfield(TR,'horizon_ok') && TR.horizon_ok), rep, TR.iters);
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end
fprintf('Elapsed: %.1f s\n', toc(t0));
diary off;
fprintf('Log saved to %s\n', logfile);
