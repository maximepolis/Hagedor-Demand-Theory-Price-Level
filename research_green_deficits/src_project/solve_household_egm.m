function [V, polA, polC, hhdiag] = solve_household_egm(r, tau, p)
% SOLVE_HOUSEHOLD_EGM  Endogenous-grid-method solver (Carroll 2006) for the
% same household problem as the package's solve_household_vfi:
%
%   V(a,e) = max_{a' >= abar_lo} u(c) + beta E[V(a',e')|e],
%   c = (1+r)a + y(e) - tau - a',   u CRRA(sigma),
%
% with y(e) = p.eGrid (EFFECTIVE endowments; S_green pre-applies damages,
% incidence, and any proportional levy before calling the solver).
%
% Differences from the VFI: policies are CONTINUOUS (linear interpolation on
% the endogenous grid) rather than restricted to the asset grid, so the
% solution has no grid-snap error; the Euler equation is solved exactly on
% the grid by construction. The value function is recovered afterward by
% policy evaluation (a beta-contraction), so V is comparable to the VFI's.
%
% The stationary distribution for the continuous policy needs the lottery
% method (Young 2010) -- see stationary_distribution_young; the on-grid
% index method of compute_stationary_distribution does not apply.
%
% INPUTS   r, tau scalars; p with .aGrid .eGrid .Pi .beta .sigma
% OUTPUTS  V (na x ne), polA (na x ne, CONTINUOUS a' values, clipped to the
%          grid range), polC (na x ne), hhdiag (.converged .iters .dc)
%
% STATUS: IMPLEMENTED (machinery). Cross-validated against the VFI by
% verify_egm_vs_vfi before any paper table uses it; the pipeline default
% remains the VFI (pg.hh_solver = 'egm' opts in through S_green).

    aG  = p.aGrid(:);          na = numel(aG);
    yv  = p.eGrid(:)';         ne = numel(yv);      % 1 x ne effective incomes
    Pi  = p.Pi;
    bet = p.beta; sig = p.sigma;
    tol = 1e-10; maxit = 5000;

    hhdiag = struct('converged', false, 'iters', 0, 'dc', NaN);

    % initial guess: consume the annuity flow (positive by the caller's
    % feasibility check at the poorest constrained state)
    c = max(r*aG + yv - tau, 1e-8);                 % na x ne (broadcast)

    for it = 1:maxit
        % Euler RHS on the a'-grid: for each (a',e),
        %   B(a',e) = beta(1+r) sum_e' Pi(e,e') u'(c(a',e'))
        B = bet*(1+r) * (c.^(-sig)) * Pi';          % na x ne
        cend = B.^(-1/sig);                         % consumption today
        aend = (cend + aG + tau - yv) / (1+r);      % endogenous current a

        cnew = zeros(na, ne);
        for e = 1:ne
            cnew(:, e) = interp1(aend(:, e), cend(:, e), aG, 'linear', 'extrap');
            % constrained region: current a below the first endogenous point
            % means a' = aG(1) binds and c is read off the budget line
            con = aG < aend(1, e);
            if any(con)
                cnew(con, e) = (1+r)*aG(con) + yv(e) - tau - aG(1);
            end
        end
        cnew = max(cnew, 1e-12);

        dc = max(abs(cnew(:) - c(:)));
        c  = cnew;
        if dc < tol
            hhdiag.converged = true; break;
        end
        if any(~isfinite(c(:)))
            hhdiag.dc = NaN; hhdiag.iters = it;
            return;                                  % blowup: caller treats as infeasible
        end
    end
    hhdiag.iters = it; hhdiag.dc = dc;
    if ~hhdiag.converged, return; end

    polC = c;
    polA = (1+r)*aG + yv - tau - polC;               % na x ne
    polA = min(max(polA, aG(1)), aG(end));           % clip to grid range

    % ---- value function by policy evaluation (same u-normalization as VFI) ----
    if abs(sig - 1) < 1e-12
        U = log(polC);
    else
        U = (polC.^(1 - sig) - 1) / (1 - sig);
    end
    V = U / (1 - bet);                               % warm start
    for itv = 1:maxit
        EV = V * Pi';                                % E[V(a',e')|e] on the grid
        Vn = zeros(na, ne);
        for e = 1:ne
            Vn(:, e) = U(:, e) + bet * interp1(aG, EV(:, e), polA(:, e), 'linear');
        end
        dV = max(abs(Vn(:) - V(:)));
        V  = Vn;
        if dV < 1e-9 * max(1, max(abs(V(:)))), break; end
    end
end
