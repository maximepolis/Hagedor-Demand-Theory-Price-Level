function [V, apol_idx, R, hhdiag] = solve_household_vfi_agg(P, Dvec, tau, pg, rbar)
% SOLVE_HOUSEHOLD_VFI_AGG  Household VFI with AGGREGATE climate risk
% (aggregate-risk plan, Stage A; appendix/AGGREGATE_RISK_PLAN.md).
%
% The individual state is (a, e, s): a = real financial wealth at the START
% of the period (in current-state prices), e = idiosyncratic efficiency,
% s = aggregate climate state. The nominal bond is the only asset; its REAL
% return is state-contingent because the (stationarized) price level is,
%     1 + r(s -> s') = (1 + rbar) * P_s / P_{s'},   1+rbar = (1+i)/(1+mu),
% so it is nominally safe but really risky -- the object the DTPL is about.
% P are STATIONARIZED price levels (deflated by the nominal-growth trend).
%
%   V(a,e,s) = max_{a' >= -abar}  u(c) + beta * E_{s',e'|s,e}[ V(a', e', s') ]
%   s.t.  c = a + y(e; D_s) - tau_s - a',        c > 0,
%         the state entering next period is a'_next = (1+r(s,s')) * a'
%         (so the continuation is evaluated at the RETURN-SCALED savings).
%
% Because (1+r(s,s'))*a' is off the asset grid, the continuation is LINEARLY
% INTERPOLATED (unlike the deterministic on-grid solver): the state-contingent
% return is intrinsic to a nominal asset and cannot be removed by a change of
% variables. Verified against a Python prototype (scratch) before shipping.
%
% INPUTS
%   P     : 1 x ns price-level vector (one per aggregate state).
%   Dvec  : 1 x ns damage levels D_s.
%   tau   : 1 x ns real lump-sum taxes tau_s.
%   pg    : project params (uses beta, sigma, abar, aGrid, eGrid, Pi,
%           Pi_agg, tol_vfi, maxit_vfi; optional psi_inc incidence gradient).
%   rbar  : deterministic real service rate 1+rbar=(1+i)/(1+mu) (scalar).
%
% OUTPUTS
%   V        : na x ne x ns value function.
%   apol_idx : na x ne x ns indices into aGrid of chosen real savings a'.
%   R        : ns x ns realized gross real returns R(s,s')=(1+rbar)P_s/P_{s'}.
%   hhdiag   : struct .iter .err .converged.

    beta  = pg.beta;  sigma = pg.sigma;
    aGrid = pg.aGrid(:);  eGrid = pg.eGrid(:)';  Pi = pg.Pi;
    Piagg = pg.Pi_agg;
    abar  = pg.abar;
    na = numel(aGrid);  ne = numel(eGrid);  ns = numel(P);
    tol = pg.tol_vfi;   maxit = pg.maxit_vfi;

    % state-contingent gross real returns R(s,s') = (1+rbar) P_s / P_{s'}
    R = (1 + rbar) * (P(:) * (1 ./ P(:))');        % ns x ns

    % effective income y(e; D_s): uniform damages, or the incidence gradient
    % chi(e) = e^{-psi}/E[e^{1-psi}] (state-independent grid; damage level D_s
    % is the only state dependence in this first pass -- the state-dependent
    % idiosyncratic-risk channel is a documented Stage-A+ refinement).
    psi = 0; if isfield(pg,'psi_inc') && ~isempty(pg.psi_inc), psi = pg.psi_inc; end
    ev = eGrid(:); wst = pg.stationary_e(:);
    if psi > 0
        cnorm = wst' * (ev.^(1-psi));
        chi = (ev.^(-psi)) / cnorm;                % E[chi(e) e] = 1
        Ymat = max(1 - Dvec(:)'.*chi, 0.05) .* ev; % ne x ns effective income
    else
        Ymat = (1 - Dvec(:)') .* ev;               % ne x ns
    end

    % initial guess: consume cash-on-hand each period
    V = zeros(na, ne, ns);
    for s = 1:ns
        for e = 1:ne
            coh = aGrid + Ymat(e,s) - tau(s);
            V(:,e,s) = utility(max(coh - aGrid(1), 1e-8), sigma) / (1 - beta);
        end
    end
    V(~isfinite(V)) = -1e10;
    apol_idx = ones(na, ne, ns);
    c_floor = 1e-8; u_floor = utility(c_floor, sigma);

    err = Inf; it = 0;
    while it < maxit
        it = it + 1;
        % continuation EV(a',e,s) = beta * sum_{s',e'} Piagg(s,s') Pi(e,e')
        %                                   * V_interp( R(s,s') a', e', s' )
        EV = zeros(na, ne, ns);
        for s = 1:ns
            for sp = 1:ns
                % off-grid target wealth, CLAMPED to the grid range (constant
                % beyond the edges, as in the prototype's np.interp) so a large
                % return scaling cannot drive a wild linear extrapolation
                wp = min(max(R(s,sp) * aGrid, aGrid(1)), aGrid(end));
                for ep = 1:ne
                    Vi = interp1(aGrid, V(:,ep,sp), wp, 'linear');
                    for e = 1:ne
                        EV(:,e,s) = EV(:,e,s) + ...
                            beta * Piagg(s,sp) * Pi(e,ep) * Vi;
                    end
                end
            end
        end
        Vnew = zeros(na, ne, ns);
        for s = 1:ns
            for e = 1:ne
                coh = aGrid + Ymat(e,s) - tau(s);   % na x 1
                C = coh - aGrid';                    % na x na  (a' across cols)
                C(:, aGrid < -abar) = -Inf;          % enforce a' >= -abar (cols)
                U = utility(C, sigma);               % -Inf where c<=0
                M = U + EV(:,e,s)';                  % add EV(a',e,s) across cols
                [Vj, k] = max(M, [], 2, 'omitnan');
                bad = ~isfinite(Vj);
                if any(bad), Vj(bad) = u_floor + EV(1,e,s); k(bad) = 1; end
                Vnew(:,e,s) = Vj;  apol_idx(:,e,s) = k;
            end
        end
        err = max(abs(Vnew(:) - V(:)));  V = Vnew;
        if err < tol, break; end
    end

    hhdiag = struct('iter', it, 'err', err, 'converged', err < tol);
    if ~hhdiag.converged
        warning('solve_household_vfi_agg:noconv', ...
            'agg VFI did not converge: err=%.3e after %d iters.', err, it);
    end
end
