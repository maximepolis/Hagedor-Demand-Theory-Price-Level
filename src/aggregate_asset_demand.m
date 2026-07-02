function [S, out] = aggregate_asset_demand(r, params)
% AGGREGATE_ASSET_DEMAND  Steady-state aggregate real asset demand S(1+r) of
% the incomplete-markets economy, i.e. the central object of the DTPL.
%
% For a candidate real rate r, this solves the fixed point
%       S = S(1+r, tau = r*S),
% where the steady-state government budget constraint in the baseline no-spending
% model requires taxes to service the real return on outstanding assets,
%       tau_ss = r * S_ss
% (interest on real government liabilities financed by lump-sum taxes). This is
% the OUTER loop; the household block (VFI/EGM + stationary distribution) is the
% INNER solve.
%
% INPUT
%   r      : scalar real rate OR vector of real rates.
%   params : struct from setup_params.
%
% OUTPUT
%   S   : aggregate asset demand. Scalar if r scalar; row vector if r vector.
%   out : struct of diagnostics.
%         Scalar r : .S .tau .C .meanE .betaR .converged .fp_iter .fp_err
%                    .dist .polA .polC .polA_idx .hhdiag .distdiag .diverged .r
%         Vector r : .r .S .tau .C .converged .diverged .betaR (all 1 x nr)
%
% ROBUSTNESS
%   As beta*(1+r) -> 1 (r -> 1/beta-1) incomplete-markets asset demand DIVERGES.
%   The routine refuses r with beta*(1+r) >= betaR_max, flags .diverged, and
%   returns S = Inf rather than crashing (see existence conditions, Section 2).
%
% PAPER SECTION: Sections 2.2-2.4 (asset-demand function and its fixed point).

    r = r(:)';                          % ensure row vector handling
    nr = numel(r);

    if nr > 1
        % -------- vector case: loop over rates --------
        S         = nan(1, nr);
        tauv      = nan(1, nr);
        Cv        = nan(1, nr);
        convv     = false(1, nr);
        divv      = false(1, nr);
        betaRv    = params.beta * (1 + r);
        p         = params;
        p.quiet_divergence = true;       % status line below replaces warnings
        lastS     = params.S_guess;      % warm-start each rate at the previous S
        for m = 1:nr
            p.S_guess = lastS;
            [Sm, om] = solve_one_rate(r(m), p);
            S(m)     = Sm;
            tauv(m)  = om.tau;
            Cv(m)    = om.C;
            convv(m) = om.converged;
            divv(m)  = om.diverged;
            if om.converged && isfinite(Sm)
                lastS = Sm;
                status = 'ok';
            elseif om.diverged
                status = 'DIVERGED (treated as S=Inf)';
            else
                status = 'NO CONVERGENCE';
            end
            fprintf('  [S(1+r) sweep %2d/%2d] r=%+.4f  S=%9.4f  %s\n', ...
                    m, nr, r(m), Sm, status);
        end
        out = struct();
        out.r         = r;
        out.S         = S;
        out.tau       = tauv;
        out.C         = Cv;
        out.converged = convv;
        out.diverged  = divv;
        out.betaR     = betaRv;
        return;
    end

    % -------- scalar case --------
    [S, out] = solve_one_rate(r, params);
end

% =========================================================================
function [S, out] = solve_one_rate(r, params)
    out = struct();
    out.r        = r;
    out.betaR    = params.beta * (1 + r);
    out.diverged = false;

    % In vector sweeps the caller prints a DIVERGED status line per rate, so
    % expected divergences are reported quietly (no warning stack traces).
    quiet = isfield(params, 'quiet_divergence') && params.quiet_divergence;

    % Existence guard: asset demand unbounded as beta(1+r) -> 1.
    if out.betaR >= params.betaR_max
        S = Inf;
        out.S = Inf; out.tau = NaN; out.C = NaN; out.meanE = NaN;
        out.converged = false; out.diverged = true;
        out.fp_iter = 0; out.fp_err = NaN;
        if ~quiet
            warning('aggregate_asset_demand:asymptote', ...
                'beta*(1+r)=%.4f >= betaR_max=%.4f: asset demand diverges (r=%.4f).', ...
                out.betaR, params.betaR_max, r);
        end
        return;
    end

    solver = pick_solver(params);

    % Lump-sum tax feasibility bound: the poorest household at the borrowing
    % constraint (a = amin, e = e_min) has maximum consumption
    %   c_max = r*amin + e_min - tau   (choosing a' = amin),
    % so the economy only exists when tau < e_min + r*amin. Since tau = r*S and
    % S(1+r) blows up as beta(1+r) -> 1, the implied tax crosses this bound
    % BEFORE the asymptote; when it does we declare divergence (economic
    % non-existence at this r) instead of iterating on an infeasible problem.
    amin        = -params.abar;
    e_min       = min(params.eGrid);
    tau_feasmax = e_min + r*amin - 1e-6;

    S   = params.S_guess;
    err = Inf; it = 0;
    diverged = false;
    hhdiag = struct(); distdiag = struct();
    dist = []; polA = []; polC = []; polA_idx = [];
    while it < params.maxit_S
        it = it + 1;
        tau = r * S;                                    % tau_ss = r_ss * S_ss
        if tau > tau_feasmax
            diverged = true;
            if ~quiet
                warning('aggregate_asset_demand:infeasible_tau', ...
                    ['tau=r*S=%.4f exceeds the feasibility bound %.4f (minimum ' ...
                     'income at the constraint): treating S(1+r) as divergent ' ...
                     'at r=%.4f.'], tau, tau_feasmax, r);
            end
            break;
        end
        [~, polA_idx, polA, polC, hhdiag] = solver(r, tau, params);
        [dist, distdiag] = compute_stationary_distribution(polA_idx, params.Pi, params);

        Stilde = params.aGrid(:)' * sum(dist, 2);       % E[a]
        if ~isfinite(Stilde) || abs(Stilde) > 1e6
            diverged = true;
            break;
        end
        err = abs(Stilde - S);
        S   = params.lambda_S * Stilde + (1 - params.lambda_S) * S;
        if err < params.tol_S
            break;
        end
    end

    % aggregates and checks
    if ~isempty(dist)
        C     = sum(sum(polC .* dist));
        meanE = params.eGrid(:)' * sum(dist, 1)';       % should equal ~1
    else
        C = NaN; meanE = NaN;
    end

    out.S         = S;
    out.tau       = r * S;
    out.C         = C;
    out.meanE     = meanE;
    out.converged = (err < params.tol_S) && ~diverged;
    out.diverged  = diverged;
    out.fp_iter   = it;
    out.fp_err    = err;
    out.dist      = dist;
    out.polA      = polA;
    out.polC      = polC;
    out.polA_idx  = polA_idx;
    out.hhdiag    = hhdiag;
    out.distdiag  = distdiag;

    if diverged
        S = Inf; out.S = Inf;
    end
    if ~out.converged && ~diverged
        warning('aggregate_asset_demand:noconv', ...
            'Outer S fixed point did not converge: err=%.3e after %d iters (r=%.4f).', ...
            err, it, r);
    end
end

% =========================================================================
function solver = pick_solver(params)
    if isfield(params, 'hh_method') && strcmpi(params.hh_method, 'egm')
        solver = @solve_household_egm;
    else
        solver = @solve_household_vfi;   % canonical
    end
end
