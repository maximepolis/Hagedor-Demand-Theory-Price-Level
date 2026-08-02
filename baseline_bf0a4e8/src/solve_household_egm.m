function [V, polA_idx, polA, polC, hhdiag] = solve_household_egm(r, tau, params)
% SOLVE_HOUSEHOLD_EGM  Endogenous Grid Method solver (Carroll 2006) for the
% household savings problem. This is an OPTIONAL speed alternative to
% solve_household_vfi; VFI remains the canonical method (see REPLICATION_NOTES).
%
% Same INPUT/OUTPUT signature as solve_household_vfi so it is a drop-in:
%   [V, polA_idx, polA, polC, hhdiag] = solve_household_egm(r, tau, params)
%
% The continuous EGM policy for a' is computed by interpolation and then, for
% compatibility with the index-based stationary_distribution, snapped to the
% nearest grid node to define polA_idx. polA/polC hold the (near-continuous)
% levels. V is recovered by iterating the value under the EGM policy.
%
% EQUATION: Euler equation  u'(c) = beta (1+r) E[u'(c')]  (unconstrained),
% with the borrowing constraint a' >= -abar handled explicitly.
%
% PAPER SECTION: Section 2.1 (household block), numerical appendix analogue.

    beta  = params.beta;
    sigma = params.sigma;
    aGrid = params.aGrid(:);
    eGrid = params.eGrid(:)';
    Pi    = params.Pi;
    na    = numel(aGrid);
    ne    = numel(eGrid);
    amin  = -params.abar;
    tol   = params.tol_vfi;
    maxit = params.maxit_vfi;

    % Initial consumption guess: consume cash flow (interest + income - tax)
    c = max((r) * aGrid + eGrid - tau, 1e-6);    % na x ne
    c = max(c, 1e-6);

    err = Inf; it = 0;
    while it < maxit
        it = it + 1;
        % Marginal utility next period on the a'-grid (a' == aGrid nodes)
        mu_next = c.^(-sigma);                    % na x ne
        Emu     = mu_next * Pi';                  % na x ne, E[u'(c')|e]
        c_endog = (beta * (1+r) * Emu).^(-1/sigma);   % consumption today
        % endogenous current assets s.t. a' = aGrid:
        %   c_endog + a' = (1+r) a + e - tau  =>  a = (c_endog + a' - e + tau)/(1+r)
        a_today = (c_endog + aGrid - eGrid + tau) / (1+r);   % na x ne

        cpol = zeros(na, ne);
        apol = zeros(na, ne);
        for j = 1:ne
            % unique() returns ascending, strictly increasing abscissa required
            % by interp1; iu maps each node back to its a' grid value.
            [xq_u, iu] = unique(a_today(:, j));
            ap_u       = aGrid(iu);
            ap = interp1(xq_u, ap_u, aGrid, 'linear', 'extrap');
            % borrowing constraint: households below the lowest endogenous node
            % are constrained at a' = amin
            constrained = aGrid < xq_u(1);
            ap(constrained) = amin;
            ap = min(max(ap, amin), aGrid(end));
            apol(:, j) = ap;
            cpol(:, j) = (1+r) * aGrid + eGrid(j) - tau - ap;
        end
        cpol = max(cpol, 1e-12);

        err = max(abs(cpol(:) - c(:)));
        c   = cpol;
        if err < tol, break; end
    end

    polA = apol;
    polC = cpol;

    % Snap continuous policy to nearest grid node for index-based distribution.
    polA_idx = zeros(na, ne);
    for j = 1:ne
        [~, polA_idx(:, j)] = min(abs(polA(:, j) - aGrid'), [], 2);
    end

    % Recover a value function under the EGM policy (fixed-point iteration).
    V = utility(polC, sigma) / (1 - beta);
    V(~isfinite(V)) = -1e10;
    for h = 1:2000
        EV = beta * (V * Pi');
        Vn = zeros(na, ne);
        for j = 1:ne
            Vn(:, j) = utility(polC(:, j), sigma) + EV(polA_idx(:, j), j);
        end
        if max(abs(Vn(:) - V(:))) < tol, V = Vn; break; end
        V = Vn;
    end

    % Euler residuals (unconstrained points)
    mu_c = polC.^(-sigma);
    Emu2 = zeros(na, ne);
    for j = 1:ne
        k = polA_idx(:, j);
        mun = polC(k, :).^(-sigma);
        Emu2(:, j) = mun * Pi(j, :)';
    end
    resid = 1 - beta*(1+r) * Emu2 ./ mu_c;
    unconstrained = polA > amin + 1e-8;
    absres = abs(resid(unconstrained));
    absres = absres(absres > 0);

    if isempty(absres)
        euler_max_log10  = -Inf;
        euler_mean_log10 = -Inf;
    else
        euler_max_log10  = log10(max(absres));
        euler_mean_log10 = log10(mean(absres));
    end

    hhdiag = struct();
    hhdiag.iter             = it;
    hhdiag.err              = err;
    hhdiag.converged        = (err < tol);
    hhdiag.euler_max_log10  = euler_max_log10;
    hhdiag.euler_mean_log10 = euler_mean_log10;
    hhdiag.frac_constrained = 1 - mean(unconstrained(:));
    hhdiag.anyInfeasible    = any(cpol(:) <= 0);
    hhdiag.method           = 'egm';
end
