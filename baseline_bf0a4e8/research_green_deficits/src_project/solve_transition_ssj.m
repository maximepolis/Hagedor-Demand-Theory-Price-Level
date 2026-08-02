function TR = solve_transition_ssj(pgc, opts)
% SOLVE_TRANSITION_SSJ  The nonlinear HANK-DTPL transition solved in SEQUENCE
% SPACE by a Newton iteration on the log price path, using the sequence-space
% (GE) Jacobian ssj_transition_jacobian. This is an independent second solver
% for the object of solve_hank_dtpl_transition.m (which uses an
% Anderson-accelerated fixed point); the two agreeing is a cross-implementation
% correctness gate.
%
% METHOD (\citealp{auclertetal2021} sequence-space Jacobian):
%   * build the boundary steady states, terminal value function VT, and
%     pre-announcement distribution dist0 exactly as the Anderson solver does;
%   * initialize the free log-price path at the log-linear bridge between the
%     steady states;
%   * Newton step:  logphat <- logphat - J \ resid,  with J the sequence-space
%     Jacobian (ssj_transition_jacobian) recomputed each iterate (or frozen at
%     the first, opts.freeze_jac, giving the chord-Newton whose FIRST step
%     reproduces the linear impulse response exactly -- the toolkit's built-in
%     correctness gate).
%
% DETERMINACY DIAGNOSTIC (a sequence-space complement to the steady-state
% eps_S<-1 test of Definition 3): at the solution the mechanism is locally
% determinate iff the GE Jacobian J is invertible with no zero-crossing of its
% determinant along the path. We report sigma_min(J) (smallest singular value),
% cond(J), and the sign of det(J); a near-singular J flags the sequence-space
% analog of the flat/steep asset-demand crossing that generates multiplicity.
%
% INPUTS: pgc (calibrated params, D0/climate fields set) and opts as in
%   solve_hank_dtpl_transition (.T .tol .maxit .regime .financing .Gg_nom
%   .verbose), plus:
%   .newton_maxit (default 12) .newton_tol (default 5e-4)
%   .fd_step (default 1e-4)    .freeze_jac (default false)
%   .damping (default 1)
%
% OUTPUT TR: same core fields as solve_hank_dtpl_transition (.phat .pi_path
%   .r_path .tau_path .D_path .Kg_path .S_path .b_path .resid .eq0 .eq1
%   .converged .reportable ...), plus:
%   .method            'ssj-newton'
%   .sigma_min         smallest singular value of the GE Jacobian at the solution
%   .cond_J            condition number of the GE Jacobian
%   .det_sign          sign of det(J)
%   .determinate       sigma_min > opts.det_tol (default 1e-6 * scale)
%   .first_step_linIRF the first Newton step from the bridge (the linear IRF)
%
% STATUS: IMPLEMENTED; a result only once a converged run is verified and it
% agrees with the Anderson solver (verify_transition_ssj.m). Drawn from the
% Dynare masterclass sequence-space-Jacobian toolkit (see HANK_METHODS.md).

    if nargin < 2, opts = struct(); end
    T       = getopt(opts, 'T', 80);
    tol     = getopt(opts, 'tol', 2e-3);
    regime  = getopt(opts, 'regime', 'nominal');
    financing = getopt(opts, 'financing', 'lumpsum');
    verbose = getopt(opts, 'verbose', true);
    nmaxit  = getopt(opts, 'newton_maxit', 12);
    ntol    = getopt(opts, 'newton_tol', 5e-4);
    % FD step in log price. The residual runs a DISCRETE-CHOICE backward
    % pass, so it is piecewise constant at fine scales: a step below the
    % policy-flip resolution (the old 1e-4) produces a near-zero/garbage
    % Jacobian and the Newton stalls at the initial bridge. 5e-3 averages
    % across policy flips (a chord Jacobian); the loop below also enlarges
    % h adaptively when the line search finds no descent.
    hfd     = getopt(opts, 'fd_step', 5e-3);
    freeze  = getopt(opts, 'freeze_jac', false);
    damping = getopt(opts, 'damping', 1);

    ctx = build_transition_ctx(pgc, T, regime, financing, opts, verbose);
    if isempty(ctx)
        TR = struct('converged', false, 'reportable', false, ...
                    'msg', 'ssj: boundary steady state / household setup failed.');
        return;
    end

    % ---- initial guess: log-linear bridge (same as the Anderson solver) ----
    phat0 = exp(linspace(log(ctx.eq0.P), log(ctx.eq1.P), T));
    x = log(phat0(1:T-1)).';                 % free unknowns (T-1 x 1)

    Jfrozen = [];
    first_step = [];
    for k = 1:nmaxit
        if isempty(Jfrozen) || ~freeze
            [J, r0, aux] = ssj_transition_jacobian(x, ctx, hfd);
            if freeze, Jfrozen = J; end
        else
            J = Jfrozen;
            [r0, aux] = transition_residual_dtpl(x, ctx);
        end
        rf = r0(1:T-1).';
        resnorm = max(abs(rf));
        if verbose
            fprintf('  [ssj-newton] iter %2d  max|S-b|/b = %.3e\n', k, resnorm);
        end
        if resnorm < ntol, break; end

        % ---- guarded Newton step ----
        if any(~isfinite(J(:))) || any(~isfinite(rf))
            if verbose
                fprintf('  [ssj-newton] nonfinite Jacobian/residual at iter %d -- stopping.\n', k);
            end
            break;
        end
        w1 = warning('off', 'MATLAB:nearlySingularMatrix');
        w2 = warning('off', 'MATLAB:singularMatrix');
        if rcond(J) < 1e-14
            dx = -pinv(J) * rf;               % minimum-norm step on a
        else                                   % (near-)singular Jacobian
            dx = -(J \ rf);
        end
        warning(w1); warning(w2);
        if k == 1, first_step = dx; end       % the linear impulse response

        % ---- backtracking line search on the free-date residual norm ----
        % Accept the first step fraction that strictly reduces the residual;
        % a full Newton step on this problem can overshoot into an
        % infeasible price path, which must be rejected, not propagated.
        step = damping; accepted = false;
        for ls = 1:7
            xtry = x + step * dx;
            rtry = transition_residual_dtpl(xtry, ctx);
            rn = max(abs(rtry(1:T-1)));
            if isfinite(rn) && rn < resnorm
                x = xtry; accepted = true;
                if verbose && step < damping
                    fprintf('  [ssj-newton]    (step damped to %.3g)\n', step);
                end
                break;
            end
            step = step / 2;
        end
        if ~accepted
            % No descent along this direction: most often the chord step h
            % is still below the residual's grid-flip resolution, so the
            % Jacobian was noise. Enlarge h and rebuild before giving up.
            if hfd < 4e-2
                hfd = 4 * hfd;
                Jfrozen = [];                  % force a J rebuild next pass
                if verbose
                    fprintf(['  [ssj-newton] no descent at iter %d -- ' ...
                             'enlarging fd_step to %.1e and rebuilding J.\n'], k, hfd);
                end
                continue;
            end
            if verbose
                fprintf('  [ssj-newton] line search found no descent at iter %d -- stopping.\n', k);
            end
            break;
        end
        if k == nmaxit, break; end
    end

    % ---- determinacy diagnostic on the final GE Jacobian ----
    if all(isfinite(J(:)))
        sv       = svd(full(J));
        sigmin   = min(sv);
        condJ    = max(sv) / max(sigmin, eps);
        detsign  = sign(det(J));
        det_tol  = getopt(opts, 'det_tol', 1e-6 * max(sv));
    else
        sigmin = NaN; condJ = NaN; detsign = NaN;
        det_tol = getopt(opts, 'det_tol', NaN);
    end

    % ---- pack (mirror the Anderson solver's output contract) ----
    [resid, aux] = transition_residual_dtpl(x, ctx);
    TR = struct();
    TR.method   = 'ssj-newton';
    TR.phat     = aux.phat;   TR.P0 = ctx.eq0.P;
    TR.pi_path  = (1 + pgc.mu) * aux.phat ./ [ctx.eq0.P, aux.phat(1:T-1)] - 1;
    TR.r_path   = aux.r_path; TR.tau_path = aux.tau_path; TR.D_path = aux.D_path;
    TR.Kg_path  = aux.Kg;     TR.S_path = aux.S_path;     TR.b_path = aux.b_path;
    TR.g_path   = aux.g_path; TR.vart_path = aux.vart_path; TR.financing = financing;
    TR.resid    = resid;
    TR.resid_interior = max(abs(resid(1:T-1)));
    TR.resid_terminal = abs(resid(T));
    TR.converged = TR.resid_interior < tol;
    TR.horizon_ok = TR.resid_terminal < max(tol, 5e-3);
    TR.reportable = TR.converged && TR.horizon_ok;
    TR.eq0 = ctx.eq0; TR.eq1 = ctx.eq1;
    TR.sigma_min = sigmin;
    TR.cond_J    = condJ;
    TR.det_sign  = detsign;
    TR.determinate = sigmin > det_tol;
    TR.first_step_linIRF = first_step;
    TR.iters = k;
    TR.msg = sprintf(['ssj-newton: interior resid=%.2e, terminal=%.2e, ' ...
        'sigma_min(J)=%.2e, cond(J)=%.1e, determinate=%d'], ...
        TR.resid_interior, TR.resid_terminal, sigmin, condJ, TR.determinate);
end

% =========================================================================
function ctx = build_transition_ctx(pgc, T, regime, financing, opts, verbose)
% Boundary steady states + terminal/initial household objects. Mirrors
% solve_hank_dtpl_transition.m lines that set up eq0, eq1, VT, dist0, so the
% two solvers linearize the SAME object.
    ctx = [];
    % SOLVER CONSISTENCY (Round 12): the residual and its finite-difference
    % Jacobian run the grid-choice backward recursion, so the boundary
    % objects (eq0/eq1, VT, dist0) must be solved by the same method. Pin
    % the local copy to 'vfi' regardless of the global EGM default --
    % EGM-based boundaries under a grid-VFI interior made the first Newton
    % step blow up (residual 0.038 -> 11 -> Inf, singular-J warnings).
    pgc.hh_solver = 'vfi';

    B0   = pgc.Bnom;
    rbar = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;
    if isfield(pgc, 'Gg_nom') && ~isempty(pgc.Gg_nom)
        Gg = getopt(opts, 'Gg_nom', pgc.Gg_nom);
    else
        Gg = getopt(opts, 'Gg_nom', 0.02 * (pgc.Bnom / 1.10));
    end
    rebate = strcmpi(financing, 'rebate');

    g_of  = @(P) Gg ./ P;
    D_of  = @(P) climate_block(g_of(P), pgc);
    rb_of = @(P) rbar * B0 ./ P;
    reg0 = struct('name','TR-BASE','Bnom',B0, 'g',@(P) 0*P, ...
        'D',@(P) 0*P + pgc.D0, 'tau_ls',@(P) rb_of(P), 'vartheta',@(P) 0);
    if rebate
        reg1 = struct('name','TR-GREEN-REBATE','Bnom',B0, 'g',g_of, 'D',D_of, ...
            'tau_ls',@(P) rb_of(P) - g_of(P), ...
            'vartheta',@(P) 2 * g_of(P) ./ (1 - D_of(P)));
    else
        reg1 = struct('name','TR-GREEN','Bnom',B0, 'g',g_of, 'D',D_of, ...
            'tau_ls',@(P) rb_of(P) + g_of(P), 'vartheta',@(P) 0);
    end
    [eq0, o0] = solve_regime_equilibrium(pgc, reg0, rbar, [0.5, 1.3]);
    if isempty(eq0), if verbose, fprintf('  ssj: no baseline ss: %s\n', o0.msg); end, return; end
    [eq1, o1] = solve_regime_equilibrium(pgc, reg1, rbar, [0.5, 1.3]);
    if isempty(eq1), if verbose, fprintf('  ssj: no green ss: %s\n', o1.msg); end, return; end
    if verbose
        fprintf('  ssj boundary steady states: P0=%.4f -> P1=%.4f (D: %.4f -> %.4f)\n', ...
            eq0.P, eq1.P, eq0.D, eq1.D);
    end

    pgcT = pgc;
    if rebate, pgcT.vartheta = eq1.vartheta; end
    [~, oT] = S_green(rbar, eq1.tau, eq1.D, pgcT);
    [~, oI] = S_green(rbar, eq0.tau, eq0.D, pgc);
    if ~oT.feasible || ~oI.feasible
        if verbose, fprintf('  ssj: boundary household problem infeasible.\n'); end
        return;
    end

    ctx = struct('T', T, 'B0', B0, 'rbar', rbar, 'Gg', Gg, 'pgc', pgc, ...
        'regime', regime, 'rebate', rebate, 'eq0', eq0, 'eq1', eq1, ...
        'VT', oT.V, 'dist0', oI.dist);
end

% =========================================================================
function v = getopt(s, f, d)
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
