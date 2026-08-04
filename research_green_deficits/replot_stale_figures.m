% REPLOT_STALE_FIGURES  Re-export the seven figures whose SOURCE DRIVERS were
% edited for labelling after the figures were last produced -- without
% re-solving anything.
%
% WHY THIS IS SOUND HERE, AND WHERE IT WOULD NOT BE.
% paper/check_output_staleness.py flags 16 stored artifacts as older than the
% driver that writes them. Every responsible driver diff was read line by
% line and every one is a FIGURE LABEL or a console banner -- the round-10 nu
% relabelling (fiscal self-financing / resource benefit-cost / net
% household-burden offset) and the R11 regime tick names. No equation, no
% grid, no tolerance and no calibration target changed. The stored .mat files
% are therefore numerically current; only the rendered labels are stale.
%
% So the correct repair is to re-render from the stored results, which takes
% seconds, rather than to re-run five drivers -- one of which
% (main_project_calibrated) would overwrite calibrated_results.mat, the root
% of the dependency tree, for no numerical gain.
%
% IF A DRIVER'S PLOT BLOCK CHANGES SHAPE -- a new panel, a different series,
% a reordered stack -- THIS FILE IS WRONG AND MUST BE UPDATED WITH IT. The
% authoritative figure is always the one the driver produces. This file is a
% label-refresh path, deliberately narrow, and it says so at the top of its
% own output. The durable fix is to extract each driver's plot block into a
% shared function so there is one definition rather than two; that is a
% larger change and is not made here.
%
% WHAT IT COVERS
%   PFig7  calibrated nu by damage column      <- calibrated_results.mat
%   PFig8  welfare incidence by quintile       <- calibrated_results.mat
%   PFig9  financing regimes                   <- regimes_results.mat
%   PFig10 bounding the revaluation channel    <- maturity_results.mat
%   PFig11 implementation efficiency           <- maturity_results.mat
%   PFig20 calibration robustness              <- robustness_results.mat
%   PFig21 aggregate-risk Stage B              <- aggrisk_stageB.mat
%
% PFig1-PFig4 and PFig18 are NOT here: they are drawn by plot_green_figures
% and plot_transition_fig, which replot_paper_figures already calls, so
% re-running that driver picks up their relabelling. Run both.
%
% USAGE   >> cd research_green_deficits
%         >> clear; replot_stale_figures
%         >> clear; replot_paper_figures      % PFig1-4, PFig18
% OUTPUT  output/figures/PFig{7,8,9,10,11,20,21}.{fig,png,pdf}

clearvars; close all; clc;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

pg = setup_params_green();
pg.figdir = fullfile(projdir, 'output', 'figures');
if ~isfolder(pg.figdir), mkdir(pg.figdir); end

fprintf('REPLOT OF LABEL-STALE FIGURES (pipeline %s)\n', kv_code_version(mfilename('fullpath')));
fprintf('No model is solved. Every series is read from a stored .mat; only\n');
fprintf('the rendered labels change. If a driver plot block changed SHAPE\n');
fprintf('rather than wording, re-run that driver instead -- see this file''s\n');
fprintf('header.\n\n');
ndone = 0; nskip = 0;

