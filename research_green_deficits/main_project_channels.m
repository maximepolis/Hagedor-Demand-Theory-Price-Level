% MAIN_PROJECT_CHANNELS  Editorial-roadmap Steps 4-5 in one run:
%
%   (A) SAFE-ASSET-CHANNEL DECOMPOSITION (decompose_safe_asset_channel):
%       WHY does the price level fall when the program is introduced?
%       Counterfactual GE price levels isolate the tax-burden, damage
%       level/incidence, risk, and financing-instrument contributions to
%       ln P1 - ln P0 (exact accounting; interaction reported).
%       -> PFig15_safe_asset_decomposition
%       -> output/tables/safe_asset_channel_summary.txt
%
%   (B) EXTENDED WELFARE GROUPS (welfare_groups_extended):
%       CE incidence by income-state quintile, wealth(=bondholding)
%       quintile, constrained vs unconstrained, high-MPC proxy, and (when
%       psi_inc>0) climate-exposure terciles, for the deficit regime and
%       the levy+rebate regime.
%       -> PFig16_extended_welfare_groups
%       -> output/tables/welfare_groups_extended_summary.txt
%
% Medium-damage column at the calibrated scale (same inputs as
% main_project_regimes). HONEST SCOPE: STEADY-STATE incidence; the levy is
% a proportional financing instrument with carbon-tax-style incidence, NOT
% a Pigouvian carbon tax (no production/emissions margin).
%
% USAGE   >> main_project_channels          % full (na=500)
%         >> FAST = true; main_project_channels
%
% STATUS: machinery IMPLEMENTED; numbers are results only once run.

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
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
    fprintf('*** FAST mode: na=%d ***\n', pg.na);
end

if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'channels_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' SAFE-ASSET CHANNEL + EXTENDED WELFARE GROUPS (Steps 4-5)\n');
fprintf(' medium damage column, calibrated scale, na=%d\n', pg.na);
fprintf('==============================================================\n');

% ----- calibrated inputs (same protocol as main_project_regimes) -----
D0_med = 0.06;
r_cal  = (1 + pg.i_ss)/(1 + pg.mu) - 1;
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile, 'file') == 2
    L = load(calfile);
    beta_star = L.RCAL.beta_star;
    Gg_cal    = L.RCAL.Gg_cal;
    fprintf('loaded calibrated inputs: beta*=%.4f, Gg=%.5f\n', beta_star, Gg_cal);
else
    fprintf('calibrated_results.mat not found -- recalibrating beta...\n');
    [beta_star, ~] = calibrate_beta(pg, r_cal, 1.10, D0_med);
    Gg_cal = 0.02 * (pg.Bnom / 1.10);
end
pgc = pg;
pgc.beta = beta_star;
pgc.climate_version = 1;
pgc.D0 = D0_med;

% ================= (A) safe-asset-channel decomposition =================
fprintf('\n--- (A) safe-asset-channel decomposition ---\n');
SA = decompose_safe_asset_channel(pgc, r_cal, pg.Bnom, Gg_cal, D0_med, [0.5, 1.3]);
if ~SA.ok, diary off; error('Safe-asset decomposition failed: %s', SA.msg); end
fprintf('  %s\n', SA.msg);

% ----- PFig15: waterfall + PE asset-demand nodes -----
fh15 = figure('Name','PFig15: Safe-asset channel','Color','w', ...
              'Position',[70 70 1200 560]);
subplot(1,2,1); hold on; box on;
contrib = [SA.c_tax, SA.c_damage, SA.c_risk, SA.c_interaction];
labs    = {'tax','damage','risk','interact.'};   % short ticks; caption explains
for k = 1:numel(contrib)
    fc = [0.55 0.65 0.85];                       % disinflationary: blue
    if contrib(k) > 0, fc = [0.85 0.35 0.30]; end % inflationary: red
    bar(k, 100*contrib(k), 0.6, 'FaceColor', fc, 'BaseValue', 0); %#ok<*UNRCH>
end
bar(numel(contrib)+1, 100*SA.dlnP_total, 0.6, 'FaceColor', [0.20 0.55 0.25]);
yline(0, 'k-', 'LineWidth', 0.8);
set(gca,'XTick',1:numel(contrib)+1,'XTickLabel',[labs,{'total'}]);
ylabel('contribution to ln P_1 - ln P_0  (%)');
title('(a) GE contributions');
subplot(1,2,2); hold on; box on;
pe = SA.PE;
vals = [pe.S_tau0_D0, pe.S_tau1_D0, pe.S_tau0_D1level, pe.S_tau0_D1risk, pe.S_tau1_D1];
pl   = {'(\tau_0,D_0)','(\tau_1,D_0)','(\tau_0,D_1^{lev})', ...
        '(\tau_0,D_1^{risk})','(\tau_1,D_1)'};
