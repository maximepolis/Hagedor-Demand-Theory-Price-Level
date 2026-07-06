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
opts = struct('T', 80, 'tol', 2e-3, 'maxit', 60, 'xi', 0.5, 'verbose', true);  % T in YEARS
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
    opts.T = 50; opts.maxit = 40;
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
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile, 'file') == 2
    L = load(calfile);
    beta_star = L.RCAL.beta_star;
    Gg_cal    = L.RCAL.Gg_cal;
    fprintf('loaded calibrated inputs: beta*=%.4f, Gg=%.5f\n', beta_star, Gg_cal);
else
    fprintf('calibrated_results.mat not found -- recalibrating beta...\n');
    [beta_star, ~] = calibrate_beta(pg, (1+pg.i_ss)/(1+pg.mu)-1, 1.10, D0_med);
    Gg_cal = 0.02 * (pg.Bnom / 1.10);
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

% ---- PFig18 ----
if ~isempty(TRn.msg) && isfield(TRn, 'phat')
    T = numel(TRn.phat);
    fh = figure('Name','PFig18: nonlinear HANK-DTPL transition','Color','w', ...
                'Position',[60 60 1100 640]);
    tv = 1:T;
    subplot(2,3,1); hold on; box on;
    plot(tv, TRn.phat, 'LineWidth', 1.8, 'Color', [0.10 0.30 0.75]);
    if isfield(TRi,'phat'), plot(tv, TRi.phat, 'LineWidth', 1.8, ...
            'Color', [0.20 0.55 0.25]); end
    yline(TRn.P0, ':k'); yline(TRn.eq1.P, '--k');
    xlabel('years'); title('stationarized price level P_t/(1+\mu)^t');
    legend({'nominal budget','indexed mandate'}, 'Location','best');
    subplot(2,3,2); hold on; box on;
    plot(tv, 100*TRn.pi_path, 'LineWidth', 1.8, 'Color', [0.10 0.30 0.75]);
    if isfield(TRi,'pi_path'), plot(tv, 100*TRi.pi_path, 'LineWidth', 1.8, ...
            'Color', [0.20 0.55 0.25]); end
    yline(100*pgc.mu, ':k');
    xlabel('years'); title('inflation (% per year)');
    subplot(2,3,3); hold on; box on;
    plot(tv, TRn.b_path, 'LineWidth', 1.8, 'Color', [0.10 0.30 0.75]);
    plot(tv, TRn.S_path, '--', 'LineWidth', 1.4, 'Color', [0.85 0.20 0.15]);
    xlabel('years'); title('real debt b_t vs asset demand S_t');
    legend({'b_t = B_t/P_t','S_t'}, 'Location','best');
    subplot(2,3,4); hold on; box on;
    plot(tv, TRn.Kg_path, 'LineWidth', 1.8, 'Color', [0.20 0.55 0.25]);
    xlabel('years'); title('green capital K_{g,t}');
    subplot(2,3,5); hold on; box on;
    plot(tv, TRn.D_path, 'LineWidth', 1.8, 'Color', [0.85 0.55 0.10]);
    xlabel('years'); title('damages D_t');
    subplot(2,3,6); hold on; box on;
    semilogy(tv, abs(TRn.resid), 'LineWidth', 1.4, 'Color', [0.10 0.30 0.75]);
    if isfield(TRi,'resid'), semilogy(tv, abs(TRi.resid), 'LineWidth', 1.4, ...
            'Color', [0.20 0.55 0.25]); end
    xlabel('years'); title('|S_t - b_t|/b_t (residuals, log scale)');
    save_all_figs(fh, 'PFig18_dtpl_transition', pg);
    fprintf('\n  [saved] PFig18_dtpl_transition\n');
end

% ---- summary ----
sf = fullfile(pg.tabdir, 'transition_dtpl_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER 2: NONLINEAR HANK-DTPL TRANSITION (v1 damped fixed point)\n');
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
