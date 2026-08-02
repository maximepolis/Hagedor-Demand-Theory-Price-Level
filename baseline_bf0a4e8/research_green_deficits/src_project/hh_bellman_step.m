function [V, polA_idx, ok] = hh_bellman_step(Vnext, r, tau, yv, p, aG)
% HH_BELLMAN_STEP  One backward-induction step of the household problem for
% the tier-2 HANK-DTPL transition (finite horizon, time-varying prices):
%
%   V_t(a,e) = max_{a' in grid}  u(c) + beta * E[ V_{t+1}(a', e') | e ],
%   c = (1+r_t) a + y_t(e) - tau_t - a',   subject to c > 0, a' >= -abar.
%
% Same grid, same CRRA utility, and the same consumption-floor guard as the
% package's infinite-horizon VFI (a forced floor with finite utility keeps
% the recursion well-defined if a state is infeasible at extreme trial
% prices; if the FLOOR IS USED AT POSITIVE MASS the caller's residuals
% will not clear, so it cannot contaminate a converged path).
%
% INPUTS: Vnext (na x ne), r, tau scalars, yv (ne x 1 effective incomes),
%         p (params with .beta .sigma .Pi), aG (na x 1 asset grid).
% OUTPUTS: V (na x ne), polA_idx (na x ne), ok (false only on NaN blowup).
%
% STATUS: IMPLEMENTED (tier-2 building block).

    na = numel(aG);
    ne = numel(yv);
    sig = p.sigma;
    bet = p.beta;
    c_floor = 1e-10;

    % expected continuation value by (a', e): EV(a',e) = sum_e' Pi(e,e') Vnext(a',e')
    EV = Vnext * p.Pi';          % na x ne

    V = zeros(na, ne);
    polA_idx = ones(na, ne);
    for e = 1:ne
        % resources(a) - a' matrix: rows a, cols a'
        res = (1 + r) * aG + yv(e) - tau;      % na x 1
        C = res - aG';                          % na x na
        C(C <= 0) = NaN;
        if abs(sig - 1) < 1e-12
            U = log(C);
        else
            U = (C.^(1 - sig) - 1) / (1 - sig);
        end
        Obj = U + bet * EV(:, e)';             % na x na
        [Vr, ix] = max(Obj, [], 2, 'omitnan');
        % forced floor for states with no feasible choice (extreme trial
        % prices): stay at the lowest grid point with floor consumption
        bad = ~isfinite(Vr);
        if any(bad)
            if abs(sig - 1) < 1e-12, uf = log(c_floor);
            else, uf = (c_floor^(1 - sig) - 1) / (1 - sig); end
            Vr(bad) = uf + bet * EV(1, e);
            ix(bad) = 1;
        end
        V(:, e) = Vr;
        polA_idx(:, e) = ix;
    end
    ok = all(isfinite(V(:)));
end
