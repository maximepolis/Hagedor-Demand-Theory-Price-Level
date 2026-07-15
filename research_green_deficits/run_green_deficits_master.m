% RUN_GREEN_DEFICITS_MASTER  One-command reproduction of the full project
% "Can Green Deficits Finance Themselves?" (editorial-roadmap Step 2).
%
% RUNS, IN SEQUENCE (each stage independent; failures are recorded and the
% master continues):
%    1. main_project_run_all        baseline: Props, PFig1-4      [MATLAB]
%    2. main_project_extended       carbon stock, incidence       [MATLAB]
%    3. main_project_calibrated     beta*, damage columns, U3     [MATLAB]
%    4. main_project_regimes        financing regimes, PFig9      [MATLAB]
%    5. main_project_maturity       maturity/indexation, U5       [MATLAB]
%    6. main_project_channels       safe-asset PFig15 + welfare
%                                   groups PFig16                 [MATLAB]
%    7. main_project_robustness     (D0,theta_g) frontier PFig20  [MATLAB]
%    8. main_project_production     Stage-1 tax-base margin       [MATLAB]
%    9. main_project_aggrisk        aggregate risk Stage A PFig19 [MATLAB]
%   10. main_project_aggrisk_stageB fiscal/welfare Stage B PFig21 [MATLAB]
%   11. main_project_transition     nonlinear DTPL path (3
%                                   designs incl. rebate) PFig18  [MATLAB]
%   12. main_project_transition_welfare  transition-inclusive
%                                   incidence (no re-solve)       [MATLAB]
%   13. verify_mu_neutrality        Theorem 2 audit (mu enters
%                                   only through r^ss)            [MATLAB]
%   14. sensitivity_climate_discipline  M7: nu over (theta_g,
%                                   delta_g); BCR=1 frontier      [MATLAB]
%   15. verify_transition_ssj       Anderson vs sequence-space
%                                   Newton cross-check + J
%                                   determinacy diagnostic        [MATLAB]
%   16. export_paper_numbers        paper/numbers_auto.tex        [MATLAB]
%   14. dynare/run_green_transitions  U6 RANK diagnostics PFig13  [Dynare]
%   15. dynare/run_green_hank         U7 tier-1 HANK IRFs PFig14  [Dynare,
%                                     heterogeneity framework]
% then writes output/tables/master_status.txt via export_master_status
% (timestamp, versions, run/skipped + reasons, figure/table counts, key
% output timestamps, implementation-status summary).
%
% USAGE   >> run_green_deficits_master
%         >> FAST = true; run_green_deficits_master     % small grids
%
% NOTE: sub-scripts execute `clearvars -except FAST`, so the master keeps
% its bookkeeping in appdata (survives clearvars), not in the workspace.

if ~exist('FAST','var'), FAST = false; end
close all; clc;

mtrack = struct();
mtrack.t_start   = datestr(now, 'yyyy-mm-dd HH:MM:SS'); %#ok<*TNOW1,*DATST>
mtrack.clock0    = clock;
mtrack.projdir   = fileparts(mfilename('fullpath'));
if isempty(mtrack.projdir), mtrack.projdir = pwd; end
mtrack.run       = {};
mtrack.skipped   = {};
mtrack.reasons   = {};
mtrack.fast      = FAST;
setappdata(0, 'gd_master_track', mtrack);
cd(mtrack.projdir);
addpath(genpath(fullfile(mtrack.projdir, 'src_project')));

stages = { ...
    'main_project_run_all',            'matlab'; ...
    'main_project_extended',           'matlab'; ...
    'main_project_calibrated',         'matlab'; ...
    'main_project_regimes',            'matlab'; ...
    'main_project_maturity',           'matlab'; ...
    'main_project_channels',           'matlab'; ...
    'main_project_robustness',         'matlab'; ...
    'main_project_production',         'matlab'; ...
    'main_project_aggrisk',            'matlab'; ...
    'main_project_aggrisk_stageB',     'matlab'; ...
    'main_project_transition',         'matlab'; ...
    'main_project_transition_welfare', 'matlab'; ...
    'verify_mu_neutrality',            'matlab'; ...
    'sensitivity_climate_discipline',  'matlab'; ...
    'verify_transition_ssj',           'matlab'; ...
    'export_paper_numbers',            'matlab'; ...
    'run_green_transitions',           'dynare'; ...
    'run_green_hank',                  'dynare-het'; ...
    'run_green_hank2',                 'dynare-het-experimental'};
