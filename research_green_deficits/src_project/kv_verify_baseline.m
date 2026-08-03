function V = kv_verify_baseline(basedir, tee)
% KV_VERIFY_BASELINE  Prove that a directory really is the frozen pre-refactor
% baseline, WITHOUT git.
%
% WHY NOT GIT. The project is distributed as a GitHub ZIP and extracted; an
% extracted archive has no .git directory, so `git rev-parse HEAD` returns an
% error string rather than a commit and every git-based check is unavailable.
% Requiring git made the baseline capture impossible for the way this project
% is actually used.
%
% WHAT REPLACES IT. Content addressing, which is what git was providing
% anyway. baseline_bf0a4e8/MANIFEST_bf0a4e8.sha256 lists the SHA-256 and byte
% length of all 152 .m files of commit bf0a4e8, generated from the commit
% OBJECT rather than from a working tree. If every file matches, the directory
% is that commit -- and that is a stronger statement than `HEAD == bf0a4e8`,
% which says nothing about whether the working tree was edited afterwards.
%
% LINE ENDINGS ARE DIAGNOSED, NOT CONFLATED WITH CORRUPTION. A ZIP extracted
% on Windows, or a file opened and resaved by an editor, can arrive with CRLF
% where the manifest recorded LF. The bytes differ, so the hash differs, but
% the CONTENT is intact. A checker that reports both cases as "MISMATCH" sends
% you looking for a corrupted download that does not exist. So each failure is
% re-hashed after normalising line endings, and reported as EOL_ONLY when that
% matches. EOL_ONLY does not fail the verification: MATLAB does not care
% whether a source file ends its lines with LF or CRLF.
%
% INPUT   basedir  the baseline root: the directory CONTAINING
%                  research_green_deficits/ and src/, and the manifest
%         tee      optional printf-like handle
%
% OUTPUT  V .ok .n .n_exact .n_eol .n_bad .n_missing .n_extra
%           .bad {paths} .missing {paths} .extra {paths}
%           .method 'sha256 (pure MATLAB, kv_sha256)' | 'BROKEN'
%           .manifest path actually used

    if nargin < 2 || isempty(tee), tee = @(varargin) fprintf(varargin{:}); end
    V = struct('ok', false, 'n', 0, 'n_exact', 0, 'n_eol', 0, 'n_bad', 0, ...
               'n_missing', 0, 'n_extra', 0, 'bad', {{}}, 'missing', {{}}, ...
               'extra', {{}}, 'method', 'sha256', 'manifest', '', ...
               'basedir', basedir);

    mf = fullfile(basedir, 'MANIFEST_bf0a4e8.sha256');
    if exist(mf, 'file') ~= 2
        tee(['kv_verify_baseline: no manifest at\n  %s\n' ...
             'The baseline directory should be the one shipped with the\n' ...
             'project (baseline_bf0a4e8/), or a GitHub ZIP of commit bf0a4e8\n' ...
             'with that manifest copied in.\n'], mf);
        return;
    end
    V.manifest = mf;

    % SHA-256 is computed by kv_sha256, in pure MATLAB. The previous version
    % used java.security.MessageDigest and gave up when R2025b reported no
    % JVM -- making the integrity gate depend on an optional runtime, so a
    % perfectly correct baseline could not be certified. That is the wrong
    % failure mode for a check whose purpose is to let work proceed.
    %
    % The hash proves itself first. A hand-written digest that is wrong does
    % not fail loudly: it returns plausible 64-character strings that never
    % match, and the verification then blames the BASELINE for a defect in the
    % checker.
    V.method = 'sha256 (pure MATLAB, kv_sha256)';
    if ~kv_sha256_selftest(false)
        V.method = 'BROKEN';
        tee(['kv_verify_baseline: kv_sha256 FAILED ITS OWN SELF-TEST.\n' ...
             'The hash is wrong, so nothing can be concluded about the baseline.\n' ...
             'Run  kv_sha256_selftest  to see which vector failed.\n']);
        return;
    end

    [H, N, P] = read_manifest(mf);
    V.n = numel(P);
    bad = {}; missing = {}; neol = 0; nex = 0;

    % Pure-MATLAB SHA-256 over ~1.1 MB is not instant. Report progress rather
    % than sitting silent for minutes, which reads as a hang and invites a
    % Ctrl-C in the middle of a verification.
    tee('hashing %d files with pure-MATLAB SHA-256 -- allow a few minutes;\n', numel(P));
    tee('this is a one-time gate, not part of any solve.\n');
    tick = max(1, floor(numel(P)/10));

    for i = 1:numel(P)
        if mod(i, tick) == 0
            tee('  ... %d/%d\n', i, numel(P));
        end
        f = fullfile(basedir, strrep(P{i}, '/', filesep));
        if exist(f, 'file') ~= 2
            missing{end+1} = P{i}; %#ok<AGROW>
            continue;
        end
        b = readbytes(f);
        h = sha256_hex(b);
        if strcmp(h, H{i})
            nex = nex + 1;
            continue;
        end
        % Not a byte match. Is it ONLY line endings? The manifest was generated
        % from LF bytes, so normalising the local file to LF and re-hashing is
        % the right comparison -- and it is the ONLY extra comparison made
        % here. (An earlier draft of this line also compared the normalised
        % hash against itself, which is trivially true, so every mismatch
        % would have been excused as a line-ending difference and `bad` could
        % never be non-empty. A check that cannot fail is worse than no check.)
        hn = sha256_hex(normalize_eol(b));
        if strcmp(hn, H{i})
            neol = neol + 1;
            continue;
        end
        bad{end+1} = sprintf('%s (expected %s..., %d bytes; got %s..., %d bytes)', ...
                             P{i}, H{i}(1:8), N(i), h(1:8), numel(b)); %#ok<AGROW>
    end

    % Files present in the baseline tree but NOT in the manifest. An extra .m
    % file is not harmless: it would be on the path during the capture and
    % could shadow a baseline function.
    found = list_m(basedir);
    extra = {};
    if ~isempty(P)
        known = containers.Map(P, num2cell(1:numel(P)));
        for i = 1:numel(found)
            if ~isKey(known, found{i}), extra{end+1} = found{i}; end %#ok<AGROW>
        end
    else
        extra = found;
    end

    V.n_exact = nex; V.n_eol = neol; V.bad = bad; V.n_bad = numel(bad);
    V.missing = missing; V.n_missing = numel(missing);
    V.extra = extra; V.n_extra = numel(extra);
    V.ok = isempty(bad) && isempty(missing) && isempty(extra);

    tee('baseline verification (%s)\n', mf);
    tee('  %d files in the manifest\n', V.n);
    tee('  %d byte-identical\n', V.n_exact);
    if neol > 0
        tee('  %d differ ONLY in line endings (content intact; not a failure)\n', neol);
    end
    if ~isempty(missing)
        tee('  %d MISSING:\n', numel(missing));
        for i = 1:min(10, numel(missing)), tee('     %s\n', missing{i}); end
        if numel(missing) > 10, tee('     ... and %d more\n', numel(missing)-10); end
    end
    if ~isempty(bad)
        tee('  %d MODIFIED:\n', numel(bad));
        for i = 1:min(10, numel(bad)), tee('     %s\n', bad{i}); end
        if numel(bad) > 10, tee('     ... and %d more\n', numel(bad)-10); end
    end
    if ~isempty(extra)
        tee('  %d UNEXPECTED .m files (they would be on the path during capture):\n', ...
            numel(extra));
        for i = 1:min(10, numel(extra)), tee('     %s\n', extra{i}); end
    end
    tee('  VERDICT: %s\n', ternstr(V.ok, ...
        'this IS the frozen pre-refactor baseline', ...
        'NOT the frozen baseline -- do not capture from it'));
