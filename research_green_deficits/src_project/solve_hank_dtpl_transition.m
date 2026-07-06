function TR = solve_hank_dtpl_transition(pgc, opts)
% SOLVE_HANK_DTPL_TRANSITION  U7 TIER 2: the nonlinear HANK-DTPL transition
% (appendix/HANK_TRANSITION_PLAN.md, first implementation).
%
% THE OBJECT: at t=1 the government unexpectedly announces a PERMANENT
% green program. From then on, perfect foresight. The unknown is the
% PRICE-LEVEL PATH {P_t}: at every date the price level must clear the
% asset market, P_t = B_t / S_t(1+r), where S_t is exact aggregate asset
% demand along the transition -- households solve a FINITE-HORIZON problem
% backward from the green terminal steady state under time-varying
% (r_t, tau_t, D_t), and the wealth distribution rolls forward from the
% no-program steady state. This is the DTPL mechanism ITSELF in dynamics:
% inflation along the path is not a Phillips-curve object; it is the
% shadow price of the nominal-debt stock against precautionary demand.
%
% STATIONARIZATION: nominal debt grows at mu and (in the nominal-budget
% regime) so does the green appropriation; define phat_t = P_t/(1+mu)^t.
% Then b_t = B0/phat_t, g_t = Gg_nom/phat_t, and the realized real return
% on nominal bonds between t-1 and t is
%     1 + r_t = (1+rbar) * phat_{t-1}/phat_t,   1+rbar = (1+i_ss)/(1+mu).
% The t=1 jump phat_1 vs phat_0 (= baseline P*) is the SURPRISE
% REVALUATION on pre-announcement bond holdings -- the paper's channel,
% now realized along a path rather than compared across steady states.
% Terminal condition: phat_T = green steady-state P*. Budget balance each
% period: tau_t = rbar*b_t + g_t (nominal regime), so the government
% budget holds by construction at every trial path.
%
% REGIMES (opts.regime):
%   'nominal'  Gg fixed in nominal terms: g_t = Gg_nom/phat_t (baseline)
%   'indexed'  real mandate: g_t = g_real (anchor-insulation experiment)
%
% METHOD (honest first implementation, labeled):
%   * backward: one Bellman step per date on the package's (a,e) grids,
%     continuation = green terminal value function (exact finite-horizon
%     solution given the terminal condition; hh_bellman_step.m);
%   * forward: exact distribution iteration with the date-t policies;
%   * update: ANDERSON-ACCELERATED fixed point on the LOG price path.
%     The underlying map is phat_t <- phat_t*(b_t/S_t)^xi (moves toward
%     phat* = B0/S_t: excess asset demand => price level FALLS => real debt
%     B0/phat rises to meet demand -- the transition version of P* = B/S).
%     Plain diagonal relaxation stalls/oscillates because phat_t enters the
%     realized return at BOTH t and t+1 with opposite signs (cross-date
%     coupling, eigenvalue near -1); Anderson type-II (Fang-Saad, memory 5)
%     combines the last few log residuals by least squares to cancel it,
%     Jacobian-free, with a +-10%/iter per-date trust region and an
%     ill-conditioning fallback to the plain damped step.
%   * convergence: over the FREE unknowns phat(1:T-1) (the terminal date is
%     pinned at the green ss); max_t |S_t-b_t|/b_t < opts.tol. The terminal
%     residual is reported SEPARATELY as a horizon-adequacy check. Residuals
%     are REPORTED, never hidden; a path that is not both converged and
%     horizon-adequate is returned .reportable = false and must not be
%     presented as a result.
%   * SCOPE OF v1: damage-level channel on endowments and the risk
%     channel sig_eps(D_t) are both active (income process rebuilt per
%     date); the incidence gradient chi(e) follows pgc.psi_inc as in
%     S_green. No aggregate risk. Lump-sum taxes (regime R1).
%
% FREQUENCY: the MATLAB package is calibrated ANNUALLY (beta*=0.9296,
% i_ss=0.04, mu=0.02, delta_g=0.10/yr), so T is in YEARS and pi_path is a
% per-YEAR rate (audit fix: an earlier driver annualized with a quarterly
% factor).
%
% COST: each path iteration = T Bellman steps (na x na x ne tensor ops)
% + T distribution pushes. At na=500, ne=7, T=80 (years), expect minutes
% per iteration and O(10-60) iterations -- run on the user machine.
%
% INPUTS: pgc from setup_params_green (+ calibrated beta), with D0 /
%         climate fields set; opts fields (all optional):
%   .T (80 years) .tol (2e-3) .maxit (60) .xi (0.5) .regime ('nominal')
%   .Gg_nom (default: pgc.Gg_nom) .verbose (true)
% OUTPUT TR: .phat (1xT), .P0, .pi_path, .r_path, .tau_path, .D_path,
%   .Kg_path, .S_path, .b_path, .resid (1xT), .iters,
%   .eq0, .eq1 (boundary steady states), .reval_stock, .reval_pv_share,
%   .msg, and the split diagnostics
%     .converged      fixed point cleared the FREE unknowns phat(1:T-1)
%     .resid_interior max|S-b|/b over 1:T-1 (the fixed-point residual)
%     .resid_argmax   date of the interior max
%     .resid_terminal |S_T-b_T|/b_T at the PINNED terminal date (horizon
%                     adequacy: small only if T is long enough for the
%                     distribution to reach the green ss)
%     .horizon_ok     resid_terminal < max(tol, 5e-3)
%     .reportable     converged AND horizon_ok -- the gate a number must
%                     pass before it may be quoted as a result
%
% STATUS: IMPLEMENTED (v1); numbers are results only once a converged
% run is verified. NONLINEAR HANK-DTPL TRANSITION tier.

    if nargin < 2, opts = struct(); end
    T      = getopt(opts, 'T', 80);   % YEARS (annual calibration)
    tol    = getopt(opts, 'tol', 2e-3);
    maxit  = getopt(opts, 'maxit', 60);
    xi     = getopt(opts, 'xi', 0.5);
    regime = getopt(opts, 'regime', 'nominal');
    verbose= getopt(opts, 'verbose', true);

    B0   = pgc.Bnom;
    rbar = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;
    % program-size default: the params struct's own calibrated program
    % (audit fix: the old hard-coded 0.02*Bnom/1.10 silently overrode a
    % caller-supplied calibration by up to 50%)
    if isfield(pgc, 'Gg_nom') && ~isempty(pgc.Gg_nom)
        Gg = getopt(opts, 'Gg_nom', pgc.Gg_nom);
    else
        Gg = getopt(opts, 'Gg_nom', 0.02 * (pgc.Bnom / 1.10));
    end

    TR = struct('converged', false, 'msg', '');

    % ---- boundary steady states (exact, reusing the regime solver) ----
    g_of  = @(P) Gg ./ P;
    D_of  = @(P) climate_block(g_of(P), pgc);
    rb_of = @(P) rbar * B0 ./ P;
    reg0 = struct('name','TR-BASE','Bnom',B0, 'g',@(P) 0*P, ...
        'D',@(P) 0*P + pgc.D0, 'tau_ls',@(P) rb_of(P), 'vartheta',@(P) 0);
    reg1 = struct('name','TR-GREEN','Bnom',B0, 'g',g_of, 'D',D_of, ...
        'tau_ls',@(P) rb_of(P) + g_of(P), 'vartheta',@(P) 0);
    [eq0, o0] = solve_regime_equilibrium(pgc, reg0, rbar, [0.5, 1.3]);
    if isempty(eq0), TR.msg = ['tier2: no baseline ss: ' o0.msg]; return; end
    [eq1, o1] = solve_regime_equilibrium(pgc, reg1, rbar, [0.5, 1.3]);
    if isempty(eq1), TR.msg = ['tier2: no green ss: ' o1.msg]; return; end
    if verbose
        fprintf('  boundary steady states: P0=%.4f -> P1=%.4f (D: %.4f -> %.4f)\n', ...
            eq0.P, eq1.P, eq0.D, eq1.D);
    end

    % terminal household objects (green ss) and initial distribution (base ss)
    [~, oT] = S_green(rbar, eq1.tau, eq1.D, pgc);
    [~, oI] = S_green(rbar, eq0.tau, eq0.D, pgc);
    if ~oT.feasible || ~oI.feasible
        TR.msg = 'tier2: boundary household problem infeasible.'; return;
    end
    VT    = oT.V;          % terminal value function (green ss)
    dist0 = oI.dist;       % pre-announcement wealth distribution

    % ---- initial guess: log-linear bridge between the steady states ----
    phat = exp(linspace(log(eq0.P), log(eq1.P), T));
    phat(T) = eq1.P;

    % Kg accumulation from zero (announcement); delta_g from pgc
    dg  = pgc.delta_g;
    qg  = 1; if isfield(pgc,'q_g') && ~isempty(pgc.q_g), qg = pgc.q_g; end

    xi0  = xi;          % base relaxation of the underlying Picard map
    mAnd = 5;           % Anderson memory (past residuals combined per step)
    Xh   = {};  Fh = {};  % history: log-price iterates and log residuals
    for it = 1:maxit
        % ---- climate + fiscal paths implied by the trial price path ----
        if strcmpi(regime, 'indexed')
            g_path = (Gg / eq1.P) * ones(1, T);   % real mandate
        else
            g_path = Gg ./ phat;                  % nominal appropriation
        end
        Kg = zeros(1, T);
        for t = 1:T
            Kprev = 0; if t > 1, Kprev = Kg(t-1); end
            Kg(t) = (1 - dg) * Kprev + qg * g_path(t);
        end
        % version-1 climate map with TRANSITION Kg (not the ss shortcut)
        D_path = pgc.D0 * exp(-pgc.theta_g * Kg);
        b_path = B0 ./ phat;
        tau_path = rbar .* b_path + g_path;
        % realized real return: surprise jump at t=1 against P0 = eq0.P
        phat_lag = [eq0.P, phat(1:T-1)];
        r_path = (1 + rbar) .* phat_lag ./ phat - 1;

        % ---- backward: date-t policies from the terminal green ss ----
        [POL, feas] = backward_policies(VT, r_path, tau_path, D_path, pgc);
        if ~feas
            TR.msg = sprintf('tier2: infeasible household problem at iter %d.', it);
            return;
        end

        % ---- forward: distribution + aggregate asset demand ----
        S_path = zeros(1, T);
        dist = dist0;
        for t = 1:T
            S_path(t) = POL(t).aGrid_dot_dist(dist);
            dist = POL(t).push(dist);
        end

        % ---- residuals ----
        % Clearing at t: b_t = B0/phat_t = S_t, so the exact clearing price
        % is phat* = B0/S_t. EXCESS DEMAND (S > b) requires phat_t to FALL so
        % that real debt B0/phat rises to meet demand -- the transition
        % version of P* = B/S (update direction audit-confirmed).
        resid = (S_path - b_path) ./ b_path;
        % CONVERGENCE is over the FREE unknowns phat(1:T-1). phat(T) is
        % PINNED at the terminal green ss, so resid(T) is NOT a lever the
        % solver can move: it is instead the HORIZON-ADEQUACY diagnostic --
        % it goes to zero only when T is long enough for the rolled-forward
        % wealth distribution to reach the green-ss distribution (at which
        % point green-ss savings = B0/eq1.P = b_T by construction). Audit
        % fix: the old criterion took max over ALL dates, so a still-settling
        % terminal date blocked declared convergence even with a perfectly
        % cleared interior -- exactly the FAST-run symptom (one terminal
        % outlier at 0.0097 against an interior mean at tolerance).
        resnorm  = max(abs(resid(1:T-1)));
        resid_T  = abs(resid(T));
        % ---- Anderson-accelerated fixed point on the log price path ----
        % Fixed point: phat_t = B0/S_t, i.e. the log residual
        %   f_t = log(b_t/S_t) = log(B0/S_t) - log(phat_t)
        % is zero at a clearing price. The plain damped map x <- x + xi*f is
        % the old multiplicative update in logs; it stalls/oscillates here
        % because a change in phat_t moves the realized return at BOTH t and
        % t+1 with opposite signs -- a cross-date coupling (eigenvalue near
        % -1) the diagonal step cannot see. Anderson (type-II, Fang-Saad)
        % combines the last mAnd residuals by least squares to cancel exactly
        % that coupling; Jacobian-free, and the standard cure for this shape.
        xcur = log(phat(1:T-1)).';               % column (T-1)
        fcur = log(b_path(1:T-1) ./ S_path(1:T-1)).';
        if verbose
            fprintf(['  iter %2d: interior max|S-b|/b = %.5f, ' ...
                'terminal(horizon) = %.5f (mem=%d)\n'], it, resnorm, ...
                resid_T, min(numel(Fh), mAnd));
        end
        if resnorm < tol
            TR.converged = true;
            break;
        end
        if it == maxit, break; end   % keep packed paths consistent with phat
        Xh{end+1} = xcur;  Fh{end+1} = fcur; %#ok<AGROW>
        if numel(Fh) > mAnd + 1, Fh = Fh(end-mAnd:end); Xh = Xh(end-mAnd:end); end
        m = numel(Fh) - 1;
        if m < 1
            xnext = xcur + xi0 * fcur;            % first step: plain damped
        else
            F  = [Fh{:}];  X = [Xh{:}];           % each (T-1) x (m+1)
            dF = diff(F, 1, 2);  dX = diff(X, 1, 2);
            ws = warning('off', 'MATLAB:rankDeficientMatrix');
            gamma = dF \ fcur;                    % argmin || fcur - dF*gamma ||
            warning(ws);
            xnext = xcur + xi0 * fcur - (dX + xi0 * dF) * gamma;
            if ~all(isfinite(xnext)) || norm(gamma) > 1e3
                xnext = xcur + xi0 * fcur;        % ill-conditioned: fall back
                Xh = Xh(end);  Fh = Fh(end);      % and restart the memory
            end
        end
        % per-date trust region (same +-10%/iter cap) then apply; terminal pin
        step = max(min(xnext - xcur, log(1.10)), log(0.90));
        phat(1:T-1) = exp((xcur + step).');
    end

    % ---- pack ----
    TR.phat   = phat;   TR.P0 = eq0.P;
    TR.pi_path = (1 + pgc.mu) * phat ./ [eq0.P, phat(1:T-1)] - 1;  % actual inflation
    TR.r_path = r_path; TR.tau_path = tau_path; TR.D_path = D_path;
    TR.Kg_path = Kg;    TR.S_path = S_path;     TR.b_path = b_path;
    TR.g_path = g_path;
    TR.resid  = resid;  TR.iters = it;
    % split diagnostics: fixed-point convergence (free unknowns) vs horizon
    % adequacy (pinned terminal date). A reportable result needs BOTH small.
    TR.resid_interior = max(abs(resid(1:T-1)));
    TR.resid_terminal = abs(resid(T));
    [~, adate]        = max(abs(resid(1:T-1)));
    TR.resid_argmax   = adate;                 % where the interior max sits
    TR.horizon_ok     = TR.resid_terminal < max(tol, 5e-3);
    TR.reportable     = TR.converged && TR.horizon_ok;
    TR.eq0 = eq0; TR.eq1 = eq1;
    % surprise revaluation at announcement (audit-corrected definitions):
    %   reval_stock    government's one-time real gain on the outstanding
    %                  nominal stock, B0*(1/P0 - 1/phat_1)  [negative under
    %                  announcement disinflation: bondholder windfall]
    %   reval_pv_share the same stock gain as a share of the program's
    %                  present value along the computed path
    TR.reval_stock    = B0 * (1/eq0.P - 1/phat(1));
    PVg               = sum(g_path ./ (1 + rbar).^(1:T));
    TR.reval_pv_share = TR.reval_stock / PVg;
    TR.msg = sprintf(['tier2 %s: fixed point %s (interior max %.5f @t=%d), ' ...
        'horizon %s (terminal resid %.5f) in %d iters; ' ...
        'impact phat_1/P0 = %.4f (surprise %s), terminal P = %.4f'], ...
        regime, ternstr(TR.converged, 'CONVERGED', 'NOT CONVERGED'), ...
        TR.resid_interior, TR.resid_argmax, ...
        ternstr(TR.horizon_ok, 'OK', 'TOO SHORT (raise T)'), TR.resid_terminal, ...
        TR.iters, phat(1)/eq0.P, ...
        ternstr(phat(1) < eq0.P, 'DISINFLATION', 'inflation'), phat(T));
end

% ==========================================================================
function [POL, feas] = backward_policies(VT, r_path, tau_path, D_path, pgc)
% One Bellman step per date, backward from the terminal value function.
% Returns, per date, a policy closure for the distribution push and the
% asset-demand aggregation. Income process rebuilt per date when the risk
% channel is active (sig_eps(D_t)), exactly as in S_green.
    T = numel(r_path);
    POL = struct('push', cell(1, T), 'aGrid_dot_dist', cell(1, T));
    feas = true;
    Vnext = VT;
    aG = pgc.aGrid(:);
    na = numel(aG);
    for t = T:-1:1
        p = pgc;
        if pgc.phi_D > 0
            p.sig_eps = pgc.sig_eps0 * (1 + pgc.phi_D * D_path(t));
            [eG, PiD, statD] = make_income_process(p);
            p.eGrid = eG; p.Pi = PiD; p.stationary_e = statD;
        end
        % damage level/incidence channel on endowments (as in S_green)
        psi = 0;
        if isfield(pgc, 'psi_inc') && ~isempty(pgc.psi_inc), psi = pgc.psi_inc; end
        ev = p.eGrid(:); wst = p.stationary_e(:);
        if psi > 0
            cnorm = wst' * (ev.^(1 - psi));
            chi = (ev.^(-psi)) / cnorm;
            yv = max(1 - D_path(t) * chi, 0.05) .* ev;
        else
            yv = (1 - D_path(t)) * ev;
        end
        [V, polA_idx, ok] = hh_bellman_step(Vnext, r_path(t), tau_path(t), ...
                                            yv, p, aG);
        if ~ok, feas = false; return; end
        Vnext = V;
        Pi_t = p.Pi;
        idx  = polA_idx;                     % na x ne
        POL(t).push = @(dist) push_dist(dist, idx, Pi_t, na);
        POL(t).aGrid_dot_dist = @(dist) sum(sum(aG(idx) .* dist));
    end
end

function dist1 = push_dist(dist, polA_idx, Pi, na)
% exact one-step distribution iteration: mass at (a,e) moves to
% (polA_idx(a,e), e') with probability Pi(e,e')
    ne = size(dist, 2);
    dist1 = zeros(na, ne);
    for e = 1:ne
        m = accumarray(polA_idx(:, e), dist(:, e), [na, 1]);
        dist1 = dist1 + m * Pi(e, :);
    end
end

function v = getopt(o, f, d)
    if isfield(o, f) && ~isempty(o.(f)), v = o.(f); else, v = d; end
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
