% WELFARE_INCIDENCE_DECILES  Decile-resolution welfare incidence of the green
% program, for (a) the three calibrated damage columns under lump-sum finance
% and (b) the four financing regimes at the medium column.
%
% WHY. The paper's incidence tables cut at quintiles plus top-10%/bottom-50%.
% At that resolution the bottom quintile mixes households at the borrowing
% limit with buffer-stock savers, and the top quintile mixes the merely
% comfortable with the bondholders who receive most of the revaluation. This
% driver re-cuts the same CE object at deciles plus top-5%/top-1%, splitting
% borrowing-limit mass points fractionally so every decile holds exactly 10%
% of baseline mass (see welfare_by_decile), and reports each tail group's
% model wealth share next to its CE gain so the one-asset model's thin top
% tail is visible rather than hidden.
%
% READS   output/calibrated_results.mat   (main_project_calibrated)
%         output/regimes_results.mat      (main_project_regimes; optional)
% WRITES  output/welfare_deciles_results.mat
%         output/tables/welfare_deciles.txt
%         export_paper_numbers picks up the \WDec* macros.
%
% USAGE   >> cd research_green_deficits; welfare_incidence_deciles

clearvars -except FORCE_RERUN; close all; t0 = tic;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
addpath(genpath(fullfile(fileparts(projdir), 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

calf = fullfile(projdir, 'output', 'calibrated_results.mat');
assert(exist(calf, 'file') == 2, ...
    'welfare_incidence_deciles: run main_project_calibrated first.');
L = load(calf, 'RCAL', 'pgc');
RCAL = L.RCAL; pgc = L.pgc;
r_cal = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;

WD = struct();
WD.r_cal = r_cal;

% ---- (a) calibrated damage columns, lump-sum finance ----
fprintf('=== Decile incidence: calibrated columns (lump-sum) ===\n');
ncol = numel(RCAL.cols);
WD.cols = cell(1, ncol);
for c = 1:ncol
    if isempty(RCAL.dec{c}) || ~RCAL.dec{c}.ok
        fprintf('  column %s skipped (no equilibrium pair).\n', RCAL.cols(c).name);
        continue;
    end
    pgcc = pgc;
    pgcc.climate_version = 1;
    pgcc.D0 = RCAL.cols(c).D0;
    wd = welfare_by_decile(r_cal, RCAL.dec{c}.base, RCAL.dec{c}.prog, pgcc);
    wd.name = RCAL.cols(c).name;
    WD.cols{c} = wd;
    if wd.ok, fprintf('  %-22s %s\n', wd.name, wd.msg); end
end

% ---- (b) financing regimes at the medium column (optional) ----
regf = fullfile(projdir, 'output', 'regimes_results.mat');
WD.regimes = {};
if exist(regf, 'file') == 2
    fprintf('=== Decile incidence: financing regimes (medium column) ===\n');
    R = load(regf, 'RREG', 'eq0', 'pgc');
    r_reg = (1 + R.pgc.i_ss)/(1 + R.pgc.mu) - 1;
    for k = 1:numel(R.RREG)
        eqk = struct('tau', R.RREG(k).tau_ls, 'D', R.RREG(k).D, ...
                     'vartheta', R.RREG(k).vartheta);
        wd = welfare_by_decile(r_reg, R.eq0, eqk, R.pgc);
        wd.name = R.RREG(k).name;
        WD.regimes{k} = wd;
        if wd.ok, fprintf('  %-22s %s\n', wd.name, wd.msg); end
    end
else
    fprintf('regimes_results.mat not found -- regime panel skipped (run main_project_regimes).\n');
end

% ---- outputs ----
save(fullfile(projdir, 'output', 'welfare_deciles_results.mat'), 'WD');
tabdir = fullfile(projdir, 'output', 'tables');
if ~isfolder(tabdir), mkdir(tabdir); end
fid = fopen(fullfile(tabdir, 'welfare_deciles.txt'), 'w');
fprintf(fid, 'WELFARE INCIDENCE AT DECILE RESOLUTION\n');
fprintf(fid, ['CE gain lambda by baseline wealth decile (%%), fractional ' ...
              'mass-point splitting;\nwealth shares in parentheses. ' ...
              'r_cal = %.4f.\n\n'], r_cal);
writeblock = @(fid, wd) fprintf(fid, ...
    ['%-22s  D1..D10: %s\n%-22s  top5 %+7.2f (share %.2f)   ' ...
     'top1 %+7.2f (share %.2f)   agg %+7.2f   constrained %.1f%%\n'], ...
    wd.name, mat2str(round(100*wd.lambda_dec, 2)), '', ...
    100*wd.lambda_top5, wd.wshare_top5, 100*wd.lambda_top1, ...
    wd.wshare_top1, 100*wd.lambda_agg, 100*wd.mass_constrained);
fprintf(fid, '--- Calibrated columns, lump-sum finance ---\n');
for c = 1:numel(WD.cols)
    if ~isempty(WD.cols{c}) && WD.cols{c}.ok, writeblock(fid, WD.cols{c}); end
end
if ~isempty(WD.regimes)
    fprintf(fid, '\n--- Financing regimes, medium column ---\n');
    for k = 1:numel(WD.regimes)
        if ~isempty(WD.regimes{k}) && WD.regimes{k}.ok, writeblock(fid, WD.regimes{k}); end
    end
end
fclose(fid);
fprintf('Wrote output/tables/welfare_deciles.txt. Elapsed %.1f s\n', toc(t0));
