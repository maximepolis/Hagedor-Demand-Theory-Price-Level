function s = kv_code_version(callerpath)
% KV_CODE_VERSION  One line identifying the revision and the actual file that
% is running, for printing at the top of every driver.
%
% WHY. A stale copy of a driver on the MATLAB path fails with a message about
% the OLD file's logic, which reads as a bug in the new instructions rather
% than as a version mismatch. That happened with main_baseline_capture: the
% shipped version takes no required variables, but an older copy asserted on
% BASELINE_OUT, and the error named a variable the current file does not
% mention. Nothing in the output said which file had run.
%
% So every driver in the parity sequence prints the pipeline revision from
% CODE_VERSION.txt AND its own resolved path and modification date. A pasted
% console log then identifies itself, and a stale file is visible in the first
% line rather than after a failed run.
%
% INPUT   callerpath  normally mfilename('fullpath') from the calling driver
% OUTPUT  s           a single line, no trailing newline

    if nargin < 1 || isempty(callerpath), callerpath = ''; end

    here = fileparts(mfilename('fullpath'));       % .../src_project
    proj = fileparts(here);
    tag = '(CODE_VERSION.txt not found)';
    vf = fullfile(proj, 'CODE_VERSION.txt');
    if exist(vf, 'file') == 2
        fh = fopen(vf, 'r');
        while true
            l = fgetl(fh);
            if ~ischar(l), break; end
            t = strtrim(l);
            if ~isempty(t) && t(1) ~= '#', tag = t; break; end
        end
        fclose(fh);
    end

    % A STALE VERSION FILE IS ITSELF A HAZARD. CODE_VERSION.txt is maintained
    % by hand and lives beside the source, so it can go out of date relative to
    % the .m files -- a run reported "pipeline R11.6" while executing R11.7
    % code, because an extract-over-existing-folder had refreshed the sources
    % and skipped the text file. Worse, with two project copies present the
    % file read here may belong to a DIFFERENT folder than the driver that is
    % running. Report the resolved location, and flag it when it is not a
    % sibling of the caller.
    sib = '';
    if ~isempty(callerpath)
        cdir = fileparts(callerpath);
        if ~strcmpi(norm_(cdir), norm_(proj)) && ~strcmpi(norm_(cdir), norm_(here))
            % The BRACKETS are load-bearing. MATLAB does not concatenate
            % adjacent string literals: 'a' 'b' is a syntax error, not 'ab'.
            % A multi-line message inside a call must be wrapped in [ ].
            sib = sprintf(['  [!! CODE_VERSION.txt read from %s, NOT from the ' ...
                           'directory of the running driver -- you have more ' ...
                           'than one copy of the project]'], proj);
        end
    end

    fpart = '';
    mix   = '';
    if ~isempty(callerpath)
        f = callerpath;
        if exist([f '.m'], 'file') == 2, f = [f '.m']; end
        d = dir(f);
        if ~isempty(d)
            fpart = sprintf('  |  %s  (modified %s)', d(1).name, ...
                            datestr(d(1).datenum, 'yyyy-mm-dd HH:MM'));

            % A MIXED EXTRACT REPORTS AN OLD REVISION FOR NEW CODE. The project
            % is delivered as a downloaded archive unpacked over the existing
            % folder, so a partial or older extract can refresh the drivers
            % while leaving CODE_VERSION.txt behind -- the banner then names a
            % revision that is not the one executing, which is the exact
            % confusion this line exists to prevent. The version file is bumped
            % only on interface changes, so a driver being somewhat newer is
            % normal; a full day newer is not. Report it as a suspicion, not as
            % a verdict, and name the fix.
            if exist(vf, 'file') == 2
                dv = dir(vf);
                if ~isempty(dv) && d(1).datenum > dv(1).datenum + 1
                    mix = sprintf(['  [!! CODE_VERSION.txt is %.1f days older ' ...
                                   'than this driver -- the revision above may ' ...
                                   'not be the code that is running; re-extract ' ...
                                   'the project]'], d(1).datenum - dv(1).datenum);
                end
            end
        else
            fpart = sprintf('  |  %s', callerpath);
        end
    end

    s = sprintf('pipeline %s%s%s%s', tag, fpart, sib, mix);
end

function s = norm_(p)
% MATLAB single-quoted strings do NOT treat backslash as an escape, so the
% separator to replace is '\', one character. '\\' would match a doubled
% backslash and leave every Windows path unnormalised -- turning this check
% into one that always fires.
    s = strrep(char(p), '\', '/');
    s = regexprep(s, '/+$', '');
end
