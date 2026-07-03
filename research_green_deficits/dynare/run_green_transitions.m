% RUN_GREEN_TRANSITIONS  U6 driver: runs green_rank_nk.mod under the FOUR
% monetary regimes required by the research-program specification, collects
% the perfect-foresight transition paths, and produces the regime-comparison
% figure PFig13 plus a summary table.
%
%   PEG          near-frozen nominal rate       (RHOI=0.999, PHIPI=0)
%   TAYLOR       standard inertial Taylor rule  (RHOI=0.8,   PHIPI=1.5)
%   AGGRESSIVE   strict inflation targeting     (RHOI=0.0,   PHIPI=3.0)
%   GREENACCOM   Taylor + temporary green accommodation tied to the
%                green-capital gap              (PSIG=0.5)
%
% REQUIREMENTS: Dynare (5.x/6.x) on the MATLAB path; run from this folder.
% HONEST SCOPE: these are RANK/NK transition DIAGNOSTICS -- they carry the
% real/nominal transition shapes, not the paper's DTPL price-level mechanism
% (see dynare/README.md and appendix/HANK_TRANSITION_PLAN.md).
%
% USAGE:  >> cd research_green_deficits/dynare
%         >> run_green_transitions
%
% OUTPUT: PFig13_rank_transitions.{fig,png,pdf} in ../output/figures,
%         dynare_transitions.mat, ../output/tables/transitions_summary.txt.

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
    error(['Dynare not found on the MATLAB path. Install Dynare and ' ...
           'addpath <dynare>/matlab, then rerun.']);
end

regimes = struct( ...
    'name',  {'PEG', 'TAYLOR', 'AGGRESSIVE', 'GREENACCOM'}, ...
    'defs',  {'-DRHOI=0.999 -DPHIPI=0.0 -DPSIG=0.0', ...
              '-DRHOI=0.8   -DPHIPI=1.5 -DPSIG=0.0', ...
              '-DRHOI=0.0   -DPHIPI=3.0 -DPSIG=0.0', ...
              '-DRHOI=0.8   -DPHIPI=1.5 -DPSIG=0.5'});

vars_keep = {'y','ppi','b','kg','d','tau','c','i'};
RES = struct();
ok  = false(1, numel(regimes));

for rgm = 1:numel(regimes)
    fprintf('\n===== regime %s =====\n', regimes(rgm).name);
    try
        eval(sprintf('dynare green_rank_nk %s noclearall nolog', regimes(rgm).defs));
        % collect paths by variable name (rows of oo_.endo_simul follow M_.endo_names)
        sim = oo_.endo_simul;                                     %#ok<NODEF>
        paths = struct();
        for v = 1:numel(vars_keep)
            idx = find(strcmp(cellstr(M_.endo_names), vars_keep{v}), 1); %#ok<NODEF>
            if ~isempty(idx), paths.(vars_keep{v}) = sim(idx, :); end
        end
        RES.(regimes(rgm).name) = paths;
        ok(rgm) = true;
        fprintf('  [%s solved: %d periods]\n', regimes(rgm).name, size(sim,2));
    catch ME
        warning('run_green_transitions:fail', ...
            'Regime %s failed: %s (Dynare version differences are the usual cause).', ...
            regimes(rgm).name, ME.message);
    end
end

if ~any(ok)
    error('No regime solved; inspect the Dynare error messages above.');
end

% ---- PFig13: regime comparison ----
cols = [0.10 0.30 0.75; 0.85 0.20 0.15; 0.85 0.55 0.10; 0.20 0.55 0.25];
panels = {'y','output'; 'ppi','inflation (net, qtr)'; 'b','real debt'; ...
          'kg','green capital'; 'd','damages'; 'tau','taxes'};
fh = figure('Name','PFig13: RANK transition diagnostics','Color','w', ...
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
    xlabel('quarters'); title(panels{pp,2});
    if pp == 1, legend(names_ok, 'Location','best'); end
end
save_all_figs(fh, 'PFig13_rank_transitions', pg);
fprintf('\n  [saved] PFig13_rank_transitions\n');

save(fullfile(projdir, 'output', 'dynare_transitions.mat'), 'RES', 'regimes', 'ok');

sf = fullfile(pg.tabdir, 'transitions_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U6 RANK/NK TRANSITIONS (perfect foresight, permanent program)\n');
    fprintf(fid, 'HONEST SCOPE: RANK diagnostics, not the DTPL price-level mechanism.\n');
    for rgm = 1:numel(regimes)
        if ~ok(rgm), fprintf(fid, '%-11s FAILED\n', regimes(rgm).name); continue; end
        s = RES.(regimes(rgm).name);
        fprintf(fid, ['%-11s pi impact %+.4f, pi peak %+.4f, debt peak %.3f, ' ...
            'kg(40q) %.3f, d(40q) %.4f\n'], regimes(rgm).name, ...
            s.ppi(2), max(s.ppi), max(s.b), s.kg(min(41,end)), s.d(min(41,end)));
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end
fprintf('Elapsed: %.1f s\n', toc(t0));
