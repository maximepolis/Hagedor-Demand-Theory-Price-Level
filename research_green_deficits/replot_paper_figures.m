% REPLOT_PAPER_FIGURES  Re-export paper figures from SAVED results -- no
% model solves. Use after a change to the figure styling (src/style_figure,
% src/finish_panel_legend) to refresh:
%
%   PFig1-PFig4   from output/project_results.mat    (plot_green_figures)
%   PFig18        from output/transition_results.mat (plot_transition_fig)
%
% The Dynare figures (PFig13/PFig14/PFig17) are refreshed by re-running
% run_green_transitions / run_green_hank / run_green_hank2, which restore
% solved regimes from their checkpoints and only re-plot; the remaining
% main_project_* drivers are fast enough to re-run outright.
%
% USAGE:  >> cd research_green_deficits; replot_paper_figures

clear; clc;
projdir = fileparts(mfilename('fullpath'));
rootdir = fileparts(projdir);
addpath(fullfile(rootdir, 'src'));
addpath(fullfile(projdir, 'src_project'));

% ---- PFig1-4: benchmark/sunspot/optimal-mu figures ----
f = fullfile(projdir, 'output', 'project_results.mat');
if exist(f, 'file') == 2
    L = load(f, 'RESP', 'pg');
    L.pg.figdir = fullfile(projdir, 'output', 'figures');  % repo may have moved
    fprintf('[replot] PFig1-PFig4 from project_results.mat ...\n');
    plot_green_figures(L.RESP, L.pg);
else
    fprintf(['[replot] %s not found -- run main_project_run_all first ' ...
             '(FAST = true for a quick pass)\n'], f);
end

% ---- PFig18: nonlinear price-level transition ----
f = fullfile(projdir, 'output', 'transition_results.mat');
if exist(f, 'file') == 2
    L = load(f);
    pgf = struct('figdir', fullfile(projdir, 'output', 'figures'));
    TRr = []; if isfield(L, 'TRr'), TRr = L.TRr; end
    fprintf('[replot] PFig18 from transition_results.mat ...\n');
    plot_transition_fig(L.TRn, L.TRi, L.pgc, pgf, TRr);
else
    fprintf('[replot] %s not found -- run main_project_transition first\n', f);
end

fprintf('[replot] done.\n');
