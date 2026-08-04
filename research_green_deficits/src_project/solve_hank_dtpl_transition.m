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
%   .fiscal  (optional, round 10): a fiscal specification struct built by
%     kv_fiscal_spec. Supplying it overrides the internal rho_d rule:
%       .phi_path      1 x T share of the program covered by current tax
%       .kappa_mode    'free' (legacy: terminal pin floats) | 'target'
%       .kappa_target  required when kappa_mode == 'target'
%       .kappa_tol     terminal-debt tolerance (default 1e-8)
%       .experiment_id string, carried into the output for provenance
%     With .fiscal absent every line below behaves exactly as before.
%
%   .financing ('lumpsum' default | 'rebate' | 'deficit'):
%     'rebate' runs the R3 design of the regimes section along the path --
%     a proportional levy at twice the program with half rebated lump-sum,
%     vartheta_t = 2 g_t/(1-D_t) and tau_ls,t = r*b_t - g_t, satisfying the
%     same flow identity tau_ls,t + vartheta_t (1-D_t) = r*b_t + g_t at
%     every date -- so the transition-inclusive welfare of the progressive
%     design is computable.
%     'deficit' runs the DEFICIT-FINANCED announcement (requires
%     regime='indexed' so the real program is identical to the balanced
%     benchmark and only the tax TIMING differs). Taxes are phased in
%     geometrically, tau_t = rbar*b_t + phi_t*g_t with
%     phi_t = 1 - rho_d^t (opts.rho_d, default 0.8), so the primary gap
%     (1-phi_t)*g_t is financed by nominal issuance ABOVE trend. Real debt
%     then follows the exact recursion implied by the nominal budget,
%       b_t = [(1+r_t) b_{t-1} + (1-phi_t) g_t] / (1+rbar),
%     which nests the benchmark at phi==1 (b_t = B0/phat_t). The
%     stationarized nominal stock Bhat_t = b_t*phat_t rises to
%     kappa_inf*B0; by nominal neutrality (Lemma: joint rescaling of B and
%     the real program is a price-level rescaling, and here the real
%     program is indexed) the terminal steady state is the SAME real
%     economy with phat_T = kappa_inf * eq1.P, so the terminal pin floats
%     with the accumulated stock (lagged one iteration, which converges
%     with the fixed point; phi_T is 1 to machine precision at T=80 for
%     rho_d <= 0.9, so kappa is flat at the tail). The terminal household
%     objects are UNCHANGED -- neutrality means the diluted terminal has
%     identical (b, tau, g, D) -- which is what makes the experiment
%     well-posed without re-solving the boundary. This answers, inside the
%     nonlinear model, whether the announcement disinflation survives
%     above-trend issuance: the impact response mixes the (weaker, because
%     delayed) tax-demand channel with the (inflationary) dilution of the
%     terminal price level, and neither sign is imposed.
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
    % refinement target: keep polishing BELOW the reportable gate while the
    % budget lasts (a residual of size tol leaves a visible +-2*tol ripple
    % in the year-on-year inflation path; polishing to tol/4 removes it)
    ttgt   = getopt(opts, 'tol_target', tol/4);
    maxit  = getopt(opts, 'maxit', 60);
    xi     = getopt(opts, 'xi', 0.5);
    regime = getopt(opts, 'regime', 'nominal');
    financing = getopt(opts, 'financing', 'lumpsum');
    rebate  = strcmpi(financing, 'rebate');
    deficit = strcmpi(financing, 'deficit');
    rho_d   = getopt(opts, 'rho_d', 0.8);

    % ---------------- FISCAL SPECIFICATION (round 10, decision D11) -------
    % The core solver takes a fiscal path and a terminal condition as INPUTS.
    % It does not know about C1-C4, and no experiment logic lives here: a
    % separate builder (kv_fiscal_spec) constructs the specifications, so the
    % four cases of the 2x2 differ in exactly one object and the solver cannot
    % silently reinterpret one of them.
    %
    % LEGACY DEFAULT. With no opts.fiscal the solver reproduces the previous
    % behaviour exactly: phi_t = 1 - rho_d^t under deficit financing, phi == 1
    % otherwise, and a terminal pin that floats with the realized dilution.
    % That path is unchanged line for line below.
    fs = getopt(opts, 'fiscal', []);
    have_fs = ~isempty(fs) && isstruct(fs);
    if have_fs
        assert(isfield(fs,'phi_path') && numel(fs.phi_path) >= T, ...
            'fiscal.phi_path must be supplied with at least T entries');
        assert(isfield(fs,'kappa_mode'), 'fiscal.kappa_mode required (free|target)');
        if isfield(fs,'consolidation_path') && ~isempty(fs.consolidation_path)
            assert(numel(fs.consolidation_path) >= T, ...
                'fiscal.consolidation_path must have at least T entries');
        end
        % 'target' no longer changes anything this solver DOES. It records
        % that the caller is solving for the consolidation amplitude and wants
        % kappa_inf reported against a target; the price path and the debt
        % recursion are identical under both modes. See the terminal-pin
        % comment below for why.
        deficit = true;                    % a supplied path IS the financing rule
    end
    assert(~deficit || strcmpi(regime, 'indexed'), ...
        ['financing=''deficit'' requires regime=''indexed'': the experiment ' ...
         'holds the REAL program at the balanced benchmark so only the tax ' ...
         'timing differs; a nominal appropriation would let the terminal ' ...
         'dilution shrink the real program and confound the comparison.']);
    verbose= getopt(opts, 'verbose', true);

    % SOLVER CONSISTENCY (Round 12): the transition interior is computed by
    % the finite-horizon GRID-CHOICE backward recursion (hh_bellman_step) and
    % an on-grid forward distribution, so the boundary steady states, the
    % terminal value function VT, and the pre-announcement distribution dist0
    % must come from the SAME household method. Pin the local copy to 'vfi'
    % regardless of the global default (pg.hh_solver='egm' since Round 12);
    % mixing EGM boundaries with grid-VFI interior steps leaves a spurious
    % terminal wedge and (in the Newton solver) an inconsistent linearization.
    pgc.hh_solver = 'vfi';

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
    if rebate
        % R3 design along the path: levy at twice the program, half rebated
        reg1 = struct('name','TR-GREEN-REBATE','Bnom',B0, 'g',g_of, 'D',D_of, ...
            'tau_ls',@(P) rb_of(P) - g_of(P), ...
            'vartheta',@(P) 2 * g_of(P) ./ (1 - D_of(P)));
    else
        reg1 = struct('name','TR-GREEN','Bnom',B0, 'g',g_of, 'D',D_of, ...
            'tau_ls',@(P) rb_of(P) + g_of(P), 'vartheta',@(P) 0);
    end
    [eq0, o0] = solve_regime_equilibrium(pgc, reg0, rbar, [0.5, 1.3]);
    if isempty(eq0), TR.msg = ['tier2: no baseline ss: ' o0.msg]; return; end
    [eq1, o1] = solve_regime_equilibrium(pgc, reg1, rbar, [0.5, 1.3]);
    if isempty(eq1), TR.msg = ['tier2: no green ss: ' o1.msg]; return; end
    if verbose
        fprintf('  boundary steady states: P0=%.4f -> P1=%.4f (D: %.4f -> %.4f)\n', ...
            eq0.P, eq1.P, eq0.D, eq1.D);
    end

    % terminal household objects (green ss) and initial distribution (base ss);
    % under the rebate design the terminal problem carries the levy vartheta
    pgcT = pgc;
    if rebate, pgcT.vartheta = eq1.vartheta; end
    [~, oT] = S_green(rbar, eq1.tau, eq1.D, pgcT);
    [~, oI] = S_green(rbar, eq0.tau, eq0.D, pgc);
    if ~oT.feasible || ~oI.feasible
        TR.msg = 'tier2: boundary household problem infeasible.'; return;
    end
    VT    = oT.V;          % terminal value function (green ss)
    dist0 = oI.dist;       % pre-announcement wealth distribution

    % ---- initial guess: log-linear bridge between the steady states ----
    % Under deficit financing the terminal price is diluted by the
    % accumulated stock; seed the bridge with the analytic zeroth-order
    % kappa (undiscounted sum of the primary gaps over the initial stock)
    % so the floating pin starts near its fixed point.
    Pterm_guess = eq1.P;
    if deficit
        kappa0 = 1 + (rho_d / (1 - rho_d)) * (Gg / B0);
        Pterm_guess = kappa0 * eq1.P;
    end
    phat = exp(linspace(log(eq0.P), log(Pterm_guess), T));
    phat(T) = Pterm_guess;

    % Kg accumulation from zero (announcement); delta_g from pgc
    dg  = pgc.delta_g;
    qg  = 1; if isfield(pgc,'q_g') && ~isempty(pgc.q_g), qg = pgc.q_g; end

    xi0  = xi;          % base relaxation of the underlying Picard map
    mAnd = 5;           % Anderson memory (past residuals combined per step)
    Xh   = {};  Fh = {};  % history: log-price iterates and log residuals
    best = struct('resnorm', Inf);   % best iterate found (returned at pack)
    for it = 1:maxit
        % ---- climate + fiscal paths implied by the trial price path ----
        % PARTIAL INDEXATION (referee R12, Major 5). The binary
        % nominal/indexed comparison is a limiting case of
        %
        %     G_{g,t} = Gbar * (P_t / Pbar)^xi,   xi in [0,1],
        %
        % so the real program is g_t = G_{g,t}/P_t = (Gbar/Pbar) *
        % (P_t/Pbar)^(xi-1). Appropriations are revised, indexed imperfectly,
        % and renegotiated; a permanent nominal amount held fixed forever and a
        % fully indexed mandate are the two ends of that interval, not the only
        % possibilities. Since the climate feedback P -> g -> D -> damages runs
        % entirely through this line, the multiplicity and anchor-insulation
        % results depend on where in [0,1] appropriations actually sit.
        %
        % Taking Pbar = eq1.P makes the rule NEST BOTH LEGACY BRANCHES EXACTLY:
        %   xi = 1 : g_t = Gbar/eq1.P                (the real mandate)
        %   xi = 0 : g_t = (Gbar/Pbar)*(Pbar/P_t) = Gbar/P_t   (nominal)
        % so this is a generalization, not a replacement. The legacy branch is
        % left untouched and is taken whenever xi_index is absent, which is
        % what keeps the D11 parity test meaningful.
        xi_index = getopt(opts, 'xi_index', []);
        if isempty(xi_index)
            if strcmpi(regime, 'indexed')
                g_path = (Gg / eq1.P) * ones(1, T);   % real mandate
            else
                g_path = Gg ./ phat;                  % nominal appropriation
            end
        else
            assert(isscalar(xi_index) && xi_index >= 0 && xi_index <= 1, ...
                'opts.xi_index must be a scalar in [0,1]');
            Pbar   = eq1.P;
            g_path = (Gg / Pbar) * (phat / Pbar) .^ (xi_index - 1);
        end
        Kg = zeros(1, T);
        for t = 1:T
            Kprev = 0; if t > 1, Kprev = Kg(t-1); end
            Kg(t) = (1 - dg) * Kprev + qg * g_path(t);
        end
        % version-1 climate map with TRANSITION Kg (not the ss shortcut)
        D_path = pgc.D0 * exp(-pgc.theta_g * Kg);
        % realized real return: surprise jump at t=1 against P0 = eq0.P
        phat_lag = [eq0.P, phat(1:T-1)];
        r_path = (1 + rbar) .* phat_lag ./ phat - 1;
        if deficit
            % DEFICIT FINANCING: taxes phase in, debt is the residual.
            % tau_t = rbar*b_t + phi_t*g_t with the service on
            % CONTEMPORANEOUS real debt (the benchmark's convention), so
            % the real recursion b_t = (1+r_t)b_{t-1} + g_t - tau_t
            % rearranges to the explicit forward form below; phi==1
            % reproduces b_t = B0/phat_t exactly (the (1+r_t)/(1+rbar)
            % factor is phat_{t-1}/phat_t).
            % THE TAX RULE, WRITTEN OUT:
            %     tau_t = rbar*b_t + phi_t*g_t + xi_t,
            % where phi_t is the contemporaneously financed share of green
            % spending, (1 - phi_t) is the initially debt-financed share, and
            % xi_t is a CONSOLIDATION SURCHARGE (zero in the legacy rule).
            % The surcharge is the fiscal instrument that retires the debt a
            % delayed phase-in accumulates; without it, "delayed taxation" and
            % "permanently higher terminal debt" are the same treatment.
            if have_fs
                phi_path = reshape(fs.phi_path(1:T), 1, T);
                xi_path  = zeros(1, T);
                if isfield(fs,'consolidation_path') && ~isempty(fs.consolidation_path)
                    xi_path = reshape(fs.consolidation_path(1:T), 1, T);
                end
            else
                phi_path = 1 - rho_d.^(1:T);          % LEGACY, unchanged
                xi_path  = zeros(1, T);               % LEGACY: no surcharge
            end
            b_path = zeros(1, T);
            bprev  = B0 / eq0.P;               % pre-announcement real debt
            for tt = 1:T
                b_path(tt) = ((1 + r_path(tt)) * bprev ...
                              + (1 - phi_path(tt)) * g_path(tt) ...
                              - xi_path(tt)) / (1 + rbar);
                bprev = b_path(tt);
            end
            vart_path = zeros(1, T);
            tau_path  = rbar .* b_path + phi_path .* g_path + xi_path;
            kappa_path = b_path .* phat / B0;  % stationarized stock, /B0
            % TERMINAL PIN: ALWAYS the legacy free form. kappa_inf is an
            % OUTCOME of the tax path, never an input to the price path.
            %
            % The previous version set phat(T) = kappa_target*eq1.P whenever a
            % target was supplied. That reaches the target by overriding the
            % accounting rather than by financing it: the debt recursion is
            % left intact but the terminal price is moved to whatever makes
            % the ratio come out right, so the "matched terminal debt" case
            % had no fiscal counterpart and the government budget was no
            % longer an identity at T. A terminal debt target must be hit
            % through the tax path. That is what the consolidation amplitude
            % a_xi is for, and it is solved for OUTSIDE this function by
            % kv_solve_consolidation, which calls this solver repeatedly with
            % different xi_path scales and reads kappa_inf back off.
            phat(T) = kappa_path(T) * eq1.P;
        else
            phi_path = ones(1, T); kappa_path = ones(1, T);
            b_path = B0 ./ phat;
            if rebate
                % R3 flow identity: tau_ls + vartheta(1-D) = r*b + g each t
                vart_path = 2 * g_path ./ (1 - D_path);
                tau_path  = rbar .* b_path - g_path;
            else
                vart_path = zeros(1, T);
                tau_path  = rbar .* b_path + g_path;
            end
        end

        % ---- backward: date-t policies from the terminal green ss ----
        [POL, feas] = transition_backward(VT, r_path, tau_path, D_path, pgc, ...
                                          vart_path);
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
        % snapshot the best iterate WITH its full consistent path set --
        % Anderson steps are not monotone, so the last iterate may be worse
        % than one seen earlier; the packed result is always the best found
        if resnorm < best.resnorm
            best = struct('resnorm', resnorm, 'phat', phat, 'resid', resid, ...
                'S_path', S_path, 'b_path', b_path, 'tau_path', tau_path, ...
                'r_path', r_path, 'D_path', D_path, 'Kg', Kg, ...
                'g_path', g_path, 'vart_path', vart_path, ...
                'phi_path', phi_path, 'kappa_path', kappa_path, 'it', it);
        end
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
        if resnorm < ttgt, break; end   % refinement target reached
        if it == maxit, break; end
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

    % ---- pack: always the BEST iterate found (with its consistent paths) ----
    phat = best.phat;       resid = best.resid;
    S_path = best.S_path;   b_path = best.b_path;  tau_path = best.tau_path;
    r_path = best.r_path;   D_path = best.D_path;  Kg = best.Kg;
    g_path = best.g_path;   vart_path = best.vart_path;
    TR.converged = best.resnorm < tol;   % the reportable gate (tol), not ttgt
    TR.phat   = phat;   TR.P0 = eq0.P;
    TR.pi_path = (1 + pgc.mu) * phat ./ [eq0.P, phat(1:T-1)] - 1;  % actual inflation
    TR.r_path = r_path; TR.tau_path = tau_path; TR.D_path = D_path;
    TR.Kg_path = Kg;    TR.S_path = S_path;     TR.b_path = b_path;
    TR.g_path = g_path;
    TR.xi_index = getopt(opts, 'xi_index', []); TR.vart_path = vart_path; TR.financing = financing;
    TR.phi_path = best.phi_path;  TR.kappa_path = best.kappa_path;
    TR.xi_path = zeros(1, T);
    if have_fs && isfield(fs,'consolidation_path') && ~isempty(fs.consolidation_path)
        TR.xi_path = reshape(fs.consolidation_path(1:T), 1, T);
    end
    % The primary gap is now the DEBT-FINANCED share net of the surcharge, so
    % that summing it reproduces the accumulated stock. Reporting
    % (1-phi)*g alone would attribute the whole gap to timing even in a case
    % whose entire purpose is that the surcharge closes it.
    TR.primary_gap = (1 - best.phi_path) .* best.g_path - TR.xi_path;
    TR.primary_gap_gross = (1 - best.phi_path) .* best.g_path;
    TR.kappa_inf = best.kappa_path(end);  TR.rho_d = rho_d;
    TR.fiscal = fs;
    TR.kappa_mode = 'free';
    TR.kappa_target = NaN;  TR.kappa_gap = NaN;  TR.kappa_hit = true;
    if have_fs
        TR.kappa_mode = lower(fs.kappa_mode);
        if strcmpi(fs.kappa_mode, 'target')
            TR.kappa_target = fs.kappa_target;
            TR.kappa_gap = abs(TR.kappa_inf/fs.kappa_target - 1);
            tolk = 1e-8; if isfield(fs,'kappa_tol'), tolk = fs.kappa_tol; end
            TR.kappa_hit = TR.kappa_gap < tolk;
        end
    end
    TR.resid  = resid;  TR.iters = it;  TR.best_iter = best.it;
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
    % headline path statistics (quotable once .reportable):
    %   frontload    share of the long-run stationarized price decline
    %                realized in the announcement year
    %   trend_return first year after which |pi - mu| stays within 25bp
    TR.frontload = (eq0.P - phat(1)) / (eq0.P - phat(T));
    late = find(abs(TR.pi_path - pgc.mu) > 0.0025, 1, 'last');
    if isempty(late), late = 0; end
    TR.trend_return = late + 1;
    TR.msg = sprintf(['tier2 %s/%s: fixed point %s (interior max %.5f @t=%d), ' ...
        'horizon %s (terminal resid %.5f) in %d iters; ' ...
        'impact phat_1/P0 = %.4f (surprise %s), terminal P = %.4f'], ...
        regime, financing, ternstr(TR.converged, 'CONVERGED', 'NOT CONVERGED'), ...
        TR.resid_interior, TR.resid_argmax, ...
        ternstr(TR.horizon_ok, 'OK', 'TOO SHORT (raise T)'), TR.resid_terminal, ...
        TR.iters, phat(1)/eq0.P, ...
        ternstr(phat(1) < eq0.P, 'DISINFLATION', 'inflation'), phat(T));
end

% ==========================================================================
% (backward pass extracted to src_project/transition_backward.m so it can be
% re-run standalone on a saved converged path -- e.g. for the
% transition-inclusive welfare of main_project_transition_welfare.)

function v = getopt(o, f, d)
    if isfield(o, f) && ~isempty(o.(f)), v = o.(f); else, v = d; end
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
