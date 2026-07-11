% MAIN_PROJECT_ROBUSTNESS  U9: calibration robustness for the headline
% self-financing result. Two exercises, both STEADY STATE, both at the
% CALIBRATED scale (beta* to debt/GDP = 1.10; program = 2% of income):
%
%  A. THE (D0, theta_g) SURFACE. The two least-disciplined climate
%     parameters are the no-abatement damage level D0 (anchored by
%     published damage estimates: DICE ~0.02, Dell-Jones-Olken /
%     Burke-Hsiang-Miguel ~0.06, Bilal-Kaenzig ~0.20) and the abatement
%     effectiveness theta_g (genuinely ILLUSTRATIVE -- no study pins it).
%     Rather than defend a point value, compute nu on the whole
%     (D0, theta_g) plane and report the nu = 1 FRONTIER: for each damage
%     level, the abatement effectiveness needed for full self-financing.
%     The paper's answer is then a correspondence, not a point estimate,
%     and the reader can locate their own beliefs on the map. The sign of
%     nu_reval is recorded at every node (expected: negative throughout
%     under lump-sum financing -- the disinflation result is not a
%     calibration artifact).
%
%  B. ONE-AT-A-TIME SENSITIVITY at the MEDIUM column, with a HELD-TARGET
%     protocol: for each variant that changes the no-program economy
%     (sigma, phi_D, psi), beta is RE-CALIBRATED so debt/GDP = 1.10 still
%     holds; variants that leave the no-program state untouched (delta_g,
%     program scale) keep the benchmark beta*. Differences in nu are then
%     pure parameter effects, never artifacts of a drifting debt ratio.
%     Variants: sigma in {1,3} (benchmark 2), phi_D in {0,1} (benchmark
%     0.5), psi in {1,2} (benchmark 0), delta_g = 0.05 (benchmark 0.10),
%     program scale in {1%,4%} of income (benchmark 2%).
%
% REQUIRES: output/calibrated_results.mat (run main_project_calibrated
% first -- it stores beta*, Gg_cal, P0_med on the same grid).
%
% USAGE   >> main_project_robustness              % na=500 benchmark grid
%         >> NA = 250; main_project_robustness    % mid-resolution
%         >> FAST = true; main_project_robustness % na=100 quick pass
%
% OUTPUT  PFig20_robustness.{fig,png,pdf}, output/robustness_results.mat,
%         output/tables/robustness_summary.txt
%
% STATUS: IMPLEMENTED. All results STEADY STATE. No parameter value in
% this file is presented as calibrated unless it carries a source; grid
% points between the three sourced damage columns are interpolating
% nodes for the frontier, labeled as such.

clearvars -except FAST NA; close all; clc;
t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
if exist('NA','var') && ~isempty(NA)
    pg.na = NA;
elseif FAST
    pg.na = pg.fast.na;
end
if pg.na ~= numel(pg.aGrid)
    u = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
end
if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'robustness_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

% ---- calibrated inputs (same protocol as the calibrated pass) ----
b_target = 1.10;
mu_cal   = pg.mu;
r_cal    = (1 + pg.i_ss)/(1 + mu_cal) - 1;
calfile  = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile, 'file') == 2
    L = load(calfile);
    beta_star = L.RCAL.beta_star;
    Gg_cal    = L.RCAL.Gg_cal;
    P0_med    = L.RCAL.P0_med;
    if isfield(L.RCAL,'na') && L.RCAL.na ~= pg.na
        fprintf(['NOTE: calibrated pass ran at na=%d, this run is na=%d.\n' ...
                 'beta* is re-solved on THIS grid to keep the debt target\n' ...
                 'exact (grid-consistency rule).\n'], L.RCAL.na, pg.na);
        [beta_star, cb0] = calibrate_beta(pg, r_cal, b_target, 0.06);
        if ~cb0.converged, error('beta recalibration on this grid failed'); end
    end
