function [chi_star, eq0] = calib_chi(rb, d, D, g, lv, Bnom, Kbar, btH, iota, p, q_ref, chi0, t0)
% MOVED, NOT COPIED, round 10 (decision D10).
%
% This function was a local function of main_twoasset_ownership_kv.m. Track B
% of the two-asset certification protocol must recalibrate on every grid, and
% a local function cannot be called from anywhere else -- so the alternative
% was a second calibration implementation. That is exactly the defect this
% round exists to prevent: two implementations of one object drift, and the
% drift is silent because both "work".
%
% The body below is the original, moved verbatim. The calling script now calls
% this file. Any change here changes the paper's calibration.
    % coarse pre-scan (log-spaced around chi0) to bracket the target before
    % the secant. The KV household holds more bonds per unit chi than the
    % frictionless one, so the target lives at SMALL chi -- start low and
    % stay in the feasible region (high chi -> S_b overshoot -> low P ->
    % high tax -> infeasible-poor states).
    chi_grid = chi0 * [0.25 0.5 1 2 4];
    eq0 = []; chi_star = chi0; best = Inf;
    lc = log(chi0); lc_p = NaN; e_p = NaN;
    for k = 1:numel(chi_grid)
        pk = p; pk.chi_b = chi_grid(k);
        eqk = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pk, q_ref, false);
        if ~eqk.ok
            fprintf('[%5.0fs] pre-scan chi=%.5f FAILED (%s)\n', toc(t0), chi_grid(k), eqk.msg);
            continue;
        end
        err = log(eqk.Sb) - log(btH);
        fprintf('[%5.0fs] pre-scan chi=%.5f S_b=%.4f err=%+.4f (min_c=%.3f)\n', ...
            toc(t0), chi_grid(k), eqk.Sb, err, eqk.min_c);
        if abs(err) < best, best = abs(err); eq0 = eqk; chi_star = chi_grid(k); lc = log(chi_grid(k)); end
    end
    if isempty(eq0), return; end                 % nothing solved -- report to caller
    % secant refinement from the best pre-scan point
    err = log(eq0.Sb) - log(btH);
    nfail = 0;                                    % consecutive-failure guard
    for itc = 1:8
        if abs(err) < 8e-3, break; end
        if isfinite(e_p) && abs(err-e_p) > 1e-9
            step = -err*(lc-lc_p)/(err-e_p); step = max(min(step,1.0),-1.0);
        else, step = -sign(err)*0.3; end
        lc_p_try = lc; lc = lc + step;
        pk = p; pk.chi_b = exp(lc);
        eqk = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pk, q_ref, false);
        if ~eqk.ok
            fprintf('[%5.0fs] secant chi=%.4f FAILED (%s)\n', toc(t0), exp(lc), eqk.msg);
            nfail = nfail + 1;
            % Target below the KV solvable floor: the household solve breaks
            % down as bond demand approaches its no-liquidity-premium corner.
            % Stop after two consecutive failures and report the closest
            % FEASIBLE equilibrium rather than burning hours in the cliff.
            if nfail >= 2
                fprintf(['[calib] direct-liquid target %.2f is below the KV solvable ' ...
                    'floor (best feasible S_b=%.4f at chi=%.5f); stopping secant.\n'], ...
                    btH, eq0.Sb, chi_star);
                break;
            end
            lc = lc_p_try;                        % step back to the feasible side
            continue;
        end
        nfail = 0;
        lc_p = lc_p_try; e_p = err;
        eq0 = eqk; chi_star = exp(lc); err = log(eqk.Sb) - log(btH);
        fprintf('[%5.0fs] secant chi=%.5f S_b=%.4f err=%+.4f (min_c=%.3f)\n', ...
            toc(t0), chi_star, eqk.Sb, err, eqk.min_c);
    end
end

