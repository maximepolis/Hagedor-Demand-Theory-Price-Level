% MAIN_PROJECT_CALIBRATED  Calibrated pass (roadmap U3). Resolves the two
% calibration tensions flagged in appendix/CALIBRATION_APPENDIX.md and
% re-runs the self-financing decomposition under externally disciplined
% low / medium / high climate-damage columns.
%
% CALIBRATION TARGETS (each mapped to a source; see the appendix):
%   C1. Discount factor beta: chosen so no-program real debt matches
%       debt/GDP ~ 1.1 (OECD general government) at the policy real rate --
%       replaces the illustrative beta=0.96 that implied debt/GDP ~ 5.
%   C2. Program scale: nominal green budget set so real green spending is
%       ~2% of mean income at the calibrated no-program price level
%       (public share of net-zero investment paths: IEA/IMF/NGFS, 1-2.5%).
%   C3. Damage columns (no-abatement damage level D0):
%         LOW    D0 = 0.02   (DICE/Nordhaus, moderate warming)
%         MEDIUM D0 = 0.06   (Dell-Jones-Olken / Burke-Hsiang-Miguel range)
%         HIGH   D0 = 0.20   (Bilal-Kaenzig global-temperature damages)
%       Reduced-form climate (version 1) is used for the columns; theta_g,
%       delta_g retained from the benchmark (theta_g remains ILLUSTRATIVE
%       pending abatement-cost mapping -- stated in the appendix).
%
% OUTPUT: per-column nu decomposition + P*, D, tau; calibrated parameter
% record; output/tables/calibrated_summary.txt; PFig7 (nu by damage column).
%
% USAGE
%   >> main_project_calibrated            % full (na=500)
%   >> FAST = true; main_project_calibrated
%
% STATUS: machinery IMPLEMENTED; numbers become CALIBRATED RESULTS only
% after this script has been run and its log recorded.

clearvars -except FAST; close all; clc;
rng(20260104, 'twister');
t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
    pg.nP_scan = pg.fast.nP_scan;
    fprintf('*** FAST mode: na=%d ***\n', pg.na);
end

% ----- calibration targets (sources in header + appendix) -----
b_target   = 1.10;                    % debt / mean income
g_share    = 0.02;                    % real green spending / mean income
D0_cols    = [0.02, 0.06, 0.20];      % LOW / MEDIUM / HIGH
col_names  = {'LOW (DICE)', 'MEDIUM (DJO-BHM)', 'HIGH (Bilal-Kaenzig)'};
mu_cal     = pg.mu;                   % 2% inflation-target anchor
r_cal      = (1 + pg.i_ss)/(1 + mu_cal) - 1;

if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'calibrated_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' CALIBRATED PASS (U3): debt/GDP target %.2f, program %.1f%% of income\n', ...
        b_target, 100*g_share);
fprintf(' damage columns D0 = {%.2f, %.2f, %.2f}, na=%d\n', D0_cols, pg.na);
fprintf('==============================================================\n');

RCAL = struct();

% =====================================================================
% C1. Calibrate beta at the MEDIUM no-program damage state
% =====================================================================
fprintf('\n===== [C1] Calibrating beta to debt/GDP = %.2f =====\n', b_target);
[beta_star, cb] = calibrate_beta(pg, r_cal, b_target, D0_cols(2));
pgc = pg;
pgc.beta = beta_star;
RCAL.beta_star = beta_star; RCAL.calib_beta = cb;

% =====================================================================
% C2. Program scale: Gg such that g_g ~ g_share at the no-program P0
% =====================================================================
% no-program price level at the calibrated beta (medium damages):
P0_med = pg.Bnom / b_target;                 % by construction S = b_target
Gg_cal = g_share * P0_med;
fprintf('\n===== [C2] Program scale: P0(med)=%.4f => Gg_cal=%.5f =====\n', ...
        P0_med, Gg_cal);
RCAL.P0_med = P0_med; RCAL.Gg_cal = Gg_cal;

% =====================================================================
% C3. Damage columns: nu decomposition per column (climate version 1)
% =====================================================================
fprintf('\n===== [C3] Self-financing by damage column =====\n');
cols = struct('name',{},'D0',{},'nu',{},'nu_reval',{},'nu_damage',{}, ...
              'P0',{},'P1',{},'D1',{},'tau1',{},'n_roots',{});
