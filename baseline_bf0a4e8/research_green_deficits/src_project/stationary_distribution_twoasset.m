function [dist, diag] = stationary_distribution_twoasset(polB, polK, rb, q, d, tau, p)
% STATIONARY_DISTRIBUTION_TWOASSET  Invariant distribution over (x, e) for
% the frictionless two-asset household (two-asset build plan, Step 0).
%
% Unlike the one-asset case, next-period cash-on-hand depends on the REALIZED
% income state e':
%     x'(s, e') = y(e') - tau + (1+rb) b'(s) + (q+d) k'(s),
% so the forward map scatters each node's mass across e'-specific x' targets
% with a Young (2010) lottery on the x-grid per (node, e') pair.
%
% INPUTS  polB, polK : (nx x ne) policies from solve_household_twoasset.
%         rb, q, d, tau, p : as in the solver (p.xGrid, p.eGrid, p.Pi,
%                            p.tol_dist, p.maxit_dist).
% OUTPUT  dist : (nx x ne) invariant distribution (sums to 1).
%         diag : .converged .iters .supnorm
%
% STATUS: scaffolded, untested pending a MATLAB run.

    nx = numel(p.xGrid); ne = numel(p.eGrid);
    xG = p.xGrid(:);
    ynet = p.eGrid(:)' - tau;                       % 1 x ne'
    Rb = 1 + rb;

    % precompute lottery targets: for each (ix, ie) node and each e', the
    % lower node index and upper weight of x'(ix, ie, e') on the x-grid
    lo_idx = zeros(nx, ne, ne); w_hi = zeros(nx, ne, ne);
    for ie = 1:ne
        base = Rb*polB(:, ie) + (q + d)*polK(:, ie);      % nx x 1
        for jep = 1:ne
            xp = ynet(jep) + base;
            idx = discretize(xp, xG);
            idx(~isfinite(idx)) = nx - 1;                 % clamp out-of-range
            idx = min(max(idx, 1), nx - 1);
            w = (xp - xG(idx)) ./ (xG(idx+1) - xG(idx));
            w = min(max(w, 0), 1);
            lo_idx(:, ie, jep) = idx;  w_hi(:, ie, jep) = w;
        end
    end

    dist = ones(nx, ne) / (nx*ne);
    diag = struct('converged', false, 'iters', 0, 'supnorm', Inf);
    for it = 1:p.maxit_dist
        nxt = zeros(nx, ne);
        for ie = 1:ne
            col = dist(:, ie);
            if ~any(col), continue; end
            for jep = 1:ne
                pm = p.Pi(ie, jep);
                if pm == 0, continue; end
                idx = lo_idx(:, ie, jep); w = w_hi(:, ie, jep);
                m = col * pm;
                nxt(:, jep) = nxt(:, jep) ...
                    + accumarray(idx,   m .* (1-w), [nx 1]) ...
                    + accumarray(idx+1, m .* w,     [nx 1]);
            end
        end
        dv = max(abs(nxt(:) - dist(:)));
        dist = nxt;
        diag.iters = it; diag.supnorm = dv;
        if dv < p.tol_dist, diag.converged = true; break; end
    end
    dist = dist / sum(dist(:));
end
