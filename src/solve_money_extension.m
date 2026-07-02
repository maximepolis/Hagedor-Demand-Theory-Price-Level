function out = solve_money_extension(params)
% SOLVE_MONEY_EXTENSION  DTPL with money in the utility function. Real balances
% m enter separably: E0 sum beta^t [ u(c) + mu(m) ], with
%       mu(m) = chi (m^{1-eta} - 1)/(1 - eta).
% Households hold bonds AND money with budget
%       c + a' + m' = (1+r) a + m/(1+pi) + e - tau.
%
% KEY RESULT (paper's money section): when the central bank sets the nominal
% interest rate i^ss, the money stock M is ENDOGENOUS. Money-market clearing
% M/P = L(.) alone CANNOT determine P (it has two unknowns M and P). It is
% ASSET-MARKET clearing B/P = S(1+r) that pins P; M then adjusts to M = P*L.
%
% STEADY-STATE MONEY DEMAND (separable, simplified demand system)
%   Combining the bond and money first-order conditions in steady state:
%       mu'(m) = u'(c) * [ 1 - 1/((1+r)(1+pi)) ] = u'(c) * i/(1+i)
%   (using the Fisher identity (1+r)(1+pi) = 1+i). With mu'(m)=chi m^{-eta} and
%   evaluating marginal utility at aggregate consumption (u'(C)=C^{-sigma}),
%       L = m = ( chi (1+i) / ( i * C^{-sigma} ) )^{1/eta}.
%   This is a transparent aggregate money-demand schedule L(1+r,1+pi); a full
%   two-asset distributional solve is avoided (see REPLICATION_NOTES).
%
% STEADY-STATE SYSTEM
%   Bonds only        : B/P^* = S(1+r^ss)         => P^*_bonds = B / S
%   Open-market ops   : B/P^* = S(1+r^ss) + L     => P^*_omo   = B / (S + L)
%   Money supply      : M^* = P^* * L             (endogenous)
%
% INPUT
%   params : struct from setup_params. Optional params.chi (0.05), params.eta (2).
%
% OUTPUT
%   out : struct with .i_ss .pi_ss .r_ss .S_assets .L .Pstar_bonds .Pstar_omo
%         .Mstar .msg and existence flags.
%
% PAPER SECTION: money extension.

    if isfield(params,'chi') && ~isempty(params.chi), chi = params.chi; else, chi = 0.05; end
    if isfield(params,'eta') && ~isempty(params.eta), eta = params.eta; else, eta = 2.0; end

    i_ss  = params.i_ss;
    pi_ss = params.pi_ss;
    Bnom  = params.Bnom;
    r_ss  = (1 + i_ss)/(1 + pi_ss) - 1;

    out = struct();
    out.chi = chi; out.eta = eta;
    out.i_ss = i_ss; out.pi_ss = pi_ss; out.r_ss = r_ss;

    % aggregate asset demand (bonds) at the policy real rate
    [S_assets, adout] = aggregate_asset_demand(r_ss, params);
    out.S_assets = S_assets;

    if ~isfinite(S_assets) || S_assets <= 0 || ~adout.converged
        out.exists = false; out.Pstar_bonds = NaN; out.Pstar_omo = NaN;
        out.msg = 'Money extension: asset demand not finite/positive; no price level.';
        warning('solve_money_extension:noS','%s', out.msg); return;
    end

    % aggregate consumption for marginal-utility scaling (endowment => ~1)
    if isfield(adout,'C') && isfinite(adout.C), Cagg = adout.C; else, Cagg = 1.0; end
    upC = Cagg^(-params.sigma);

    % money demand (opportunity cost i/(1+i))
    opp = i_ss / (1 + i_ss);
    if opp <= 0
        L = 0;   % at the zero lower bound money and bonds are perfect substitutes
    else
        L = ( chi * (1 + i_ss) / ( i_ss * upC ) )^(1/eta);
    end
    out.L = L;

    % price levels
    out.Pstar_bonds = Bnom / S_assets;              % asset market pins P
    out.Pstar_omo   = Bnom / (S_assets + L);        % if bonds+money are liabilities
    out.Mstar       = out.Pstar_bonds * L;          % endogenous money supply
    out.exists      = true;

    out.msg = sprintf([ ...
        'Money extension: S=%.4f, L=%.4f. Asset-market clearing pins ' ...
        'P*_bonds = B/S = %.4f (M*=P*L=%.4f endogenous). Under open-market ' ...
        'operations P*_omo = B/(S+L) = %.4f. Money-market clearing ALONE ' ...
        '(M/P=L) cannot determine P because M is endogenous.'], ...
        S_assets, L, out.Pstar_bonds, out.Mstar, out.Pstar_omo);

    fprintf('\n[money extension]\n%s\n', out.msg);
end
