function h = kv_hash(varargin)
% KV_HASH  Deterministic hex digest of numeric / char / logical / struct /
% cell content, used to key cached scan results by (alpha, q, grid,
% calibration) rather than by position in a loop.
%
% WHY CONTENT AND NOT AN INDEX. A cache keyed by loop index silently serves
% stale results the moment a grid or a parameter changes, which is exactly
% the failure a cache is supposed to prevent. Keying on the full content of
% the state grids, the calibrated parameters and the economy-level constants
% means a widened k-grid, a different chi_b, or a different alpha produces a
% different key and therefore a recompute, with no bookkeeping to get wrong.
%
% Struct fields are serialised in SORTED name order, and the field name goes
% into the digest alongside its value, so two structs with the same values
% under different names do not collide and field-order changes do not
% spuriously invalidate the cache.
%
% MD5 via the JVM when it is there; a 128-bit FNV-1a pair otherwise, so a
% -nojvm session still gets a usable (if weaker) key.

    b = uint8([]);
    for i = 1:numel(varargin)
        b = [b; ser(varargin{i})]; %#ok<AGROW>
    end
    h = digest(b);
end

function b = ser(x)
    if isstruct(x)
        if numel(x) ~= 1
            b = uint8([]);
            for i = 1:numel(x), b = [b; ser(x(i))]; end %#ok<AGROW>
            return;
        end
        f = sort(fieldnames(x));
        b = uint8([]);
        for i = 1:numel(f)
            b = [b; uint8(f{i}(:)); ser(x.(f{i}))]; %#ok<AGROW>
        end
    elseif iscell(x)
        b = uint8([]);
        for i = 1:numel(x), b = [b; ser(x{i})]; end %#ok<AGROW>
    elseif ischar(x) || isstring(x)
        b = uint8(char(x(:)));
    elseif islogical(x)
        b = uint8(x(:));
    elseif isnumeric(x)
        v = double(x(:));
        v(isnan(v)) = -realmax;              % NaN is not equal to itself
        b = typecast(v, 'uint8')';
        b = b(:);
    elseif isa(x, 'function_handle')
        b = uint8(func2str(x));  b = b(:);
    else
        b = uint8([]);                       % unhashable: contributes nothing
    end
    b = b(:);
end

function h = digest(b)
    h = '';
    try
        md = java.security.MessageDigest.getInstance('MD5');
        md.update(typecast(b, 'int8'));   % Java bytes are SIGNED; uint8 > 127
        d = typecast(md.digest(), 'uint8');
        h = lower(reshape(dec2hex(d, 2)', 1, []));
    catch
        h = '';
    end
    if isempty(h)
        h = poly_digest(b);
    end
    % A digest that is constant carries no information, and a key that is
    % constant silently maps every configuration to the SAME cache entry --
    % the exact failure content addressing exists to prevent. The first
    % version of this file did precisely that: it fell back to a 64-bit FNV
    % whose multiply SATURATES in MATLAB uint8/64 arithmetic (a*b pins at
    % intmax rather than wrapping), so mod(intmax, intmax) drove the state to
    % zero and every key came out '0000000000000000'. Fail loudly instead.
    assert(numel(unique(h)) > 1, 'kv_hash: degenerate digest "%s"', h);
end

function h = poly_digest(b)
% Four independent Horner hashes modulo distinct Mersenne-ish primes, in
% DOUBLE arithmetic. Every intermediate stays below 2^53 (hv < p < 2^31
% times a base < 2^8, plus a byte), so each step is exact -- unlike uint64
% multiplication, which saturates instead of wrapping and destroys the state.
% Capped at the first 64 KiB plus the length, because this loops in MATLAB.
% Everything this project hashes is a few KiB, so the cap never bites; it is
% there so a careless caller cannot turn a key into a minute of compute.
    n = numel(b);
    v = double(b(1:min(n, 65536)));
    P = [2147483647 2147483629 2147483587 2147483579];
    B = [131 137 139 149];
    h = '';
    for j = 1:4
        hv = mod(1469598103 + n, P(j));
        for i = 1:numel(v)
            hv = mod(hv*B(j) + v(i) + 1, P(j));
        end
        h = [h lower(dec2hex(hv, 8))]; %#ok<AGROW>
    end
end
