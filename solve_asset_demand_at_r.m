function [S, out] = solve_asset_demand_at_r(par, r)
% SOLVE_ASSET_DEMAND_AT_R  Steady-state asset-demand function S(1+r).
% Implements the fixed point of Eq. (12)/Section 2.4 for the baseline endowment
% economy: in a stationary equilibrium taxes pay interest on debt, tau_ss=r_ss*S_ss
% (text after Eq. 11), and S_ss = int a dOmega evaluated at that tau.
%
% Returns S(1+r) and an 'out' struct with policies, distribution and checks.

    assert(par.beta*(1+r) < 1, ...
        'solve_asset_demand_at_r: beta*(1+r)>=1 -> asset demand unbounded (Eq. 22, fn. 15).');

    S = par.S_guess;
    for it = 1:par.fp_maxit
        tau = r*S;                         % tau_ss = r_ss * S_ss
        [Snew, out] = aggregate_savings(par, r, tau);
        if abs(Snew - S) < par.fp_tol, S = Snew; break; end
        S = par.fp_damp*Snew + (1-par.fp_damp)*S;
    end
    out.r = r; out.S = S; out.tau = r*S; out.fp_iter = it;
    out.resource_resid = abs(out.agg.C - 1);   % Eq. 8 check: int c = 1
    out.beta_check     = par.beta*(1+r);       % must be < 1
end