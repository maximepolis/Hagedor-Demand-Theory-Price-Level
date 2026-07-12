% MAIN_PROJECT_TRANSITION_WELFARE  Transition-INCLUSIVE welfare incidence.
%
% The steady-state welfare comparison (Table 5) asks how a household fares
% across stationary equilibria; the natural referee objection is that the
% program's costs are front-loaded (taxes rise at the announcement) while
% its benefits accrue over decades (damages fall as green capital builds),
% so steady-state incidence may misstate who gains from the ANNOUNCEMENT.
% This driver answers it exactly, with no new solves of the fixed point:
%
%   V1(a,e) = value of entering date 1 of the CONVERGED announced path
%             (from transition_backward on the saved price path, including
%             the announcement-date surprise revaluation via r_path(1)),
%   V0(a,e) = value of remaining in the no-program steady state forever,
%
% and lambda(a,e) is the permanent-consumption transfer equating them --
% the transition-inclusive counterpart of Table 5, aggregated over the same
% baseline wealth groups. The steady-state incidence is recomputed on the
% same grids for an apples-to-apples column.
%
% REQUIREMENTS: output/transition_results.mat (run main_project_transition
% first). Runtime: one backward pass per design (~seconds to a minute at
% the saved resolution) -- the fixed point itself is NOT re-solved.
%
% OUTPUT: output/tables/transition_welfare_summary.txt,
%         output/transition_welfare.mat
%
% USAGE:  >> cd research_green_deficits; main_project_transition_welfare

clear; clc; t0 = tic;
projdir = fileparts(mfilename('fullpath'));
rootdir = fileparts(projdir);
addpath(fullfile(rootdir, 'src'));
addpath(fullfile(projdir, 'src_project'));

f = fullfile(projdir, 'output', 'transition_results.mat');
if exist(f, 'file') ~= 2
    error('main_project_transition_welfare:nores', ...
        'output/transition_results.mat not found -- run main_project_transition first.');
end
L = load(f, 'TRn', 'TRi', 'pgc');
pgc  = L.pgc;
rbar = (1 + pgc.i_ss) / (1 + pgc.mu) - 1;

fprintf('==============================================================\n');
fprintf(' TRANSITION-INCLUSIVE WELFARE (from the saved converged path)\n');
fprintf('==============================================================\n');

TW = struct();
designs = {'nominal', L.TRn; 'indexed', L.TRi};
for d = 1:size(designs, 1)
    name = designs{d, 1};  TR = designs{d, 2};
    if isempty(TR) || ~isfield(TR, 'phat') || ~isfield(TR, 'reportable') || ~TR.reportable
        fprintf('  [%s] path not reportable -- skipped\n', name);
        continue;
    end
    % boundary household objects on the SAME grids the path was solved on
    [~, oI] = S_green(rbar, TR.eq0.tau, TR.eq0.D, pgc);   % baseline ss
    [~, oT] = S_green(rbar, TR.eq1.tau, TR.eq1.D, pgc);   % green ss
    if ~oI.feasible || ~oT.feasible
        fprintf('  [%s] boundary household problem infeasible -- skipped\n', name);
        continue;
    end
    % date-1 value of the announced path (one backward pass, no fixed point)
    [~, feas, V1] = transition_backward(oT.V, TR.r_path, TR.tau_path, ...
                                        TR.D_path, pgc);
    if ~feas
        fprintf('  [%s] backward pass infeasible -- skipped\n', name);
        continue;
    end
    wg_tr = welfare_from_values(oI.V, V1,   oI.dist, pgc);  % transition-incl.
    wg_ss = welfare_from_values(oI.V, oT.V, oI.dist, pgc);  % ss-to-ss, same grids
    if ~wg_tr.ok || ~wg_ss.ok
        fprintf('  [%s] CE transform failed -- skipped\n', name);
        continue;
    end
    TW.(name) = struct('wg_transition', wg_tr, 'wg_steadystate', wg_ss);
    fprintf(['  [%s] agg: ss-to-ss %+.2f%%, transition-inclusive %+.2f%% ' ...
             '(bot50 %+.2f%% -> %+.2f%%, top10 %+.2f%% -> %+.2f%%)\n'], ...
        name, 100*wg_ss.lambda_agg, 100*wg_tr.lambda_agg, ...
        100*wg_ss.lambda_bot50, 100*wg_tr.lambda_bot50, ...
        100*wg_ss.lambda_top10, 100*wg_tr.lambda_top10);
end

save(fullfile(projdir, 'output', 'transition_welfare.mat'), 'TW');

sf  = fullfile(projdir, 'output', 'tables', 'transition_welfare_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'TRANSITION-INCLUSIVE WELFARE INCIDENCE (medium damages, calibrated scale)\n');
    fprintf(fid, ['lambda(a,e): CE transfer equating V0 (stay in baseline ss forever)\n' ...
        'with V1 (enter date 1 of the converged announced path, incl. the\n' ...
        'announcement revaluation). Same grids/distribution as the ss column.\n\n']);
    fn = fieldnames(TW);
    for d = 1:numel(fn)
        wgt = TW.(fn{d}).wg_transition;  wgs = TW.(fn{d}).wg_steadystate;
        fprintf(fid, '[%s design]\n', upper(fn{d}));
        fprintf(fid, '%-12s %-14s %-14s\n', 'group', 'ss-to-ss (%)', 'transition (%)');
        for q = 1:5
            fprintf(fid, 'Q%-11d %-14.2f %-14.2f\n', q, ...
                100*wgs.lambda_q(q), 100*wgt.lambda_q(q));
        end
        fprintf(fid, '%-12s %-14.2f %-14.2f\n', 'bottom50', 100*wgs.lambda_bot50, 100*wgt.lambda_bot50);
        fprintf(fid, '%-12s %-14.2f %-14.2f\n', 'top10',    100*wgs.lambda_top10, 100*wgt.lambda_top10);
        fprintf(fid, '%-12s %-14.2f %-14.2f\n', 'constr',   100*wgs.lambda_constr, 100*wgt.lambda_constr);
        fprintf(fid, '%-12s %-14.2f %-14.2f\n\n', 'aggregate', 100*wgs.lambda_agg, 100*wgt.lambda_agg);
    end
    fprintf(fid, ['Reading: "transition" > "ss-to-ss" for a group means the announced\n' ...
        'path treats that group BETTER than the steady-state comparison suggests\n' ...
        '(e.g. bondholders collect the announcement windfall; the poor bear\n' ...
        'front-loaded taxes before damage relief arrives).\n']);
    fclose(fid);
    fprintf('\n  [saved] %s\n', sf);
end
fprintf('Elapsed: %.1f s\n', toc(t0));
