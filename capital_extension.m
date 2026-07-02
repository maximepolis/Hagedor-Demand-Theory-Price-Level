function res = capital_extension(par)
% CAPITAL_EXTENSION  Section 3.6. Adds capital with Cobb-Douglas F=K^alpha (h=1).
% Bonds and capital are perfect substitutes (same return). Equations:
%   F_K(K*,1)+1-delta = 1+r_ss = (1+i_ss)/(1+pi_ss)   (Eq. 51) -> pins K*
%   K* + B/P*         = S(1+r_ss)                      (Eq. 50) -> pins P*
%   tau_ss            = r_ss (S_ss - K_ss)             (Eq. 49)
% Household budget c+a'=(1+r)a + w e - tau (Eq. 46), w=F_h=(1-alpha)K^alpha.
% Verifies price-level determinacy survives capital: P* finite, positive.

    alpha=par.alpha; delta=par.delta; bet=par.beta;
    i_ss=par.i_ss; pi_ss=par.g_B; B=par.B;
    r_ss=(1+i_ss)/(1+pi_ss)-1;                       % Eq. 17
    assert(bet*(1+r_ss)<1, 'capital_extension: beta*(1+r_ss)>=1.');

    % Firm FOC (Eq. 51): alpha K^(alpha-1) = r + delta
    Kstar = (alpha/(r_ss+delta))^(1/(1-alpha));      % capital stock
    w     = (1-alpha)*Kstar^alpha;                   % real wage = F_h(K*,1)

    % Household TOTAL asset demand S(1+r) with wage income and tau=r*(S-K*) (Eq.49).
    parc = par; parc.wage = w; parc.inc_scale = 1.0;
    S = par.S_guess + Kstar;                         % initial guess for total assets
    for it=1:par.fp_maxit
        tau = r_ss*(S - Kstar);                      % Eq. 49
        [Snew, out] = aggregate_savings(parc, r_ss, tau);
        if abs(Snew-S) < par.fp_tol, S = Snew; break; end
        S = par.fp_damp*Snew + (1-par.fp_damp)*S;
    end

    assert(S > Kstar, 'capital_extension: S<=K*, no positive bond price level (need S>K*).');
    P = B / (S - Kstar);                             % Eq. 50 -> Eq. 22 analogue

    % Resource constraint (Eq. 45 steady state): int c = K^alpha - delta*K
    netY = Kstar^alpha - delta*Kstar;

    res.r_ss=r_ss; res.pi_ss=pi_ss; res.K=Kstar; res.w=w; res.S=S; res.P=P; res.B=B;
    res.tau_ss=r_ss*(S-Kstar); res.C=out.agg.C; res.netY=netY;
    res.resource_resid=abs(out.agg.C - netY);
    res.market_resid=abs(Kstar + B/P - S);           % Eq. 50 residual
    res.firm_resid=abs(alpha*Kstar^(alpha-1)+(1-delta) - (1+r_ss));  % Eq. 51 residual
    res.beta_check=bet*(1+r_ss); res.euler_max=out.hh.euler_max;

    fprintf('\n=== Capital extension (Section 3.6, Eq. 45-51) ===\n');
    fprintf(' r_ss=%.4f  K*=%.4f  w=%.4f  S=%.4f  P*=B/(S-K*)=%.6f\n', r_ss,Kstar,w,S,P);
    fprintf(' Checks: asset-mkt(Eq.50)=%.2e  firm(Eq.51)=%.2e  resource(Eq.45)=%.2e  Euler=%.2e\n', ...
             res.market_resid, res.firm_resid, res.resource_resid, res.euler_max);
    fprintf(' -> Price level remains DETERMINATE with capital.\n');
end