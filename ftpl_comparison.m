function res = ftpl_comparison(par, ad)
% FTPL_COMPARISON  Demand Theory of the Price Level (DTPL) vs Fiscal Theory (FTPL).
% Implements Sections 3.5.1, 3.5.4-3.5.5 and Appendix B:
%  * DTPL: asset-market clearing P* = B/S((1+i)/(1+pi))           (Eq. 22)
%  * FTPL: present-value gov. budget with ACTIVE policy and (1+r)=1/beta:
%          P_FTPL = B(1+i)(1-beta)/s = B(1+pi)r/s                 (Eq. 27)
%  * Generic non-equivalence: equating them requires S(1+i)=(tau-g)/i (Eq. A.36),
%    which fails since S->inf as 1+r->1/beta while the RHS stays finite.
%  * Passive-policy present-value identity (Eq. 43) is trivially satisfied for
%    ANY P0 -> cannot pin the price level; only asset clearing does.
% The paper's mechanism is DTPL, NOT FTPL -- this routine documents the difference.

    if nargin < 2 || isempty(ad), ad = asset_demand_curve(par); end

    i_ss = par.i_ss; pi_ss = par.g_B; bet = par.beta; B = par.B;
    r_ss = (1+i_ss)/(1+pi_ss) - 1;

    % ---- DTPL price level (Eq. 22) ----
    S = ad.Sfun(1+r_ss);
    P_DTPL = B / S;
    tau_ss = r_ss * S;                         % steady-state real surplus = r*S (passive)

    % ---- FTPL "price level" (Eq. 27), complete markets logic, s = tau_ss ----
    s = tau_ss;                                % real primary surplus (no g here)
    P_FTPL = B*(1+i_ss)*(1-bet) / s;           % Eq. 27 (uses 1+r=1/beta)
    res.DTPL.P=P_DTPL; res.DTPL.r=r_ss; res.DTPL.S=S;
    res.FTPL.P=P_FTPL; res.FTPL.s=s;

    % ---- Non-equivalence (Eq. A.35-A.36): would need S(1+i)=(tau-g)/i --------
    g = 0;                                      % no real gov. spending here
    res.eqA36.lhs_S      = ad.Sfun(1+i_ss);     % S(1+i)
    res.eqA36.rhs        = (tau_ss - g)/i_ss;   % (tau-g)/i
    res.eqA36.equal      = abs(res.eqA36.lhs_S - res.eqA36.rhs) < 1e-6;

    % Show S -> inf as 1+r -> 1/beta while RHS stays finite (Eq. A.36 limit)
    rr = linspace(r_ss, 1/bet-1-1e-3, 25).';
    res.limit.onepr = 1+rr;
    res.limit.S     = arrayfun(@(x) ad.Sfun(x), 1+rr);
    res.limit.rhs   = (tau_ss - g)./ (rr);      % finite

    % ---- Passive present-value identity is trivial (Eq. 43): holds for any P0 -
    P0grid = [0.5;1;2]*B;
    lhs = (B./P0grid)*(1+i_ss);
    % RHS = sum_{j>=0} (1/(1+r))^j tau_ss with tau_ss = r*(B/P0) (passive rule, Eq.44)
    rhs = ((1+r_ss)/r_ss) * ( r_ss*(B./P0grid) );   % = (1+r)(B/P0) = (B/P0)(1+i) since pi=... 
    % numerically lhs and rhs coincide for ALL P0 -> identity, cannot pin P0:
    res.identity.P0  = P0grid;
    res.identity.lhs = lhs;
    res.identity.rhs = rhs;
    res.identity.gap = max(abs(lhs-rhs));

    fprintf('\n=== DTPL vs FTPL (Sections 3.5.1, 3.5.4-3.5.5, App. B) ===\n');
    fprintf(' DTPL: P* = B/S((1+i)/(1+pi)) = %.6f  (asset-market clearing, Eq.22)\n', P_DTPL);
    fprintf(' FTPL: P  = B(1+i)(1-beta)/s  = %.6f  (PV gov. budget, Eq.27)\n', P_FTPL);
    fprintf(' Equating them needs S(1+i)=(tau-g)/i: %.4f vs %.4f -> equal? %d (Eq. A.36)\n', ...
             res.eqA36.lhs_S, res.eqA36.rhs, res.eqA36.equal);
    fprintf(' Passive PV identity (Eq.43) gap across P0 in {0.5,1,2}*B: %.2e -> holds for ANY P0\n', ...
             res.identity.gap);
    res.note = ['Passive fiscal policy here -> FTPL is NOT operating; the price level is ', ...
                'pinned by asset-market clearing (DTPL), not the gov. budget identity.'];
end