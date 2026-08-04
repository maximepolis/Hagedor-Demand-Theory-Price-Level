function st = kv_solve_bond_given_q(q, al, CTX, W, toptol, Pseed)
% KV_SOLVE_BOND_GIVEN_Q  Solve ONLY the bond market conditional on a trial
% tree price: find P with S_b(P) = iota*B/P, taxes and dividends consistent
% with that P. The tree market is deliberately left as the residual, which is
% the object the diagnostic scan maps:
%   F_k(q;alpha) = S_k(P(q,alpha),q,alpha) - Kbar.
%
% WHY THIS IS A BRACKETED SOLVE AND NOT A DAMPED ITERATION. It used to be
%   P <- 0.5*P + 0.5*iota*B/S_b(P)
% for up to 80 sweeps, accepted if the step fell below 1e-13. That map is not
% a contraction everywhere: at prices away from equilibrium it oscillates,
% burns all 80 household solves, and returns BOND_NAN. That is what produced
% the SCATTERED failures at alpha = 0.5 -- infeasible-looking q values
% interleaved with feasible ones, which a domain boundary cannot do. The
% failure was in the solver, not in the model.
%
% The residual is monotone, which is what makes bracketing safe. A higher P
% deflates the real debt burden iota*B/P, so the lump-sum tax
% tau = r*B/P + (1-alpha)*g falls, after-tax income rises and liquid demand
% S_b(P) rises; meanwhile real supply iota*B/P falls. So
%   F_b(P) = S_b(P) - iota*B/P
% is increasing in P, equivalently g(P) = iota*B/S_b(P) - P is decreasing.
% Bracket g by geometric expansion, then take safeguarded secant steps that
% fall back to bisection whenever they leave the bracket or fail to reduce
% |g|. Superlinear where the fixed point was merely damped: this typically
% costs 10-15 household solves rather than 80, so it is both more robust and
% several times faster.
%
% Every return carries st.code (see KV_NODE_STATUS). st.ok means ADMISSIBLE,
% not merely "did not error": a point where the household solve diverged,
% consumption went non-positive, or no bracket exists is reported as a
% feasibility failure with a reason, never as a residual. Callers must
% bracket, interpolate and difference only across admissible points.

    if nargin < 4, W = []; end
    if nargin < 5 || isempty(toptol), toptol = 1e-4; end
    if nargin < 6, Pseed = []; end
    steptol = 1e-3;   % largest relative bond residual callable "cleared to a step"
    st = struct('ok',false,'code','POLICY_NONCONV','P',NaN,'Sb',NaN,'Sk',NaN, ...
                'sol',[],'dist',[],'dV',NaN,'ddist',NaN,'min_c',NaN, ...
                'churn',NaN,'churn_non',NaN,'vfi_soft',true, ...
                'ksat',NaN,'bsat',NaN,'Pits',0,'Pgap',NaN,'Pjump',NaN, ...
                'tau',NaN,'dvd',NaN,'dist_loose',false,'stepped',false, ...
                'edge_lo',false,'edge_hi',false,'edge_code','','seed_rungs',0);

    P0 = CTX.iota*CTX.Bnom/0.30;
    if ~isempty(Pseed) && isfinite(Pseed) && Pseed > 0, P0 = Pseed; end

    S = struct('W',W,'n',0,'code','','o',[]);
    gof = @(P, Win) gres(P, q, al, CTX, toptol, Win);

    % ---- bracket g(P) = iota*B/S_b(P) - P, which is decreasing in P -------
    % AN INFEASIBLE EXPLORATORY ENDPOINT IS A DOMAIN EDGE, NOT A FAILURE OF
    % THIS SOLVE. The previous version returned the endpoint's code as the
    % code of the whole call, so one overshoot into the region where the
    % household problem stops being defined -- typically a low P, where the
    % real debt burden iota*B/P and hence the lump-sum tax explode and
    % consumption goes non-positive -- discarded a q at which the root was
    % comfortably interior and already bracketed.
    %
    % That is the mechanism behind the SCATTERED pattern. Whether the
    % geometric expansion overshoots depends on where the continuation seed
    % P0 sits relative to the root, and the seed moves with q; so neighbouring
    % q could differ in whether they ever probed the infeasible region, and
    % the admissible set came out interleaved. kv_bracket_finite reads
    % interleaving as an indictment of the solver rather than a domain
    % boundary, and it was right: a domain does not alternate.
    %
    % Expansion now STOPS at an infeasible endpoint and keeps the last
    % feasible one. Failure is reported only if no sign change exists among
    % points the model actually defines, and it is then reported as
    % BOND_DOMAIN_EDGE -- which, unlike the old BOND_NOBRACKET, is a statement
    % about the model and should appear in CONTIGUOUS runs of q.
    [g0, S] = call(gof, P0, S);
    if ~isempty(S.code)
        [P0, g0, S] = seed_ladder(gof, P0, S);
        if isfield(S,'n_seed_rungs'), st.seed_rungs = S.n_seed_rungs; end
        if ~isempty(S.code), st.code = S.code; st.Pits = S.n; return; end
    end
    lo = P0; hi = P0; glo = g0; ghi = g0;
    edge_lo = false; edge_hi = false; edge_code = '';
    fac = 1.6; got = false;
    for i = 1:14
        if glo > 0 && ghi > 0                     % need a larger P
            if edge_hi, break; end
            Pn = hi*fac; [gn, S] = call(gof, Pn, S);
            if ~isempty(S.code)
                edge_hi = true; edge_code = S.code; S.code = ''; continue;
            end
            lo = hi; glo = ghi; hi = Pn; ghi = gn;
        elseif glo < 0 && ghi < 0                 % need a smaller P
            if edge_lo, break; end
            Pn = lo/fac; [gn, S] = call(gof, Pn, S);
            if ~isempty(S.code)
                edge_lo = true; edge_code = S.code; S.code = ''; continue;
            end
            hi = lo; ghi = glo; lo = Pn; glo = gn;
        else
            got = true; break;
        end
        if ~isfinite(glo) || ~isfinite(ghi), break; end
    end
    st.edge_lo = edge_lo; st.edge_hi = edge_hi; st.edge_code = edge_code;
    if ~got && ~(glo >= 0 && ghi <= 0)
        if edge_lo || edge_hi
            % The model bounds the feasible price range and no equilibrium
            % lies inside it. Distinct from "the expansion ran out of steps".
            st.code = 'BOND_DOMAIN_EDGE';
        else
            st.code = 'BOND_NOBRACKET';
        end
        st.Pits = S.n; return;
    end

    % ---- safeguarded secant inside the bracket ---------------------------
    % Track the BEST point seen, not the last. On a step function the last
    % iterate can sit on the wrong side of a jump while a better one was
    % already visited, and reporting the last would throw that away.
    % ILLINOIS, not plain false position. Plain regula falsi stalls: one
    % endpoint is retained forever, |g| falls but the BRACKET WIDTH does not
    % go to zero. That is what the max-62-evaluations nodes were doing -- 60
    % secant steps that never collapsed the bracket, so the step test below
    % (which requires a collapsed bracket before it will call a residual a
    % discretization jump) could not fire and the node was thrown away as
    % BOND_NAN. Illinois halves the retained endpoint's function value
    % whenever the same side is updated twice running, which restores
    % two-sided convergence, and a forced bisection every 8th step bounds the
    % width geometrically in the worst case.
    best = struct('P', NaN, 'g', Inf, 'o', []);
    side = 0;
    for i = 1:60
        if abs(ghi - glo) > 0 && mod(i, 8) ~= 0   % false-position candidate
            Ps = lo + glo*(hi-lo)/(glo-ghi);
        else
            Ps = 0.5*(lo+hi);                     % forced bisection
        end
        if ~(isfinite(Ps) && Ps > min(lo,hi) && Ps < max(lo,hi))
            Ps = 0.5*(lo+hi);                     % safeguard -> bisection
        end
        P = Ps;
        [gP, S] = call(gof, P, S);
        if ~isempty(S.code), st.code = S.code; st.Pits = S.n; return; end
        if abs(gP) < abs(best.g), best.P = P; best.g = gP; best.o = S.o; end
        if abs(gP)/max(1,abs(P)) < 1e-12, break; end
        if (hi-lo) < 1e-13*max(1,abs(P)), break; end
        if gP > 0
            lo = P; glo = gP;
            if side == 1, ghi = ghi/2; end        % Illinois on the retained side
            side = 1;
        else
            hi = P; ghi = gP;
            if side == -1, glo = glo/2; end
            side = -1;
        end
    end

    % ---- did it clear, step, or fail? ------------------------------------
    % S_b(P) is a STEP function of P: the adjuster's portfolio choice is an
    % argmax over a discrete candidate set, so aggregate liquid demand jumps
    % as P moves the household problem across a candidate switch. When the
    % market-clearing price falls inside such a jump there is NO P at which
    % the residual vanishes -- the bracket collapses onto the discontinuity
    % with |g| still finite. The previous version called that BOND_NAN, i.e.
    % it reported "the model is undefined here" for prices at which the model
    % is perfectly well defined and merely fails to have an exact zero on a
    % discrete grid. That is what produced the SCATTERED failures that
    % survived the switch away from the damped iteration: alternating q nodes
    % whose bond root happened to land on a jump.
    %
    % The tree market already handles exactly this by taking the closest
    % approach the discretization admits and gating the achieved residual
    % (the golden-section polish in kv_solve_alpha). The bond market now does
    % the same, and reports which of the two happened.
    P = best.P; gP = best.g;
    st.Pits = S.n;
    st.Pgap = abs(gP)/max(1,abs(P));
    st.Pjump = abs(glo - ghi);                    % local jump in g, if any
    brw = (hi - lo)/max(1, abs(P));
    if ~isfinite(st.Pgap)
        st.code = 'BOND_NAN'; return;
    elseif st.Pgap >= 1e-8
        if brw < 1e-7 && st.Pgap < steptol
            st.stepped = true;                    % clears to within one jump
        else
            % The bracket has NOT collapsed, so this is genuine
            % non-convergence -- or the jump is too big to call it clearing.
            st.code = 'BOND_NAN'; return;
        end
    end

    o = best.o;
    [code, D] = kv_node_status(o, P, CTX, toptol);
    % BOND_STEP must not be masked by BOUNDARY_HIT. With the bond grid frozen
    % every node is BOUNDARY_HIT, so the previous "only override OK" rule hid
    % the step information entirely -- the status histogram showed
    % BOUNDARY_HIT x58 and no BOND_STEP anywhere, which read as "the step
    % relaxation never fired" when in fact it could never be reported.
    if st.stepped && (strcmp(code,'OK') || strcmp(code,'BOUNDARY_HIT'))
        code = 'BOND_STEP';
    end
    st.code = code;
    st.P = P; st.Sb = o.Sb; st.Sk = o.Sk; st.sol = o.sol; st.dist = o.dist;
    st.dV = o.dV; st.ddist = o.ddist;
    if isfield(o, 'churn'),     st.churn     = o.churn;     end
    if isfield(o, 'churn_non'), st.churn_non = o.churn_non; end
    if isfield(o, 'vfi_soft'),  st.vfi_soft  = o.vfi_soft;  end
    if isfield(o,'dist_loose'), st.dist_loose = o.dist_loose; end
    st.min_c = D.min_c; st.ksat = D.ksat; st.bsat = D.bsat;
    st.tau = kv_tau_of(al, P, CTX); st.dvd = kv_div_of(P, CTX);
    st.ok = kv_is_admissible(code);
