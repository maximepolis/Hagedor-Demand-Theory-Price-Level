% MAIN_PROJECT_MATURITY  Roadmap U5 + implementation efficiency:
%   M1. Maturity / indexation / holder-composition bounds on the revaluation
%       channel (debt_maturity_revaluation.m) -- pure arithmetic on the saved
%       calibrated and optimal-policy results, runs in seconds.
%   M2. Implementation-efficiency sweep q_g in {0.6, 0.8, 1.0}: how much of
%       the damage dividend survives planning delays and procurement
%       frictions (Leeper-Walker-Yang; IMF Climate-PIMA discipline).
%
% REQUIRES: output/calibrated_results.mat (run main_project_calibrated first)
% and, for the duration block, output/project_results.mat (baseline run).
%
% OUTPUTS: PFig10 (nu^M bounds), PFig11 (nu by q_g),
%          output/tables/maturity_summary.txt.
%
% USAGE
%   >> main_project_maturity            % M1 instant; M2 ~3-6 min at na=500
%   >> FAST = true; main_project_maturity

clearvars -except FAST; close all; clc;
rng(20260106, 'twister');
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
    fprintf('*** FAST mode: na=%d ***\n', pg.na);
end
if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'maturity_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' U5: MATURITY / INDEXATION / HOLDER BOUNDS + q_g EFFICIENCY\n');
fprintf('==============================================================\n');

calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile, 'file') ~= 2
    diary off;
    error('Run main_project_calibrated first (needs calibrated_results.mat).');
end
L = load(calfile);
RCAL = L.RCAL;
beta_star = RCAL.beta_star;  Gg_cal = RCAL.Gg_cal;
r_cal = (1 + pg.i_ss)/(1 + pg.mu) - 1;

% =====================================================================
% M1. nu^M bounds at the calibrated MEDIUM column
% =====================================================================
fprintf('\n===== [M1] Maturity / indexation / holder bounds =====\n');
dm = RCAL.dec{2};                     % medium column decomposition
if ~isfield(dm,'ok') || ~dm.ok
    diary off; error('Medium-column decomposition missing from calibrated_results.');
end
% accommodation move for the duration block: use the baseline package's
% W(mu) experiment if available (mu 0.02 -> 0.045), else duration off.
r1_acc = r_cal;  P0_acc = dm.base.P;  P1_acc = dm.base.P;   %#ok<NASGU>
resfile = fullfile(projdir, 'output', 'project_results.mat');
if exist(resfile, 'file') == 2
    R = load(resfile);
    if isfield(R.RESP, 'opt') && isfinite(R.RESP.opt.mu_star)
        kk  = find(R.RESP.opt.mu_grid == R.RESP.opt.mu_star, 1);
        r1_acc = R.RESP.opt.r(kk);
        fprintf('duration block uses accommodation move r: %.4f -> %.4f (mu* = %.3f)\n', ...
                r_cal, r1_acc, R.RESP.opt.mu_star);
    end
else
    fprintf('project_results.mat not found: duration term evaluated at r1=r0 (off).\n');
end

grids = struct('alpha_I', [0, 0.10, 0.25], ...   % indexed-debt shares (OECD range)
               'alpha_F', [0, 0.30, 0.50], ...   % foreign-held shares
               'delta_m', [0, 0.80, 0.90]);      % 1y / ~5y / ~10y duration
M = debt_maturity_revaluation(dm.base.P, dm.prog.P, r_cal, r1_acc, ...
        dm.prog.g_real, dm.nu_reval, dm.nu_damage, grids);

% PFig10: fiscal nu^M vs indexed share; domestic reval vs foreign share
fh10 = figure('Name','PFig10: Bounding the revaluation channel', ...
              'Color','w','Position',[80 80 1000 420]);
subplot(1,2,1); hold on; box on;
plot(M.fiscal.alpha_I, M.fiscal.nu_M, 'o-', 'LineWidth',2, ...
     'Color',[0.85 0.20 0.15], 'MarkerFaceColor',[0.85 0.20 0.15]);
plot(M.fiscal.alpha_I, M.fiscal.nu_reval_fiscal, 's--', 'LineWidth',1.5, ...
     'Color',[0.10 0.30 0.75]);
