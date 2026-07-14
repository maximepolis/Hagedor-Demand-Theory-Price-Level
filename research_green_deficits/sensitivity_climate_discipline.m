% SENSITIVITY_CLIMATE_DISCIPLINE  Referee M7: the abatement block
% (theta_g, delta_g) is the least externally disciplined part of the
% calibration, and delta_g in particular enters the dividend only through the
% ratio theta_g/delta_g (Kg = q_g*g/delta_g, D = D0*exp(-theta_g*Kg)). This
% driver maps how the RESOURCE benefit-cost ratio (nu_damage) and the total
% self-financing share (nu) move across a (theta_g, delta_g) grid, and reports
% the theta_g threshold at which nu_damage crosses one -- the "what must you
% believe" frontier -- as a function of delta_g. It makes the delta_g
% dependence explicit rather than buried in a single benchmark number.
%
% USAGE   >> sensitivity_climate_discipline
%         >> FAST = true; sensitivity_climate_discipline
%
% OUTPUT  output/climate_discipline_results.mat,
%         output/tables/climate_discipline.txt, PFig_climate_discipline.*
%
% STATUS: sensitivity driver; pure re-use of self_financing_decomposition.

clearvars -except FAST NA; close all; clc;
rng(20260714, 'twister'); t0 = tic;

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
    pg.na = pg.fast.na; pg.nP_scan = pg.fast.nP_scan;
end
if pg.na ~= numel(pg.aGrid)
    u = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
end
if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'climate_discipline_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' CLIMATE-DISCIPLINE SENSITIVITY (M7): nu over (theta_g, delta_g)\n');
fprintf('==============================================================\n');

% reuse the calibrated medium column
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), pg.beta = L.RCAL.beta_star; end
    if isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal'),   Gg_cal = L.RCAL.Gg_cal;    end
end
if ~exist('Gg_cal','var'), Gg_cal = 0.02 * (pg.Bnom / 1.10); end

r_cal = (1 + pg.i_ss)/(1 + pg.mu) - 1;
D0med = 0.06;

pgc = pg;
pgc.climate_version = 1;
pgc.D0     = D0med;
pgc.Gg_nom = Gg_cal;
pgc.taugrid_S = linspace(-0.02, 0.10, 6);
pgc.Dgrid_S   = linspace(0, D0med, 3);

% ONE interpolant serves the whole grid (it spans the (tau,D) plane at r_cal)
ad2 = build_S_interp_green(r_cal, pgc);

theta_grid = linspace(0.5, 3.0, 11);          % abatement effectiveness
delta_grid = [0.05, 0.075, 0.10, 0.15];       % green-capital depreciation

NU  = nan(numel(delta_grid), numel(theta_grid));
NUD = nan(numel(delta_grid), numel(theta_grid));   % nu_damage = BCR
for i = 1:numel(delta_grid)
    pgi = pgc; pgi.delta_g = delta_grid(i);
    for j = 1:numel(theta_grid)
        pgij = pgi; pgij.theta_g = theta_grid(j);
        dec = self_financing_decomposition(pgij, ad2);
        if dec.ok
            NU(i,j)  = dec.nu;
            NUD(i,j) = dec.nu_damage;
        end
    end
    fprintf('  delta_g=%.3f done (nu_dam at theta=%.1f is %.2f .. at theta=%.1f is %.2f)\n', ...
        delta_grid(i), theta_grid(1), NUD(i,1), theta_grid(end), NUD(i,end));
end

% threshold theta_g where BCR (nu_damage) crosses 1, per delta_g
th_bcr1 = nan(1, numel(delta_grid));
for i = 1:numel(delta_grid)
    v = NUD(i,:);
    k = find(v(1:end-1) < 1 & v(2:end) >= 1, 1, 'first');
    if ~isempty(k)
        th_bcr1(i) = interp1(v(k:k+1), theta_grid(k:k+1), 1);
    end
end

save(fullfile(projdir,'output','climate_discipline_results.mat'), ...
     'theta_grid','delta_grid','NU','NUD','th_bcr1','Gg_cal','r_cal','D0med');

% ----- table -----
sf = fullfile(pg.tabdir, 'climate_discipline.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'CLIMATE-DISCIPLINE SENSITIVITY (M7).  D0=%.2f, Gg=%.5f, na=%d\n', ...
            D0med, Gg_cal, pg.na);
    fprintf(fid, 'Kg = g/delta_g;  D = D0*exp(-theta_g*Kg).  nu_damage is the BCR.\n\n');
    fprintf(fid, 'RESOURCE BCR (nu_damage) over (delta_g rows, theta_g cols):\n');
    fprintf(fid, '  delta_g \\ theta_g');
    fprintf(fid, ' %5.2f', theta_grid); fprintf(fid, '\n');
    for i = 1:numel(delta_grid)
        fprintf(fid, '  %7.3f        ', delta_grid(i));
        fprintf(fid, ' %5.2f', NUD(i,:)); fprintf(fid, '\n');
    end
    fprintf(fid, '\nTHETA_G THRESHOLD where BCR crosses 1 (aggregate resources rise):\n');
    for i = 1:numel(delta_grid)
        if isfinite(th_bcr1(i))
            fprintf(fid, '  delta_g=%.3f:  theta_g* = %.2f\n', delta_grid(i), th_bcr1(i));
        else
            fprintf(fid, '  delta_g=%.3f:  BCR<1 on the whole theta grid\n', delta_grid(i));
        end
    end
    fprintf(fid, ['\nReading: the BCR depends on abatement only through theta_g/delta_g,\n' ...
        'so a faster-depreciating green stock (higher delta_g) needs a\n' ...
        'proportionally larger theta_g to clear one. The benchmark delta_g=0.10\n' ...
        'is the conservative middle of the reported range.\n']);
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ----- figure -----
fh = figure('Name','PFig: climate discipline (M7)','Color','w', ...
            'Position',[70 70 980 420]);
subplot(1,2,1); hold on; box on;
shades = [0.20 0.40 0.70; 0.45 0.70 0.45; 0.85 0.55 0.20; 0.75 0.30 0.30];
for i = 1:numel(delta_grid)
    plot(theta_grid, NUD(i,:), 'o-', 'Color', shades(min(i,4),:), ...
        'LineWidth',1.3, 'MarkerFaceColor', shades(min(i,4),:));
end
yline(1, 'k--', 'LineWidth',1.2, 'HandleVisibility','off');
xlabel('abatement effectiveness \theta_g'); ylabel('resource BCR (\nu_{dam})');
legend(arrayfun(@(d) sprintf('\\delta_g=%.3f',d), delta_grid, ...
       'UniformOutput',false), 'Location','northwest');
title('(a) BCR vs \theta_g, by \delta_g');
subplot(1,2,2); hold on; box on;
plot(delta_grid, th_bcr1, 'ks-', 'LineWidth',1.4, 'MarkerFaceColor','k');
xlabel('green depreciation \delta_g'); ylabel('\theta_g threshold (BCR=1)');
title('(b) break-even \theta_g rises with \delta_g');
save_all_figs(fh, 'PFig_climate_discipline', pg);
fprintf('  [saved] PFig_climate_discipline\n');

fprintf('\nElapsed: %.1f s\n', toc(t0));
diary off;
