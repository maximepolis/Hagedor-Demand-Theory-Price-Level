function [pgc, opts, info] = kv_legacy_transition_setup(FAST)
% KV_LEGACY_TRANSITION_SETUP  Build (pgc, opts) exactly as the legacy
% transition drivers do, so that any run claiming to reproduce the legacy
% experiment actually does.
%
% THE DEFECT THIS FIXES. kv_kappa_legacy called
%     o = struct('T',T,'regime','indexed','financing','deficit','rho_d',rho_bar);
%     TRd = solve_hank_dtpl_transition(pgc, o);
% with pgc = setup_params_green(), i.e. the DEFAULT discount factor. Every
% real caller -- main_transition_deficit.m lines 55-83, main_project_transition
% -- instead does
%
%     pgc = pg; pgc.beta = beta_star; pgc.climate_version = 1; pgc.D0 = D0_med;
%     opts.Gg_nom = Gg_cal;
%
% with beta_star from calibrate_beta. The difference is not cosmetic: with the
% default beta, asset demand exceeds debt supply at every price in the
% solver's hard-coded [0.5, 1.3] bracket, so the excess-demand function has no
% sign change and the BASELINE STEADY STATE does not exist. The observed
% failure was
%     regime TR-BASE: no sign change on [0.5, 1.3] (Phi ends: +2.018 / +3.078)
%
% The FAST branch also rebuilds the asset grid at pg.fast.na, which the
% earlier code omitted -- it only shortened the horizon, so FAST changed T
% without changing the grid the legacy FAST runs use.
%
% Any kappa recovered from the old setup was therefore not the manuscript's
% legacy dilution. Nothing was reported from it.
%
% THE CALIBRATION IS ALWAYS RECOMPUTED, never read from
% output/calibrated_results.mat as the legacy driver optionally does. A cached
% beta present in one run and absent in another would make two runs differ by
% their cache rather than by their code.
%
% This file is duplicated as a LOCAL function inside main_baseline_capture,
% which runs with a deliberately isolated MATLAB path (only the frozen
% baseline is reachable) and so cannot call into src_project. The two must
% stay identical; the D11 parity comparison is what would detect it if they
% did not, since a setup difference moves every path.
%
% INPUT   FAST  logical
% OUTPUT  pgc   parameters with the calibrated beta, climate_version, D0
%         opts  T, tol, maxit, xi, verbose, Gg_nom
%         info  .beta_star .D0_med .Gg_cal .na .T .source

    if nargin < 1 || isempty(FAST), FAST = false; end

    pg = setup_params_green();
    opts = struct('T', 80, 'tol', 2e-3, 'maxit', 120, 'xi', 0.5, 'verbose', false);
    if FAST
        pg.na    = pg.fast.na;
        u        = linspace(0, 1, pg.na)';
        pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u .^ pg.acurv);
        pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
        opts.T = 60; opts.maxit = 80;
    end

    D0_med = 0.06;
    [beta_star, ~] = calibrate_beta(pg, (1 + pg.i_ss)/(1 + pg.mu) - 1, 1.10, D0_med);
    Gg_cal = 0.02 * (pg.Bnom / 1.10);

    pgc = pg;
    pgc.beta = beta_star;
    pgc.climate_version = 1;
    pgc.D0 = D0_med;
    opts.Gg_nom = Gg_cal;

    info = struct('beta_star', beta_star, 'D0_med', D0_med, 'Gg_cal', Gg_cal, ...
                  'na', pg.na, 'T', opts.T, 'fast', FAST, ...
                  'source', 'main_transition_deficit.m lines 55-83');
end
