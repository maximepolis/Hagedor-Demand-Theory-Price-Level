function [beta_star, chi_star, eq0] = calib_beta_chi(rb, d, D, g, lv, Bnom, Kbar, ...
                                          btH, Wt, iota, p, q_ref, t0)
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
% NOTE: this header sits BELOW the complete signature on purpose. It used
% to sit between the two lines of the continued argument list, which is a
% MATLAB parse error -- a `...` promises the statement continues, and a
% comment-only line is not a continuation. The file could not be parsed at
% all, so the two-instrument calibration was unreachable; nothing caught it
% because the shipped benchmark leaves W_targ empty and never calls it.
% paper/check_matlab_blocks.py now checks for this class.
    % TWO-INSTRUMENT calibration (referee item M3): beta and chi_b jointly
    % target total household wealth W and the liquid share omega.
    %
    % WHY THIS PAIRING. Both instruments raise the direct liquid holding
    % S_b, so targeting (W, S_b) with (beta, chi) is a near-collinear system
    % and the Newton is ill-conditioned. The economics is triangular
    % instead: beta sets the LEVEL of precautionary wealth (patience), chi
    % sets the SHARE held liquid (the convenience yield). Targeting
    % (W, omega) exploits that, and since S_b = omega * W, hitting both
    % delivers the direct-holding target as a by-product -- the residuals
    % satisfy r_W + r_omega = log S_b - log btH exactly.
    %
    % Solved by damped Broyden in (log beta, log chi) with a finite-
    % difference seed. beta is clamped below the 1/(1+r) boundary, where
    % aggregate asset demand diverges and the calibration stops being
    % economically identified rather than merely numerically hard.
    om_t   = btH / Wt;                          % implied liquid-share target
    lb_max = log(0.999/(1 + rb));               % patience boundary
    chi_lo = 0.10 * max(p.chi_b, 1e-12);        % identification floor, see below
    x  = [min(log(p.beta), lb_max); log(max(p.chi_b, 1e-8))];
    ev = @(xx) eval_own(rb, d, D, g, lv, Bnom, Kbar, iota, ...
                        setfield(setfield(p, 'beta', exp(min(xx(1), lb_max))), ...
                                 'chi_b', exp(xx(2))), q_ref); %#ok<SFLD>
    beta_star = p.beta; chi_star = p.chi_b; eq0 = [];

    [r, eqx] = resid_of(ev(x), Wt, om_t);
    if isempty(eqx), fprintf('  2D calibration: initial point infeasible\n'); return; end
    eq0 = eqx; beta_star = exp(min(x(1), lb_max)); chi_star = exp(x(2));
    report2d(t0, 0, x, eqx, r, lb_max);

    % finite-difference seed for the Jacobian (2 extra solves)
    h = 0.02; J = zeros(2,2);
    for j = 1:2
        xp = x; xp(j) = xp(j) + h;
        [rp, eqp] = resid_of(ev(xp), Wt, om_t);
        if isempty(eqp), rp = r + h*[1;1]; end   % crude fallback: keep it invertible
        J(:,j) = (rp - r)/h;
    end
    if abs(det(J)) < 1e-8, J = J + 1e-3*eye(2); end

    best = norm(r);
    for it = 1:12
        if norm(r, Inf) < 2e-2, break; end
        % IDENTIFICATION GUARD. chi moves the liquid share only from ABOVE:
        % with infrequent rebalancing the tree is a poor buffer, so
        % self-insurance holds a minimum liquid position whatever the
        % convenience weight, and omega is bounded below by that floor.
        % Below the floor chi is not identified -- the solver keeps cutting
        % it for no movement in omega, and lands at chi ~ 0, where the
        % convenience yield the KVJ evidence disciplines has been removed
        % and the tree market approaches the flat-demand boundary of
        % Proposition~determinacy. Stop and report the floor instead: it is
        % a property of the model, not a solver failure.
        if exp(x(2)) < chi_lo
            fprintf(['  2D calibration: chi has fallen below %.1e (a tenth of ' ...
                     'its\n  disciplined value) while omega has stalled at ' ...
                     '%.3f against a %.3f\n  target. The liquid share is at ' ...
                     'its floor and chi is not identified\n  below it; ' ...
                     'reporting the best identified point.\n'], ...
                    chi_lo, eq0.Sb/max(eq0.Sb + eq0.q*eq0.Kbar, 1e-12), om_t);
            break;
        end
        dx = -(J \ r);
        st = min(1, 0.35/max(abs(dx)));          % trust region in logs
        accepted = false;
        for bt = 1:5                             % backtracking
            xn = x + st*dx; xn(1) = min(xn(1), lb_max);
            [rn, eqn] = resid_of(ev(xn), Wt, om_t);
            if ~isempty(eqn) && norm(rn) < norm(r)
                dr = rn - r; s = xn - x;
                J = J + ((dr - J*s) * s.') / max(s.'*s, 1e-12);   % Broyden
                x = xn; r = rn;
                if norm(r) < best
                    best = norm(r); eq0 = eqn;
                    beta_star = exp(min(x(1), lb_max)); chi_star = exp(x(2));
                end
                accepted = true; break;
            end
            st = st/2;
        end
        report2d(t0, it, x, eq0, r, lb_max);
        if ~accepted
            fprintf('  2D calibration: no improving step; keeping the best point\n');
            break;
        end
    end
end

