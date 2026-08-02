function gs = kv_grid_state(p, varargin)
% KV_GRID_STATE  What widening, if any, a parameter struct's grids already
% carry -- read from an explicit stamp when there is one, inferred from the
% ceilings when there is not.
%
% THE BUG THIS EXISTS TO MAKE IMPOSSIBLE. main_twoasset_ownership_kv with
% REGRID = true widens the grids and then SAVES THE WIDENED p into
% output/twoasset_ownership_kv.mat. Three downstream drivers --
% main_preferred_signal_noise, main_preferred_decomposition and
% main_kv_residual_scan -- then load that p and apply "the widening the scan
% verified" to it. Before the REGRID run that was correct. After it, every one
% of them widens an already-widened grid:
%
%     kmax : 60 -> 360 -> 2160        (kfac = 6 applied twice)
%     bmax : 12 ->  96 ->  768        (bfac = 8 applied twice)
%
% and those are exactly the numbers main_preferred_signal_noise printed
% ("kmax 2160.0, bmax 768.00") before failing. Nothing warned, because the
% .mat carried no record of its own provenance and the widening routine was
% written as an OPERATION ("multiply the ceiling by kfac") rather than as a
% TARGET STATE ("be at kfac relative to the calibration base"). An operation
% applied twice is a different grid; a target state applied twice is the same
% grid. See KV_ENSURE_WIDENED, which is the interface callers should use.
%
% INFERENCE, when there is no stamp. The factor is just the ratio of the
% ceiling to the calibration base, so it is exact and needs no guessing:
%       kfac = p.kGrid(end) / base.kmax,   bfac = p.bGrid(end) / base.bmax.
% A ratio of 1 means unwidened, 6 means widened once at kfac = 6, and 36
% means the accident above. Inference is reported as such: `gs.source` says
% 'stamp' or 'inferred', and a caller that needs certainty can insist.
%
% INPUT   p          params with .kGrid, .bGrid (and ideally .grid_state)
%         'base', B  optional override of kv_grid_base()
%
% OUTPUT  gs.kfac, gs.bfac   applied factors relative to the calibration base
%         gs.kmax, gs.bmax, gs.xmax    current ceilings
%         gs.nk, gs.nb, gs.nx, gs.nac  current node counts
%         gs.source          'stamp' | 'inferred'
%         gs.base            the base used
%         gs.consistent      stamp and inference agree (true if inferred)
%         gs.double_widened  a factor is a perfect square of a plausible
%                            single factor AND exceeds it -- the specific
%                            accident above, flagged by name

    ip = inputParser; ip.KeepUnmatched = true;
    addParameter(ip, 'base', kv_grid_base());
    parse(ip, varargin{:});
    base = ip.Results.base;

    assert(isstruct(p) && isfield(p,'kGrid') && isfield(p,'bGrid'), ...
        'kv_grid_state: p needs kGrid and bGrid');

    kmax = p.kGrid(end); bmax = p.bGrid(end);
    kfac_inf = kmax / base.kmax;
    bfac_inf = bmax / base.bmax;

    gs = struct('kfac', kfac_inf, 'bfac', bfac_inf, ...
                'kmax', kmax, 'bmax', bmax, 'xmax', NaN, ...
                'nk', numel(p.kGrid), 'nb', numel(p.bGrid), ...
                'nx', NaN, 'nac', NaN, ...
                'source', 'inferred', 'base', base, ...
                'consistent', true, 'double_widened', false, ...
                'kfac_inferred', kfac_inf, 'bfac_inferred', bfac_inf);
    if isfield(p,'xGridA'),  gs.xmax = p.xGridA(end); gs.nx  = numel(p.xGridA); end
    if isfield(p,'acGrid'),  gs.nac = numel(p.acGrid); end

    if isfield(p, 'grid_state') && isstruct(p.grid_state) ...
            && isfield(p.grid_state,'kfac') && isfield(p.grid_state,'bfac')
        st = p.grid_state;
        gs.source = 'stamp';
        gs.kfac = st.kfac; gs.bfac = st.bfac;
        % A stamp that disagrees with the ceilings is worse than no stamp:
        % it is a false record. Report it rather than trusting either side.
        gs.consistent = near(st.kfac, kfac_inf) && near(st.bfac, bfac_inf);
    end

    % Name the specific accident. A factor that is the square of an integer
    % >= 2 is the signature of an operation applied twice; it is not proof,
    % but it is the only reading anyone has ever needed, and saying so by
    % name beats leaving the reader to divide 2160 by 60.
    gs.double_widened = is_square_gt1(gs.kfac) || is_square_gt1(gs.bfac);
end

% ---------------------------------------------------------------------
function t = near(a, b)
    t = abs(a - b) <= 1e-8 * max(1, abs(b));
end

function t = is_square_gt1(f)
    t = false;
    if ~isfinite(f) || f <= 1.5, return; end
    r = sqrt(f);
    t = abs(r - round(r)) < 1e-8 && round(r) >= 2;
end