setappdata(0, 'gd_master_stages', stages);

for master_k = 1:size(getappdata(0,'gd_master_stages'), 1)
    stages = getappdata(0, 'gd_master_stages');           % survives clearvars
    stage  = stages{master_k, 1};
    kind   = stages{master_k, 2};
    t      = getappdata(0, 'gd_master_track');
    cd(t.projdir);
    fprintf('\n############ MASTER %d/%d: %s ############\n', ...
        master_k, size(stages,1), stage);

    % availability gates for the Dynare tiers
    if startsWith(kind, 'dynare') && exist('dynare', 'file') ~= 2
        t.skipped{end+1} = stage;
        t.reasons{end+1} = 'Dynare not on the MATLAB path';
        setappdata(0, 'gd_master_track', t);
        fprintf('  [skipped] %s\n', t.reasons{end});
        continue;
    end
    % the two-asset tier never runs inside the master: the Dynare dev-build
    % heterogeneity solves intermittently hard-crash the whole MATLAB
    % process (uncatchable), so it must be run manually in its own session
    % (run_green_hank2; crash-resilient spawn/checkpoint modes are its
    % default). Its accuracy protocol PASSED on 2026-07-09 and the banked
    % checkpointed results back Table 7 / PFig17.
    if strcmp(kind, 'dynare-het-experimental')
        t.skipped{end+1} = stage;
        t.reasons{end+1} = ['tier-1b runs manually in its own session ' ...
                            '(intermittent hard crashes in the Dynare dev ' ...
                            'build); banked results: accuracy PASSED 2026-07-09'];
        setappdata(0, 'gd_master_track', t);
        fprintf('  [skipped] %s\n', t.reasons{end});
        continue;
    end

    % stash the loop locals: the sub-script's `clearvars -except FAST`
    % wipes stage/kind/master_k from the base workspace, so re-read them
    % from appdata after eval (both the success and the catch paths).
    setappdata(0, 'gd_master_iter', ...
        struct('stage', stage, 'kind', kind, 'k', master_k));
    try
        FAST = t.fast; %#ok<NASGU>   % restore flag for the sub-script
        if startsWith(kind, 'dynare')
            cd(fullfile(t.projdir, 'dynare'));
        end
        eval(stage);
        it       = getappdata(0, 'gd_master_iter');   % survives clearvars
        stage    = it.stage;  kind = it.kind;  master_k = it.k;
        t = getappdata(0, 'gd_master_track');
        t.run{end+1} = stage;
    catch ME
        it       = getappdata(0, 'gd_master_iter');
        stage    = it.stage;  kind = it.kind;  master_k = it.k;
        t = getappdata(0, 'gd_master_track');
        t.skipped{end+1} = stage;
        if strcmp(kind, 'dynare-het') && ...
                contains(lower(ME.message), 'heterogeneity')
            t.reasons{end+1} = ['Dynare heterogeneity framework missing: ' ME.message];
        else
            t.reasons{end+1} = ME.message;
        end
        warning('master:stagefail', 'Stage %s failed: %s', stage, ME.message);
    end
    setappdata(0, 'gd_master_track', t);
    diary off;   % in case a failed stage left its diary open
end

% ---- consolidated machine-written status ----
t = getappdata(0, 'gd_master_track');
cd(t.projdir);
export_master_status(t);
rmappdata(0, 'gd_master_track');
rmappdata(0, 'gd_master_stages');
if isappdata(0, 'gd_master_iter'), rmappdata(0, 'gd_master_iter'); end
fprintf('\nMASTER RUN COMPLETE (%.1f s). See output/tables/master_status.txt,\n', ...
    etime(clock, t.clock0));
fprintf('MODEL_STATUS.md and ROADMAP.md.\n');
