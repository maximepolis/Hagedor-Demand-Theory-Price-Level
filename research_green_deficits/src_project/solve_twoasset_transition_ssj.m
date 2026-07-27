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
%   * step  x <- x - alpha * (J \ r), with J the sequence-space Jacobian,
%     held fixed across iterations (chord Newton) and refreshed only when
%     progress stalls, since each J costs 2(T-1) residual evaluations;
%   * alpha is chosen by backtracking on ||r||_inf, which also handles trial
%     steps that push the equity-bond spread non-positive.
%
% DETERMINACY DIAGNOSTIC. At the solution the mechanism is locally determinate
% iff J is invertible. We report sigma_min(J) and cond(J): a near-singular J
% is the sequence-space analogue of the flat asset-demand crossing that
% generates steady-state multiplicity.
%
% OPTS  .newton_maxit (12) .newton_tol (1e-4) .fd_step (1e-3)
%       .refresh_after (3)  .verbose (true)  .t0 (tic handle)
%
% OUTPUT TR .x .Ppath .qpath .Sb .Sk .resid .rnorm .converged .iters
%           .sigma_min .cond_J .J .history

    if nargin < 2, opts = struct(); end
    nmax    = getopt(opts, 'newton_maxit', 12);
    ntol    = getopt(opts, 'newton_tol',  1e-4);
    hfd     = getopt(opts, 'fd_step',     1e-3);
    refresh = getopt(opts, 'refresh_after', 3);
    verbose = getopt(opts, 'verbose', true);
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
        fprintf('[%5.0fs] newton  0: ||r||inf = %.3e\n', toc(t0), rn);
    end

    J = []; sinceJ = 0; converged = false; it = 0;
    for it = 1:nmax
        if rn < ntol, converged = true; break; end
        if isempty(J) || sinceJ >= refresh
            if verbose
                fprintf('[%5.0fs]   building Jacobian (%d residual solves)...\n', ...
                        toc(t0), 2*n);
            end
            J = twoasset_transition_jacobian(x, ctx, hfd);
            sinceJ = 0;
        end
        % Newton direction; least-squares fallback if J is ill-conditioned
        lastwarn('');
        dx = -(J \ r);
        if ~all(isfinite(dx)) || ~isempty(lastwarn)
            dx = -pinv(J) * r;
        end
        % backtracking line search on ||r||inf (also rejects infeasible steps)
        alpha = 1; ok = false;
        for ls = 1:8
            xt = x + alpha*dx;
            [rt, auxt] = twoasset_transition_residual(xt, ctx);
            if auxt.feas && max(abs(rt)) < rn
                x = xt; r = rt; aux = auxt; rn = max(abs(rt)); ok = true; break;
            end
            alpha = 0.4*alpha;
        end
        sinceJ = sinceJ + 1;
        hist(end+1) = rn; %#ok<AGROW>
        if verbose
            fprintf('[%5.0fs] newton %2d: ||r||inf = %.3e  (step %.3f)\n', ...
                    toc(t0), it, rn, alpha);
        end
        if ~ok
            if sinceJ > 0 && ~isempty(J)
                J = []; sinceJ = 0;      % stale chord: rebuild once and retry
                if verbose, fprintf('   line search failed; refreshing Jacobian\n'); end
                continue;
            end
            if verbose, fprintf('   line search failed with a fresh Jacobian; stopping\n'); end
            break;
        end
    end
    if rn < ntol, converged = true; end

    % determinacy diagnostic at the solution
    sig = NaN; cnd = NaN;
    if ~isempty(J)
        sv = svd(J); sig = min(sv); cnd = max(sv)/max(min(sv), eps);
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
