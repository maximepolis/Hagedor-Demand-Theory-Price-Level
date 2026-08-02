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
%           .method 'sha256' | 'unavailable'
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

    if ~have_sha256()
        V.method = 'unavailable';
        tee(['kv_verify_baseline: SHA-256 is unavailable (no JVM). Verification\n' ...
             'cannot be performed, and an UNVERIFIED baseline must not be used to\n' ...
             'certify a refactor. Start MATLAB with the JVM enabled.\n']);
        return;
    end

    [H, N, P] = read_manifest(mf);
    V.n = numel(P);
    bad = {}; missing = {}; neol = 0; nex = 0;

    for i = 1:numel(P)
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
function t = have_sha256()
    t = false;
    try
        java.security.MessageDigest.getInstance('SHA-256');
        t = true;
    catch
    end
end

function h = sha256_hex(b)
    md = java.security.MessageDigest.getInstance('SHA-256');
    md.update(typecast(b(:), 'int8'));         % Java bytes are SIGNED
    d = typecast(md.digest(), 'uint8');
    h = lower(reshape(dec2hex(d, 2)', 1, []));
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
