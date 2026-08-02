function [beta_star, eq0] = calib_beta(rb, d, D, g, lv, Bnom, Kbar, btH, iota, p, q_ref, t0)
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
    % LEVEL calibration: beta targets the direct liquid holding S_b.
    %
    % Why beta and not chi. Household liquid wealth factors as S_b = omega*W,
    % where omega is the liquid SHARE and W total wealth. chi moves only
    % omega. The infrequent-adjustment friction raises W sharply (the tree is
    % a poor buffer, so households self-insure with more of everything: at the
    % frictionless-calibrated beta, W = 3.3 -> 6.8 x income) AND raises
    % omega's floor (absent a liquidity premium an illiquid asset is dominated
    % as a buffer, so bond demand cannot be squeezed below it). Both moves
    % push S_b UP, and chi -> 0 merely asymptotes to omega_min*W. beta is the
    % instrument that moves W, hence the only one that reaches the level.
    %
    % Monotone: lower beta -> less patient -> lower W -> lower S_b. Lowering
    % beta also deflates q (raising the tree's dividend yield toward a
    % plausible value) and thins liquid buffers, which is what generates the
    % wealthy-hand-to-mouth mass the friction is there to deliver.
    b0 = p.beta;
    beta_grid = b0 * [0.95 0.97 0.985 1.00];
    eq0 = []; beta_star = b0; best = Inf;
    bb = b0; bb_p = NaN; e_p = NaN;
    for k = 1:numel(beta_grid)
        pk = p; pk.beta = beta_grid(k);
        eqk = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pk, q_ref, false);
        if ~eqk.ok
            fprintf('[%5.0fs] pre-scan beta=%.5f FAILED (%s)\n', toc(t0), beta_grid(k), eqk.msg);
            continue;
        end
        err = log(eqk.Sb) - log(btH);
        fprintf('[%5.0fs] pre-scan beta=%.5f S_b=%.4f q=%.3f W=%.3f err=%+.4f (min_c=%.3f)\n', ...
            toc(t0), beta_grid(k), eqk.Sb, eqk.q, eqk.Sb + eqk.q*Kbar, err, eqk.min_c);
        if abs(err) < best
            best = abs(err); eq0 = eqk; beta_star = beta_grid(k); bb = beta_grid(k);
        end
    end
    if isempty(eq0), return; end
    % secant in beta from the best pre-scan point
    err = log(eq0.Sb) - log(btH);
    nfail = 0; damp = 1;
    for itc = 1:8
        if abs(err) < 2e-2, break; end
        if isfinite(e_p) && abs(err - e_p) > 1e-9
            step = -err*(bb - bb_p)/(err - e_p);
        else
            step = -sign(err) * 0.015 * b0;      % err>0 (S_b too high) -> beta down
        end
        step = damp * max(min(step, 0.02*b0), -0.02*b0);   % damped trust region
        bb_try = min(max(bb + step, 0.80), 0.9995); % keep beta admissible
        if abs(bb_try - bb) < 1e-6, break; end
        pk = p; pk.beta = bb_try;
        eqk = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pk, q_ref, false);
        if ~eqk.ok
            fprintf('[%5.0fs] secant beta=%.5f FAILED (%s)\n', toc(t0), bb_try, eqk.msg);
            nfail = nfail + 1; damp = 0.4*damp;  % retry closer to the feasible point
            if nfail >= 3
                fprintf(['[calib] beta secant stalled; reporting best feasible ' ...
                    'S_b=%.4f at beta=%.5f.\n'], eq0.Sb, beta_star);
                break;
            end
            continue;                            % keep (bb, err); retry a shorter step
        end
        nfail = 0; damp = min(1, 2*damp);
        bb_p = bb; e_p = err; bb = bb_try;
        eq0 = eqk; beta_star = bb_try; err = log(eqk.Sb) - log(btH);
        fprintf('[%5.0fs] secant beta=%.5f S_b=%.4f q=%.3f W=%.3f err=%+.4f (min_c=%.3f)\n', ...
            toc(t0), beta_star, eqk.Sb, eqk.q, eqk.Sb + eqk.q*Kbar, err, eqk.min_c);
    end
end

