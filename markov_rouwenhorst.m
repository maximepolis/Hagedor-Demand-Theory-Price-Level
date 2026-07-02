function [z, P] = markov_rouwenhorst(n, rho, sig_eps)
% MARKOV_ROUWENHORST  Rouwenhorst (1995) discretization of AR(1):
%   log z_t = rho*log z_{t-1} + eps_t,  eps ~ N(0,sig_eps^2).
% Returns log-grid z (n x 1) and transition matrix P (n x n, rows sum to 1).
% Used to build the N-state endowment Markov chain of Eq. (1) in the paper.
    p = (1+rho)/2;  q = p;
    P = [p, 1-p; 1-q, q];
    for k = 3:n
        Pk = zeros(k);
        Pk(1:k-1,1:k-1) = Pk(1:k-1,1:k-1) + p    *P;
        Pk(1:k-1,2:k)   = Pk(1:k-1,2:k)   + (1-p)*P;
        Pk(2:k,1:k-1)   = Pk(2:k,1:k-1)   + (1-q)*P;
        Pk(2:k,2:k)     = Pk(2:k,2:k)     + q    *P;
        Pk(2:k-1,:)     = Pk(2:k-1,:)/2;     % keep rows summing to 1
        P = Pk;
    end
    fi = sqrt(n-1) * sig_eps / sqrt(1-rho^2);   % half-width of the grid
    z  = linspace(-fi, fi, n).';
end