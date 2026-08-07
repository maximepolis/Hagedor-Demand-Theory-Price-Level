function check_output_staleness()
% CHECK_OUTPUT_STALENESS  Which stored artifacts are older than the code that
% writes them. MATLAB port of paper/check_output_staleness.py.
%
% WHY A SECOND IMPLEMENTATION. The audit existed only as a Python script, and
% the collaborator's machine has MATLAB and no Python -- so the one check that
% belongs in the RUN loop was the one check that could not be run there, and
% replot_stale_figures ended by printing a `python3 ...` next step that was
% useless on the machine reading it. This file closes that gap. The Python
% version stays for the maintainer side; the two answer the same question by
% different evidence, which is stated below because it matters.
%
% THE EVIDENCE DIFFERS, DELIBERATELY. The Python version dates files by their
% last GIT COMMIT. That is unavailable here: the project arrives as an
% extracted archive with no repository, which is the same reason
% kv_code_version cannot trust timestamps either. So this version compares
% FILE MODIFICATION TIMES, and that carries a failure mode worth naming
% rather than hiding: an extract stamps a batch of .m files at once, so every
% artifact produced before that extract looks stale whether or not its writer
% actually changed.
%
% HOW THE FIRST VERSION GOT THAT GUARD WRONG. It compared the OLDEST and
% NEWEST source file and treated a wide span as licence to trust the column.
% Its first real run disproved it: all fourteen flagged writers carried the
% identical stamp 2026-08-07 12:04 -- one unpack, not fourteen edits -- while
% the global span read 116 hours because the tree also held files from
% earlier extracts, and the check duly announced the comparison "meaningful".
% False reassurance is worse than no check, because the reader stops looking.
%
% The guard is now per-row and measures CLUSTERING: how many other sources
% share this writer's timestamp. Files are edited singly and unpacked in
% batches, so a shared stamp dates an unpack and cannot date an edit. Such
% rows report "cannot-tell", never "stale". On a tree assembled entirely by
% extraction this correctly leaves NOTHING stale -- and says so as a limit of
% the evidence, not as a clean bill of health.
%
% What it can always answer, extract or no extract: which artifacts the paper
% needs and does NOT exist. That part is timestamp-free and is reported first.
%
% USAGE   >> clear; check_output_staleness
% OUTPUT  console only; nothing is written, nothing is solved.

    projdir = fileparts(mfilename('fullpath'));
    if isempty(projdir), projdir = pwd; end
    rootdir = fileparts(projdir);

    fprintf('OUTPUT STALENESS AUDIT\n');
    fprintf('%s\n', kv_code_version(mfilename('fullpath')));
    fprintf(['artifact vs the .m file that writes it, by modification time.\n' ...
             'Read the EXTRACT WARNING below before believing a stale row.\n\n']);

    % ---- collect the source files that could be writers ------------------
    srcs = [dir(fullfile(projdir, '*.m')); ...
            dir(fullfile(projdir, 'src_project', '*.m')); ...
            dir(fullfile(rootdir, 'src', '*.m'))];
    if isempty(srcs)
        fprintf('no .m files found -- is this the project directory?\n'); return;
    end
    stext = cell(numel(srcs), 1);
    spath = cell(numel(srcs), 1);
    sdate = zeros(numel(srcs), 1);
    for i = 1:numel(srcs)
        spath{i} = fullfile(srcs(i).folder, srcs(i).name);
        sdate(i) = srcs(i).datenum;
        try, stext{i} = fileread(spath{i}); catch, stext{i} = ''; end
    end

    % ---- is the .m timestamp spread wide enough to be informative? -------
    % MEASURE CLUSTERING, NOT SPREAD. The first version of this test compared
    % the OLDEST and NEWEST source file and concluded that a wide span meant
    % the timestamps were trustworthy. Its first real run disproved it: all
    % fourteen flagged writers carried the identical stamp 2026-08-07 12:04
    % -- one unpack event, not fourteen edits -- while the global span was
    % 116 hours because the tree also held files from earlier extracts. The
    % check duly announced that the comparison was "meaningful". A test that
    % offers false reassurance is worse than no test, because the reader stops
    % looking.
    %
    % The right signal is local and per-row: how many OTHER source files share
    % this writer's timestamp. Files are edited one at a time and unpacked in
    % batches, so a stamp shared by several files dates an extraction and
    % cannot date an edit. Any row whose writer sits in such a batch is
    % demoted to "cannot tell" rather than reported as stale.
    BATCH_MIN = 1/(24*60);      % same minute
    BATCH_N   = 3;              % this many co-stamped files means a batch
    nshare = zeros(numel(sdate), 1);
    for i = 1:numel(sdate)
        nshare(i) = sum(abs(sdate - sdate(i)) <= BATCH_MIN);
    end

    % ---- artifacts -------------------------------------------------------
    arts = [dir(fullfile(projdir, 'output', '*.mat')); ...
            dir(fullfile(projdir, 'output', 'tables', '*.txt'))];

    n_stale = 0; n_fresh = 0; n_nowriter = 0; n_cant = 0;
    stale_rows = {}; cant_rows = {};
    fprintf('%-40s %-17s %-17s %-9s %s\n', 'artifact', 'artifact stamp', ...
            'writer stamp', 'verdict', 'written by');
    fprintf('%s\n', repmat('-', 1, 112));
    for i = 1:numel(arts)
        base = arts(i).name;
        [wpath, wdate, widx] = local_writer(base, spath, stext, sdate);
        if isempty(wpath)
            n_nowriter = n_nowriter + 1; continue;
        end
        adate = arts(i).datenum;
        if wdate <= adate
            n_fresh = n_fresh + 1; continue;
        end
        if nshare(widx) >= BATCH_N
            n_cant = n_cant + 1; cant_rows{end+1} = base; vd = 'cant-tell'; %#ok<AGROW>
        else
            n_stale = n_stale + 1; stale_rows{end+1} = base; vd = 'STALE'; %#ok<AGROW>
        end
        fprintf('%-40s %-17s %-17s %-9s %s\n', base, ...
                datestr(adate, 'yyyy-mm-dd HH:MM'), ...
                datestr(wdate, 'yyyy-mm-dd HH:MM'), vd, local_name(wpath));
    end
    if n_stale == 0 && n_cant == 0
        fprintf('(no artifact is older than its writer)\n');
    end

    fprintf(['\n%d artifact(s) checked: %d STALE, %d cannot-tell, %d current, ' ...
             '%d with no writer found.\n'], ...
            numel(arts), n_stale, n_cant, n_fresh, n_nowriter);
    if n_nowriter > 0
        fprintf(['"no writer found" is usually an artifact written by an external\n' ...
                 'tool or by a driver whose save() this parser cannot see. It is\n' ...
                 'not a staleness verdict either way.\n']);
    end

    % ---- what the two verdicts mean --------------------------------------
    fprintf('\nHOW TO READ THE VERDICT COLUMN\n');
    if n_cant > 0
        fprintf(['  cannot-tell: the writer shares its timestamp with at least\n' ...
                 '  %d other source file(s), which dates an UNPACK, not an edit.\n' ...
                 '  Modification time cannot say whether that driver changed, so\n' ...
                 '  these rows are evidence in neither direction. %d row(s).\n'], ...
                BATCH_N - 1, n_cant);
    end
    if n_stale > 0
        fprintf(['  STALE: the writer carries a timestamp shared with no batch,\n' ...
                 '  i.e. it looks individually edited AFTER its own output was\n' ...
                 '  produced. These are the rows worth re-running. %d row(s).\n'], ...
                n_stale);
    end
    if n_cant > 0 && n_stale == 0
        fprintf(['  Nothing survives as STALE on this tree: every candidate sits\n' ...
                 '  in an unpack batch. That is the honest answer, NOT a clean\n' ...
                 '  bill of health -- decide what to re-run from the run log and\n' ...
                 '  from CODE_VERSION.txt, which records what actually changed.\n']);
    end

    % ---- the timestamp-free half: what the paper needs and does not have -
    % These are the artifacts the exporter and the figure drivers read. A
    % missing one is a fact no timestamp argument can soften.
    needed = { 'calibrated_results.mat',    'main_project_calibrated'; ...
               'regimes_results.mat',       'main_project_regimes'; ...
               'robustness_results.mat',    'main_project_robustness'; ...
               'twoasset_ownership_kv.mat', 'main_twoasset_ownership_kv'; ...
               'wealth_fit_results.mat',    'wealth_concentration_fit'; ...
               'convenience_kvj.mat',       'calibrate_convenience_kvj'; ...
               'deficit_decomposition.mat', 'main_deficit_decomposition'; ...
               'deficit_estimands.mat',     'main_deficit_estimands'; ...
               'timing_frontier.mat',       'main_timing_frontier' };
    fprintf('\nREQUIRED ARTIFACTS (existence only -- no timestamp involved)\n');
    n_missing = 0;
    for i = 1:size(needed, 1)
        f = fullfile(projdir, 'output', needed{i,1});
        if exist(f, 'file') == 2
            fprintf('  present  %-30s\n', needed{i,1});
        else
            n_missing = n_missing + 1;
            fprintf('  MISSING  %-30s  run: clear; %s\n', needed{i,1}, needed{i,2});
        end
    end
    if n_missing == 0
        fprintf('  all present.\n');
    end
