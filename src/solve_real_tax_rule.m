function [roots, out] = solve_real_tax_rule(params, tau_star, gamma, i_ss, Bnom)
% SOLVE_REAL_TAX_RULE  Steady state under a REAL tax rule of the form
%       tau_t = tau^* + gamma ( r_t b_t - tau^* ),   b_t = B_t / P_t.
% In steady state, for gamma ~= 1, the nominal budget constraint implies that
% inflation depends on the price level:
%       1 + pi^ss = 1 + i^ss - (P / B) * tau^*.
% The steady-state price level therefore solves the asset-market condition
%       S( (1+i^ss)/(1+pi^ss(P)) ) = B / P,
% which is a NONLINEAR equation in P that need not have a unique solution.
%
% INPUTS
%   params   : struct from setup_params.
%   tau_star : target real primary surplus tau^* in the rule.
%   gamma    : feedback coefficient (recorded; steady-state pi depends on it only
%              through the gamma~=1 case, retained for documentation/interface).
%   i_ss     : steady-state nominal interest rate.
%   Bnom     : nominal debt.
%
% OUTPUTS
%   roots : column vector of ALL positive price-level roots found (may be empty,
%           unique, or multiple -- the paper stresses non-uniqueness is possible).
%   out   : struct with .Pgrid .resid (residual over the scan grid), .r_at_root,
%           .pi_at_root, .S_at_root, .ad (asset-demand interpolant), .msg,
%           .sign_changes.
%
% METHOD
%   Scan a positive grid of P for sign changes of the residual
%       F(P) = S(r(P)) - B/P,   r(P) = (1+i^ss)/(1+pi(P)) - 1,
%   then refine each bracket with fzero. Uses a precomputed S(r) interpolant so
%   the household problem is not re-solved at every trial P. Does NOT stop at the
%   first root.
%
% PAPER SECTION: real tax rules (Figure 3 analogue).

    if nargin < 4 || isempty(i_ss), i_ss = params.i_ss; end
    if nargin < 5 || isempty(Bnom), Bnom = params.Bnom; end

    % Precompute S(r) interpolant on a real-rate grid.
    ad = asset_demand_interp(params);

    % inflation as a function of P:  1+pi(P) = 1 + i_ss - (P/B) tau^*
    gross_pi = @(P) (1 + i_ss) - (P ./ Bnom) * tau_star;
    r_of_P   = @(P) (1 + i_ss) ./ gross_pi(P) - 1;

    % residual F(P) = S(r(P)) - B/P
    F = @(P) resid_fun(P, r_of_P, ad, Bnom);

    % ----- scan for sign changes -----
    Pgrid = linspace(params.P_min, params.P_max, params.nP);
    Fvals = arrayfun(F, Pgrid);

    roots = [];
    sign_changes = 0;
    for k = 1:numel(Pgrid)-1
        f1 = Fvals(k); f2 = Fvals(k+1);
        if isfinite(f1) && isfinite(f2) && (f1 == 0)
            roots(end+1,1) = Pgrid(k); %#ok<AGROW>
        elseif isfinite(f1) && isfinite(f2) && (sign(f1) ~= sign(f2))
            sign_changes = sign_changes + 1;
            try
                pr = fzero(F, [Pgrid(k), Pgrid(k+1)], ...
                           optimset('TolX', params.tol_root));
                if isfinite(pr) && pr > 0
                    roots(end+1,1) = pr; %#ok<AGROW>
                end
            catch ME
                warning('solve_real_tax_rule:fzero', ...
                    'fzero failed on bracket [%.4f, %.4f]: %s', ...
                    Pgrid(k), Pgrid(k+1), ME.message);
            end
        end
    end
    roots = uniquetol_local(roots, 1e-6);

    % ----- diagnostics at each root -----
    r_at   = r_of_P(roots);
    pi_at  = gross_pi(roots) - 1;
    S_at   = arrayfun(ad.S_of_r, r_at);

    out = struct();
    out.Pgrid        = Pgrid;
    out.resid        = Fvals;
    out.ad           = ad;
    out.r_at_root    = r_at;
    out.pi_at_root   = pi_at;
    out.S_at_root    = S_at;
    out.sign_changes = sign_changes;
    out.tau_star     = tau_star;
    out.gamma        = gamma;
    out.i_ss         = i_ss;
    out.Bnom         = Bnom;

    if isempty(roots)
        out.msg = sprintf(['No positive price-level root found on [%.3f, %.3f] ' ...
            '(%d sign changes). Residual signs: F(Pmin)=%+.3e, F(Pmax)=%+.3e.'], ...
            params.P_min, params.P_max, sign_changes, Fvals(1), Fvals(end));
        warning('solve_real_tax_rule:noroot', '%s', out.msg);
    elseif numel(roots) == 1
        out.msg = sprintf('Unique steady-state price level P* = %.4f.', roots(1));
    else
        out.msg = sprintf('MULTIPLE steady-state price levels found: %s.', ...
            mat2str(roots', 5));
    end
end

% -------------------------------------------------------------------------
function v = resid_fun(P, r_of_P, ad, Bnom)
    r = r_of_P(P);
    S = ad.S_of_r(r);            % NaN outside converged range
    if ~isfinite(S) || P <= 0
        v = NaN;
    else
        v = S - Bnom / P;
    end
end

% -------------------------------------------------------------------------
function u = uniquetol_local(x, tol)
% Simple tolerance-based unique for a small vector of roots (avoids toolbox).
    x = sort(x(:));
    if isempty(x), u = x; return; end
    u = x(1);
    for k = 2:numel(x)
        if abs(x(k) - u(end)) > tol
            u(end+1,1) = x(k); %#ok<AGROW>
        end
    end
end
