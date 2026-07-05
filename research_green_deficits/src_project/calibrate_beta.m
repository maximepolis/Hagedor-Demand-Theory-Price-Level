function [beta_star, out] = calibrate_beta(pg, r_target, b_target, D_level)
% CALIBRATE_BETA  Calibration step C1 (roadmap U3): choose the discount
% factor so that the no-program stationary equilibrium matches a target real
% debt level (debt-to-income ratio, since mean income is normalized).
%
% TARGET (calibration appendix, "known tension 1"):
%     S(1 + r_target; tau = r*S, damages D_level) = b_target,
% i.e. real government debt held in equilibrium equals b_target * mean income
% (OECD general-government debt/GDP ~ 1.0-1.2; default target 1.1).
%
% METHOD: bisection over beta. Aggregate assets are strictly increasing in
% beta (more patience => more buffer stock), so the map is monotone. Each
% evaluation runs the root package's tau = r*S fixed point
% (aggregate_asset_demand) with endowments scaled by (1 - D_level).
%
% INPUTS
%   pg       : project params (grids, tolerances, income process).
%   r_target : policy real rate at which to hit the target.
%   b_target : target real debt / mean income (e.g. 1.1).
%   D_level  : damage level of the calibration state (medium column).
%
% OUTPUTS
%   beta_star : calibrated discount factor.
%   out       : .trace (beta, S per iteration), .S_at_star, .converged.
%
% STATUS: IMPLEMENTED. The resulting beta is a CALIBRATED value (target:
% debt/GDP) once this routine has been run; until then all reported numbers
% remain from the illustrative benchmark.

    lo = 0.85; hi = 0.955;      % asymptote guard: hi*(1+r) < betaR_max
    if hi*(1 + r_target) >= pg.betaR_max
        hi = pg.betaR_max/(1 + r_target) - 1e-3;
    end

    trace = [];
    S_of_beta = @(bb) eval_S(pg, bb, r_target, D_level);

    S_lo = S_of_beta(lo);  S_hi = S_of_beta(hi);
    trace = [trace; lo, S_lo; hi, S_hi];
    fprintf('  [calibrate_beta] S(%.3f)=%.3f  S(%.3f)=%.3f  target=%.3f\n', ...
            lo, S_lo, hi, S_hi, b_target);
    if ~(S_lo < b_target && S_hi > b_target)
        warning('calibrate_beta:bracket', ...
            'Target %.3f not bracketed by [%.3f, %.3f]; returning closest end.', ...
            b_target, S_lo, S_hi);
        if abs(S_lo - b_target) < abs(S_hi - b_target), beta_star = lo;
        else, beta_star = hi; end
        out = struct('trace', trace, 'S_at_star', NaN, 'converged', false);
        return;
    end

    for it = 1:14
        mid  = 0.5*(lo + hi);
        S_md = S_of_beta(mid);
        trace = [trace; mid, S_md]; %#ok<AGROW>
        fprintf('  [calibrate_beta %2d] beta=%.4f  S=%.4f\n', it, mid, S_md);
        if abs(S_md - b_target) < 5e-3 || (hi - lo) < 2e-4
            lo = mid; hi = mid; break;
        end
        if S_md < b_target, lo = mid; else, hi = mid; end
    end
    beta_star = 0.5*(lo + hi);

    out = struct();
    out.trace     = trace;
    out.S_at_star = S_of_beta(beta_star);
    out.converged = abs(out.S_at_star - b_target) < 2e-2;
    fprintf('  [calibrate_beta] beta* = %.4f (S=%.4f, target %.3f)\n', ...
            beta_star, out.S_at_star, b_target);
end

% -------------------------------------------------------------------------
function S = eval_S(pg, bb, r, D)
% No-program equilibrium asset level at candidate beta: the root package's
% tau = r*S fixed point in the SAME economy the results use.
%
% AUDIT FIX: the previous version scaled endowments by (1-D) only and
% omitted the climate RISK channel sig_eps(D) = sig_eps0*(1+phi_D*D) and
% the incidence gradient that S_green applies -- so beta* was calibrated
% in a lower-risk economy than the one all results are computed in (with
% phi_D = 0.5 active by default, the calibration missed its own debt
% target). eval_S now mirrors S_green's income-process rebuild and
% damage/incidence scaling exactly, so the calibration and results
% economies coincide. NOTE: this shifts beta* slightly vs earlier runs --
% main_project_calibrated must be re-run to refresh the calibrated pass.
    p = pg;
    p.beta = bb;

    % (1) risk channel: rebuild the income process at sig_eps(D)
    if pg.phi_D > 0
        p.sig_eps = pg.sig_eps0 * (1 + pg.phi_D * D);
        [eG, PiD, statD] = make_income_process(p);
        p.eGrid = eG; p.Pi = PiD; p.stationary_e = statD;
    end

    % (2) damage level / incidence channel on the (possibly rebuilt) grid
    psi = 0;
    if isfield(pg, 'psi_inc') && ~isempty(pg.psi_inc), psi = pg.psi_inc; end
    if psi > 0
        ev = p.eGrid(:); wst = p.stationary_e(:);
        cnorm = wst' * (ev.^(1 - psi));
        chi   = (ev.^(-psi)) / cnorm;
        scale = max(1 - D * chi, 0.05);
        p.eGrid = (scale .* ev)';
    else
        p.eGrid = (1 - D) * p.eGrid;
    end

    [S, ~] = aggregate_asset_demand(r, p);
    if ~isfinite(S), S = 1e6; end     % divergence counts as "too high"
end