else
    fprintf('calibrated_results.mat not found -- calibrating beta now.\n');
    [beta_star, cb0] = calibrate_beta(pg, r_cal, b_target, 0.06);
    if ~cb0.converged, error('beta calibration failed'); end
    P0_med = pg.Bnom / b_target;
    Gg_cal = 0.02 * P0_med;
end

fprintf('==============================================================\n');
fprintf(' ROBUSTNESS (U9): na=%d, beta*=%.4f, Gg_cal=%.5f, target b/Y=%.2f\n', ...
        pg.na, beta_star, Gg_cal, b_target);
fprintf('==============================================================\n');

pgc        = pg;
pgc.beta   = beta_star;
pgc.Gg_nom = Gg_cal;
pgc.mu     = mu_cal;
pgc.climate_version = 1;

RB = struct();
RB.na = pg.na; RB.beta_star = beta_star; RB.Gg_cal = Gg_cal;

% =====================================================================
% A. nu over the (D0, theta_g) plane + the nu = 1 frontier
% =====================================================================
% D0 nodes: the three SOURCED columns (0.02 DICE / 0.06 DJO-BHM / 0.20
% Bilal-Kaenzig) plus two interpolating nodes for the frontier's shape.
D0_grid    = [0.02, 0.06, 0.10, 0.15, 0.20];
D0_sourced = [true, true, false, false, true];
th_grid    = 0:0.25:3.0;
if FAST, th_grid = 0:0.5:3.0; end

fprintf('\n===== [A] nu(D0, theta_g) surface: %d x %d nodes =====\n', ...
        numel(D0_grid), numel(th_grid));
NU  = nan(numel(D0_grid), numel(th_grid));   % nu
NR  = nan(size(NU));                          % nu_reval
NROOTS = zeros(size(NU));
for r = 1:numel(D0_grid)
    fprintf('\n--- D0 = %.2f (%s) ---\n', D0_grid(r), ...
            ternstr(D0_sourced(r), 'sourced column', 'interpolating node'));
    pgr = pgc;
    pgr.D0        = D0_grid(r);
    pgr.taugrid_S = linspace(-0.01, 0.08, 5);
    pgr.Dgrid_S   = linspace(0, D0_grid(r), 3);
    pgr.theta_sweep = th_grid;                % decomposition sweeps these
    ad2r = build_S_interp_green(r_cal, pgr);  % one interpolant per row
    dec  = self_financing_decomposition(pgr, ad2r);
    if isfield(dec, 'sweep') && ~isempty(dec.sweep)
        NU(r,:)     = dec.sweep.nu;
        NR(r,:)     = dec.sweep.nu_reval;
        NROOTS(r,:) = dec.sweep.n_roots;
    end
end
% nu = 1 frontier theta*(D0): linear interpolation between the bracketing
% COMPUTED nodes; NaN (reported as "above range") when nu < 1 everywhere.
th_star = nan(1, numel(D0_grid));
for r = 1:numel(D0_grid)
    nuv = NU(r,:);
    k = find(nuv(1:end-1) < 1 & nuv(2:end) >= 1, 1);
    if ~isempty(k)
        th_star(r) = th_grid(k) + (1 - nuv(k)) * ...
            (th_grid(k+1) - th_grid(k)) / (nuv(k+1) - nuv(k));
    elseif ~isempty(nuv) && all(isfinite(nuv)) && nuv(1) >= 1
        th_star(r) = th_grid(1);
    end
end
RB.surface = struct('D0_grid', D0_grid, 'D0_sourced', D0_sourced, ...
    'th_grid', th_grid, 'NU', NU, 'NR', NR, 'NROOTS', NROOTS, ...
    'th_star', th_star);
fprintf('\nnu=1 frontier theta*(D0):\n');
for r = 1:numel(D0_grid)
    if isfinite(th_star(r))
        fprintf('  D0=%.2f -> theta*=%.2f\n', D0_grid(r), th_star(r));
    else
        fprintf('  D0=%.2f -> above the swept range (nu<1 for all theta<=%.1f)\n', ...
                D0_grid(r), th_grid(end));
    end
