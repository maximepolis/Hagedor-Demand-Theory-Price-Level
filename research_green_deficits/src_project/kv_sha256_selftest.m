function ok = kv_sha256_selftest(verbose)
% KV_SHA256_SELFTEST  Prove kv_sha256 before anything trusts it.
%
% A hand-written hash that is wrong does not fail loudly -- it produces
% plausible 64-character strings that never match a manifest, and the
% verification then reports the BASELINE as corrupt when the defect is in the
% checker. This project has already been burnt by checks that could not fail
% and by a hash (kv_hash) silently driven to zero by MATLAB's integer
% saturation, so kv_verify_baseline runs this first and refuses to proceed if
% it does not pass.
%
% The vectors are the published NIST ones plus the padding boundaries, which
% are where a from-scratch implementation actually goes wrong: 55 bytes (one
% block after padding), 56 bytes (spills into a second), and 64 bytes (an
% exact block, so padding adds a whole extra one).
%
% USAGE  kv_sha256_selftest          prints a table
%        ok = kv_sha256_selftest(false)

    if nargin < 1, verbose = true; end

    T = { ...
      uint8([]),                              'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'empty string';
      uint8('abc'),                           'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', '"abc" (NIST)';
      uint8(['abcdbcdecdefdefgefghfghighijhijk' 'ijkljklmklmnlmnomnopnopq']), ...
                                              '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1', '56 bytes, 2 blocks (NIST)';
      zeros(55,1,'uint8'),                    '02779466cdec163811d078815c633f21901413081449002f24aa3e80f0b88ef7', '55 zero bytes (pad edge)';
      zeros(56,1,'uint8'),                    'd4817aa5497628e7c77e6b606107042bbba3130888c5f47a375e6179be789fbb', '56 zero bytes (pad edge)';
      zeros(64,1,'uint8'),                    'f5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b', '64 zero bytes (exact block)';
      uint8(0:255),                           '40aff2e9d2d8922e47afd4648e6967497158785fbd1da870e7110266bf944880', 'all 256 byte values' };

    nbad = 0;
    if verbose
        fprintf('kv_sha256 self-test\n');
    end
    for i = 1:size(T, 1)
        got = kv_sha256(T{i,1});
        good = strcmp(got, T{i,2});
        nbad = nbad + ~good;
        if verbose
            fprintf('  %-6s %-28s %s\n', tern(good,'ok','WRONG'), T{i,3}, got(1:16));
            if ~good, fprintf('         expected %s\n', T{i,2}(1:16)); end
        end
    end

    % Determinism: the same bytes twice must give the same digest. Catches a
    % persistent-variable mistake, which would only show on the SECOND call
    % and so would pass a single-shot test.
    d1 = kv_sha256(uint8('abc')); d2 = kv_sha256(uint8('abc'));
    same = strcmp(d1, d2); nbad = nbad + ~same;
    if verbose
        fprintf('  %-6s %-28s\n', tern(same,'ok','WRONG'), 'repeat call is identical');
    end

    ok = (nbad == 0);
    if verbose
        fprintf('\nKV_SHA256 SELFTEST: %s\n', tern(ok, 'PASS', sprintf('FAIL (%d)', nbad)));
    end
end

function s = tern(c, a, b)
    if c, s = a; else, s = b; end
end
