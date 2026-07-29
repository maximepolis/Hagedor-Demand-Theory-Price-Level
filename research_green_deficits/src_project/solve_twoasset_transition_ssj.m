function TR = solve_twoasset_transition_ssj(ctx, opts)
% SOLVE_TWOASSET_TRANSITION_SSJ  Newton solve in sequence space for the joint
% announcement path {P_t, q_t} of the two-asset DTPL economy.
%
% WHY NEWTON HERE. The damped fixed point on this system diverges. P_t enters
% both the stationarized bond return (1+r_b) P_{t-1}/P_t and the tax
% tau_t = r^b_t B/P_t, so a rise in P_t cuts the tax twice over; the implied
% local elasticity of bond demand is an order of magnitude above one and no
% scalar relaxation both converges and moves. A Newton step uses the actual
% derivative, including the cross-market blocks that a scalar update ignores,
% and converges from the same starting point the damped map cannot leave.
%
% METHOD (\citealp{auclertetal2021}):
%   * unknown x = [log P_1..P_{T-1}; log q_1..q_{T-1}]; the terminal date is
%     pinned at the program steady state;
%   * residuals are the two market-clearing conditions in logs;
%   * the step is Levenberg-Marquardt on the Gauss-Newton system,
%     (J'J + lam diag(J'J)) dx = -J'r, with J held across iterations and
%     refreshed when progress stalls, since each J costs 2(T-1) residual
%     solves. Plain Newton is the wrong tool: J comes from finite differences
%     on a residual with a nonzero discretization floor, so directions the
%     data do not support must be damped rather than merely shortened. lam
%     adapts on acceptance, and rejection also covers trial steps that push
%     the equity-bond spread non-positive.
%
% DETERMINACY DIAGNOSTIC. At the solution the mechanism is locally determinate
% iff J is invertible. We report sigma_min(J) and cond(J): a near-singular J
% is the sequence-space analogue of the flat asset-demand crossing that
% generates steady-state multiplicity.
%
% OPTS  .newton_maxit (60) .newton_tol (1e-4) .fd_step (1e-2)
%       .refresh_after (10) .verbose (true) .t0 (tic handle)
%         Between full rebuilds the Jacobian is carried by Broyden rank-1
%         updates, so refreshes can be rare: a rebuild is 2(T-1) solves.
%       .x0 (empty) : warm start. Supplying a previously solved path is what
%         makes continuation in the shock size work; from a nearby solution
%         the Newton has a good starting point even when the log-linear
%         bridge does not.
%       .time_budget (900) : wall-clock cap in seconds. The solve stops
%         gracefully and reports its best path rather than running away.
%       .noise_floor (0) : measured discretization floor of the residual. The
%         effective tolerance is max(newton_tol, 5*noise_floor), because no
%         solver can drive a residual below the noise of its own evaluation.
%
% OUTPUT TR .x .Ppath .qpath .Sb .Sk .resid .rnorm .converged .iters
%           .sigma_min .cond_J .J .history

    if nargin < 2, opts = struct(); end
    nmax    = getopt(opts, 'newton_maxit', 60);
    ntol    = getopt(opts, 'newton_tol',  1e-4);
    hfd     = getopt(opts, 'fd_step',     1e-2);
    refresh = getopt(opts, 'refresh_after', 10);
    verbose = getopt(opts, 'verbose', true);
    nfloor  = getopt(opts, 'noise_floor', 0);
    tbudget = getopt(opts, 'time_budget', 900);   % wall-clock cap, seconds
    x0in    = getopt(opts, 'x0', []);             % warm start (continuation)
    Phi     = getopt(opts, 'basis', []);          % (T-1) x K projection basis
    t0      = getopt(opts, 't0', tic);

    T = ctx.T; n = T - 1;
    % PROJECTION. With a basis, the unknown is the coefficient vector and the
    % path is reconstructed as log X_t = log X_term + Phi*a. Without one, the
    % unknown is the path itself (every date free).
    useB = ~isempty(Phi) && size(Phi,1) == n;
    if useB
        K = size(Phi, 2); nvar = 2*K;
        lPT = log(ctx.Pterm); lqT = log(ctx.qterm);
        expand = @(a) [lPT + Phi*a(1:K); lqT + Phi*a(K+1:2*K)];
    else
        K = 0; nvar = 2*n; expand = @(a) a(:);
    end

    lpb = log(linspace(ctx.P0, ctx.Pterm, T+1)); lpb = lpb(2:end-1).';
    lqb = log(linspace(ctx.q0, ctx.qterm, T+1)); lqb = lqb(2:end-1).';
    if ~isempty(x0in) && numel(x0in) == nvar
        a = x0in(:);                 % continue from a previously solved point
    elseif useB
        a = [Phi\(lpb - lPT); Phi\(lqb - lqT)];   % least-squares fit of the bridge
    else
        a = [lpb; lqb];
    end
    x = expand(a);

    [r, aux] = twoasset_transition_residual(expand(a), ctx);
    rn = max(abs(r));               % sup-norm: the economic convergence test
    r2 = norm(r);                   % 2-norm: the merit LM actually minimizes
    hist = rn;
    if verbose, report_split(0, r, n, rn, r2, NaN, toc(t0)); end

    % Convergence target cannot be below the discretization floor of the
    % residual itself (measured by the driver's steady-state consistency
    % check and passed in as noise_floor). Asking for less is asking the
    % solver to chase grid noise.
    tol_eff = max(ntol, 5*nfloor);

    % Progress guard. A Jacobian rebuild costs 2(T-1) residual solves (about
    % 450s at T=120), so a refresh cycle that buys almost nothing is pure
    % waste: the last run spent ~2000s and five rebuilds improving ||r||2 by
    % 0.2%. If a full cycle does not cut the merit by at least min_gain, the
    % solve is at a local minimum of a near-singular system and stops.
    min_gain = getopt(opts, 'min_gain', 0.02);
    r2_at_last_J = Inf;
    lam0 = 1e-3; lam = lam0; lam_max = 1e8;
    J = []; Jprev = []; tjac = 0; sinceJ = 0; converged = false; it = 0; nstall = 0;
    for it = 1:nmax
        if rn < tol_eff, converged = true; break; end
        if toc(t0) > tbudget
            if verbose
                fprintf('   wall-clock budget (%.0fs) reached; stopping with the best path\n', tbudget);
            end
            break;
        end
        if isempty(J) || sinceJ >= refresh
            if verbose
                fprintf('[%5.0fs]   building Jacobian (%d residual solves, h=%.1e)...\n', ...
                        toc(t0), nvar, hfd);
            end
            if toc(t0) + 1.2*tjac > tbudget && ~isempty(Jprev)
                if verbose
                    fprintf('   not enough budget for another Jacobian; stopping\n');
                end
                break;
            end
            if isfinite(r2_at_last_J) && r2 > (1 - min_gain)*r2_at_last_J
                if verbose
                    fprintf(['   last Jacobian cycle cut the merit by only %.2f%% ' ...
                             '(< %.0f%%); at a local minimum, stopping\n'], ...
                            100*(1 - r2/r2_at_last_J), 100*min_gain);
                end
                break;
            end
            r2_at_last_J = r2;
            tj = tic;
            J = ssj_jac(a, expand, ctx, hfd, r);
            tjac = toc(tj); Jprev = J;
            sinceJ = 0; lam = lam0;      % a FRESH Jacobian deserves a fresh lam
        end

        % LEVENBERG-MARQUARDT step on the Gauss-Newton system. Acceptance is
        % tested on the 2-NORM, which is the objective LM actually descends;
        % judging it by the sup-norm (as an earlier version did) rejects steps
        % that genuinely improve the fit merely because they raise one element,
        % and the solve then stalls with lam running away.
        JtJ = J.'*J;  Jtr = J.'*r;  dg = diag(JtJ);
        dg(dg <= 0) = max(max(dg), 1);
        ok = false; dead = false;
        for attempt = 1:10
            if lam > lam_max, break; end
            dx = -(JtJ + lam*diag(dg)) \ Jtr;
            if ~all(isfinite(dx)), lam = 5*lam; continue; end
            if max(abs(dx)) < 1e-11, dead = true; break; end   % step is numerically nil
            [rt, auxt] = twoasset_transition_residual(expand(a + dx), ctx);
            if auxt.feas && norm(rt) < r2
                % BROYDEN update: a full rebuild costs 2(T-1) residual solves
                % (the dominant expense); this rank-1 correction keeps the
                % Jacobian current along the direction just travelled for free.
                dr = rt - r; den = dx.'*dx;
                if den > 0, J = J + ((dr - J*dx)*dx.')/den; end
                a = a + dx; r = rt; aux = auxt;
                r2 = norm(r); rn = max(abs(r));
                lam = max(lam/3, 1e-9); ok = true; break;
            end
            lam = 5*lam;
        end
        sinceJ = sinceJ + 1;
        hist(end+1) = rn; %#ok<AGROW>
        if verbose, report_split(it, r, n, rn, r2, lam, toc(t0)); end

        if ok, nstall = 0; continue; end

        % No improving step. Try ONE fresh Jacobian with lam reset; if that
        % also fails, stop. Rebuilding repeatedly with a runaway lam is pure
        % waste: the step is already numerically zero, so nothing can change.
        nstall = nstall + 1;
        if dead || lam > lam_max || nstall >= 2
            if verbose
                if dead
                    fprintf('   step is numerically zero; at a local minimum of the merit\n');
                else
                    fprintf('   no improving step after %d fresh Jacobian(s); stopping\n', nstall);
                end
            end
            break;
        end
        if verbose, fprintf('   no LM step accepted; refreshing Jacobian with lam reset\n'); end
        J = []; sinceJ = 0; lam = lam0;
    end
    if rn < tol_eff, converged = true; end

    % Determinacy / conditioning diagnostic. Reported whether or not the
    % solve converged: on failure it is the single most informative number,
    % since a tiny sigma_min says the price paths cannot move the markets
    % (the sequence-space analogue of a flat asset-demand crossing) rather
    % than that the solver was badly tuned.
    sig = NaN; cnd = NaN;
    if isempty(J) && ~isempty(Jprev), J = Jprev; end
    if ~isempty(J)
        sv = svd(J); sig = min(sv); cnd = max(sv)/max(min(sv), eps);
        if verbose
            fprintf('   GE Jacobian: sigma_min = %.3e, cond = %.3e\n', sig, cnd);
        end
    end

    x = expand(a);
    Ppath = [exp(x(1:n)).', ctx.Pterm];
    qpath = [exp(x(n+1:2*n)).', ctx.qterm];
    TR = struct('x', a, 'path', x, 'nvar', nvar, 'Ppath', Ppath, 'qpath', qpath, ...
                'Sb', aux.Sb, 'Sk', aux.Sk, 'rb_t', aux.rb_t, 'tau_t', aux.tau_t, ...
                'resid', r, 'rnorm', rn, 'converged', converged, 'iters', it, ...
                'sigma_min', sig, 'cond_J', cnd, 'J', J, 'history', hist, ...
                'xsat', aux.xsat, 'xsat_t', aux.xsat_t, ...
                'gap_res', aux.gap_res, 'gap_res_t', aux.gap_res_t, ...
                'method', 'ssj-newton');
end

function v = getopt(s, f, d)
    if isstruct(s) && isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end

function report_split(it, r, n, rn, r2, lam, tsec)
% Residual broken out by market and by date. Which BLOCK binds, and WHERE in
% the path, is what distinguishes a conditioning problem from a horizon that
% is too short for the distribution to settle.
    [mb, ib] = max(abs(r(1:n)));
    [mk, ik] = max(abs(r(n+1:2*n)));
    if isnan(lam)
        fprintf(['[%5.0fs] newton %2d: ||r||inf = %.3e  ||r||2 = %.3e   ' ...
                 'bond %.2e (t=%d)  tree %.2e (t=%d)\n'], ...
                tsec, it, rn, r2, mb, ib, mk, ik);
    else
        fprintf(['[%5.0fs] newton %2d: ||r||inf = %.3e  ||r||2 = %.3e   ' ...
                 'bond %.2e (t=%d)  tree %.2e (t=%d)  lam %.1e\n'], ...
                tsec, it, rn, r2, mb, ib, mk, ik, lam);
    end
end

function J = ssj_jac(a, expand, ctx, h, r0)
% Finite-difference Jacobian in the COEFFICIENT space. With a projection
% basis this is 2K columns rather than 2(T-1), so a rebuild costs 16 residual
% solves at T=120 instead of 238. Columns are independent, so parfor applies
% exactly as before.
    a = a(:); m = numel(a); nr = numel(r0);
    cols = cell(m,1);
    parfor j = 1:m
        ap = a; ap(j) = ap(j) + h;
        [rp, auxp] = twoasset_transition_residual(expand(ap), ctx);
        if auxp.feas
            cols{j} = (rp - r0)/h;
        else
            am = a; am(j) = am(j) - h;
            [rm, auxm] = twoasset_transition_residual(expand(am), ctx);
            if auxm.feas
                cols{j} = (r0 - rm)/h;
            else
                cols{j} = zeros(nr,1);
            end
        end
    end
    J = zeros(nr, m);
    for j = 1:m, J(:,j) = cols{j}; end
end