end

% ---------------------------------------------------------------------
function [P, g, S] = seed_ladder(gof, P0, S)
% The seed itself was infeasible. That is not the same as the model being
% undefined at this q: the seed is a CONTINUATION guess carried over from a
% neighbouring alpha or a coarser grid, and it can land outside the feasible
% price range without saying anything about whether a root exists inside it.
%
% Walk outward from the seed in alternating directions before giving up. The
% ladder is short and geometric on purpose -- it is looking for any foothold
% in the feasible set, not for the root, which the bracket search then finds.
    P = P0; g = NaN;
    rungs = [1.5 1/1.5 2.25 1/2.25 3.375 1/3.375 6 1/6];
    for i = 1:numel(rungs)
        S.code = '';
        Pt = P0 * rungs(i);
        [gt, S] = call(gof, Pt, S);
        S.n_seed_rungs = i;
        if isempty(S.code) && isfinite(gt)
            P = Pt; g = gt; S.code = ''; return;
        end
    end
    % every rung failed: leave the last code in place for the caller to report
end

function [g, S] = call(gof, P, S)
% One residual evaluation, warm-started from the previous one. The warm start
% is a pure accelerator here: the household solve runs to its own tolerance,
% so it does not change the fixed point, only how fast it is reached.
    S.n = S.n + 1;
    [g, o, code] = gof(P, S.W);
    if ~isempty(code), S.code = code; g = NaN; return; end
    S.o = o; S.W = o.sol.V; S.code = '';
end

function [g, o, code] = gres(P, q, al, CTX, toptol, W)
% g(P) = iota*B/S_b(P) - P, the excess-price map whose zero is the bond
% market equilibrium at this tree price. Decreasing in P (see the header).
% A household-side failure is returned as a CODE, never as a number.
    g = NaN; o = []; code = '';
    if ~isfinite(P) || P <= 0, code = 'BOND_NAN'; return; end
    pe  = kv_prices_to_pe(al, CTX);
    tau = kv_tau_of(al, P, CTX);
    dvd = kv_div_of(P, CTX);
    o = kv_stationary_block(CTX.r_b, q, dvd, tau, pe, W);
    c0 = kv_node_status(o, P, CTX, toptol);
    if ~kv_is_admissible(c0), code = c0; return; end
    if ~isfinite(o.Sb) || o.Sb <= 0, code = 'BOND_NAN'; return; end
    g = CTX.iota*CTX.Bnom/o.Sb - P;
end
