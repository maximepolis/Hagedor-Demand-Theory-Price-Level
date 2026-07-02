function res = compute_price_level_nominal_bonds(par, ad)
% COMPUTE_PRICE_LEVEL_NOMINAL_BONDS  Baseline Demand Theory of the Price Level.
% Implements Section 3.1-3.3:
%   pi_ss = (B'-B)/B = g_B                         (Eq. 18: inflation = nominal debt growth)
%   1+r_ss = (1+i_ss)/(1+pi_ss)                    (Eq. 17: Fisher)
%   S(1+r_ss) = B/P*                               (Eq. 21)
%   P* = B / S((1+i_ss)/(1+pi_ss))                 (Eq. 22)
% Also reports the Taylor-rule variant (Eq. 19-20, endnote 14): inflation is still
% pinned by fiscal policy and is INDEPENDENT of the monetary inflation target.

    if nargin < 2, ad = []; end

    %% --- Scenario A: monetary policy sets i_ss directly ---------------------
    i_ss  = par.i_ss;
    pi_ss = par.g_B;                                  % Eq. 18
    r_ss  = (1+i_ss)/(1+pi_ss) - 1;                   % Eq. 17
    assert(par.beta*(1+r_ss) < 1, 'beta*(1+r_ss)>=1: no finite-P steady state (Eq.22).');

    [S, out] = solve_asset_demand_at_r(par, r_ss);    % S(1+r_ss), Eq. 12/21
    assert(S > 0, 'S(1+r_ss)<=0: no positive finite price level.');
    P = par.B / S;                                    % Eq. 22

    res.i_ss=i_ss; res.pi_ss=pi_ss; res.r_ss=r_ss; res.S=S; res.P=P; res.B=par.B;
    res.tau_ss=out.tau; res.C=out.agg.C; res.resource_resid=out.resource_resid;
    res.market_resid=abs(S - par.B/P);                % asset-market residual (Eq.14)
    res.beta_check=par.beta*(1+r_ss); res.euler_max=out.hh.euler_max;
    res.out=out;

    %% --- Scenario B: Taylor rule (Eq. 19-20). Inflation set by fiscal policy.
    i_taylor = max(par.ibar + par.phi*(par.g_B - par.pistar), 0);   % Eq. 20
    pi_b     = par.g_B;                                              % still Eq. 18
    r_b      = (1+i_taylor)/(1+pi_b) - 1;                            % Eq. 17
    Pb = NaN; Sb = NaN;
    if par.beta*(1+r_b) < 1
        Sb = solve_asset_demand_at_r(par, r_b);
        Pb = par.B / Sb;
    end
    res.taylor.i_ss=i_taylor; res.taylor.pi_ss=pi_b; res.taylor.r_ss=r_b;
    res.taylor.S=Sb; res.taylor.P=Pb;

    %% --- Comparative statics: P linear in B, and P vs inflation -------------
    Bgrid = linspace(0.25,2.5,10).';
    res.cs.B = Bgrid;  res.cs.P_vs_B = Bgrid / S;     % Eq. 22 linearity in B

    pigrid = linspace(0.00,0.06,13).';                % vary nominal debt growth
    Pvec = nan(size(pigrid)); rvec = Pvec;
    if isempty(ad), ad = struct('Sfun',[]); end
    for k=1:numel(pigrid)
        rk = (1+i_ss)/(1+pigrid(k)) - 1;
        if par.beta*(1+rk) < 1
            if ~isempty(ad.Sfun), Sk = ad.Sfun(1+rk); else, Sk = solve_asset_demand_at_r(par, rk); end
            Pvec(k) = par.B / Sk;  rvec(k) = rk;
        end
    end
    res.cs.pi = pigrid; res.cs.P_vs_pi = Pvec; res.cs.r_vs_pi = rvec;

    %% --- Report ------------------------------------------------------------
    fprintf('\n=== Baseline DTPL (nominal bonds, Section 3.1-3.3) ===\n');
    fprintf(' i_ss=%.4f  pi_ss=%.4f (=g_B)  r_ss=%.4f  beta(1+r)=%.4f\n', i_ss,pi_ss,r_ss,res.beta_check);
    fprintf(' S(1+r_ss)=%.6f   P* = B/S = %.6f   (B=%.3f)\n', S, P, par.B);
    fprintf(' Checks: int c =%.6f (target 1), resource resid=%.2e, asset-mkt resid=%.2e, Euler=%.2e\n', ...
             res.C, res.resource_resid, res.market_resid, res.euler_max);
    fprintf(' Taylor rule (Eq.20): i_ss=%.4f but pi_ss=%.4f UNCHANGED -> P*=%.6f\n', ...
             i_taylor, pi_b, Pb);
end