for c = 1:numel(D0_cols)
    fprintf('\n--- column %s: D0=%.2f ---\n', col_names{c}, D0_cols(c));
    pgcc = pgc;
    pgcc.climate_version = 1;
    pgcc.D0     = D0_cols(c);
    pgcc.Gg_nom = Gg_cal;
    pgcc.mu     = mu_cal;
    % interpolant grids sized to the calibrated tax range (tau ~ r*b + g ~
    % 0.02-0.05) and the column's damage span
    pgcc.taugrid_S = linspace(-0.01, 0.08, 5);
    pgcc.Dgrid_S   = linspace(0, D0_cols(c), 3);
    ad2c = build_S_interp_green(r_cal, pgcc);

    dec_c = self_financing_decomposition(pgcc, ad2c);
    cols(c).name = col_names{c};
    cols(c).D0   = D0_cols(c);
    if dec_c.ok
        cols(c).nu        = dec_c.nu;
        cols(c).nu_reval  = dec_c.nu_reval;
        cols(c).nu_damage = dec_c.nu_damage;
        cols(c).P0   = dec_c.base.P;  cols(c).P1 = dec_c.prog.P;
        cols(c).D1   = dec_c.prog.D;  cols(c).tau1 = dec_c.prog.tau;
        cols(c).n_roots = dec_c.out_prog.n_roots;
    else
        cols(c).nu = NaN; cols(c).nu_reval = NaN; cols(c).nu_damage = NaN;
        cols(c).P0 = NaN; cols(c).P1 = NaN; cols(c).D1 = NaN;
        cols(c).tau1 = NaN; cols(c).n_roots = 0;
    end
    RCAL.dec{c} = dec_c;
end
RCAL.cols = cols;

% ----- PFig7: nu by damage column -----
fh7 = figure('Name','PFig7: Calibrated self-financing by damage column', ...
             'Color','w','Position',[80 80 640 480]); hold on; box on;
nuv = [cols.nu]; nrv = [cols.nu_reval]; ndv = [cols.nu_damage];
bh = bar(1:numel(cols), [nrv; ndv]', 'stacked');
set(bh(1), 'FaceColor', [0.55 0.65 0.85]);   % revaluation
set(bh(2), 'FaceColor', [0.45 0.70 0.45]);   % damage dividend
plot([0.5, numel(cols)+0.5], [1 1], 'k--', 'LineWidth', 1.3);
plot(1:numel(cols), nuv, 'ko', 'MarkerFaceColor','k', 'MarkerSize', 7);
set(gca, 'XTick', 1:numel(cols), 'XTickLabel', {'LOW','MEDIUM','HIGH'});
ylabel('self-financing share \nu');
title(sprintf(['Calibrated pass: debt/GDP=%.1f, program %.0f%% of income ' ...
      '(\\beta=%.3f)'], b_target, 100*g_share, beta_star));
legend({'revaluation \nu_{reval}','damage dividend \nu_{dam}', ...
        'full financing','total \nu'}, 'Location','northwest');
save_all_figs(fh7, 'PFig7_calibrated_nu', pg);

% ----- summary -----
save(fullfile(projdir, 'output', 'calibrated_results.mat'), 'RCAL', 'pgc');
sf = fullfile(pg.tabdir, 'calibrated_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'CALIBRATED PASS (U3) SUMMARY\n');
    fprintf(fid, 'targets: debt/GDP=%.2f  g_share=%.3f  mu=%.3f  i=%.3f\n', ...
            b_target, g_share, mu_cal, pg.i_ss);
    fprintf(fid, 'beta* = %.4f (S at beta* = %.4f; converged=%d)\n', ...
            beta_star, cb.S_at_star, cb.converged);
    fprintf(fid, 'Gg_cal = %.5f (P0_med=%.4f)\n', Gg_cal, P0_med);
    for c = 1:numel(cols)
        fprintf(fid, '%-22s D0=%.2f: nu=%.3f (reval %+.3f, damage %.3f), P0=%.4f P1=%.4f, roots=%d\n', ...
            cols(c).name, cols(c).D0, cols(c).nu, cols(c).nu_reval, ...
            cols(c).nu_damage, cols(c).P0, cols(c).P1, cols(c).n_roots);
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

fprintf('\n================ CALIBRATED SUMMARY ================\n');
fprintf(' beta* = %.4f;  Gg_cal = %.5f (%.1f%% of income at P0)\n', ...
        beta_star, Gg_cal, 100*g_share);
for c = 1:numel(cols)
    fprintf(' %-22s nu = %.3f (reval %+.3f + damage %.3f)\n', ...
            cols(c).name, cols(c).nu, cols(c).nu_reval, cols(c).nu_damage);
end
fprintf(' Elapsed: %.1f s\n', toc(t0));
fprintf('====================================================\n');
diary off;
fprintf('Log saved to %s\n', logfile);
