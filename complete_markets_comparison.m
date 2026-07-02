function res = complete_markets_comparison(par, ad)
% COMPLETE_MARKETS_COMPARISON  Representative-agent benchmark => INDETERMINACY.
% Implements Section 3.4 / Figure 2b:
%   Complete markets:  (1+r_ss)beta = 1  (Eq. 24)  -> r_ss independent of B/P
%                      => any P clears the asset market => P indeterminate.
%   Incomplete markets: S(1+r) is a function (Eq. 23) -> unique P (Fig. 2a).
% Also covers hand-to-mouth + PIH (Eq. 25): same indeterminacy.

    if nargin < 2 || isempty(ad), ad = asset_demand_curve(par); end

    r_ra = 1/par.beta - 1;                  % Eq. 24: complete-markets real rate
    res.r_ra = r_ra;

    % Policy consistency: a steady state with complete markets exists ONLY if
    % (1+i_ss)/(1+pi_ss) = 1/beta. Otherwise NO steady state (Eq. 24).
    onepr_policy = (1+par.i_ss)/(1+par.g_B);
    res.policy_consistent = abs(onepr_policy - 1/par.beta) < 1e-8;

    % Indeterminacy demonstration: pick THREE price levels; show all clear the
    % asset market at r=r_ra because the RA absorbs ANY B/P at that rate.
    Ptry = [0.5; 1.0; 2.0]*par.B;           % arbitrary candidate price levels
    BP   = par.B ./ Ptry;                   % real bonds absorbed
    res.cm.P  = Ptry;
    res.cm.BP = BP;
    res.cm.r_clearing = r_ra*ones(size(Ptry));  % all clear at the SAME rate (Eq.24)

    % Contrast: incomplete markets gives a UNIQUE P at the SAME policy (if feasible)
    r_inc = onepr_policy - 1;
    if par.beta*(1+r_inc) < 1
        S_inc = ad.Sfun(1+r_inc);
        res.inc.r = r_inc; res.inc.S = S_inc; res.inc.P = par.B / S_inc;  % Eq. 22 unique
    else
        res.inc.r = r_inc; res.inc.S = NaN; res.inc.P = NaN;
    end

    % Hand-to-mouth + PIH (Eq. 25): only PIH hold bonds -> (1+r)beta=1 -> indeterminate
    res.htm.note = 'Eq.(25): (1+i)/(1+pi)=1+r=1/beta independent of P -> indeterminate.';

    fprintf('\n=== Complete-markets comparison (Section 3.4, Fig. 2b) ===\n');
    fprintf(' RA real rate r=1/beta-1=%.4f. Policy-consistent SS exists? %d\n', r_ra, res.policy_consistent);
    fprintf(' COMPLETE markets: price levels %.2f, %.2f, %.2f all clear at r=%.4f -> INDETERMINATE\n', ...
             Ptry(1),Ptry(2),Ptry(3), r_ra);
    if isfinite(res.inc.P)
        fprintf(' INCOMPLETE markets at same policy: unique r=%.4f, S=%.4f, P*=%.4f -> DETERMINATE\n', ...
                 res.inc.r, res.inc.S, res.inc.P);
    end
    fprintf(' Hand-to-mouth+PIH: %s\n', res.htm.note);
end