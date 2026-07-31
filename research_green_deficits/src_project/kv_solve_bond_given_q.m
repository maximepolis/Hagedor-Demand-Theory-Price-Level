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
                'ksat',NaN,'bsat',NaN,'Pits',0,'Pgap',NaN,'Pjump',NaN, ...
                'tau',NaN,'dvd',NaN,'dist_loose',false,'stepped',false);

    P0 = CTX.iota*CTX.Bnom/0.30;
    if ~isempty(Pseed) && isfinite(Pseed) && Pseed > 0, P0 = Pseed; end

    S = struct('W',W,'n',0,'code','','o',[]);
    gof = @(P, Win) gres(P, q, al, CTX, toptol, Win);

    % ---- bracket g(P) = iota*B/S_b(P) - P, which is decreasing in P -------
    [g0, S] = call(gof, P0, S);
    if ~isempty(S.code), st.code = S.code; st.Pits = S.n; return; end
    lo = P0; hi = P0; glo = g0; ghi = g0;
    fac = 1.6; got = false;
    for i = 1:14
        if glo > 0 && ghi > 0                     % need a larger P
            lo = hi; glo = ghi; hi = hi*fac;
            [ghi, S] = call(gof, hi, S);
        elseif glo < 0 && ghi < 0                 % need a smaller P
            hi = lo; ghi = glo; lo = lo/fac;
            [glo, S] = call(gof, lo, S);
        else
            got = true; break;
        end
        if ~isempty(S.code), st.code = S.code; st.Pits = S.n; return; end
        if ~isfinite(glo) || ~isfinite(ghi), break; end
    end
    if ~got && ~(glo >= 0 && ghi <= 0)
        st.code = 'BOND_NOBRACKET'; st.Pits = S.n; return;
    end

    % ---- safeguarded secant inside the bracket ---------------------------
    % Track the BEST point seen, not the last. On a step function the last
    % iterate can sit on the wrong side of a jump while a better one was
    % already visited, and reporting the last would throw that away.
    best = struct('P', NaN, 'g', Inf, 'o', []);
    for i = 1:60
        if abs(ghi - glo) > 0                     % secant candidate
            Ps = lo + glo*(hi-lo)/(glo-ghi);
        else
            Ps = 0.5*(lo+hi);
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
        if gP > 0, lo = P; glo = gP; else, hi = P; ghi = gP; end
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
        if brw < 1e-9 && st.Pgap < steptol
            st.stepped = true;                    % clears to within one jump
        else
            % The bracket has NOT collapsed, so this is genuine
            % non-convergence -- or the jump is too big to call it clearing.
            st.code = 'BOND_NAN'; return;
        end
    end

    o = best.o;
    [code, D] = kv_node_status(o, P, CTX, toptol);
    if st.stepped && strcmp(code,'OK'), code = 'BOND_STEP'; end
    st.code = code;
    st.P = P; st.Sb = o.Sb; st.Sk = o.Sk; st.sol = o.sol; st.dist = o.dist;
    st.dV = o.dV; st.ddist = o.ddist;
    if isfield(o,'dist_loose'), st.dist_loose = o.dist_loose; end
    st.min_c = D.min_c; st.ksat = D.ksat; st.bsat = D.bsat;
    st.tau = kv_tau_of(al, P, CTX); st.dvd = kv_div_of(P, CTX);
    st.ok = kv_is_admissible(code);
end

% ---------------------------------------------------------------------
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