% =====================================================================
% PFig7 and PFig8 -- main_project_calibrated
% =====================================================================
f = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(f, 'file') == 2
    L = load(f, 'RCAL');
    RCAL = L.RCAL;
    cols = RCAL.cols;
    beta_star = RCAL.beta_star;
    % The driver prints these as its calibration targets; they are constants
    % of the calibrated pass rather than solved objects, so reading them from
    % RCAL when present and falling back to the documented values is safe.
    % They enter the TITLE only -- no series depends on them.
    b_target = 1.10; g_share = 0.02;
    if isfield(RCAL, 'b_target'), b_target = RCAL.b_target; end
    if isfield(RCAL, 'g_share'),  g_share  = RCAL.g_share;  end
    col_names = {'LOW (DICE)', 'MEDIUM (DJO-BHM)', 'HIGH (Bilal-Kaenzig)'};

    % ---- PFig8: welfare incidence by wealth quintile ----
    wgs = {};
    if isfield(RCAL, 'welfare_groups'), wgs = RCAL.welfare_groups; end
    have = find(cellfun(@(w) ~isempty(w) && isstruct(w) && isfield(w,'ok') && w.ok, wgs));
    if ~isempty(have)
        fh8 = figure('Name','PFig8: Welfare incidence by wealth quintile', ...
                     'Color','w','Position',[80 80 820 540]); hold on; box on;
        Mq = nan(numel(have), 5);
        for k = 1:numel(have), Mq(k, :) = 100 * wgs{have(k)}.lambda_q; end
        bh = bar(1:5, Mq', 'grouped');
        shades = [0.55 0.65 0.85; 0.45 0.70 0.45; 0.85 0.35 0.30];
        for k = 1:numel(have), set(bh(k), 'FaceColor', shades(min(k,3),:)); end
        yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
        set(gca, 'XTick', 1:5, ...
            'XTickLabel', {'Q1 (poorest)','Q2','Q3','Q4','Q5 (richest)'});
        ylabel('consumption-equivalent gain (%)');
        legend(cellfun(@(c) col_names{c}, num2cell(have), 'UniformOutput', false), ...
               'Location', 'southoutside', 'Orientation', 'horizontal');
        save_all_figs(fh8, 'PFig8_welfare_incidence', pg);
        fprintf('  [replot] PFig8_welfare_incidence\n'); ndone = ndone + 1;
    else
        fprintf('  [skip]   PFig8: no welfare groups in RCAL\n'); nskip = nskip + 1;
    end

    % ---- PFig7: nu by damage column ----
    % TERMINOLOGY (round 10). nu_reval is FISCAL SELF-FINANCING, nu_dam is
    % the RESOURCE BENEFIT-COST RATIO, and their sum nu is the NET
    % HOUSEHOLD-BURDEN OFFSET. Calling nu a "self-financing share" asserts
    % the fiscal reading of a household object, which is the misstatement
    % this relabelling exists to remove.
    fh7 = figure('Name','PFig7: Calibrated net household-burden offset by damage column', ...
                 'Color','w','Position',[80 80 640 480]); hold on; box on;
    nuv = [cols.nu]; nrv = [cols.nu_reval]; ndv = [cols.nu_damage];
    bh = bar(1:numel(cols), [nrv; ndv]', 'stacked');
    set(bh(1), 'FaceColor', [0.55 0.65 0.85]);   % revaluation
    set(bh(2), 'FaceColor', [0.45 0.70 0.45]);   % damage dividend
    plot([0.5, numel(cols)+0.5], [1 1], 'k--', 'LineWidth', 1.3);
    plot(1:numel(cols), nuv, 'ko', 'MarkerFaceColor','k', 'MarkerSize', 7);
    set(gca, 'XTick', 1:numel(cols), 'XTickLabel', {'LOW','MEDIUM','HIGH'});
    ylabel('net household-burden offset \nu');
    title(sprintf(['Calibrated pass: debt/GDP=%.1f, program %.0f%% of income ' ...
          '(\\beta=%.3f)'], b_target, 100*g_share, beta_star));
    legend({'revaluation \nu_{reval}','damage dividend \nu_{dam}', ...
            'full financing','total \nu'}, 'Location','northwest');
    save_all_figs(fh7, 'PFig7_calibrated_nu', pg);
    fprintf('  [replot] PFig7_calibrated_nu\n'); ndone = ndone + 1;
else
    fprintf('  [skip]   PFig7/PFig8: %s not found\n', f); nskip = nskip + 2;
end

% =====================================================================
% PFig9 -- main_project_regimes
% =====================================================================
f = fullfile(projdir, 'output', 'regimes_results.mat');
if exist(f, 'file') == 2
    L = load(f, 'RREG'); RREG = L.RREG;
    if ~isempty(RREG)
        fh9 = figure('Name','PFig9: Financing regimes','Color','w', ...
                     'Position',[80 80 1200 560]);
        % The internal regime NAMES are R1-LUMPSUM ... R4-MIXED-DEFICIT-LEVY,
        % but 'R1 deficit' must never reach an axis: R1 is the lump-sum
        % baseline and carries no deficit, so the internal name would
        % misdescribe the bar it sits under.
        nm = {'Lump-sum','Proportional levy','Levy plus rebate','Mixed'};
        subplot(1,2,1); hold on; box on;
        bh = bar([[RREG.nu_reval]; [RREG.nu_damage]]', 'stacked');
        set(bh(1),'FaceColor',[0.55 0.65 0.85]);
        set(bh(2),'FaceColor',[0.45 0.70 0.45]);
        yline(1, 'k--', 'LineWidth',1.2, 'HandleVisibility','off');
        plot(1:numel(RREG), [RREG.nu], 'ko', 'MarkerFaceColor','k', 'MarkerSize',7);
        set(gca,'XTick',1:numel(RREG),'XTickLabel',nm,'XTickLabelRotation',20);
        ylabel('Net household-burden offset \nu');
        title('(a) Net household-burden offset');
        legend({'Revaluation', 'Damage dividend', 'Total offset'}, ...
               'Location','southoutside', 'Orientation','horizontal');
        subplot(1,2,2); hold on; box on;
        bh2 = bar(100*[[RREG.lam_b50]; [RREG.lam_t10]]', 'grouped');
        set(bh2(1),'FaceColor',[0.85 0.35 0.30]);
        set(bh2(2),'FaceColor',[0.30 0.35 0.75]);
        yline(0, 'k-', 'LineWidth',0.8, 'HandleVisibility','off');
        set(gca,'XTick',1:numel(RREG),'XTickLabel',nm,'XTickLabelRotation',20);
        ylabel('consumption-equivalent gain (%)');
        title('(b) welfare incidence');
        legend({'bottom 50%','top 10%'}, ...
               'Location','southoutside', 'Orientation','horizontal');
        save_all_figs(fh9, 'PFig9_financing_regimes', pg);
        fprintf('  [replot] PFig9_financing_regimes\n'); ndone = ndone + 1;
    else
        fprintf('  [skip]   PFig9: RREG empty\n'); nskip = nskip + 1;
    end
else
    fprintf('  [skip]   PFig9: %s not found\n', f); nskip = nskip + 1;
end

% =====================================================================
% PFig10 and PFig11 -- main_project_maturity
% =====================================================================
f = fullfile(projdir, 'output', 'maturity_results.mat');
if exist(f, 'file') == 2
    L = load(f, 'M', 'qgs', 'nu_q', 'nur_q', 'nud_q');
    M = L.M; qgs = L.qgs; nu_q = L.nu_q; nur_q = L.nur_q; nud_q = L.nud_q;

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
    legend({'total \nu^M','revaluation component','full financing'}, ...
           'Location','best');
    subplot(1,2,2); hold on; box on;
    ccol = [0.10 0.30 0.75; 0.85 0.55 0.10; 0.85 0.20 0.15];
    for i = 1:numel(M.domestic.alpha_I)
        plot(M.domestic.alpha_F, M.domestic.nu_reval_domestic(i,:), 'o-', ...
             'LineWidth',2, 'Color',ccol(min(i,3),:));
    end
    plot([min(M.domestic.alpha_F) max(M.domestic.alpha_F)], [0 0], 'k-');
    xlabel('foreign-held share  \alpha_F');
    ylabel('domestic revaluation incidence');
    title('(b) Who absorbs the windfall');
    legend(arrayfun(@(a) sprintf('\\alpha_I=%.2f', a), M.domestic.alpha_I, ...
           'UniformOutput', false), 'Location','best');
    save_all_figs(fh10, 'PFig10_maturity_bounds', pg);
    fprintf('  [replot] PFig10_maturity_bounds\n'); ndone = ndone + 1;

    fh11 = figure('Name','PFig11: Implementation efficiency','Color','w', ...
                  'Position',[80 80 620 460]); hold on; box on;
    bh = bar(qgs, [nur_q; nud_q]', 'stacked');
    set(bh(1),'FaceColor',[0.55 0.65 0.85]);
    set(bh(2),'FaceColor',[0.45 0.70 0.45]);
    plot(qgs, nu_q, 'ko-', 'MarkerFaceColor','k', 'LineWidth',1.5);
    plot([min(qgs)-0.05, max(qgs)+0.05], [1 1], 'k--');
    xlabel('implementation efficiency  q_g');
    ylabel('net household-burden offset \nu');
    title('Damage dividend under implementation frictions (medium damages)');
    legend({'revaluation','damage dividend','total \nu','full financing'}, ...
           'Location','best');
    save_all_figs(fh11, 'PFig11_implementation_qg', pg);
    fprintf('  [replot] PFig11_implementation_qg\n'); ndone = ndone + 1;
else
    fprintf('  [skip]   PFig10/PFig11: %s not found\n', f); nskip = nskip + 2;
end

% =====================================================================
% PFig20 -- main_project_robustness
% =====================================================================
f = fullfile(projdir, 'output', 'robustness_results.mat');
if exist(f, 'file') == 2
    L = load(f, 'RB'); RB = L.RB;
    S = RB.surface; SEN = RB.sensitivity;
    fh = figure('Name','PFig20: calibration robustness','Color','w', ...
                'Position',[60 60 1150 420]);
    subplot(1,2,1); hold on; box on;
    [TT, DD] = meshgrid(S.th_grid, S.D0_grid);
    contourf(TT, DD, S.NU, 12, 'LineColor', 'none');
    cb = colorbar; ylabel(cb, 'net household-burden offset \nu');
    okf = isfinite(S.th_star);
    plot(S.th_star(okf), S.D0_grid(okf), 'w-o', 'LineWidth', 2.2, ...
         'MarkerFaceColor','w', 'MarkerSize',5);
    yl = S.D0_grid(S.D0_sourced);
    plot(pg.theta_g*ones(size(yl)), yl, 'rs', 'MarkerFaceColor','r', ...
         'MarkerSize',7);
    xlabel('abatement effectiveness \theta_g');
    ylabel('no-abatement damages D_0');
    title('(a) \nu over (D_0,\theta_g); white: \nu=1 frontier');
    subplot(1,2,2); hold on; box on;
    SENok = SEN([SEN.ok]);
    bar([SENok.nu], 'FaceColor', [0.20 0.55 0.25]);
    yline(1, 'k--');
    set(gca,'XTick',1:numel(SENok),'XTickLabel',{SENok.name}, ...
        'XTickLabelRotation',35);
    ylabel('net household-burden offset \nu');
    title('(b) one-at-a-time sensitivity (medium column, held debt target)');
    save_all_figs(fh, 'PFig20_robustness', pg);
    fprintf('  [replot] PFig20_robustness\n'); ndone = ndone + 1;
else
    fprintf('  [skip]   PFig20: %s not found\n', f); nskip = nskip + 1;
end

% =====================================================================
% PFig21 -- main_project_aggrisk_stageB
% =====================================================================
f = fullfile(projdir, 'output', 'aggrisk_stageB.mat');
if exist(f, 'file') == 2
    L = load(f, 'FISC', 'WEL');
    FISC = L.FISC; WEL = L.WEL;
    fh = figure('Name','PFig21: aggregate-risk Stage B','Color','w', ...
                'Position',[60 60 1120 420]);
    subplot(1,2,1); hold on; box on;
    b1 = bar([1 2 3], [FISC.nu_reval FISC.nu_dam FISC.nu], 0.6);
    b1.FaceColor = 'flat';
    b1.CData = [0.10 0.30 0.75; 0.20 0.55 0.25; 0.35 0.35 0.35];
    yline(1,'k--'); yline(0,'k-');
    set(gca,'XTick',1:3,'XTickLabel',{'\nu_{reval}','\nu_{dam}','\nu (total)'});
    ylabel('net household-burden offset  \nu');
    title('(a) fiscal decomposition (premium inert)');
    subplot(1,2,2); hold on; box on;
    gg = [WEL.risk.constrained, WEL.risk.wq(1), WEL.risk.wq(3), WEL.risk.wq(5), ...
          WEL.risk.state(1), WEL.risk.state(2), WEL.risk.overall];
    bar(100*gg, 'FaceColor', [0.55 0.20 0.55]);
    set(gca,'XTick',1:7, ...
        'XTickLabel',{'constr','Q1','Q3','Q5','Calm','Severe','all'}, ...
        'XTickLabelRotation',30);
    ylabel('insurance value (CE %)'); yline(0,'k-');
    title('(b) welfare value of risk compression, by group');
    save_all_figs(fh, 'PFig21_aggrisk_welfare', pg);
    fprintf('  [replot] PFig21_aggrisk_welfare\n'); ndone = ndone + 1;
else
    fprintf('  [skip]   PFig21: %s not found\n', f); nskip = nskip + 1;
end

fprintf('\n%d figure(s) re-exported, %d skipped.\n', ndone, nskip);
fprintf('Now run:  clear; replot_paper_figures   (PFig1-PFig4, PFig18)\n');
fprintf('Then:     python3 paper/check_output_staleness.py\n');
