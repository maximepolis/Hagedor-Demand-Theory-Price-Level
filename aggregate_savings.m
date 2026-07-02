function [S, out] = aggregate_savings(par, r, tau)
% AGGREGATE_SAVINGS  Aggregate household asset demand for GIVEN (r, tau).
% Solves the household problem (Section 2.1) and the stationary distribution,
% returning S = int a' dOmega (Eq. 10). Used by solve_asset_demand_at_r (which
% adds the tau=r*S fixed point) and by the Section 3.8 extension (exogenous tau).
    [cpol, apol, hh] = solve_household_problem(par, r, tau);
    [dist, agg, chk] = stationary_distribution(apol, cpol, par);
    S = agg.S;
    out.cpol=cpol; out.apol=apol; out.dist=dist; out.agg=agg; out.hh=hh; out.chk=chk; out.tau=tau;
end