bar(1:numel(vals), vals, 0.6, 'FaceColor', [0.85 0.55 0.10]);
% zoom to the informative range: level differences, not the zero base
rng_ = [min(vals), max(vals)];
ylim([rng_(1) - 0.35*diff(rng_), rng_(2) + 0.35*diff(rng_)]);
set(gca,'XTick',1:numel(vals),'XTickLabel',pl,'XTickLabelRotation',25);
ylabel('aggregate asset demand S');
title('(b) PE demand at fixed r');
save_all_figs(fh15, 'PFig15_safe_asset_decomposition', pg);
fprintf('  [saved] PFig15_safe_asset_decomposition\n');

% ----- summary table -----
sf = fullfile(pg.tabdir, 'safe_asset_channel_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'SAFE-ASSET-CHANNEL DECOMPOSITION (Step 4) -- STEADY STATE\n');
    fprintf(fid, 'medium damages D0=%.2f, calibrated beta*=%.4f, Gg=%.5f, r=%.4f\n\n', ...
        D0_med, beta_star, Gg_cal, r_cal);
    fprintf(fid, 'GE counterfactual price levels:\n');
    fprintf(fid, '  N0 baseline            P0     = %.4f\n', SA.eq0.P);
    fprintf(fid, '  N1 program (lump-sum)  P1     = %.4f   D1*=%.4f\n', SA.eq1.P, SA.D1star);
    if ~isempty(SA.eq2), fprintf(fid, '  N2 tax-only            P_tax  = %.4f\n', SA.eq2.P); end
    if ~isempty(SA.eq3), fprintf(fid, '  N3 damage-only         P_dam  = %.4f\n', SA.eq3.P); end
    if ~isempty(SA.eq4), fprintf(fid, '  N4 risk-only           P_risk = %.4f\n', SA.eq4.P); end
    if ~isempty(SA.eq5), fprintf(fid, '  N5 levy-financed       P_levy = %.4f\n', SA.eq5.P); end
    fprintf(fid, '\nlog contributions to ln P1 - ln P0 = %+.4f:\n', SA.dlnP_total);
    fprintf(fid, '  tax burden            %+.4f\n', SA.c_tax);
    fprintf(fid, '  damage level+incid.   %+.4f\n', SA.c_damage);
    fprintf(fid, '  risk (phi_D channel)  %+.4f\n', SA.c_risk);
    fprintf(fid, '  interaction           %+.4f\n', SA.c_interaction);
    fprintf(fid, '  financing swap (levy vs lump-sum, at same program): %+.4f\n', SA.c_financing);
    fprintf(fid, '\nPE asset-demand nodes at fixed r (tau0=%.4f, tau1=%.4f):\n', ...
        SA.eq0.tau_ls, SA.eq0.tau_ls + SA.eq1.g);
    fprintf(fid, '  S(tau0,D0)=%.4f  S(tau1,D0)=%.4f  S(tau0,D1lev)=%.4f  S(tau0,D1risk)=%.4f  S(tau1,D1)=%.4f\n', ...
        SA.PE.S_tau0_D0, SA.PE.S_tau1_D0, SA.PE.S_tau0_D1level, ...
        SA.PE.S_tau0_D1risk, SA.PE.S_tau1_D1);
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ================= (B) extended welfare groups =================
fprintf('\n--- (B) extended welfare groups ---\n');
% deficit regime (N1) vs levy+rebate regime, against the same baseline
g_of  = @(P) Gg_cal ./ P;
D_of  = @(P) climate_block(g_of(P), pgc);
rb_of = @(P) r_cal * pg.Bnom ./ P;
regR = struct('name','R3-PROP-LEVY-REBATE','Bnom',pg.Bnom, 'g',g_of, 'D',D_of, ...
    'tau_ls',@(P) rb_of(P) - g_of(P), 'vartheta',@(P) 2*g_of(P)./(1 - D_of(P)));
[eqR, oR] = solve_regime_equilibrium(pgc, regR, r_cal, [0.5, 1.3]);
fprintf('  %s\n', oR.msg);

WX = struct();
WX.deficit = welfare_groups_extended(r_cal, SA.eq0, SA.eq1, pgc);
if WX.deficit.ok, fprintf('  DEFICIT: %s\n', WX.deficit.msg); end
if ~isempty(eqR)
    WX.rebate = welfare_groups_extended(r_cal, SA.eq0, eqR, pgc);
    if WX.rebate.ok, fprintf('  REBATE:  %s\n', WX.rebate.msg); end
end

% ----- PFig16 -----
if WX.deficit.ok
    fh16 = figure('Name','PFig16: Extended welfare groups','Color','w', ...
                  'Position',[80 80 1050 430]);
    subplot(1,2,1); hold on; box on;
    M = 100*[WX.deficit.lambda_income_q; WX.deficit.lambda_wealth_q]';
    bh = bar(M, 'grouped');
    set(bh(1),'FaceColor',[0.85 0.35 0.30]); set(bh(2),'FaceColor',[0.30 0.35 0.75]);
    plot([0.5 5.5],[0 0],'k-','LineWidth',0.8);
    xlabel('quintile (baseline distribution)'); ylabel('CE gain (%)');
    title('(a) Deficit financing: income vs wealth(=bond) quintiles');
    legend({'income-state quintiles','wealth quintiles'},'Location','best');
    subplot(1,2,2); hold on; box on;
    cats = {'constr.','unconstr.','high-MPC','low-MPC'};
    vd = 100*[WX.deficit.lambda_constrained, WX.deficit.lambda_unconstrained, ...
              WX.deficit.lambda_mpc.hi, WX.deficit.lambda_mpc.lo];
    if isfield(WX,'rebate') && WX.rebate.ok
        vr = 100*[WX.rebate.lambda_constrained, WX.rebate.lambda_unconstrained, ...
                  WX.rebate.lambda_mpc.hi, WX.rebate.lambda_mpc.lo];
        bh2 = bar([vd; vr]', 'grouped');
        set(bh2(1),'FaceColor',[0.85 0.35 0.30]); set(bh2(2),'FaceColor',[0.20 0.55 0.25]);
        legend({'deficit','levy+rebate'},'Location','best');
    else
        bar(vd, 0.6, 'FaceColor', [0.85 0.35 0.30]);
    end
    plot([0.5 4.5],[0 0],'k-','LineWidth',0.8);
    set(gca,'XTick',1:4,'XTickLabel',cats);
    ylabel('CE gain (%)');
    title('(b) Constrained and high-MPC households');
    save_all_figs(fh16, 'PFig16_extended_welfare_groups', pg);
    fprintf('  [saved] PFig16_extended_welfare_groups\n');
end

% ----- summary table -----
sf = fullfile(pg.tabdir, 'welfare_groups_extended_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'EXTENDED WELFARE GROUPS (Step 5) -- STEADY-STATE CE incidence\n');
    fprintf(fid, 'medium damages, calibrated scale; wealth quintiles = BONDHOLDING\n');
    fprintf(fid, 'quintiles (one-asset economy); MPC groups are a dC/dA PROXY.\n\n');
    regs = fieldnames(WX);
    for k = 1:numel(regs)
        w = WX.(regs{k});
        if ~isstruct(w) || ~isfield(w,'ok') || ~w.ok, continue; end
        fprintf(fid, '[%s]\n', upper(regs{k}));
        fprintf(fid, '  income-q (%%):  %s\n', mat2str(round(100*w.lambda_income_q,2)));
        fprintf(fid, '  wealth-q (%%):  %s\n', mat2str(round(100*w.lambda_wealth_q,2)));
        fprintf(fid, '  constrained %+.2f%% (mass %.1f%%)  unconstrained %+.2f%%\n', ...
            100*w.lambda_constrained, 100*w.share_constrained, 100*w.lambda_unconstrained);
        fprintf(fid, '  high-MPC %+.2f%%  low-MPC %+.2f%%  (dC/dA threshold %.3f)\n', ...
            100*w.lambda_mpc.hi, 100*w.lambda_mpc.lo, w.lambda_mpc.thresh);
        if w.lambda_exposure.active
            fprintf(fid, '  exposure terciles (hi/mid/lo chi): %+.2f%% / %+.2f%% / %+.2f%%\n', ...
                100*w.lambda_exposure.hi, 100*w.lambda_exposure.mid, 100*w.lambda_exposure.lo);
        else
            fprintf(fid, '  exposure groups: INACTIVE (psi_inc = 0 at this calibration)\n');
        end
        fprintf(fid, '  aggregate: %+.2f%%\n\n', 100*w.lambda_agg);
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

save(fullfile(projdir,'output','channels_results.mat'), 'SA', 'WX', 'pgc');
fprintf('\nElapsed: %.1f s\n', toc(t0));
diary off;
fprintf('Log saved to %s\n', logfile);