plot([min(M.fiscal.alpha_I) max(M.fiscal.alpha_I)], [1 1], 'k--');
xlabel('indexed-debt share  \alpha_I'); ylabel('share of program cost');
title('(a) Fiscal \nu^M: indexation leakage');
legend({'total \nu^M','revaluation component','full financing'}, 'Location','best');
subplot(1,2,2); hold on; box on;
cols = [0.10 0.30 0.75; 0.85 0.55 0.10; 0.85 0.20 0.15];
for i = 1:numel(M.domestic.alpha_I)
    plot(M.domestic.alpha_F, M.domestic.nu_reval_domestic(i,:), 'o-', ...
         'LineWidth',2, 'Color',cols(min(i,3),:));
end
plot([min(M.domestic.alpha_F) max(M.domestic.alpha_F)], [0 0], 'k-');
xlabel('foreign-held share  \alpha_F'); ylabel('domestic revaluation incidence');
title('(b) Who absorbs the windfall');
legend(arrayfun(@(a) sprintf('\\alpha_I=%.2f', a), M.domestic.alpha_I, ...
       'UniformOutput', false), 'Location','best');
save_all_figs(fh10, 'PFig10_maturity_bounds', pg);
fprintf('  [saved] PFig10_maturity_bounds\n');

% =====================================================================
% M2. Implementation-efficiency sweep q_g (medium column)
% =====================================================================
fprintf('\n===== [M2] Implementation efficiency q_g =====\n');
qgs = [0.6, 0.8, 1.0];
nu_q = nan(size(qgs)); nur_q = nan(size(qgs)); nud_q = nan(size(qgs));
for k = 1:numel(qgs)
    pgq = pg;
    pgq.beta = beta_star;
    pgq.climate_version = 1;
    pgq.D0 = 0.06;
    pgq.Gg_nom = Gg_cal;
    pgq.q_g = qgs(k);
    pgq.taugrid_S = linspace(-0.01, 0.08, 5);
    pgq.Dgrid_S   = linspace(0, 0.06, 3);
    ad2q = build_S_interp_green(r_cal, pgq);
    dq = self_financing_decomposition(pgq, ad2q);
    if dq.ok
        nu_q(k) = dq.nu; nur_q(k) = dq.nu_reval; nud_q(k) = dq.nu_damage;
    end
    fprintf('  q_g=%.2f: nu=%.3f (reval %+.3f, damage %.3f)\n', ...
            qgs(k), nu_q(k), nur_q(k), nud_q(k));
end

fh11 = figure('Name','PFig11: Implementation efficiency','Color','w', ...
              'Position',[80 80 620 460]); hold on; box on;
bh = bar(qgs, [nur_q; nud_q]', 'stacked');
set(bh(1),'FaceColor',[0.55 0.65 0.85]); set(bh(2),'FaceColor',[0.45 0.70 0.45]);
plot(qgs, nu_q, 'ko-', 'MarkerFaceColor','k', 'LineWidth',1.5);
plot([min(qgs)-0.05, max(qgs)+0.05], [1 1], 'k--');
xlabel('implementation efficiency  q_g');
ylabel('self-financing share \nu');
title('Damage dividend under implementation frictions (medium damages)');
legend({'revaluation','damage dividend','total \nu','full financing'}, ...
       'Location','best');
save_all_figs(fh11, 'PFig11_implementation_qg', pg);
fprintf('  [saved] PFig11_implementation_qg\n');

% ----- summary -----
sf = fullfile(pg.tabdir, 'maturity_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U5 MATURITY BOUNDS + q_g (medium column, calibrated scale)\n');
    fprintf(fid, '%s\n', M.notes);
    fprintf(fid, 'fiscal nu^M by alpha_I: ');
    fprintf(fid, ' %.2f->%.3f', [M.fiscal.alpha_I; M.fiscal.nu_M]);
    fprintf(fid, '\nduration holding-revaluation (r %.4f->%.4f): ', r_cal, r1_acc);
    fprintf(fid, ' dm=%.2f->%+.3f', [M.duration.delta_m; M.duration.holding_revaluation]);
    fprintf(fid, '\nq_g sweep: ');
    fprintf(fid, ' %.2f->nu=%.3f', [qgs; nu_q]);
    fprintf(fid, '\n');
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end
save(fullfile(projdir,'output','maturity_results.mat'), 'M', 'qgs', 'nu_q', 'nur_q', 'nud_q');

fprintf('\n================ U5 SUMMARY ================\n');
fprintf(' Level-jump equivalence holds; indexation leakage and holder\n');
fprintf(' composition bound the channel; duration active only under the\n');
fprintf(' accommodation move. q_g sweep quantifies implementation frictions.\n');
fprintf(' Elapsed: %.1f s\n', toc(t0));
fprintf('============================================\n');
diary off;
fprintf('Log saved to %s\n', logfile);
