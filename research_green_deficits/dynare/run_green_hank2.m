% RUN_GREEN_HANK2  U7 tier-1b driver: the TWO-ASSET green HANK
% (green_hank2.mod -- liquid nominal bonds vs illiquid equity/capital,
% sticky wages + prices, convex portfolio-adjustment costs, endogenous
% government debt, climate block) under FOUR regimes, collecting the
% linearized sequence-space IRFs to the quasi-permanent green-investment
% shock. Produces PFig17 plus summary and validation tables.
%
%   WEAK        PHIPI=1.1
%   TAYLOR      PHIPI=1.5 (default)               PHIB=0.10 (deficit)
%   GREENACCOM  PHIPI=1.5, PSIG=0.03
%   TAYLORBAL   PHIPI=1.5, PHIB=0.75              (balanced comparator)
%
% WHY THIS TIER: the liquid-bond market is now separate from total wealth,
% so the program's effect on the demand for and supply of LIQUID NOMINAL
% SAFE ASSETS -- the paper's B/P margin -- is a directly plotted object
% (bg, rb), and MPC heterogeneity is realistic (wealthy hand-to-mouth).
%
% REQUIREMENTS: the Dynare heterogeneity build that ran
% heterogeneity/hank_two_assets_steady_state.mod. EXPECT SLOWER SOLVES
% than the one-asset tier (3 calibrated parameters, 3D household state).
%
% HONEST SCOPE: LINEARIZED IRFs; NOT the nonlinear DTPL transition.
% Grids follow the verified example (ne=3, nb=10, na=20): coarse,
% magnitudes indicative.
%
% USAGE:  >> cd research_green_deficits/dynare
%         >> run_green_hank2
%
% OUTPUT: PFig17_hank2_green_irfs.{fig,png,pdf}, hank2_green_irfs.mat,
%         ../output/tables/hank2_irfs_summary.txt,
%         ../output/tables/hank2_validation.txt.

clear; close all;
t0 = tic;

