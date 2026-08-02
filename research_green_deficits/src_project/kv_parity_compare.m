function C = kv_parity_compare(A, B, nameA, nameB, tol, tee)
% KV_PARITY_COMPARE  Compare two captured result sets field by field, in both
% absolute and relative terms, and REPORT the discrepancy rather than failing
% without a diagnosis.
%
% WHY BOTH NORMS. The refactor MOVED code rather than reimplementing it, so
% the expectation is bit-identical output and any difference at all is
% informative. But an iterative solve whose stopping rule fires one iteration
% earlier can change the last bits without changing anything economic, and a
% test that only says FAIL cannot tell that apart from a real defect. So every
% field reports:
%     abs  = max |a - b|
%     rel  = max |a - b| / max(1, |b|)      (elementwise, then max)
%     ulp  = abs / eps(max|b|)              how many floating-point steps
% and the verdict names which of the three tiers it fell in:
%     EXACT      bitwise identical
%     ULP        differs within a few floating-point steps of the magnitude
%     TOL        within the stated tolerance but not ULP-close
%     FAIL       outside tolerance
%
% A field present in one set and absent in the other is MISSING, never
% silently skipped: a capture that lost a field would otherwise read as a pass.
%
% INPUT   A, B    structs of captured quantities, same field names
%         nameA/B labels for the report
%         tol     scalar, or struct mapping field name -> tolerance
%         tee     optional printf-like handle
%
% OUTPUT  C .rows (one per field) .pass .n_exact .n_ulp .n_tol .n_fail
%           .missing_in_A .missing_in_B .worst

    if nargin < 6 || isempty(tee), tee = @(varargin) fprintf(varargin{:}); end
    if nargin < 5 || isempty(tol), tol = 1e-12; end

    fa = fieldnames(A); fb = fieldnames(B);
    C = struct('rows', struct('name',{},'abs',{},'rel',{},'ulp',{}, ...
                              'verdict',{},'na',{},'class',{}), ...
               'pass', true, 'n_exact', 0, 'n_ulp', 0, 'n_tol', 0, 'n_fail', 0, ...
               'missing_in_A', {setdiff(fb, fa)'}, ...
               'missing_in_B', {setdiff(fa, fb)'}, ...
               'worst', struct('name','', 'rel', 0));

    tee('\n%-30s %12s %12s %10s  %s\n', ...
        sprintf('%s vs %s', nameA, nameB), 'max|abs|', 'max rel', 'ulps', 'verdict');
    tee('%s\n', repmat('-', 1, 82));

    common = intersect(fa, fb, 'stable');
    for i = 1:numel(common)
        f = common{i};
        a = A.(f); b = B.(f);
        t = fieldtol(tol, f);
        r = compare_one(a, b, t);
        r.name = f;
        C.rows(end+1) = r; %#ok<AGROW>
        switch r.verdict
            case 'EXACT', C.n_exact = C.n_exact + 1;
            case 'ULP',   C.n_ulp   = C.n_ulp   + 1;
            case 'TOL',   C.n_tol   = C.n_tol   + 1;
            otherwise
                C.n_fail = C.n_fail + 1; C.pass = false;
        end
        if isfinite(r.rel) && r.rel > C.worst.rel
            C.worst = struct('name', f, 'rel', r.rel);
        end
        tee('%-30s %12.4e %12.4e %10s  %s%s\n', f, r.abs, r.rel, ...
            ulpstr(r.ulp), r.verdict, mark(r.verdict));
    end

    for i = 1:numel(C.missing_in_A)
        tee('%-30s %12s %12s %10s  MISSING in %s\n', C.missing_in_A{i}, '-','-','-', nameA);
        C.pass = false; C.n_fail = C.n_fail + 1;
    end
    for i = 1:numel(C.missing_in_B)
        tee('%-30s %12s %12s %10s  MISSING in %s\n', C.missing_in_B{i}, '-','-','-', nameB);
        C.pass = false; C.n_fail = C.n_fail + 1;
    end

    tee('%s\n', repmat('-', 1, 82));
    tee('  %d exact, %d within ulps, %d within tolerance, %d FAIL\n', ...
        C.n_exact, C.n_ulp, C.n_tol, C.n_fail);
    if C.n_fail == 0 && (C.n_tol > 0 || C.n_ulp > 0)
        tee(['  NOT bit-identical. The refactor moved code rather than rewriting it,\n' ...
             '  so this is worth a look even though it passes: the usual benign cause\n' ...
             '  is an iterative stopping rule firing one step earlier. Check that the\n' ...
             '  ITERATION COUNTS below also match before accepting it as benign.\n']);
    end
    if ~isempty(C.worst.name)
        tee('  worst field: %s (relative %.4e)\n', C.worst.name, C.worst.rel);
    end
end

% ---------------------------------------------------------------------
function r = compare_one(a, b, t)
    r = struct('name','', 'abs', NaN, 'rel', NaN, 'ulp', NaN, ...
               'verdict', 'FAIL', 'na', false, 'class', class(b));

    if ischar(a) || isstring(a) || ischar(b) || isstring(b)
        same = isequal(char(a), char(b));
        r.abs = double(~same); r.rel = double(~same); r.ulp = 0;
        r.verdict = ternstr(same, 'EXACT', 'FAIL');
        return;
    end
    if islogical(a) || islogical(b)
        same = isequal(logical(a), logical(b));
        r.abs = double(~same); r.rel = double(~same); r.ulp = 0;
        r.verdict = ternstr(same, 'EXACT', 'FAIL');
        return;
    end
    if isstruct(a) || isstruct(b) || iscell(a) || iscell(b)
        same = isequaln(a, b);
        r.abs = double(~same); r.rel = double(~same); r.ulp = 0;
        r.verdict = ternstr(same, 'EXACT', 'FAIL');
        r.class = 'struct/cell (isequaln)';
        return;
    end

    a = double(a); b = double(b);
    if ~isequal(size(a), size(b))
        r.verdict = 'FAIL'; r.abs = Inf; r.rel = Inf; r.class = 'size mismatch';
        return;
    end
    % NaNs must MATCH, not be ignored. A capture that turned a number into a
    % NaN would otherwise pass any tolerance test ever written.
    na = isnan(a); nb = isnan(b);
    if ~isequal(na, nb)
        r.verdict = 'FAIL'; r.abs = Inf; r.rel = Inf; r.class = 'NaN pattern differs';
        return;
    end
    r.na = any(na(:));
    a(na) = 0; b(nb) = 0;

    d = abs(a - b);
    r.abs = max(d(:));
    if isempty(r.abs), r.abs = 0; end
    den = max(1, max(abs(b(:))));
    r.rel = r.abs / den;
    scale = max(abs(b(:)));
    if isempty(scale) || scale == 0, scale = 1; end
    r.ulp = r.abs / eps(scale);

    if r.abs == 0
        r.verdict = 'EXACT';
    elseif r.ulp <= 8
        r.verdict = 'ULP';
    elseif r.rel <= t
        r.verdict = 'TOL';
    else
        r.verdict = 'FAIL';
    end
end

function t = fieldtol(tol, f)
    if isstruct(tol)
        if isfield(tol, f), t = tol.(f);
        elseif isfield(tol, 'default'), t = tol.default;
        else, t = 1e-12;
        end
    else
        t = tol;
    end
end

function s = ulpstr(u)
    if ~isfinite(u), s = '-'; elseif u == 0, s = '0';
    elseif u < 1e5, s = sprintf('%.0f', u);
    else, s = sprintf('%.0e', u);
    end
end

function s = mark(v)
    if strcmp(v, 'FAIL'), s = '   <<<'; else, s = ''; end
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
