% RUN_GREEN_DEFICITS_MASTER  One-command reproduction of the full project
% "Can Green Deficits Finance Themselves?" (editorial-roadmap Step 2).
%
% RUNS, IN SEQUENCE (each stage independent; failures are recorded and the
% master continues):
%   1. main_project_run_all      baseline: Props, PFig1-4        [MATLAB]
%   2. main_project_extended     carbon stock, incidence, X1-X4  [MATLAB]
%   3. main_project_calibrated   beta*, damage columns, U3       [MATLAB]
%   4. main_project_regimes      financing regimes, U4, PFig9    [MATLAB]
%   5. main_project_maturity     maturity/indexation, U5         [MATLAB]
%   6. main_project_channels     safe-asset decomposition PFig15
%                                + extended welfare PFig16       [MATLAB]
%   7. dynare/run_green_transitions   U6 RANK diagnostics        [Dynare]
%   8. dynare/run_green_hank          U7 tier-1 HANK IRFs        [Dynare,
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
    'main_project_run_all',    'matlab'; ...
    'main_project_extended',   'matlab'; ...
    'main_project_calibrated', 'matlab'; ...
    'main_project_regimes',    'matlab'; ...
    'main_project_maturity',   'matlab'; ...
    'main_project_channels',   'matlab'; ...
    'main_project_transition', 'matlab'; ...
    'run_green_transitions',   'dynare'; ...
    'run_green_hank',          'dynare-het'; ...
    'run_green_hank2',         'dynare-het'};
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

    try
        FAST = t.fast; %#ok<NASGU>   % restore flag for the sub-script
        if startsWith(kind, 'dynare')
            cd(fullfile(t.projdir, 'dynare'));
        end
        eval(stage);
        t = getappdata(0, 'gd_master_track');
        t.run{end+1} = stage;
    catch ME
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
fprintf('\nMASTER RUN COMPLETE (%.1f s). See output/tables/master_status.txt,\n', ...
    etime(clock, t.clock0));
fprintf('MODEL_STATUS.md and ROADMAP.md.\n');
