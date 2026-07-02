function [eGrid, Pi, stationary_e] = make_income_process(params)
% MAKE_INCOME_PROCESS  Build the discretized idiosyncratic endowment process.
%
% INPUT
%   params : struct with fields ne, rho, sig_eps (see setup_params).
%
% OUTPUTS
%   eGrid        : 1 x ne row vector of endowment levels, NORMALIZED so that
%                  the stationary mean endowment E[e] = 1 (paper normalization,
%                  Section 2.1).
%   Pi           : ne x ne Markov transition matrix (rows sum to 1).
%   stationary_e : ne x 1 invariant distribution of the income chain.
%
% PAPER SECTION: Section 2.1, finite-state Markov endowment e_t with transition
% matrix Pi normalized to unit mean. Exactly implemented from the paper's setup;
% the specific AR(1) parameters are the replicator's benchmark choice.

    ne      = params.ne;
    rho     = params.rho;
    sig_eps = params.sig_eps;

    if ne == 1
        % Degenerate case: single deterministic endowment (complete-markets-like)
        eGrid        = 1.0;
        Pi           = 1.0;
        stationary_e = 1.0;
        return;
    end

    [zlog, Pi]   = rouwenhorst(ne, rho, sig_eps);
    e            = exp(zlog(:));               % income levels

    stationary_e = stationary_from_Pi(Pi);     % invariant distribution

    % Normalize to unit mean under the stationary distribution.
    meanE        = stationary_e(:)' * e(:);
    e            = e / meanE;

    eGrid        = e(:)';                       % 1 x ne row vector
end

% -------------------------------------------------------------------------
function d = stationary_from_Pi(Pi)
% Invariant distribution of a row-stochastic matrix Pi as the normalized left
% eigenvector for eigenvalue 1, with an iterative fallback for robustness.
    n = size(Pi, 1);
    d = [];
    try
        [V, D]   = eig(Pi');
        lam      = diag(D);
        [~, idx] = min(abs(lam - 1));
        d        = real(V(:, idx));
        d        = d / sum(d);
        if any(d < -1e-10) || any(~isfinite(d))
            d = [];    % fall through to iteration
        end
    catch
        d = [];
    end
    if isempty(d)
        d = ones(n, 1) / n;
        for it = 1:100000
            dn = Pi' * d;
            if max(abs(dn - d)) < 1e-14, d = dn; break; end
            d = dn;
        end
    end
    d = max(d, 0);
    d = d / sum(d);
    d = d(:);
end
