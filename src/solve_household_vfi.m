function [V, polA_idx, polA, polC, hhdiag] = solve_household_vfi(r, tau, params)
% SOLVE_HOUSEHOLD_VFI  Canonical value-function-iteration solver for the
% household savings problem of the incomplete-markets economy (Section 2.1).
%
% PROBLEM
%   V(a,e) = max_{a' in aGrid, a' >= -abar}  u(c) + beta E[ V(a',e') | e ]
%   s.t.   c + a' = (1+r) a + e - tau,   c > 0.
%
% INPUTS
%   r      : real interest rate (scalar).
%   tau    : real lump-sum tax (scalar).
%   params : struct from setup_params (uses beta, sigma, abar, aGrid, eGrid,
%            Pi, tol_vfi, maxit_vfi).
%
% OUTPUTS
%   V        : na x ne value function.
%   polA_idx : na x ne indices into aGrid of the optimal a'.
%   polA     : na x ne optimal next-period assets (levels).
%   polC     : na x ne optimal consumption.
%   hhdiag   : struct with convergence + accuracy diagnostics:
%              .iter, .err, .converged, .euler_max_log10, .euler_mean_log10,
%              .frac_constrained, .anyInfeasible, .method.
%
% METHOD NOTES
%   * Choices are restricted to the asset grid, so NO interpolation is needed
%     and the solution is exact on the grid (robust, transparent).
%   * Feasible consumption is computed for EVERY candidate a'; infeasible
%     (c <= 0) choices receive -Inf utility. Monotonicity of the policy is
%     therefore NOT relied upon for correctness (it is checked as a diagnostic).
%   * Modified policy iteration (Howard improvement) accelerates convergence.
%
% PAPER SECTION: Section 2.1 (household block).

    beta   = params.beta;
    sigma  = params.sigma;
    aGrid  = params.aGrid(:);        % na x 1
    eGrid  = params.eGrid(:)';       % 1 x ne
    Pi     = params.Pi;              % ne x ne
    na     = numel(aGrid);
    ne     = numel(eGrid);
    tol    = params.tol_vfi;
    maxit  = params.maxit_vfi;
    n_howard = 40;                   % Howard improvement sweeps per outer step

    % ----- feasibility bookkeeping -----
    anyInfeasible = false;

    % ----- initial guess: value of consuming cash-on-hand each period -----
    V = zeros(na, ne);
    coh0 = (1+r) * aGrid + eGrid - tau;         % na x ne cash-on-hand
    c0   = max(coh0 - aGrid(1), 1e-8);          % consume down to the constraint
    V    = utility(c0, sigma) / (1 - beta);
    V(~isfinite(V)) = -1e10;

    polA_idx = ones(na, ne);
    err = Inf;
    it  = 0;

    while it < maxit
        it = it + 1;

        % Continuation value EV(k,j) = beta * sum_{j'} Pi(j,j') V(k,j')
        EV = beta * (V * Pi');                   % na x ne

        Vnew = zeros(na, ne);
        for j = 1:ne
            coh = (1+r) * aGrid + eGrid(j) - tau;  % na x 1 cash-on-hand
            % consumption matrix C(i,k) = coh(i) - aGrid(k)
            C = coh - aGrid';                      % na x na
            U = utility(C, sigma);                 % -Inf where C <= 0
            if ~anyInfeasible && all(~isfinite(U(1,:)))
                anyInfeasible = true;              % lowest state fully infeasible
            end
            M = U + EV(:, j)';                     % add EV(k,j) across columns
            [Vj, kidx] = max(M, [], 2);
            Vnew(:, j)     = Vj;
            polA_idx(:, j) = kidx;
        end

        err = max(abs(Vnew(:) - V(:)));
        V   = Vnew;
        if err < tol
            break;
        end

        % ---- Howard policy-improvement sweeps (hold policy fixed) ----
        for h = 1:n_howard
            EVh = beta * (V * Pi');
            for j = 1:ne
                coh  = (1+r) * aGrid + eGrid(j) - tau;
                idx  = polA_idx(:, j);
                cH   = coh - aGrid(idx);
                V(:, j) = utility(cH, sigma) + EVh(idx, j);
            end
        end
    end

    % ----- policy levels and consumption -----
    polA = aGrid(polA_idx);
    polC = zeros(na, ne);
    for j = 1:ne
        polC(:, j) = (1+r) * aGrid + eGrid(j) - tau - polA(:, j);
    end
    if any(polC(:) <= 0)
        anyInfeasible = true;
        polC = max(polC, 1e-12);
    end

    % ----- Euler-equation residuals -----
    % residual = 1 - beta(1+r) E[u'(c')]/u'(c);  unconstrained where a' > amin.
    amin  = -params.abar;
    mu_c  = polC.^(-sigma);
    Emu   = zeros(na, ne);
    for j = 1:ne
        k = polA_idx(:, j);                    % next-asset index
        cn = polC(k, :);                       % na x ne consumption next period
        mun = cn.^(-sigma);                    % na x ne
        Emu(:, j) = mun * Pi(j, :)';           % E[u'(c')|e=j]
    end
    resid = 1 - beta*(1+r) * Emu ./ mu_c;
    unconstrained = polA > amin + 1e-10;
    frac_constrained = 1 - mean(unconstrained(:));

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
    hhdiag.frac_constrained = frac_constrained;
    hhdiag.anyInfeasible    = anyInfeasible;
    hhdiag.method           = 'vfi';

    if ~hhdiag.converged
        warning('solve_household_vfi:noconv', ...
            'VFI did not converge: err=%.3e after %d iters (r=%.4f, tau=%.4f).', ...
            err, it, r, tau);
    end
end
