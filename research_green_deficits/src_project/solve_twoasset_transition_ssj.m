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
    t0      = getopt(opts, 't0', tic);

    T = ctx.T; n = T - 1;
    % start from the log-linear bridge between the two steady states
    lpb = log(linspace(ctx.P0, ctx.Pterm, T+1)); lpb = lpb(2:end-1);
    lqb = log(linspace(ctx.q0, ctx.qterm, T+1)); lqb = lqb(2:end-1);
    x   = [lpb(:); lqb(:)];

    [r, aux] = twoasset_transition_residual(x, ctx);
    rn = max(abs(r));
    hist = rn;
    if verbose
        report_split(0, r, n, rn, NaN, toc(t0));
    end

    % Convergence target cannot be below the discretization floor of the
    % residual itself (measured by the driver's steady-state consistency
    % check and passed in as noise_floor). Asking for less is asking the
    % solver to chase grid noise.
    tol_eff = max(ntol, 5*nfloor);

    J = []; sinceJ = 0; converged = false; it = 0; lam = 1e-3;
    for it = 1:nmax
        if rn < tol_eff, converged = true; break; end
        if isempty(J) || sinceJ >= refresh
            if verbose
                fprintf('[%5.0fs]   building Jacobian (%d residual solves, h=%.1e)...\n', ...
                        toc(t0), 2*n, hfd);
            end
            J = twoasset_transition_jacobian(x, ctx, hfd);
            sinceJ = 0;
        end

        % LEVENBERG-MARQUARDT step. A plain Newton solve, x <- x - J\r, is
        % the wrong tool here: J is built by finite differences on a residual
        % with a nonzero noise floor, and the tree market (fixed supply) can
        % make the price block genuinely ill-conditioned. LM interpolates
        % between Gauss-Newton and gradient descent, damping the directions
        % the data do not support, and adapts lambda instead of merely
        % shortening a fixed direction the way a line search does.
        JtJ = J.'*J;  Jtr = J.'*r;  dg = diag(JtJ);
        dg(dg <= 0) = max(max(dg), 1);
        ok = false;
        for attempt = 1:8
            dx = -(JtJ + lam*diag(dg)) \ Jtr;
            if ~all(isfinite(dx)), lam = 5*lam; continue; end
            [rt, auxt] = twoasset_transition_residual(x + dx, ctx);
            if auxt.feas && max(abs(rt)) < rn
                % BROYDEN update. A full rebuild costs 2(T-1) residual solves
                % (the dominant expense); this rank-1 correction keeps the
                % Jacobian current along the direction just travelled for
                % free, so the chord stays accurate for many more steps.
                dr = rt - r;
                den = dx.'*dx;
                if den > 0, J = J + ((dr - J*dx)*dx.')/den; end
                x = x + dx; r = rt; aux = auxt; rn = max(abs(rt));
                lam = max(lam/3, 1e-9); ok = true; break;
            end
            lam = 5*lam;
        end
        sinceJ = sinceJ + 1;
        hist(end+1) = rn; %#ok<AGROW>
        if verbose, report_split(it, r, n, rn, lam, toc(t0)); end
        if ~ok
            if ~isempty(J) && sinceJ > 0
                J = []; sinceJ = 0;
                if verbose, fprintf('   no LM step accepted; refreshing Jacobian\n'); end
                continue;
            end
            if verbose, fprintf('   no LM step accepted with a fresh Jacobian; stopping\n'); end
            break;
        end
    end
    if rn < tol_eff, converged = true; end

    % Determinacy / conditioning diagnostic. Reported whether or not the
    % solve converged: on failure it is the single most informative number,
    % since a tiny sigma_min says the price paths cannot move the markets
    % (the sequence-space analogue of a flat asset-demand crossing) rather
    % than that the solver was badly tuned.
    sig = NaN; cnd = NaN;
    if isempty(J)
        try, J = twoasset_transition_jacobian(x, ctx, hfd); catch, end
    end
    if ~isempty(J)
        sv = svd(J); sig = min(sv); cnd = max(sv)/max(min(sv), eps);
        if verbose
            fprintf('   GE Jacobian: sigma_min = %.3e, cond = %.3e\n', sig, cnd);
        end
    end

    Ppath = [exp(x(1:n)).', ctx.Pterm];
    qpath = [exp(x(n+1:2*n)).', ctx.qterm];
    TR = struct('x', x, 'Ppath', Ppath, 'qpath', qpath, ...
                'Sb', aux.Sb, 'Sk', aux.Sk, 'rb_t', aux.rb_t, 'tau_t', aux.tau_t, ...
                'resid', r, 'rnorm', rn, 'converged', converged, 'iters', it, ...
                'sigma_min', sig, 'cond_J', cnd, 'J', J, 'history', hist, ...
                'method', 'ssj-newton');
end

function v = getopt(s, f, d)
    if isstruct(s) && isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end

function report_split(it, r, n, rn, lam, tsec)
% Residual broken out by market and by date. Which BLOCK binds, and WHERE in
% the path, is what distinguishes a conditioning problem from a horizon that
% is too short for the distribution to settle.
    [mb, ib] = max(abs(r(1:n)));
    [mk, ik] = max(abs(r(n+1:2*n)));
    if isnan(lam)
        fprintf('[%5.0fs] newton %2d: ||r||inf = %.3e   bond %.2e (t=%d)  tree %.2e (t=%d)\n', ...
                tsec, it, rn, mb, ib, mk, ik);
    else
        fprintf('[%5.0fs] newton %2d: ||r||inf = %.3e   bond %.2e (t=%d)  tree %.2e (t=%d)  lam %.1e\n', ...
                tsec, it, rn, mb, ib, mk, ik, lam);
    end
end
