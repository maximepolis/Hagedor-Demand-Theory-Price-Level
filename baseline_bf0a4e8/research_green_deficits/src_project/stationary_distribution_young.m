function [dist, distdiag] = stationary_distribution_young(polA, Pi, p)
% STATIONARY_DISTRIBUTION_YOUNG  Invariant distribution for a CONTINUOUS
% savings policy by the lottery method of Young (2010, JEDC): mass at (a_i,e)
% choosing a' = polA(i,e) is split between the two bracketing grid points
% with weights that preserve the mean, then pushed through Pi.
%
% Companion to solve_household_egm (whose policies are off-grid); the
% package's compute_stationary_distribution handles the VFI's on-grid index
% policies and is unchanged.
%
% INPUTS   polA (na x ne continuous a' values, within grid range), Pi, p
% OUTPUTS  dist (na x ne, sums to 1), distdiag (.converged .iters .dd)

    aG = p.aGrid(:); na = numel(aG); ne = size(Pi, 1);
    tol = 1e-12; maxit = 100000;

    % bracket indices k and left weights w, per state (vectorized)
    A  = min(max(polA, aG(1)), aG(end));
    k  = discretize(A, aG);                    % index of left bracket
    k  = min(max(k, 1), na - 1);
    w  = (aG(k + 1) - A) ./ (aG(k + 1) - aG(k));   % weight on aG(k)
    w  = min(max(w, 0), 1);

    % per-e sparse transition over assets: row i -> cols k(i,e), k(i,e)+1
    T = cell(1, ne);
    rows = (1:na)';
    for e = 1:ne
        T{e} = sparse([rows; rows], [k(:, e); k(:, e) + 1], ...
                      [w(:, e); 1 - w(:, e)], na, na);
    end

    dist = ones(na, ne) / (na * ne);
    distdiag = struct('converged', false, 'iters', 0, 'dd', NaN);
    for it = 1:maxit
        % assets move by the policy lottery, then e moves by Pi
        anext = zeros(na, ne);
        for e = 1:ne
            anext(:, e) = T{e}' * dist(:, e);
        end
        dnew = anext * Pi;
        dd = max(abs(dnew(:) - dist(:)));
        dist = dnew;
        if dd < tol
            distdiag.converged = true; break;
        end
    end
    distdiag.iters = it; distdiag.dd = dd;
    dist = dist / sum(dist(:));
end
