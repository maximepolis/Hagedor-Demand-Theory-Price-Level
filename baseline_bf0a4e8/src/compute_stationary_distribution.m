function [dist, distdiag] = compute_stationary_distribution(polA_idx, Pi, params)
% COMPUTE_STATIONARY_DISTRIBUTION  Invariant distribution over joint states
% (a,e) induced by the household policy and the income Markov chain.
%
% This is the actual implementation. The public entry point required by the
% replication spec, stationary_distribution.m, is a thin wrapper around this
% function. The implementation carries a UNIQUE name so that internal solver
% calls can never be shadowed by a stale stationary_distribution.m from an
% older prototype sitting on the MATLAB path or in the current folder (older
% versions used a different 2-argument signature and caused
% "Too many input arguments" errors).
%
% INPUTS
%   polA_idx : na x ne matrix of indices into aGrid giving the chosen a'
%              (from solve_household_vfi / solve_household_egm).
%   Pi       : ne x ne income transition matrix.
%   params   : struct from setup_params (uses aGrid, tol_dist, maxit_dist).
%
% OUTPUTS
%   dist     : na x ne stationary distribution, sums to 1.
%   distdiag : struct with .converged, .iter, .err, .method, .mass.
%
% METHOD
%   The next-asset choice lies exactly on the grid (VFI restricts a' to nodes;
%   EGM snaps to the nearest node), so the joint-state transition is a
%   DETERMINISTIC map on assets combined with the stochastic income chain:
%     T[(a_i,e_j) -> (a_{k}, e_{j'})] = Pi(j,j'),  k = polA_idx(i,j).
%   The invariant distribution is the exact eigenvector of T' for eigenvalue 1
%   (computed by power iteration; sparse). No Monte-Carlo simulation is used.
%
% PAPER SECTION: Section 2.1 stationary equilibrium (Omega).

    aGrid = params.aGrid(:);
    na    = numel(aGrid);
    ne    = size(Pi, 1);
    N     = na * ne;
    tol   = params.tol_dist;
    maxit = params.maxit_dist;

    % ----- build sparse row-stochastic transition matrix T (N x N) -----
    % linear index for state (a_i, e_j) is s = (j-1)*na + i
    nnz_max = N * ne;
    rows = zeros(nnz_max, 1);
    cols = zeros(nnz_max, 1);
    vals = zeros(nnz_max, 1);
    p = 0;
    for j = 1:ne
        for i = 1:na
            from = (j-1)*na + i;
            k    = polA_idx(i, j);        % next asset index
            for jp = 1:ne
                prob = Pi(j, jp);
                if prob > 0
                    p = p + 1;
                    rows(p) = from;
                    cols(p) = (jp-1)*na + k;
                    vals(p) = prob;
                end
            end
        end
    end
    rows = rows(1:p); cols = cols(1:p); vals = vals(1:p);
    T = sparse(rows, cols, vals, N, N);      % row-stochastic

    % ----- power iteration for the invariant distribution -----
    d   = ones(N, 1) / N;
    Tt  = T';
    err = Inf; it = 0;
    while it < maxit
        it = it + 1;
        dn = Tt * d;
        err = max(abs(dn - d));
        d = dn;
        if err < tol, break; end
    end
    d = max(d, 0);
    d = d / sum(d);

    dist = reshape(d, na, ne);

    distdiag = struct();
    distdiag.converged = (err < tol);
    distdiag.iter      = it;
    distdiag.err       = err;
    distdiag.method    = 'power-iteration';
    distdiag.mass      = sum(dist(:));

    if ~distdiag.converged
        warning('compute_stationary_distribution:noconv', ...
            'Distribution power iteration did not converge: err=%.3e after %d iters.', ...
            err, it);
    end
end
