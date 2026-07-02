function res = money_demand_extension(par, ad)
% MONEY_DEMAND_EXTENSION  Section 3.7. Money-in-utility, endogenous money supply.
% Preferences u(c)+mu(m), mu(m)=chi*m^(1-xi)/(1-xi) (Eq. 52). The central bank
% sets i_ss and supplies whatever money clears demand (M endogenous). Steady state:
%   B/P*  = S((1+i)/(1+pi), 1+pi)                    (Eq. 59)
%   M*/P* = L((1+i)/(1+pi), 1+pi)                    (Eq. 58)  => M* = P* L
% Open-market version (Eq. 61-63): B/P* = S + L  (Eq. 63), M* = P* L.
%
% APPROXIMATION (documented): with SEPARABLE preferences we compute household
% money demand from the static FOC mu'(m)=u'(c)*opp (opp = user cost of money),
% aggregated over the baseline (bond-economy) consumption distribution. This
% captures L(1+r,1+pi) for the determinacy result without solving a 2-asset state
% space; it does not feed money holdings back into the budget. The qualitative
% result (price level determinate via asset clearing; M endogenous) is unaffected.

    if nargin < 2 || isempty(ad), ad = asset_demand_curve(par); end
    i_ss=par.i_ss; pi_ss=par.g_B; bet=par.beta; B=par.B;
    r_ss=(1+i_ss)/(1+pi_ss)-1;
    assert(bet*(1+r_ss)<1, 'money_demand_extension: beta*(1+r_ss)>=1.');

    % Bond-economy stationary distribution & consumption (for L aggregation)
    [S, out] = solve_asset_demand_at_r(par, r_ss);
    cpol = out.cpol; dist = out.dist;

    % User cost of money (opportunity cost). Convention switch (documented).
    switch lower(par.money_opp)
        case 'paper', opp = i_ss/(1+pi_ss);   % consistent with paper timing (Section 3.7 footnotes)
        otherwise,    opp = i_ss/(1+i_ss);    % standard user cost
    end
    opp = max(opp, 1e-8);

    % Household money demand m_i from FOC mu'(m)=u'(c)*opp:
    %   chi*m^(-xi) = c^(-sigma)*opp  =>  m = (chi/(c^(-sigma)*opp))^(1/xi)
    c = cpol(:);
    muc = c.^(-par.sigma);
    m_i = (par.chi ./ (muc*opp)).^(1/par.xi);
    L = sum(dist(:).*m_i);                    % aggregate real money L (Eq. 54)

    % --- Case 1: money supplied to satisfy demand (Eq. 58-59) ---
    P1 = B / S;                               % Eq. 59 (asset/bond clearing pins P)
    M1 = P1 * L;                              % Eq. 60
    res.case1.P=P1; res.case1.M=M1; res.case1.S=S; res.case1.L=L;

    % --- Case 2: open-market operations (Eq. 61-63): B/P = S + L ---
    P2 = B / (S + L);                         % Eq. 63
    M2 = P2 * L;
    res.case2.P=P2; res.case2.M=M2; res.case2.S=S; res.case2.L=L;

    % Steady-state nominal money growth = inflation (Eq. 64-65)
    res.money_growth = pi_ss;
    res.r_ss=r_ss; res.pi_ss=pi_ss; res.i_ss=i_ss; res.opp=opp;
    res.approx_note = ['Separable-MIU static money demand aggregated over baseline ', ...
                       'consumption distribution; opp = ' par.money_opp '.'];

    fprintf('\n=== Money-demand extension (Section 3.7, Eq. 52-65) ===\n');
    fprintf(' r_ss=%.4f  S=%.4f  L=%.4f  (opp cost=%.4f)\n', r_ss,S,L,opp);
    fprintf(' Case 1 (M satisfies demand): P*=B/S=%.6f, M*=P*L=%.6f (Eq.58-60)\n', P1,M1);
    fprintf(' Case 2 (open-market): P*=B/(S+L)=%.6f, M*=P*L=%.6f (Eq.63)\n', P2,M2);
    fprintf(' Money growth = inflation = %.4f (Eq.64-65). M is ENDOGENOUS; P set by asset clearing.\n', pi_ss);
    fprintf(' [Approximation] %s\n', res.approx_note);
end