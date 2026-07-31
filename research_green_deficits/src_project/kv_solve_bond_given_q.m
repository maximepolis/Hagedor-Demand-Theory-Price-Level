function st = kv_solve_bond_given_q(q, al, CTX, W, toptol, Pseed)
% KV_SOLVE_BOND_GIVEN_Q  Solve ONLY the bond market conditional on a trial
% tree price: P = iota*B/S_b with tau and div consistent with that P. The
% tree market is deliberately left as the residual, which is the object the
% diagnostic scan maps: F_k(q;alpha) = S_k(P(q,alpha),q,alpha) - Kbar.
%
% The inner loop is a damped fixed point on P and is SERIAL by nature -- it
% is a contraction, iterate k+1 reads iterate k. Parallelism belongs one
% level up, across independent (alpha,q) nodes.
%
% Every return carries st.code (see KV_NODE_STATUS). st.ok now means
% ADMISSIBLE, not merely "did not error": a point where the household solve
% diverged, consumption went non-positive, or the P iteration failed to
% settle is reported as a feasibility failure with a reason, never as a
% residual. Callers must bracket, interpolate and difference only across
% points with a finite residual and an admissible code.

    if nargin < 4, W = []; end
    if nargin < 5 || isempty(toptol), toptol = 1e-4; end
    if nargin < 6, Pseed = []; end
    st = struct('ok',false,'code','POLICY_NONCONV','P',NaN,'Sb',NaN,'Sk',NaN, ...
                'sol',[],'dist',[],'dV',NaN,'ddist',NaN,'min_c',NaN, ...
                'ksat',NaN,'bsat',NaN,'Pits',NaN,'Pgap',NaN,'tau',NaN,'dvd',NaN);
    pe = kv_prices_to_pe(al, CTX);
    P = CTX.iota*CTX.Bnom/0.30;
    if ~isempty(Pseed) && isfinite(Pseed) && Pseed > 0, P = Pseed; end
    o = []; conv = false; it = 0; gap = NaN;
    for it = 1:80
        if ~isfinite(P) || P <= 0, st.code = 'BOND_NAN'; return; end
        tau = kv_tau_of(al, P, CTX);
        dvd = kv_div_of(P, CTX);
        o = kv_stationary_block(CTX.r_b, q, dvd, tau, pe, W);
        [c0, ~] = kv_node_status(o, P, CTX, toptol);
        if ~strcmp(c0,'OK') && ~strcmp(c0,'BOUNDARY_HIT')
            st.code = c0; return;                 % household side failed
        end
        W = o.sol.V;
        Pn = CTX.iota*CTX.Bnom/max(o.Sb,1e-12);
        gap = abs(Pn-P)/max(1,abs(P));
        if gap < 1e-13, P = Pn; conv = true; break; end
        P = 0.5*P + 0.5*Pn;
    end
    st.Pits = it; st.Pgap = gap;
    if ~conv && ~(isfinite(gap) && gap < 1e-8)
        % The P fixed point did not settle. Reporting the last iterate as an
        % equilibrium price would put a number that is not a fixed point into
        % the residual map, which is worse than reporting nothing.
        st.code = 'BOND_NAN'; return;
    end

    [code, D] = kv_node_status(o, P, CTX, toptol);
    st.code = code;
    st.P = P; st.Sb = o.Sb; st.Sk = o.Sk; st.sol = o.sol; st.dist = o.dist;
    st.dV = o.dV; st.ddist = o.ddist;
    st.min_c = D.min_c; st.ksat = D.ksat; st.bsat = D.bsat;
    st.tau = kv_tau_of(al, P, CTX); st.dvd = kv_div_of(P, CTX);
    st.ok = strcmp(code,'OK') || strcmp(code,'BOUNDARY_HIT');
end