dyndir = fileparts(mfilename('fullpath'));
if isempty(dyndir), dyndir = pwd; end
cd(dyndir);
projdir = fileparts(dyndir);
addpath(genpath(fullfile(fileparts(projdir), 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));
pg = setup_params_green();          % for figdir/tabdir only

if exist('dynare', 'file') ~= 2
    error('Dynare not found on the MATLAB path.');
end

regimes = struct( ...
    'name',  {'WEAK', 'TAYLOR', 'GREENACCOM', 'TAYLORBAL'}, ...
    'defs',  {'-DPHIPI=1.1', ...
              '-DPHIPI=1.5', ...
              '-DPHIPI=1.5 -DPSIG=0.03', ...
              '-DPHIPI=1.5 -DPHIB=0.75'});

vars_keep = {'Y','pi','i','r','rb','ra','bg','tax','gg','kg','d','p','K','I','w','N'};
RES = struct();
CAL = struct();
ok  = false(1, numel(regimes));

for rgm = 1:numel(regimes)
    fprintf('\n===== HANK2 regime %s =====\n', regimes(rgm).name);
    try
        nm = sprintf('grn2_%s', lower(regimes(rgm).name));
        copyfile('green_hank2.mod', [nm '.mod']);
        if exist(['+' nm], 'dir'), rmdir(['+' nm], 's'); end
        if exist(nm, 'dir'), rmdir(nm, 's'); end
        eval(sprintf('dynare %s %s noclearall nolog', nm, regimes(rgm).defs));

        irfs = [];
        if exist('oo_', 'var') && isfield(oo_, 'irfs') && ~isempty(fieldnames(oo_.irfs))
            irfs = oo_.irfs;                       %#ok<NODEF>
        elseif exist('oo_', 'var') && isfield(oo_, 'heterogeneity') ...
                && isfield(oo_.heterogeneity, 'irfs')
            irfs = oo_.heterogeneity.irfs;
        end
        if isempty(irfs)
            warning('run_green_hank2:noirfs', ...
                'Regime %s: solved but no IRFs found; inspect fieldnames(oo_).', ...
                regimes(rgm).name);
            continue;
        end
        paths = struct();
        fn = fieldnames(irfs);
        for v = 1:numel(vars_keep)
            hit = find(strcmpi(fn, [vars_keep{v} '_e_g']), 1);
            if isempty(hit)
                hit = find(strncmpi(fn, [vars_keep{v} '_'], numel(vars_keep{v})+1), 1);
            end
            if ~isempty(hit), paths.(vars_keep{v}) = irfs.(fn{hit})(:).'; end
        end
        if ~isfield(paths, 'Y')
            warning('run_green_hank2:names', ...
                'Regime %s: IRF fields do not match expected names: %s', ...
                regimes(rgm).name, strjoin(fn, ', '));
            continue;
        end
        RES.(regimes(rgm).name) = paths;
        ok(rgm) = true;
        if exist('M_', 'var')
            pn = cellstr(M_.param_names);
            CAL.(regimes(rgm).name) = struct( ...
                'beta_ss', M_.params(strcmp(pn,'beta_ss')), ...
                'vphi',    M_.params(strcmp(pn,'vphi')), ...
                'chi1',    M_.params(strcmp(pn,'chi1')));
        end
        fprintf('  [%s solved: IRF horizon %d]\n', regimes(rgm).name, numel(paths.Y));
    catch ME
        warning('run_green_hank2:fail', 'Regime %s failed: %s', ...
            regimes(rgm).name, ME.message);
    end
end

if ~any(ok)
    error('No HANK2 regime solved; inspect the Dynare messages above.');
end

% ---- PFig17 ----
cols = [0.10 0.30 0.75; 0.85 0.20 0.15; 0.20 0.55 0.25; 0.45 0.45 0.45];
panels = {'Y','output'; 'pi','inflation (net, qtr)'; 'bg','government debt'; ...
          'rb','liquid (bond) return'; 'kg','green capital'; 'p','equity price'};
fh = figure('Name','PFig17: two-asset HANK green-program IRFs','Color','w', ...
            'Position',[60 60 1100 640]);
Tshow = 120;
names_ok = {regimes(ok).name};
for pp = 1:size(panels,1)
    subplot(2,3,pp); hold on; box on;
    for rgm = 1:numel(regimes)
        if ~ok(rgm), continue; end
        s = RES.(regimes(rgm).name);
        if isfield(s, panels{pp,1})
            v = s.(panels{pp,1});
            plot(0:min(Tshow,numel(v))-1, v(1:min(Tshow,numel(v))), ...
                 'LineWidth', 1.8, 'Color', cols(rgm,:));
        end
    end
    yline(0, ':', 'Color', [0.4 0.4 0.4]);
    xlabel('quarters'); title(panels{pp,2});
    if pp == 1, legend(names_ok, 'Location','best'); end
end
save_all_figs(fh, 'PFig17_hank2_green_irfs', pg);
fprintf('\n  [saved] PFig17_hank2_green_irfs\n');

save(fullfile(projdir, 'output', 'hank2_green_irfs.mat'), 'RES', 'regimes', 'ok');

% ---- summary ----
sf = fullfile(pg.tabdir, 'hank2_irfs_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER-1b: TWO-ASSET HANK IRFs to a quasi-permanent green shock\n');
    fprintf(fid, '(liquid bonds vs illiquid equity; LINEARIZED; NOT the DTPL transition)\n\n');
    for rgm = 1:numel(regimes)
        if ~ok(rgm), fprintf(fid, '%-11s FAILED\n', regimes(rgm).name); continue; end
        s = RES.(regimes(rgm).name);
        fprintf(fid, ['%-11s pi impact %+.5f (ann %+.2f%%), Y impact %+.5f, ' ...
            'rb impact %+.5f, bg(40q) %+.4f, kg(40q) %+.4f, d(40q) %+.6f, p impact %+.4f\n'], ...
            regimes(rgm).name, s.pi(1), 400*s.pi(1), s.Y(1), s.rb(1), ...
            s.bg(min(40,end)), s.kg(min(40,end)), s.d(min(40,end)), s.p(1));
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ---- validation ----
vf = fullfile(pg.tabdir, 'hank2_validation.txt');
fid = fopen(vf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER-1b TWO-ASSET HANK VALIDATION\n');
    fprintf(fid, 'Scope: TIER-1 LINEARIZED HANK IRF (two-asset; sequence-space; horizon 300).\n');
    fprintf(fid, 'Liquid nominal bonds vs illiquid equity with convex adjustment costs;\n');
    fprintf(fid, 'endogenous government debt (liquid supply = lamB*bg); Fisher equation\n');
    fprintf(fid, 'present. NOT nonlinear DTPL price-level determination.\n');
    fprintf(fid, 'Grids: ne=3 (rho_e=0.966, sig_e=0.92, example calibration), nb=10, na=20\n');
    fprintf(fid, '-- COARSE; magnitudes indicative. Steady-state residuals: Dynare log.\n\n');
    fprintf(fid, '%-11s %-8s %-8s %-10s %-9s %-9s %-11s %-11s %-11s\n', ...
        'regime', 'solved', 'horizon', 'beta_ss*', 'vphi*', 'chi1*', ...
        'pi impact', 'Y impact', 'bg(40q)');
    for rgm = 1:numel(regimes)
        if ~ok(rgm), fprintf(fid, '%-11s %-8s\n', regimes(rgm).name, 'NO'); continue; end
        s = RES.(regimes(rgm).name);
        cb = struct('beta_ss',NaN,'vphi',NaN,'chi1',NaN);
        if isfield(CAL, regimes(rgm).name), cb = CAL.(regimes(rgm).name); end
        fprintf(fid, '%-11s %-8s %-8d %-10.6f %-9.4f %-9.4f %+-11.5f %+-11.5f %+-11.5f\n', ...
            regimes(rgm).name, 'yes', numel(s.Y), cb.beta_ss, cb.vphi, cb.chi1, ...
            s.pi(1), s.Y(1), s.bg(min(40,end)));
    end
    fprintf(fid, '\nIRFs: one-std e_g shock (0.01 ~ 1%% of output), rho_g=0.995.\n');
    fclose(fid);
    fprintf('  [saved] %s\n', vf);
end
fprintf('Elapsed: %.1f s\n', toc(t0));
