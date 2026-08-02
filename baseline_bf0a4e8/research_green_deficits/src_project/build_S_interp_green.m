function ad2 = build_S_interp_green(r, pg, taugrid, Dgrid)
% BUILD_S_INTERP_GREEN  Precompute S(1+r; tau, D) on a (tau, D) grid at a fixed
% real rate and return a bilinear interpolant. All project root-finding runs on
% this interpolant, so the expensive household solves happen once per real rate.
% (Since the interpolant covers the (tau, D) plane, a single build serves ALL
% values of theta_g, Gg, and both policy regimes at that rate.)
%
% INPUTS
%   r       : real interest rate.
%   pg      : project params.
%   taugrid : (optional) tau nodes; default pg.taugrid_S.
%   Dgrid   : (optional) D nodes; default pg.Dgrid_S.
%
% OUTPUT
%   ad2 : struct with
%         .r, .taugrid, .Dgrid, .Smat (ntau x nD), .Wmat (welfare at nodes),
%         .S_of(tau, D)  -> bilinear interpolation, NaN outside the grid or
%                           where nodes are infeasible,
%         .n_feasible    -> count of finite nodes.
%
% Used by: solve_green_steady_state, self_financing_decomposition,
%          optimal_policy_green. Theory object: the S function of Lemma 1.

    if nargin < 3 || isempty(taugrid), taugrid = pg.taugrid_S; end
    if nargin < 4 || isempty(Dgrid),   Dgrid   = pg.Dgrid_S;   end
    taugrid = taugrid(:)'; Dgrid = Dgrid(:)';

    % ---- feasibility-aware tau clamp -------------------------------------
    % With the incidence gradient (psi_inc > 0) the poorest household's
    % effective income falls steeply in D, so high-(tau, D) corners of a
    % rectangular grid become infeasible. Clamp the tau range at the lump-sum
    % bound evaluated at the MEDIAN damage node (corners beyond it are filled
    % below); this keeps the grid informative where equilibria live.
    psi = 0;
    if isfield(pg,'psi_inc') && ~isempty(pg.psi_inc), psi = pg.psi_inc; end
    Dmid = Dgrid(max(1, ceil(numel(Dgrid)/2)));
    ev   = pg.eGrid(:); wst = pg.stationary_e(:);
    floor_s = 0.05;
    if isfield(pg,'scale_floor') && ~isempty(pg.scale_floor), floor_s = pg.scale_floor; end
    if psi > 0
        chi   = (ev.^(-psi)) / (wst' * (ev.^(1-psi)));
        y_min = min(max(1 - Dmid*chi, floor_s) .* ev);
    else
        y_min = (1 - Dmid) * min(ev);
    end
    tau_bound = y_min + r*(-pg.abar) - 0.02;
    if max(taugrid) > tau_bound
        taugrid = linspace(min(taugrid), max(min(taugrid)+1e-3, tau_bound), ...
                           numel(taugrid));
        fprintf('  [tau grid clamped at %.3f by incidence feasibility]\n', tau_bound);
    end

    nt = numel(taugrid); nD = numel(Dgrid);
    Smat = nan(nt, nD);
    Wmat = nan(nt, nD);

    fprintf('  [S(tau,D) interpolant at r=%+.4f: %d x %d nodes]\n', r, nt, nD);
    for jD = 1:nD
        for it = 1:nt
            [Sij, oij] = S_green(r, taugrid(it), Dgrid(jD), pg);
            if isfinite(Sij), Smat(it, jD) = Sij; Wmat(it, jD) = oij.W; end
            fprintf('    node (tau=%+.3f, D=%.3f): S=%8.4f\n', ...
                    taugrid(it), Dgrid(jD), Smat(it, jD));
        end
    end

    % ---- fill remaining infeasible corner nodes (NaN) by nearest finite
    % value within the same D-row, so bilinear cells stay usable for the
    % SCAN only. Every reported equilibrium is re-solved exactly at the root
    % (resid_exact), so extrapolated cells cannot produce spurious results
    % silently. The fill count is reported.
    n_filled = 0;
    for jD = 1:nD
        row = Smat(:, jD);
        good = find(isfinite(row));
        bad  = find(~isfinite(row));
        if ~isempty(good) && ~isempty(bad)
            for ib = bad'
                [~, near] = min(abs(taugrid(good) - taugrid(ib)));
                Smat(ib, jD) = row(good(near));
                Wmat(ib, jD) = Wmat(good(near), jD);
                n_filled = n_filled + 1;
            end
        end
    end
    if n_filled > 0
        fprintf('  [%d infeasible corner node(s) filled by nearest-in-tau for scanning]\n', ...
                n_filled);
    end

    ad2 = struct();
    ad2.r        = r;
    ad2.taugrid  = taugrid;
    ad2.Dgrid    = Dgrid;
    ad2.Smat     = Smat;
    ad2.Wmat     = Wmat;
    ad2.n_filled = n_filled;
    ad2.n_feasible = nnz(isfinite(Smat)) - n_filled;

    % Bilinear interpolation; interp2 needs meshgrid orientation (D on rows).
    [TT, DD] = meshgrid(taugrid, Dgrid);       % nD x nt
    Sq = Smat';                                % nD x nt
    ad2.S_of = @(tau, D) interp2(TT, DD, Sq, tau, D, 'linear', NaN);

    if ad2.n_feasible < 4
        warning('build_S_interp_green:sparse', ...
            'Only %d feasible S(tau,D) nodes; interpolant unreliable.', ...
            ad2.n_feasible);
    end
end
