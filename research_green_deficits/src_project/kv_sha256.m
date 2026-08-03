function h = kv_sha256(b)
% KV_SHA256  SHA-256 in pure MATLAB. No JVM, no toolbox, no shell-out.
%
% WHY NOT java.security.MessageDigest. It is unavailable: R2025b reported
% "SHA-256 is unavailable (no JVM)" and the baseline verification could not
% run at all. Making the integrity gate depend on an optional runtime meant a
% correct baseline could not be certified, which is the wrong failure mode for
% a check that exists to let work proceed.
%
% THE ARITHMETIC TRAP THIS AVOIDS. MATLAB's integer types SATURATE rather than
% wrap: uint32(4294967295) + uint32(1) is 4294967295, not 0. SHA-256 is
% defined on addition modulo 2^32, so every addition here is done in DOUBLE
% and reduced with mod(). Doubles represent integers exactly to 2^53 and the
% largest sum taken is five terms below 2^32 (about 2.1e10), so the
% intermediate is exact. An earlier hash in this project (kv_hash) was silently
% driven to zero by exactly this saturation, so it is worth being explicit.
%
% Bit operations use bitand/bitxor/bitshift on uint32, which operate within the
% class and discard shifted-out bits -- that is the behaviour a rotate needs.
%
% SELF-TEST. `kv_sha256('selftest')` is NOT how you test it; call
% kv_sha256_selftest, which checks the published NIST vectors plus a
% multi-block case. The implementation proves itself before the verifier
% trusts it.
%
% INPUT   b  uint8 vector (or char, which is converted bytewise)
% OUTPUT  h  64-character lowercase hex digest

    persistent K H0
    if isempty(K)
        Khex = [ ...
        '428a2f98';'71374491';'b5c0fbcf';'e9b5dba5';'3956c25b';'59f111f1'; ...
        '923f82a4';'ab1c5ed5';'d807aa98';'12835b01';'243185be';'550c7dc3'; ...
        '72be5d74';'80deb1fe';'9bdc06a7';'c19bf174';'e49b69c1';'efbe4786'; ...
        '0fc19dc6';'240ca1cc';'2de92c6f';'4a7484aa';'5cb0a9dc';'76f988da'; ...
        '983e5152';'a831c66d';'b00327c8';'bf597fc7';'c6e00bf3';'d5a79147'; ...
        '06ca6351';'14292967';'27b70a85';'2e1b2138';'4d2c6dfc';'53380d13'; ...
        '650a7354';'766a0abb';'81c2c92e';'92722c85';'a2bfe8a1';'a81a664b'; ...
        'c24b8b70';'c76c51a3';'d192e819';'d6990624';'f40e3585';'106aa070'; ...
        '19a4c116';'1e376c08';'2748774c';'34b0bcb5';'391c0cb3';'4ed8aa4a'; ...
        '5b9cca4f';'682e6ff3';'748f82ee';'78a5636f';'84c87814';'8cc70208'; ...
        '90befffa';'a4506ceb';'bef9a3f7';'c67178f2'];
        K  = uint32(hex2dec(Khex));
        H0 = uint32(hex2dec(['6a09e667';'bb67ae85';'3c6ef372';'a54ff53a'; ...
                             '510e527f';'9b05688c';'1f83d9ab';'5be0cd19']));
    end

    if ischar(b) || isstring(b), b = uint8(char(b)); end
    b = uint8(b(:));
    L = numel(b);

    % ---- padding: 0x80, zeros to 56 mod 64, then the 64-bit big-endian
    % message length IN BITS.
    nzero = mod(56 - mod(L + 1, 64), 64);
    bitlen = L * 8;                      % exact in double for any real file
    lenb = zeros(8, 1, 'uint8');
    v = bitlen;
    for i = 8:-1:1
        lenb(i) = uint8(mod(v, 256));
        v = floor(v / 256);
    end
    msg = [b; uint8(128); zeros(nzero, 1, 'uint8'); lenb];

    nblk = numel(msg) / 64;
    Mall = reshape(msg, 64, nblk);
    H = H0;

    for blk = 1:nblk
        % Big-endian 32-bit words. typecast reads little-endian on every
        % platform MATLAB supports, so swapbytes gives the big-endian words
        % SHA-256 is defined on.
        W = zeros(64, 1, 'uint32');
        W(1:16) = swapbytes(typecast(Mall(:, blk), 'uint32'));
        for t = 17:64
            x  = W(t-15);
            s0 = bitxor(bitxor(rotr(x, 7), rotr(x, 18)), bitshift(x, -3));
            y  = W(t-2);
            s1 = bitxor(bitxor(rotr(y, 17), rotr(y, 19)), bitshift(y, -10));
            W(t) = add32(W(t-16), s0, W(t-7), s1);
        end

        a = H(1); bq = H(2); c = H(3); d = H(4);
        e = H(5); f  = H(6); g = H(7); hq = H(8);
        for t = 1:64
            S1  = bitxor(bitxor(rotr(e, 6), rotr(e, 11)), rotr(e, 25));
            ch  = bitxor(bitand(e, f), bitand(bitcmp(e), g));
            T1  = add32(hq, S1, ch, K(t), W(t));
            S0  = bitxor(bitxor(rotr(a, 2), rotr(a, 13)), rotr(a, 22));
            maj = bitxor(bitxor(bitand(a, bq), bitand(a, c)), bitand(bq, c));
            T2  = add32(S0, maj);
            hq = g; g = f; f = e; e = add32(d, T1);
            d  = c; c = bq; bq = a; a = add32(T1, T2);
        end
        H = uint32([add32(H(1), a);  add32(H(2), bq); add32(H(3), c);  add32(H(4), d); ...
                    add32(H(5), e);  add32(H(6), f);  add32(H(7), g);  add32(H(8), hq)]);
    end

    h = lower(sprintf('%08x', H));
end

% ---------------------------------------------------------------------
function y = rotr(x, n)
% Rotate right within 32 bits. bitshift on uint32 discards bits shifted out,
% which is what makes the two halves combine into a rotation.
    y = bitor(bitshift(x, -n), bitshift(x, 32 - n));
end

function y = add32(varargin)
% Addition modulo 2^32, done in DOUBLE because MATLAB's uint32 saturates.
    s = 0;
    for i = 1:nargin
        s = s + double(varargin{i});
    end
    y = uint32(mod(s, 4294967296));
end
