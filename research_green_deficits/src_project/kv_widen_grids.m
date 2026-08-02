function [p, W] = kv_widen_grids(p, kfac, ref)
% KV_WIDEN_GRIDS  Widen the top of the illiquid-asset state space of the
% preferred (ownership + illiquidity) economy, holding the lower bounds, the
% node counts, and every calibrated parameter fixed.
%
% WHY. The residual scan found no path dependence (up-vs-down hysteresis
% exactly 0) and no household-convergence problem (VFI dV < 1e-6), but it
% found 2.8e-3 of mass in the top two nodes of BOTH the k- and the b-grid,
% about 29 times the 1e-4 tolerance. With aggregate tree supply normalised to
% Kbar = 1, 2.8e-3 of mass sitting at k ~ 56 contributes ~0.16 to S_k: a
% sixth of the aggregate is pinned against the boundary and cannot respond to
% q, which is exactly why the reduced tree residual would not clear. The
% b-grid is the same story in miniature: 2.9e-3 at b ~ 11.5 is 0.033 of an
% S_b of 0.299, a ninth of liquid demand held rigid against a wall.
%
% THERE ARE TWO CEILINGS AND ONLY ONE OF THEM IS BINDING TODAY. The adjuster
% does not choose k' on kGrid; it chooses an outlay a on acGrid and a liquid
% share s on sGrid, so its tree purchase is capped at
%
%       k'_max = acGrid(end) * (1 - sGrid(1)) / q,
%
% and separately every candidate is clamped onto the state grid by
% Kcl = min(Kc, kGrid(end)) before its continuation value is read. At the
% calibrated q = 1.518 the outlay ceiling sits at 386.4*0.955/1.518 = 243,
% four times above kmax = 60, so today it is the STATE grid that truncates
% and widening kmax is the right move. That ordering reverses once kmax
% passes ~243: the outlay ceiling becomes binding and widening kmax alone
% would move a wall that is no longer the one in the way. This routine
% therefore sizes xmax (hence acGrid) from the widened kmax and reports the
% attainable k' before and after, so which ceiling binds is never assumed.
%
% NODE COUNT IS FIXED, SO CURVATURE HAS TO ABSORB THE WIDENING. Rebuilding
% k_j = kmax*u_j^g with the same g and a larger kmax rescales every interior
% node by the same factor, which would coarsen the region where essentially
% all of the mass lives (mean k = 1) by exactly the widening factor. Instead
% the exponent is re-solved so that the number of nodes below a reference
% level k_ref is UNCHANGED:
%
%       g' = g * log((k_ref-lo)/(kmax_new-lo)) / log((k_ref-lo)/(kmax_old-lo)),
%
% which holds the sub-k_ref node placement fixed and spends the widening
% entirely on the sparse tail. The cost is real and is reported: resolution
% between k_ref and the new ceiling falls by the widening factor. That is the
% correct trade -- a coarse tail that the distribution can reach is strictly
% better than a fine wall it cannot pass.
%
% INPUT   p     : calibrated params (bGrid, kGrid, xGridA, acGrid, sGrid, eGrid)
%         kfac  : multiplicative widening of kmax (>= 1)
%         ref   : struct with fields
%                   r_b  (required) bond return, for the cash-on-hand bound
%                   q    (required) reference tree price
%                   d    (required) reference dividend
%                   kref     (opt, default 5)    preserve node count below this k
%                   bfac     (opt, default 1)    widening of bmax; 1 = untouched
%                   bref     (opt, default 3)    preserve node count below this b
%                   qhi      (opt, default 1.15) safety factor on q
%                   dhi      (opt, default 1.30) safety factor on d
%                   headroom (opt, default 1.02) slack on the implied xmax
%
% OUTPUT  p (widened) and W, a report struct suitable for printing.
%
% THIS FUNCTION IS AN OPERATION, NOT A TARGET STATE, AND SO IS NOT
% IDEMPOTENT. Applying it twice gives kfac^2. That is not hypothetical: once
% REGRID began saving the widened p, three drivers loaded it and applied the
% verified factors again, giving kmax = 60*36 = 2160 and bmax = 12*64 = 768.
% CALL KV_ENSURE_WIDENED INSTEAD unless you specifically want to compose a
% widening onto whatever the grid already carries. The cumulative factor
% relative to the calibration base is recorded in p.grid_state either way, so
% the next reader is never left inferring it from a ceiling.

    if nargin < 2 || isempty(kfac), kfac = 1; end
    if nargin < 3, ref = struct(); end
    gf = @(f,dv) getdef(ref, f, dv);
    kref = gf('kref', 5); bfac = gf('bfac', 1); bref = gf('bref', 3);
    qhi = gf('qhi', 1.15); dhi = gf('dhi', 1.30); hr = gf('headroom', 1.02);
    assert(isfield(ref,'r_b') && isfield(ref,'q') && isfield(ref,'d'), ...
        'kv_widen_grids: ref needs r_b, q and d');
    assert(kfac >= 1 && bfac >= 1, 'kv_widen_grids: factors must be >= 1');

    nk = numel(p.kGrid); nb = numel(p.bGrid);
    nx = numel(p.xGridA); nac = numel(p.acGrid);
    [klo, kmax0, gk] = kv_grid_curv(p.kGrid);
    [blo, bmax0, gb] = kv_grid_curv(p.bGrid);
    [xlo, xmax0, gx] = kv_grid_curv(p.xGridA);
    [alo, amax0, ga] = kv_grid_curv(p.acGrid);
    s1 = min(p.sGrid(:)); ymax = max(p.eGrid(:));
    fac_ac = amax0 / xmax0;                     % 0.92 in the calibration

    W = struct('kmax0', kmax0, 'bmax0', bmax0, 'xmax0', xmax0, ...
               'gk0', gk, 'gb0', gb, 'gx0', gx, ...
               'kprime_max0', amax0*(1-s1)/ref.q, 'changed', false);
    if kfac == 1 && bfac == 1
        W.kmax = kmax0; W.bmax = bmax0; W.xmax = xmax0;
        W.gk = gk; W.gb = gb; W.gx = gx;
        W.kprime_max = W.kprime_max0;
        W.n_below_kref0 = nbelow(p.kGrid, kref); W.n_below_kref = W.n_below_kref0;
        base = kv_grid_base();
        p.grid_state = struct('kfac', kmax0/base.kmax, 'bfac', bmax0/base.bmax, ...
                              'kmax', kmax0, 'bmax', bmax0, 'xmax', xmax0, ...
                              'base', base, 'stamped_by', 'kv_widen_grids:noop');
        W.kfac_cumulative = p.grid_state.kfac;
        W.bfac_cumulative = p.grid_state.bfac;
        W.composed_onto_widened = false;
        return;
    end

    kmax = kfac * kmax0;
    bmax = bfac * bmax0;

    % xmax must satisfy BOTH bounds:
    %  (i)  the adjuster can actually buy k' = kmax:  fac_ac*xmax*(1-s1)/qhi >= kmax
    %  (ii) cash-on-hand at the top of the state space is on the grid:
    %       (1+r_b)*bmax + (qhi+dhi)*kmax + ymax
    qh = qhi*ref.q; dh = dhi*ref.d;
    x_port = kmax * qh / (fac_ac * (1 - s1));
    x_coh  = (1+ref.r_b)*bmax + (qh + dh)*kmax + ymax;
    xmax = hr * max(x_port, x_coh);
    xmax = max(xmax, xmax0);                     % never shrink

    % reference cash-on-hand: the position of a household holding k = kref
    xref = (1+ref.r_b)*min(bref, bmax0) + (qh + dh)*kref + ymax;

    gkN = recurv(gk, klo, kmax0, kmax, kref);
    gxN = recurv(gx, xlo, xmax0, xmax, xref);
    gaN = recurv(ga, alo, amax0, fac_ac*xmax, fac_ac*xref);
    gbN = recurv(gb, blo, bmax0, bmax, bref);

    W.n_below_kref0 = nbelow(p.kGrid, kref);
    W.n_below_bref0 = nbelow(p.bGrid, bref);

    p.kGrid  = kv_grid_build(klo, kmax, gkN, nk);
    p.xGridA = kv_grid_build(xlo, xmax, gxN, nx);
    p.acGrid = kv_grid_build(alo, fac_ac*xmax, gaN, nac);
    if bfac > 1, p.bGrid = kv_grid_build(blo, bmax, gbN, nb); end

    W.changed = true;
    W.kmax = kmax; W.bmax = bmax; W.xmax = xmax;
    W.gk = gkN; W.gb = gbN; W.gx = gxN; W.ga = gaN;
    W.kprime_max = fac_ac*xmax*(1-s1)/ref.q;
    W.n_below_kref = nbelow(p.kGrid, kref);
    W.n_below_bref = nbelow(p.bGrid, bref);
    W.kref = kref; W.bref = bref;
    W.bind_portfolio = x_port >= x_coh;          % which bound set xmax

    % Cumulative provenance, relative to the CALIBRATION base rather than to
    % whatever this call happened to receive. W.kmax0 is the input ceiling and
    % answers "what did this call do"; grid_state.kfac answers "where is this
    % grid", which is the question a downstream driver actually has.
    base = kv_grid_base();
    p.grid_state = struct('kfac', kmax/base.kmax, 'bfac', bmax/base.bmax, ...
                          'kmax', kmax, 'bmax', bmax, 'xmax', xmax, ...
                          'base', base, 'stamped_by', 'kv_widen_grids');
    W.kfac_cumulative = p.grid_state.kfac;
    W.bfac_cumulative = p.grid_state.bfac;
    W.composed_onto_widened = (kmax0 > base.kmax*(1+1e-8)) || (bmax0 > base.bmax*(1+1e-8));
end

% ---------------------------------------------------------------------
function gN = recurv(g, lo, hi0, hi1, xref)
% exponent that leaves the node count below xref unchanged when the ceiling
% moves hi0 -> hi1. Falls back to the original exponent if xref is not
% strictly interior to both grids.
    gN = g;
    if ~(hi1 > hi0), return; end
    a0 = (xref - lo)/(hi0 - lo); a1 = (xref - lo)/(hi1 - lo);
    if ~(a0 > 0 && a0 < 1 && a1 > 0 && a1 < 1), return; end
    gN = g * log(a1)/log(a0);
    if ~isfinite(gN) || gN <= 0, gN = g; end
end

function n = nbelow(x, r)
    n = sum(x(:) <= r);
end

function v = getdef(s, f, dv)
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end
