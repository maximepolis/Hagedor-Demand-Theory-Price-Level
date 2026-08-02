function tau = twoasset_fiscal_tax(r_b, Bnom, P, g_real)
% TWOASSET_FISCAL_TAX  Real tax per household implied by the government budget
% under the nominal growth rule. ONE definition, shared by the steady-state
% solver and the transition residual.
%
%   tau_t = r_b * (B / P_t) + g_t
%
% WHERE IT COMES FROM. Fiscal policy fixes the nominal stock's growth rate,
% B_{t+1} = (1+mu) B_t, so the stationarized stock Bhat is CONSTANT and taxes
% are the residual in the government's flow budget:
%
%   B_{t+1} = (1+i) B_t + P_t g_t - P_t tau_t   and   B_{t+1} = (1+mu) B_t
%   =>  tau_t = g_t + (i - mu) B_t / P_t  =  g_t + r_b * bhat_t,
%
% with r_b = (i-mu)/(1+mu) the policy-pinned real service rate.
%
% WHY THE REALIZED RETURN DOES NOT BELONG HERE. Households earn the realized
% real return (1+r_b) Phat_{t-1}/Phat_t - 1, which differs from r_b whenever
% the price level moves. That difference is a capital gain or loss on the
% outstanding STOCK -- the revaluation this paper is about. The government
% does not pay it: it pays the fixed nominal coupon i. Charging the realized
% return to taxpayers would hand households the revaluation and tax them for
% it at the same time.
%
% This cost three converged-looking runs. The transition residual used the
% realized return here while the steady-state solver used r_b, and because
% the two coincide EXACTLY at a constant price path, the driver's
% steady-state consistency gate (which holds prices constant) could not see
% it: the gate passed at 1e-07 while the announcement-date residual floored
% at 7e-03. The error was proportional to the price jump, hence to the shock
% size, and lived at t = 1, 2 -- immovable by any reparameterization of the
% price path, because no price path can repair a mis-specified tax.
%
% INPUTS  r_b    : constant policy-pinned real service rate.
%         Bnom   : stationarized nominal stock (constant under the rule).
%         P      : price level, scalar or 1 x T path.
%         g_real : real green appropriation, scalar or conforming path.
% OUTPUT  tau    : real tax per household, same shape as P.

    tau = r_b * Bnom ./ P + g_real;
end