end

% ---------------------------------------------------------------------
function h = sha256_hex(b)
    h = kv_sha256(b);
end

function b = readbytes(f)
    fh = fopen(f, 'r');
    b = fread(fh, Inf, '*uint8');
    fclose(fh);
end

function b = normalize_eol(b)
% CRLF -> LF, then a lone CR -> LF. Done on bytes so it is exact.
    b = b(:);
    cr = 13; lf = 10;
    drop = false(size(b));
    idx = find(b == cr);
    for i = 1:numel(idx)
        k = idx(i);
        if k < numel(b) && b(k+1) == lf
            drop(k) = true;                     % CRLF: drop the CR
        else
            b(k) = lf;                          % lone CR: becomes LF
        end
    end
    b(drop) = [];
end

function [H, N, P] = read_manifest(mf)
    H = {}; N = []; P = {};
    fh = fopen(mf, 'r');
    while true
        l = fgetl(fh);
        if ~ischar(l), break; end
        s = strtrim(l);
        if isempty(s) || s(1) == '#', continue; end
        t = regexp(s, '^([0-9a-f]{64})\s+(\d+)\s+(.+)$', 'tokens', 'once');
        if isempty(t), continue; end
        H{end+1} = t{1};  N(end+1) = str2double(t{2});  P{end+1} = strtrim(t{3}); %#ok<AGROW>
    end
    fclose(fh);
end

function n = list_m(basedir)
    n = {};
    for d = {'research_green_deficits', 'src'}
        root = fullfile(basedir, d{1});
        if ~isfolder(root), continue; end
        f = dir(fullfile(root, '**', '*.m'));
        for i = 1:numel(f)
            if f(i).isdir, continue; end
            p = fullfile(f(i).folder, f(i).name);
            rel = strrep(p(numel(basedir)+2:end), filesep, '/');
            n{end+1} = rel; %#ok<AGROW>
        end
    end
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