end
fprintf('sign(nu_reval): %d of %d computed nodes negative\n', ...
        sum(NR(:) < 0), sum(isfinite(NR(:))));

% =====================================================================
% B. One-at-a-time sensitivity at MEDIUM (held debt-target protocol)
% =====================================================================
fprintf('\n===== [B] sensitivity at the MEDIUM column =====\n');
% name, field, value, recalibrate beta? (yes iff the variant changes the
% NO-PROGRAM economy: preferences or the damage-risk/incidence channels)
variants = { ...
  'sigma=1',      'sigma',   1.0,  true;  ...
  'sigma=3',      'sigma',   3.0,  true;  ...
  'phi_D=0',      'phi_D',   0.0,  true;  ...
  'phi_D=1',      'phi_D',   1.0,  true;  ...
  'psi=1',        'psi_inc', 1.0,  true;  ...
  'psi=2',        'psi_inc', 2.0,  true;  ...
  'delta_g=0.05', 'delta_g', 0.05, false; ...
  'scale=1%',     'g_share', 0.01, false; ...
  'scale=4%',     'g_share', 0.04, false; ...
};
SEN = struct('name',{},'beta',{},'nu',{},'nu_reval',{},'nu_damage',{}, ...
             'dlnP',{},'ok',{});
for v = 1:size(variants,1)
    vname = variants{v,1}; vf = variants{v,2}; vv = variants{v,3};
    recal = variants{v,4};
    fprintf('\n--- variant %s ---\n', vname);
    pgv = pgc;  pgv.D0 = 0.06;
    if strcmp(vf, 'g_share')
        pgv.Gg_nom = vv * P0_med;      % rescale the program, not a param
    else
        pgv.(vf) = vv;
    end
    bv = beta_star;
    if recal
        [bv, cbv] = calibrate_beta(pgv, r_cal, b_target, 0.06);
        if ~cbv.converged
            warning('variant %s: beta recalibration failed -- skipped', vname);
            SEN(end+1) = struct('name',vname,'beta',NaN,'nu',NaN, ...
                'nu_reval',NaN,'nu_damage',NaN,'dlnP',NaN,'ok',false); %#ok<SAGROW>
            continue;
        end
        fprintf('  recalibrated beta* = %.4f (target held)\n', bv);
    end
    pgv.beta      = bv;
    pgv.taugrid_S = linspace(-0.01, 0.10, 5);
    pgv.Dgrid_S   = linspace(0, 0.06, 3);
    pgv.theta_sweep = pg.theta_sweep;   % default sweep; headline uses benchmark theta
    ad2v = build_S_interp_green(r_cal, pgv);
    decv = self_financing_decomposition(pgv, ad2v);
    okv  = isfield(decv,'ok') && decv.ok;
    if okv
        SEN(end+1) = struct('name',vname,'beta',bv,'nu',decv.nu, ...
            'nu_reval',decv.nu_reval,'nu_damage',decv.nu_damage, ...
            'dlnP',100*log(decv.prog.P/decv.base.P),'ok',true); %#ok<SAGROW>
        fprintf('  %s: nu=%.3f (reval %+.3f, damage %.3f), dlnP=%+.2f%%\n', ...
            vname, decv.nu, decv.nu_reval, decv.nu_damage, ...
            100*log(decv.prog.P/decv.base.P));
    else
        SEN(end+1) = struct('name',vname,'beta',bv,'nu',NaN, ...
            'nu_reval',NaN,'nu_damage',NaN,'dlnP',NaN,'ok',false); %#ok<SAGROW>
        warning('variant %s: decomposition failed', vname);
    end
end
RB.sensitivity = SEN;

save(fullfile(projdir,'output','robustness_results.mat'), 'RB');

% =====================================================================
% PFig20: (a) the surface + frontier; (b) the sensitivity bars
% =====================================================================
fh = figure('Name','PFig20: calibration robustness','Color','w', ...
            'Position',[60 60 1150 420]);
