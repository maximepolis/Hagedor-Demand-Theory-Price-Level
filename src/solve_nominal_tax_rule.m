function [ss, out] = solve_nominal_tax_rule(params, omega1, omega2, i_ss, Bnom)
% SOLVE_NOMINAL_TAX_RULE  Steady state under a NOMINAL tax rule of the form
%       T_t = omega1 * i_t * B_t + omega2 * B_t.
% Substituting into the nominal government budget constraint
%       B_{t+1} = (1 + i_t) B_t - T_t
% gives the nominal debt-growth (hence inflation) rule
%       B_{t+1}/B_t = (1 - omega1) i_t + (1 - omega2),
% so in steady state
%       1 + pi^ss = (1 - omega1) i^ss + (1 - omega2).
% The real rate then follows from Fisher and the price level from asset-market
% clearing, exactly as in the baseline DTPL.
%
% INPUTS
%   params : struct from setup_params.
%   omega1 : loading on interest cost i_t B_t in the nominal tax rule.
%   omega2 : loading on the principal B_t in the nominal tax rule.
%   i_ss   : steady-state nominal interest rate.
%   Bnom   : nominal debt.
%
% OUTPUTS
%   ss  : steady-state struct (adds .omega1 .omega2 to the DTPL ss struct).
%   out : diagnostics (adds .pi_from_rule, .special_case label).
%
% SPECIAL CASES (paper discussion)
%   omega1 = 1 : fiscal policy fully offsets interest costs; debt growth (and
%                inflation) is independent of the monetary rate i^ss.
%   omega1 < 1 : higher i^ss raises debt growth and inflation.
%   omega1 > 1 : higher i^ss lowers debt growth and inflation.
%
% PAPER SECTION: nominal tax rules (policy-rules section).

    if nargin < 4 || isempty(i_ss), i_ss = params.i_ss; end
    if nargin < 5 || isempty(Bnom), Bnom = params.Bnom; end

    pi_ss = (1 - omega1) * i_ss + (1 - omega2);   % 1+pi = (1-w1) i + (1-w2)
    % Note: this expression equals (1+pi^ss) directly, i.e. GROSS growth.
    gross_pi = pi_ss;
    pi_ss    = gross_pi - 1;                       % net inflation

    [ss, out] = solve_steady_state_DTPL(params, i_ss, pi_ss, Bnom);
    ss.omega1 = omega1;
    ss.omega2 = omega2;

    out.pi_from_rule = pi_ss;
    out.gross_debt_growth = gross_pi;
    if abs(omega1 - 1) < 1e-12
        out.special_case = 'omega1=1: inflation independent of i^ss';
    elseif omega1 < 1
        out.special_case = 'omega1<1: higher i^ss raises inflation';
    else
        out.special_case = 'omega1>1: higher i^ss lowers inflation';
    end
end