end

% =========================================================================
function [wpath, wdate, widx] = local_writer(base, spath, stext, sdate)
% The .m file that writes this artifact, by the same two rules the Python
% version uses: a .mat must appear inside a save(...) statement, and a .txt
% must reach an fopen -- either written into the call directly, or assigned
% to a variable that fopen is later handed. The variable hop matters: the
% house pattern is `sf = fullfile(tabdir,'x.txt'); fid = fopen(sf,'w');`,
% and a rule that only looked inside fopen( would miss every table in the
% project. When several files match, the NEWEST wins -- that is the one whose
% change would make the artifact stale.
    wpath = ''; wdate = -Inf; widx = 0;
    esc = regexptranslate('escape', base);
    is_mat = numel(base) > 4 && strcmpi(base(end-3:end), '.mat');
    for i = 1:numel(stext)
        s = stext{i};
        if isempty(s) || ~contains(s, base), continue; end
        hit = false;
        if is_mat
            hit = ~isempty(regexp(s, ['save\s*\([^;]{0,400}?''' esc ''''], 'once'));
        else
            if contains(s, 'fopen(')
                hit = ~isempty(regexp(s, ['fopen\s*\([^;]{0,200}?''' esc ''''], 'once'));
                if ~hit
                    % Find variables assigned this literal, then look for an
                    % fopen on any of them.
                    vs = regexp(s, ['(\w+)\s*=\s*[^;\n]{0,200}?''' esc ''''], ...
                                'tokens');
                    for k = 1:numel(vs)
                        v = regexptranslate('escape', vs{k}{1});
                        if ~isempty(regexp(s, ['fopen\s*\(\s*' v '\b'], 'once'))
                            hit = true; break;
                        end
                    end
                end
            end
        end
        if hit && sdate(i) > wdate
            wdate = sdate(i); wpath = spath{i}; widx = i;
        end
    end
    if isempty(wpath), wdate = NaN; end
end

function n = local_name(p)
    [~, b, e] = fileparts(p); n = [b e];
end