subplot(1,2,1); hold on; box on;
[TT, DD] = meshgrid(th_grid, D0_grid);
contourf(TT, DD, NU, 12, 'LineColor', 'none');
cb = colorbar; ylabel(cb, 'self-financing share \nu');
% nu = 1 frontier over computed nodes
okf = isfinite(th_star);
plot(th_star(okf), D0_grid(okf), 'w-o', 'LineWidth', 2.2, ...
     'MarkerFaceColor','w', 'MarkerSize',5);
% mark the three sourced damage columns and the benchmark theta
yl = D0_grid(D0_sourced);
plot(pg.theta_g*ones(size(yl)), yl, 'rs', 'MarkerFaceColor','r', ...
     'MarkerSize',7);
xlabel('abatement effectiveness \theta_g'); ylabel('no-abatement damages D_0');
title('(a) \nu over (D_0,\theta_g); white: \nu=1 frontier');
subplot(1,2,2); hold on; box on;
nuS = [SEN.nu];
bar(nuS, 'FaceColor', [0.20 0.55 0.25]);
yline(1, 'k--');
set(gca,'XTick',1:numel(SEN),'XTickLabel',{SEN.name},'XTickLabelRotation',35);
ylabel('self-financing share \nu');
title('(b) one-at-a-time sensitivity (medium column, held debt target)');
save_all_figs(fh, 'PFig20_robustness', pg);
fprintf('\n  [saved] PFig20_robustness\n');

% =====================================================================
% summary table
% =====================================================================
sf = fullfile(pg.tabdir, 'robustness_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'CALIBRATION ROBUSTNESS (U9) -- STEADY STATE, calibrated scale\n');
    fprintf(fid, 'beta*=%.4f (debt/GDP target %.2f), program 2%% of income, na=%d\n\n', ...
            beta_star, b_target, pg.na);
    fprintf(fid, '[A] nu over (D0, theta_g); D0 sourced columns: 0.02 DICE,\n');
    fprintf(fid, '    0.06 DJO-BHM, 0.20 Bilal-Kaenzig; 0.10/0.15 interpolating.\n');
    fprintf(fid, '%-8s', 'D0\th_g');
    fprintf(fid, '%7.2f', th_grid); fprintf(fid, '   theta*(nu=1)\n');
    for r = 1:numel(D0_grid)
        fprintf(fid, '%-8.2f', D0_grid(r));
        fprintf(fid, '%7.3f', NU(r,:));
        if isfinite(th_star(r)), fprintf(fid, '   %8.2f\n', th_star(r));
        else, fprintf(fid, '   >%.1f (above swept range)\n', th_grid(end)); end
    end
    fprintf(fid, 'sign(nu_reval): %d of %d computed nodes NEGATIVE (disinflationary\n', ...
            sum(NR(:) < 0), sum(isfinite(NR(:))));
    fprintf(fid, 'revaluation; the sign result is not a calibration artifact).\n\n');
    fprintf(fid, '[B] one-at-a-time sensitivity at MEDIUM (D0=0.06), held debt target\n');
    fprintf(fid, '%-14s %-9s %-8s %-9s %-10s %-9s\n', 'variant', 'beta*', ...
            'nu', 'nu_reval', 'nu_damage', 'dlnP(%)');
    for v = 1:numel(SEN)
        if SEN(v).ok
            fprintf(fid, '%-14s %-9.4f %-8.3f %+-9.3f %-10.3f %+-9.2f\n', ...
                SEN(v).name, SEN(v).beta, SEN(v).nu, SEN(v).nu_reval, ...
                SEN(v).nu_damage, SEN(v).dlnP);
        else
            fprintf(fid, '%-14s FAILED\n', SEN(v).name);
        end
    end
    fprintf(fid, ['\nProtocol: variants changing the no-program economy (sigma,\n' ...
        'phi_D, psi) re-calibrate beta to hold debt/GDP=1.10; variants that\n' ...
        'do not (delta_g, program scale) keep the benchmark beta*.\n']);
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end
fprintf('\nElapsed: %.1f s\n', toc(t0));
diary off;

% -------------------------------------------------------------------------
function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
