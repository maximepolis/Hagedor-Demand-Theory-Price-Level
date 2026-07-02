function out = solve_capital_extension(params)
% SOLVE_CAPITAL_EXTENSION  DTPL with a production/capital sector. Adding capital
% introduces ONE extra real equation that pins K^*; asset-market clearing still
% pins down the price level P^*. The point (paper's capital section) is that
% capital does NOT remove price-level determinacy.
%
% PRODUCTION  Cobb-Douglas Y = F(K,1) = K^alpha, capital depreciation delta.
%   Steady-state real rate from the capital Euler / firm FOC:
%       F_K(K^*,1) + 1 - delta = 1 + r^ss
%       => alpha K^{alpha-1} + 1 - delta = 1 + r^ss
%       => K^* = ( alpha / (r^ss + delta) )^{1/(1-alpha)}.
%   Wage from the labor FOC:  w = F_L(K^*,1) = (1-alpha) K^{*alpha}.
%
% ASSET MARKET  Households hold capital AND government bonds:
%       K^* + B/P^* = S(1 + r^ss)
%   =>  P^* = B / ( S(1+r^ss) - K^* ),   provided S(1+r^ss) > K^*.
%   If S(1+r^ss) <= K^* there is no positive finite price level.
%
% HOUSEHOLDS  Budget c + a' = (1+r) a + w e - tau, with tau financing the real
%   interest on government bonds only, tau = r * b = r * (S - K^*). Solved by a
%   small outer fixed point over S (analogous to aggregate_asset_demand).
%
% INPUT
%   params : struct from setup_params. Optional fields params.alpha (0.36),
%            params.delta (0.08).
%
% OUTPUT
%   out : struct with .r_ss .Kstar .w .S_assets .Pstar .exists .msg and the
%         underlying household solution.
%
% PAPER SECTION: capital extension.

    if isfield(params,'alpha') && ~isempty(params.alpha), alpha = params.alpha; else, alpha = 0.36; end
    if isfield(params,'delta') && ~isempty(params.delta), delta = params.delta; else, delta = 0.08; end

    i_ss  = params.i_ss;
    pi_ss = params.pi_ss;
    Bnom  = params.Bnom;
    r_ss  = (1 + i_ss)/(1 + pi_ss) - 1;

    out = struct();
    out.alpha = alpha; out.delta = delta; out.r_ss = r_ss;

    % Need r_ss + delta > 0 and beta(1+r) < 1
    if (r_ss + delta) <= 0
        out.exists = false;
        out.msg = 'Capital extension: r^ss + delta <= 0, K^* undefined.';
        warning('solve_capital_extension:badrate','%s', out.msg); return;
    end

    Kstar = ( alpha / (r_ss + delta) )^(1/(1-alpha));
    w     = (1 - alpha) * Kstar^alpha;
    out.Kstar = Kstar;
    out.w     = w;

    % household params with wage income
    p = params;
    p.eGrid = w * params.eGrid;      % labor income w*e

    % outer fixed point: S with tau = r*(S - K^*) (bond interest financing)
    if params.beta*(1+r_ss) >= params.betaR_max
        out.exists = false; out.S_assets = Inf; out.Pstar = NaN;
        out.msg = 'Capital extension: beta*(1+r^ss) too high, asset demand diverges.';
        warning('solve_capital_extension:asymptote','%s', out.msg); return;
    end

    % lump-sum feasibility bound with wage income w*e (see aggregate_asset_demand)
    tau_feasmax = min(p.eGrid) + r_ss*(-p.abar) - 1e-6;

    S = max(params.S_guess, Kstar + 0.5);
    err = Inf; it = 0; dist=[]; polC=[];
    while it < params.maxit_S
        it = it + 1;
        b   = S - Kstar;                     % real bond holdings
        tau = r_ss * b;                      % taxes finance bond interest
        if tau > tau_feasmax
            warning('solve_capital_extension:infeasible_tau', ...
                ['tau=%.4f exceeds feasibility bound %.4f: asset demand ' ...
                 'divergent at r=%.4f.'], tau, tau_feasmax, r_ss);
            S = Inf;
            break;
        end
        [~, polA_idx, polA, polC, ~] = solve_household_vfi(r_ss, tau, p);
        [dist, ~] = compute_stationary_distribution(polA_idx, p.Pi, p);
        Stilde = p.aGrid(:)' * sum(dist, 2);
        err = abs(Stilde - S);
        S = params.lambda_S*Stilde + (1-params.lambda_S)*S;
        if err < params.tol_S, break; end
    end
    out.S_assets = S;
    out.fp_iter  = it; out.fp_err = err;

    if S > Kstar && isfinite(S)
        out.Pstar  = Bnom / (S - Kstar);
        out.breal  = S - Kstar;
        out.exists = true;
        out.msg = sprintf(['Capital extension: K^*=%.4f, S=%.4f, ' ...
            'P^* = B/(S-K^*) = %.4f. Determinacy preserved.'], Kstar, S, out.Pstar);
    else
        out.Pstar  = NaN; out.breal = S - Kstar; out.exists = false;
        out.msg = sprintf(['Capital extension: S(1+r^ss)=%.4f <= K^*=%.4f, ' ...
            'no positive finite price level.'], S, Kstar);
        warning('solve_capital_extension:noprice','%s', out.msg);
    end

    if ~isempty(dist)
        out.C = sum(sum(polC .* dist));
        out.dist = dist;
    end
end
