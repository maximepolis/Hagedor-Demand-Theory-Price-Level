% RUN_GREEN_HANK  U7 (tier 1) driver: runs green_hank.mod -- the native
% Dynare heterogeneity-framework HANK with the climate block -- under FOUR
% monetary regimes, collects the linearized sequence-space IRFs to the
% quasi-permanent deficit-financed green-investment shock, and produces the
% regime-comparison figure PFig14 plus a summary table.
%
%   WEAK         PHIPI=1.1              (weakly active rule)
%   TAYLOR       PHIPI=1.5              (default)
%   AGGRESSIVE   PHIPI=3.0
%   GREENACCOM   PHIPI=1.5, PSIG=0.03   (temporary accommodation tied to
%                the program flow, fading as it does)
%
% REQUIREMENTS: a Dynare version with the heterogeneity framework
% (heterogeneity_dimension / heterogeneity_solve) -- the version that ran
% heterogeneity/hank_one_asset_steady_state.mod successfully.
%
% HONEST SCOPE: LINEARIZED IRFs around the initial steady state. The
% nominal-rate + ex-post-Fisher block means surprise inflation revalues
% household asset positions (the paper's redistribution channel,
% linearized), but this is NOT the nonlinear DTPL price-level transition
% (appendix/HANK_TRANSITION_PLAN.md, tier 2, NOT YET IMPLEMENTED).
%
% USAGE:  >> cd research_green_deficits/dynare
%         >> run_green_hank
%
% OUTPUT: PFig14_hank_green_irfs.{fig,png,pdf} in ../output/figures,
%         hank_green_irfs.mat, ../output/tables/hank_irfs_summary.txt.

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
    error(['Dynare not found on the MATLAB path. Install the Dynare ' ...
           'version with the heterogeneity framework and addpath ' ...
           '<dynare>/matlab, then rerun.']);
end

regimes = struct( ...
    'name',  {'WEAK', 'TAYLOR', 'AGGRESSIVE', 'GREENACCOM'}, ...
    'defs',  {'-DPHIPI=1.1 -DPSIG=0.0', ...
              '-DPHIPI=1.5 -DPSIG=0.0', ...
              '-DPHIPI=3.0 -DPSIG=0.0', ...
              '-DPHIPI=1.5 -DPSIG=0.03'});

vars_keep = {'Y','pi','i','r','b','tau','gg','kg','d'};
RES = struct();
ok  = false(1, numel(regimes));

for rgm = 1:numel(regimes)
    fprintf('\n===== HANK regime %s =====\n', regimes(rgm).name);
    try
        % per-regime copies: avoids stale preprocessor artifacts when one
        % .mod is re-run with different -D defines (see run_green_transitions)
        nm = sprintf('grnhk_%s', lower(regimes(rgm).name));
        copyfile('green_hank.mod', [nm '.mod']);
        if exist(['+' nm], 'dir'), rmdir(['+' nm], 's'); end
        if exist(nm, 'dir'), rmdir(nm, 's'); end
        eval(sprintf('dynare %s %s noclearall nolog', nm, regimes(rgm).defs));

        % ---- collect IRFs defensively: the heterogeneity framework is new
        % and the output location may differ across Dynare builds ----
        irfs = [];
        if exist('oo_', 'var') && isfield(oo_, 'irfs') && ~isempty(fieldnames(oo_.irfs))
            irfs = oo_.irfs;                       %#ok<NODEF>
        elseif exist('oo_', 'var') && isfield(oo_, 'heterogeneity') ...
                && isfield(oo_.heterogeneity, 'irfs')
            irfs = oo_.heterogeneity.irfs;
        end
        if isempty(irfs)
            warning('run_green_hank:noirfs', ...
                ['Regime %s: solved, but no IRFs found in oo_.irfs or ' ...
                 'oo_.heterogeneity.irfs. Inspect oo_ interactively ' ...
                 '(fieldnames(oo_)) and report the structure.'], ...
                regimes(rgm).name);
            continue;
        end
        paths = struct();
        fn = fieldnames(irfs);
        for v = 1:numel(vars_keep)
            % standard Dynare IRF naming: <var>_<shock>
            hit = find(strcmpi(fn, [vars_keep{v} '_e_g']), 1);
            if isempty(hit)      % fallback: any field starting with var name
                hit = find(strncmpi(fn, [vars_keep{v} '_'], numel(vars_keep{v})+1), 1);
            end
            if ~isempty(hit), paths.(vars_keep{v}) = irfs.(fn{hit})(:).'; end
        end
        if ~isfield(paths, 'Y')
            warning('run_green_hank:names', ...
                'Regime %s: IRF fields found but none match expected names: %s', ...
                regimes(rgm).name, strjoin(fn, ', '));
            continue;
        end
        RES.(regimes(rgm).name) = paths;
        ok(rgm) = true;
        fprintf('  [%s solved: IRF horizon %d]\n', regimes(rgm).name, numel(paths.Y));
    catch ME
        warning('run_green_hank:fail', 'Regime %s failed: %s', ...
            regimes(rgm).name, ME.message);
    end
end

if ~any(ok)
    error('No HANK regime solved; inspect the Dynare messages above.');
end

% ---- PFig14: regime comparison (IRFs, deviations from steady state) ----
cols = [0.10 0.30 0.75; 0.85 0.20 0.15; 0.85 0.55 0.10; 0.20 0.55 0.25];
panels = {'Y','output'; 'pi','inflation (net, qtr)'; 'b','real debt'; ...
          'kg','green capital'; 'd','damages'; 'r','ex-post real return'};
fh = figure('Name','PFig14: HANK green-program IRFs','Color','w', ...
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
save_all_figs(fh, 'PFig14_hank_green_irfs', pg);
fprintf('\n  [saved] PFig14_hank_green_irfs\n');

save(fullfile(projdir, 'output', 'hank_green_irfs.mat'), 'RES', 'regimes', 'ok');

sf = fullfile(pg.tabdir, 'hank_irfs_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER-1: HANK IRFs to a quasi-permanent green-investment shock\n');
    fprintf(fid, '(native Dynare heterogeneity framework; LINEARIZED sequence-space\n');
    fprintf(fid, 'solution; NOT the nonlinear DTPL price-level transition)\n\n');
    for rgm = 1:numel(regimes)
        if ~ok(rgm), fprintf(fid, '%-11s FAILED\n', regimes(rgm).name); continue; end
        s = RES.(regimes(rgm).name);
        fprintf(fid, ['%-11s pi impact %+.5f (annualized %+.2f%%), ' ...
            'Y impact %+.5f, debt(40q) %+.4f, kg(40q) %+.4f, d(40q) %+.6f\n'], ...
            regimes(rgm).name, s.pi(1), 400*s.pi(1), s.Y(1), ...
            s.b(min(40,end)), s.kg(min(40,end)), s.d(min(40,end)));
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end
fprintf('Elapsed: %.1f s\n', toc(t0));
