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

    fpart = '';
    if ~isempty(callerpath)
        f = callerpath;
        if exist([f '.m'], 'file') == 2, f = [f '.m']; end
        d = dir(f);
        if ~isempty(d)
            fpart = sprintf('  |  %s  (modified %s)', d(1).name, ...
                            datestr(d(1).datenum, 'yyyy-mm-dd HH:MM'));
        else
            fpart = sprintf('  |  %s', callerpath);
        end
    end

    s = sprintf('pipeline %s%s', tag, fpart);
end
