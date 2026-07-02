function res = nominal_tax_rules(par, ad)
% NOMINAL_TAX_RULES  Section 3.5.2. Nominal tax rule (Eq. 30):
%   T_t = omega1*i_t*B_t + omega2*B_t
% => debt growth B_{t+1}/B_t = (1-omega1) i + (1-omega2)        (Eq. 32)
% => steady-state inflation 1+pi_ss = (1-omega1) i_ss + (1-omega2)  (Eq. 33)
% Price level then from asset-market clearing P* = B / S((1+i)/(1+pi)) (Eq. 22).
% Shows how omega1, omega2 shape inflation (and MP (ir)relevance, omega1=1 vs <>1).

    if nargin < 2 || isempty(ad), ad = asset_demand_curve(par); end
    i_ss = par.i_ss;

    % Grid of (omega1, omega2) cases incl. the baseline-equivalent (omega1=1,omega2=-g_B)
    cases = [ ...
        1.0, -par.g_B ;     % MP-irrelevant, replicates constant 2% debt growth
        0.5, -0.01    ;     % omega1<1: higher i -> higher inflation
        1.5, -0.03    ];    % omega1>1: higher i -> lower inflation
    res.cases = cases;

    nC = size(cases,1);
    res.pi = nan(nC,1); res.r = nan(nC,1); res.S = nan(nC,1); res.P = nan(nC,1);
    fprintf('\n=== Nominal tax rules (Section 3.5.2, Eq. 30-33) ===\n');
    for k = 1:nC
        o1 = cases(k,1); o2 = cases(k,2);
        onepi = (1-o1)*i_ss + (1-o2);           % Eq. 33 : 1+pi_ss
        pi_ss = onepi - 1;
        r_ss  = (1+i_ss)/(1+pi_ss) - 1;         % Eq. 17
        if par.beta*(1+r_ss) < 1
            S = ad.Sfun(1+r_ss);
            P = par.B / S;                       % Eq. 22
        else
            S = NaN; P = NaN;
        end
        res.pi(k)=pi_ss; res.r(k)=r_ss; res.S(k)=S; res.P(k)=P;
        fprintf(' omega1=%.2f omega2=%+.2f -> pi_ss=%.4f r_ss=%.4f S=%.4f P*=%.4f\n', ...
                 o1,o2,pi_ss,r_ss,S,P);
    end

    % Show monetary-policy effect on inflation as a function of omega1 (Eq. 33)
    o1g = linspace(0.0,2.0,21).'; o2 = -par.g_B;
    res.o1_grid = o1g;
    res.pi_vs_o1 = (1-o1g)*i_ss + (1-o2) - 1;   % d pi / d i = (1-omega1)
    res.note = 'omega1=1: MP irrelevant for inflation; omega1<1 (>1): higher i raises (lowers) inflation.';
end