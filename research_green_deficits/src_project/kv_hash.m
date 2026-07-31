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
        md.update(b);
        d = typecast(md.digest(), 'uint8');
        h = lower(reshape(dec2hex(d, 2)', 1, []));
    catch
        h = '';
    end
    if isempty(h)
        % The fallback loops in MATLAB, so it is capped: the first 64 KiB
        % plus the total length. Everything this project hashes (grids,
        % scalars) is a few KiB, so the cap never bites here; it exists so a
        % careless caller cannot turn a key into a minute of compute.
        n = numel(b);
        bb = b(1:min(n, 65536));
        h = [fnv1a(bb, uint64(14695981039346656037)) ...
             fnv1a([flipud(bb); typecast(uint64(n),'uint8')'], uint64(1099511628211))];
    end
end

function s = fnv1a(b, seed)
    p = uint64(1099511628211); hv = seed;
    for i = 1:numel(b)
        hv = bitxor(hv, uint64(b(i)));
        hv = mod(hv * p, uint64(18446744073709551615));
    end
    s = lower(dec2hex(hv, 16));
end
