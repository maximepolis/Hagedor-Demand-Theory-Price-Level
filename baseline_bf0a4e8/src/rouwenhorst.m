function [z, Pi] = rouwenhorst(n, rho, sig_eps)
% ROUWENHORST  Rouwenhorst (1995) discretization of the AR(1)
%     log z_t = rho * log z_{t-1} + eps_t,   eps_t ~ N(0, sig_eps^2).
%
% INPUTS
%   n       : number of grid points (states)
%   rho     : AR(1) persistence
%   sig_eps : std of the innovation
%
% OUTPUTS
%   z  : n x 1 grid of log-income nodes (equally spaced)
%   Pi : n x n transition matrix, Pi(i,j) = Prob(state j tomorrow | state i)
%        Rows sum to one by construction.
%
% PAPER SECTION: builds the finite-state Markov endowment process of Section 2.1.
% The Rouwenhorst method is used because it matches the AR(1) persistence well
% even at high rho, which matters for the precautionary-savings asset demand.

    if n < 1
        error('rouwenhorst:n', 'n must be a positive integer.');
    elseif n == 1
        z  = 0;
        Pi = 1;
        return;
    end

    p = (1 + rho) / 2;    % up-up and down-down probabilities
    q = p;

    Pi = [p, 1-p; 1-q, q];
    for k = 3:n
        Pk = zeros(k);
        Pk(1:k-1, 1:k-1) = Pk(1:k-1, 1:k-1) + p     * Pi;
        Pk(1:k-1, 2:k  ) = Pk(1:k-1, 2:k  ) + (1-p) * Pi;
        Pk(2:k,   1:k-1) = Pk(2:k,   1:k-1) + (1-q) * Pi;
        Pk(2:k,   2:k  ) = Pk(2:k,   2:k  ) + q     * Pi;
        Pk(2:k-1, :)     = Pk(2:k-1, :) / 2;   % keep rows summing to 1
        Pi = Pk;
    end

    % Grid half-width so that the stationary variance matches the AR(1).
    psi = sqrt(n - 1) * sig_eps / sqrt(1 - rho^2);
    z   = linspace(-psi, psi, n)';
end
