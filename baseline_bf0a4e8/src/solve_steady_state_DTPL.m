function [ss, out] = solve_steady_state_DTPL(params, i_ss, pi_ss, Bnom)
% SOLVE_STEADY_STATE_DTPL  Baseline Demand-Theory-of-the-Price-Level steady
% state. Given monetary policy (nominal rate i^ss) and fiscal policy (nominal
% debt growth = inflation pi^ss), the real rate and hence household asset demand
% are pinned down, and the price level clears the asset market.
%
% EQUATIONS (baseline, Section 2)
%   Fisher            : 1 + r^ss = (1 + i^ss) / (1 + pi^ss)
%   Debt growth       : 1 + pi^ss = B_{t+1}/B_t  (nominal fiscal rule)
%   Asset demand      : S = S(1 + r^ss)
%   Price level       : P* = Bnom / S(1 + r^ss)
%   Real tax          : tau^ss = r^ss * S
%
% INPUTS
%   params : struct from setup_params.
%   i_ss   : steady-state nominal interest rate.
%   pi_ss  : steady-state inflation (= nominal debt growth rate).
%   Bnom   : nominal government debt (>0).
%
% OUTPUTS
%   ss  : struct of scalar steady-state objects (beta, sigma, abar, i_ss, pi_ss,
%         r_ss, Bnom, S_assets, Pstar, tau_ss) and the existence flag .exists.
%   out : diagnostics from aggregate_asset_demand plus .msg existence message.
%
% EXISTENCE
%   Requires S(1+r^ss) > 0, finite, and beta*(1+r^ss) < 1. If any fails the
%   routine reports "no finite positive steady-state price level for this policy
%   combination" (out.msg) and sets ss.exists = false, ss.Pstar = NaN.
%
% PAPER SECTION: Section 2 (baseline determinacy result, P* = B/S(1+r)).

    if nargin < 2 || isempty(i_ss),  i_ss  = params.i_ss;  end
    if nargin < 3 || isempty(pi_ss), pi_ss = params.pi_ss; end
    if nargin < 4 || isempty(Bnom),  Bnom  = params.Bnom;  end

    r_ss  = (1 + i_ss) / (1 + pi_ss) - 1;     % Fisher relation

    ss = struct();
    ss.beta   = params.beta;
    ss.sigma  = params.sigma;
    ss.abar   = params.abar;
    ss.i_ss   = i_ss;
    ss.pi_ss  = pi_ss;
    ss.r_ss   = r_ss;
    ss.Bnom   = Bnom;
    ss.betaR  = params.beta * (1 + r_ss);

    [S_assets, out] = aggregate_asset_demand(r_ss, params);

    ss.S_assets = S_assets;

    % Existence checks
    ok_betaR  = (ss.betaR < 1) && (ss.betaR < params.betaR_max);
    ok_S      = isfinite(S_assets) && (S_assets > 0);
    ok_conv   = isfield(out, 'converged') && out.converged;
    ss.exists = ok_betaR && ok_S && ok_conv;

    if ss.exists
        ss.Pstar  = Bnom / S_assets;                 % P* = B / S(1+r)
        ss.tau_ss = r_ss * S_assets;                 % real steady-state tax
        out.msg   = 'Finite positive steady-state price level exists.';
    else
        ss.Pstar  = NaN;
        ss.tau_ss = NaN;
        reasons = {};
        if ~ok_betaR, reasons{end+1} = 'beta*(1+r^ss) >= 1'; end
        if ~ok_S,     reasons{end+1} = 'S(1+r^ss) not finite/positive'; end
        if ~ok_conv,  reasons{end+1} = 'asset-demand solver did not converge'; end
        out.msg = sprintf(['No finite positive steady-state price level for ' ...
            'this policy combination (%s).'], strjoin(reasons, '; '));
        warning('solve_steady_state_DTPL:noexist', '%s', out.msg);
    end
end
