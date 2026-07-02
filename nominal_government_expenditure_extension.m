function res = nominal_government_expenditure_extension(par, ad)
% NOMINAL_GOVERNMENT_EXPENDITURE_EXTENSION  Section 3.8 + Result A1 (Appendix A.1.1).
% Two cases.
% (A) Real (price-indexed) bonds B^real fixed, nominal G and nominal taxes (Eq.66-71):
%       tau(P) = G/P - omega + r*B^real,  income (1-omega)e   (Eq. 66-67)
%       clearing  S(1+r_ss, G/P) = B^real                      (Eq. 69, 71)
%     S is strictly decreasing in G/P (Result A1) => increasing in P => unique P*.
% (B) Nominal bonds B and nominal G>0 (Eq.72-74):
%       tau = G/P - omega + r*S  (fixed point in S),  S(1+r,G/P)=B/P  (Eq. 74)
% This makes the theory a DEMAND theory (G/P shifts demand), not a demand-for-bonds
% theory. We also produce the data for Figure 4 (asset-demand curve shifts with P).

    if nargin < 2 || isempty(ad), ad = asset_demand_curve(par); end
    i_ss=par.i_ss; pi_ss=par.g_B; bet=par.beta;
    r_ss=(1+i_ss)/(1+pi_ss)-1;
    assert(bet*(1+r_ss)<1, 'gov-exp extension: beta*(1+r_ss)>=1.');
    G=par.G; omega=par.omega_e; Breal=par.B_real;

    %% ---- Case A: real bonds, nominal G & taxes (Eq. 69/71) -----------------
    parA = par; parA.inc_scale = (1-omega);            % income (1-omega)e (Eq. 67)
    % excess demand fA(P) = S(1+r, tau(P)) - B^real, with tau(P)=G/P-omega+r*Breal
    fA = @(P) local_excessA(P, parA, r_ss, G, omega, Breal);

    Pg = linspace(0.05, 8, 200).';
    fv = nan(size(Pg));
    for k=1:numel(Pg), fv(k)=fA(Pg(k)); end
    PA = NaN;
    for k=1:numel(Pg)-1
        if isfinite(fv(k)) && isfinite(fv(k+1)) && fv(k)*fv(k+1)<0
            PA = fzero(fA, [Pg(k) Pg(k+1)]); break;
        end
    end
    res.caseA.P = PA; res.caseA.Breal = Breal; res.caseA.r = r_ss;
    if isfinite(PA)
        res.caseA.tau = G/PA - omega + r_ss*Breal;
    end

    % Figure 4 data: asset-demand curves shift with P (different G/P), Eq. 69
    Plevels = [0.8;1.2;2.0]*max(PA,1);
    rr = linspace(-0.02, 1/bet-1-0.004, 18).';
    res.fig.r = rr; res.fig.curves = nan(numel(rr), numel(Plevels)); res.fig.Plevels=Plevels;
    for c=1:numel(Plevels)
        tauP = G/Plevels(c) - omega + r_ss*Breal;
        for k=1:numel(rr)
            if bet*(1+rr(k))<1
                res.fig.curves(k,c) = aggregate_savings(parA, rr(k), G/Plevels(c)-omega+rr(k)*Breal);
            end
        end
    end
    res.fig.Breal = Breal;

    %% ---- Case B: nominal bonds and nominal G (Eq. 72-74) -------------------
    parB = par; parB.inc_scale = (1-omega);
    fB = @(P) local_excessB(P, parB, r_ss, G, omega, par.B, par);
    fvB = nan(size(Pg));
    for k=1:numel(Pg), fvB(k)=fB(Pg(k)); end
    PB = NaN;
    for k=1:numel(Pg)-1
        if isfinite(fvB(k)) && isfinite(fvB(k+1)) && fvB(k)*fvB(k+1)<0
            PB = fzero(fB, [Pg(k) Pg(k+1)]); break;
        end
    end
    res.caseB.P = PB; res.caseB.B = par.B; res.caseB.r = r_ss;

    res.r_ss=r_ss; res.pi_ss=pi_ss;
    fprintf('\n=== Nominal government expenditure (Section 3.8, Result A1) ===\n');
    fprintf(' r_ss=%.4f  G=%.3f  omega=%.2f\n', r_ss, G, omega);
    if isfinite(PA)
        fprintf(' Case A (real bonds B^real=%.3f): unique P*=%.6f, tau=%.4f (Eq.69/71)\n', Breal, PA, res.caseA.tau);
    else
        fprintf(' Case A: no interior P* found in scan range.\n');
    end
    if isfinite(PB)
        fprintf(' Case B (nominal bonds B=%.3f, G>0): unique P*=%.6f (Eq.74)\n', par.B, PB);
    else
        fprintf(' Case B: no interior P* found in scan range.\n');
    end
    fprintf(' Demand depends on G/P (Result A1: S decreasing in G/P) -> a DEMAND theory.\n');
end

% ---- helpers ----
function v = local_excessA(P, parA, r, G, omega, Breal)
    if parA.beta*(1+r) >= 1 || P<=0, v=NaN; return; end
    tau = G/P - omega + r*Breal;          % Eq. 66 real taxes
    S   = aggregate_savings(parA, r, tau);
    v   = S - Breal;                      % Eq. 69/71
end
function v = local_excessB(P, parB, r, G, omega, B, par)
    if parB.beta*(1+r) >= 1 || P<=0, v=NaN; return; end
    % tau = G/P - omega + r*S : fixed point in S (Eq. 73)
    S = par.S_guess;
    for it=1:par.fp_maxit
        tau  = G/P - omega + r*S;
        Snew = aggregate_savings(parB, r, tau);
        if abs(Snew-S)<par.fp_tol, S=Snew; break; end
        S = par.fp_damp*Snew + (1-par.fp_damp)*S;
    end
    v = S - B/P;                          % Eq. 74
end