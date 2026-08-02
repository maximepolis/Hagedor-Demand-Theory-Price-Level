function [p, R] = kv_ensure_widened(p, kfac_target, bfac_target, ref, tee)
% KV_ENSURE_WIDENED  Put the grids AT a widening, rather than applying one.
%
% This is the interface every driver should call. kv_widen_grids performs an
% OPERATION -- multiply the ceilings by (kfac, bfac) -- and an operation is
% not idempotent: applying it to a grid that already carries it produces
% kfac^2, silently. That is what happened after REGRID started saving the
% widened grid to output/twoasset_ownership_kv.mat, and it is what produced
% kmax = 2160 and bmax = 768 (60x36 and 12x64) in main_preferred_signal_noise.
%
% This function is a TARGET STATE: "be at (kfac, bfac) relative to the
% calibration base". Calling it twice is the same as calling it once. The
% three cases are decided, reported, and never guessed:
%
%   already at the target      -> no-op, R.action = 'ALREADY'
%   at the calibration base    -> widen once, R.action = 'APPLIED'
%   at neither                 -> ERROR, R.action = 'INCOMPATIBLE'
%
% The third case is deliberately fatal. A grid at kfac = 36 when the caller
% wants 6 cannot be repaired by dividing: the curvature exponent was refit
% against the wrong ceiling, so the interior node placement is not the
% placement kfac = 6 would have produced, and the calibrated beta and chi_b
% belong to neither grid. The only correct response is to rebuild from the
% base, which is a decision for the caller, not for this function.
%
% INPUT   p            params carrying .kGrid, .bGrid, .xGridA, .acGrid
%         kfac_target  target illiquid widening (1 = calibration base)
%         bfac_target  target liquid widening
%         ref          passed to kv_widen_grids: .r_b .q .d (+ kref/bref/...)
%         tee          optional printf-like handle for the report
%
% OUTPUT  p  at the target state, stamped with p.grid_state
%         R  .action .before .after .W (the kv_widen_grids report, if it ran)

    if nargin < 5 || isempty(tee), tee = @(varargin) fprintf(varargin{:}); end
    if isempty(kfac_target), kfac_target = 1; end
    if isempty(bfac_target), bfac_target = 1; end

    gs0 = kv_grid_state(p);
    R = struct('action','', 'before', gs0, 'after', [], 'W', struct('changed',false));

    at_target = near(gs0.kfac, kfac_target) && near(gs0.bfac, bfac_target);
    at_base   = near(gs0.kfac, 1)           && near(gs0.bfac, 1);

    if at_target
        R.action = 'ALREADY';
        tee(['grids ALREADY at kfac=%.4g bfac=%.4g (kmax %.1f, bmax %.2f), from %s;\n' ...
             '  no widening applied. Re-applying it would give kfac=%.4g.\n'], ...
            gs0.kfac, gs0.bfac, gs0.kmax, gs0.bmax, gs0.source, gs0.kfac*kfac_target);
        p = stamp(p, gs0.kfac, gs0.bfac, 'kv_ensure_widened:already');
        R.after = kv_grid_state(p);
        return;
    end

    if at_base
        [p, W] = kv_widen_grids(p, kfac_target, setfield_(ref, 'bfac', bfac_target)); %#ok<SFLD>
        p = stamp(p, kfac_target, bfac_target, 'kv_ensure_widened:applied');
        R.action = 'APPLIED'; R.W = W; R.after = kv_grid_state(p);
        tee(['grids widened from the calibration base to kfac=%.4g bfac=%.4g:\n' ...
             '  kmax %.1f -> %.1f, bmax %.2f -> %.2f, xmax %.1f -> %.1f\n'], ...
            kfac_target, bfac_target, W.kmax0, W.kmax, W.bmax0, W.bmax, W.xmax0, W.xmax);
        return;
    end

    R.action = 'INCOMPATIBLE';
    base = gs0.base;
    extra = '';
    if gs0.double_widened
        extra = sprintf(['\n  This is the DOUBLE-WIDENING accident: %g = %g^2. The grid was widened\n' ...
                         '  once when it was calibrated (REGRID = true saves the widened p) and again\n' ...
                         '  by this driver. Load a base-grid calibration, or run with the factors\n' ...
                         '  already applied and pass kfac = %g here.'], ...
                        gs0.kfac, sqrt(gs0.kfac), gs0.kfac);
    end
    error('kv_ensure_widened:incompatible', ...
        ['grids are at kfac=%.6g bfac=%.6g (kmax %.1f, bmax %.2f; source %s) but the\n' ...
         'caller asked for kfac=%.6g bfac=%.6g. The calibration base is kmax %.1f, bmax %.2f.\n' ...
         'Refusing to widen: a grid at the wrong factor cannot be corrected by rescaling,\n' ...
         'because the curvature exponent was refit against a different ceiling and the\n' ...
         'calibrated beta and chi_b belong to neither grid.%s'], ...
        gs0.kfac, gs0.bfac, gs0.kmax, gs0.bmax, gs0.source, ...
        kfac_target, bfac_target, base.kmax, base.bmax, extra);
end

% ---------------------------------------------------------------------
function p = stamp(p, kfac, bfac, by)
% Record provenance IN the struct, so that a p written to a .mat carries its
% own history and the next reader does not have to infer it from a ceiling.
    p.grid_state = struct('kfac', kfac, 'bfac', bfac, ...
                          'kmax', p.kGrid(end), 'bmax', p.bGrid(end), ...
                          'base', kv_grid_base(), 'stamped_by', by);
    if isfield(p,'xGridA'), p.grid_state.xmax = p.xGridA(end); end
end

function s = setfield_(s, f, v)
    if ~isstruct(s), s = struct(); end
    s.(f) = v;
end

function t = near(a, b)
    t = abs(a - b) <= 1e-8 * max(1, abs(b));
end
