% MAIN_PROJECT_REGIMES  Financing-regime comparison (roadmap U4).
% Compares FOUR ways of financing the SAME real green program at the
% calibrated medium-damage column, holding monetary policy and the nominal
% debt rule fixed:
%
%   R1-DEFICIT            lump-sum financing (the paper's baseline):
%                         tau_ls = r*b + g,     vartheta = 0
%   R2-PROP-LEVY          proportional levy funds the program (carbon-tax-
%                         STYLE incidence; NOT a Pigouvian carbon tax --
%                         no production/emissions margin exists here):
%                         tau_ls = r*b,         vartheta = g/(1-D)
%   R3-PROP-LEVY-REBATE   levy at twice the program, half rebated lump-sum
%                         (Kaenzig-style progressive rebate design):
%                         tau_ls = r*b - g,     vartheta = 2g/(1-D)
%   R4-MIXED-DEFICIT-LEVY half deficit / half levy:
%                         tau_ls = r*b + g/2,   vartheta = g/(2(1-D))
%
% All four satisfy the same aggregate budget identity
%   tau_ls + vartheta*(1-D) = r*b + g,
% so aggregate resources are IDENTICAL across regimes: differences in the
% price level, self-financing share and welfare are pure INCIDENCE effects
% (proportional vs lump-sum) transmitted through asset demand. HONEST SCOPE:
% in the endowment economy neither instrument is distortionary and the levy
% carries no Pigouvian margin (households cannot abate); the emissions-price
% margin requires the production extension (roadmap U8) and is NOT claimed.
%
% Uses the calibrated pass (beta*, Gg_cal) -- loads output/calibrated_results
% .mat if present, otherwise recalibrates. Produces PFig9 and
% output/tables/regimes_summary.txt.
%
% USAGE
%   >> main_project_regimes              % full (na=500)
%   >> FAST = true; main_project_regimes
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
logfile = fullfile(pg.logdir, 'regimes_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' FINANCING REGIMES (U4): deficit vs carbon-levy vs rebate vs mixed\n');
fprintf(' medium damage column, calibrated scale, na=%d\n', pg.na);
fprintf('==============================================================\n');

% ----- calibrated inputs: load if available, else recalibrate -----
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

% ----- regime maps -----
B = pg.Bnom;
g_of  = @(P) Gg_cal ./ P;
D_of  = @(P) climate_block(g_of(P), pgc);
rb_of = @(P) r_cal * B ./ P;

REG = {};
REG{1} = struct('name','R1-DEFICIT','Bnom',B, 'g',g_of, 'D',D_of, ...
    'tau_ls',   @(P) rb_of(P) + g_of(P), ...
    'vartheta', @(P) 0);
REG{2} = struct('name','R2-PROP-LEVY','Bnom',B, 'g',g_of, 'D',D_of, ...
    'tau_ls',   @(P) rb_of(P), ...
    'vartheta', @(P) g_of(P) ./ (1 - D_of(P)));
REG{3} = struct('name','R3-PROP-LEVY-REBATE','Bnom',B, 'g',g_of, 'D',D_of, ...
    'tau_ls',   @(P) rb_of(P) - g_of(P), ...
    'vartheta', @(P) 2 * g_of(P) ./ (1 - D_of(P)));
REG{4} = struct('name','R4-MIXED-DEFICIT-LEVY','Bnom',B, 'g',g_of, 'D',D_of, ...
    'tau_ls',   @(P) rb_of(P) + 0.5 * g_of(P), ...
    'vartheta', @(P) 0.5 * g_of(P) ./ (1 - D_of(P)));

% ----- common no-program baseline (lump-sum, D = D0) -----
fprintf('\n--- no-program baseline ---\n');
base_reg = struct('name','BASELINE','Bnom',B, 'g',@(P) 0*P, ...
    'D',@(P) 0*P + D0_med, 'tau_ls',@(P) rb_of(P), 'vartheta',@(P) 0);
[eq0, out0] = solve_regime_equilibrium(pgc, base_reg, r_cal, [0.5, 1.3]);
if isempty(eq0), diary off; error('No baseline equilibrium: %s', out0.msg); end
fprintf('  %s\n', out0.msg);

% ----- solve each regime + nu + welfare incidence -----
RREG = struct('name',{},'P',{},'D',{},'tau_ls',{},'vartheta',{},'nu',{}, ...
              'nu_reval',{},'nu_damage',{},'W',{},'lam_b50',{},'lam_t10',{}, ...
              'lam_agg',{});
for k = 1:numel(REG)
    fprintf('\n--- %s ---\n', REG{k}.name);
    [eqk, outk] = solve_regime_equilibrium(pgc, REG{k}, r_cal, [0.5, 1.3]);
    if isempty(eqk), fprintf('  %s\n', outk.msg); continue; end
    fprintf('  %s\n', outk.msg);

    nu_reval  = r_cal * B * (1/eq0.P - 1/eqk.P) / eqk.g;
    nu_damage = (eq0.D - eqk.D) / eqk.g;

    wg = welfare_by_group(r_cal, eq0, eqk, pgc);

    RREG(end+1) = struct('name',REG{k}.name,'P',eqk.P,'D',eqk.D, ...
        'tau_ls',eqk.tau_ls,'vartheta',eqk.vartheta, ...
        'nu',nu_reval+nu_damage,'nu_reval',nu_reval,'nu_damage',nu_damage, ...
        'W',eqk.W, ...
        'lam_b50', ternary(wg.ok, wg.lambda_bot50, NaN), ...
        'lam_t10', ternary(wg.ok, wg.lambda_top10, NaN), ...
        'lam_agg', ternary(wg.ok, wg.lambda_agg, NaN)); %#ok<SAGROW>
    if wg.ok, fprintf('  welfare: %s\n', wg.msg); end
end

% ----- PFig9 -----
if ~isempty(RREG)
    fh9 = figure('Name','PFig9: Financing regimes','Color','w', ...
                 'Position',[80 80 1200 560]);
    nm = {'R1 deficit','R2 levy','R3 levy+rebate','R4 mixed'};  % short ticks
    subplot(1,2,1); hold on; box on;
    bh = bar([[RREG.nu_reval]; [RREG.nu_damage]]', 'stacked');
    set(bh(1),'FaceColor',[0.55 0.65 0.85]); set(bh(2),'FaceColor',[0.45 0.70 0.45]);
    yline(1, 'k--', 'LineWidth',1.2, 'HandleVisibility','off');
    plot(1:numel(RREG), [RREG.nu], 'ko', 'MarkerFaceColor','k', 'MarkerSize',7);
    set(gca,'XTick',1:numel(RREG),'XTickLabel',nm,'XTickLabelRotation',20);
    ylabel('self-financing share \nu');
    title('(a) self-financing');
    % legend BELOW the axes: never overlaps the stacked bars
    legend({'revaluation','damage dividend','total \nu'}, ...
           'Location','southoutside', 'Orientation','horizontal');
    subplot(1,2,2); hold on; box on;
    bh2 = bar(100*[[RREG.lam_b50]; [RREG.lam_t10]]', 'grouped');
    set(bh2(1),'FaceColor',[0.85 0.35 0.30]); set(bh2(2),'FaceColor',[0.30 0.35 0.75]);
    yline(0, 'k-', 'LineWidth',0.8, 'HandleVisibility','off');
    set(gca,'XTick',1:numel(RREG),'XTickLabel',nm,'XTickLabelRotation',20);
    ylabel('consumption-equivalent gain (%)');
    title('(b) welfare incidence');
    legend({'bottom 50%','top 10%'}, ...
           'Location','southoutside', 'Orientation','horizontal');
    save_all_figs(fh9, 'PFig9_financing_regimes', pg);
    fprintf('\n  [saved] PFig9_financing_regimes\n');
end

% ----- summary -----
save(fullfile(projdir,'output','regimes_results.mat'), 'RREG', 'eq0', 'pgc');
sf = fullfile(pg.tabdir, 'regimes_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'FINANCING REGIMES (U4): medium damages, calibrated scale\n');
    fprintf(fid, 'beta*=%.4f Gg=%.5f baseline P0=%.4f\n', beta_star, Gg_cal, eq0.P);
    for k = 1:numel(RREG)
        fprintf(fid, ['%-22s P*=%.4f D=%.4f tau_ls=%+.4f vth=%.4f ' ...
            'nu=%.3f (rev %+.3f dam %.3f) lam_b50=%+.2f%% lam_t10=%+.2f%%\n'], ...
            RREG(k).name, RREG(k).P, RREG(k).D, RREG(k).tau_ls, ...
            RREG(k).vartheta, RREG(k).nu, RREG(k).nu_reval, ...
            RREG(k).nu_damage, 100*RREG(k).lam_b50, 100*RREG(k).lam_t10);
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

fprintf('\n================ REGIMES SUMMARY ================\n');
fprintf(' baseline P0=%.4f (no program, lump-sum)\n', eq0.P);
for k = 1:numel(RREG)
    fprintf(' %-22s P*=%.4f  nu=%.3f  bottom50 %+.2f%%  top10 %+.2f%%\n', ...
        RREG(k).name, RREG(k).P, RREG(k).nu, 100*RREG(k).lam_b50, ...
        100*RREG(k).lam_t10);
end
fprintf(' Elapsed: %.1f s\n', toc(t0));
fprintf('=================================================\n');
diary off;
fprintf('Log saved to %s\n', logfile);

% -------------------------------------------------------------------------
function s = ternary(cond, a, b)
    if cond, s = a; else, s = b; end
end
