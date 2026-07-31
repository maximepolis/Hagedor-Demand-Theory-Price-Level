function st = kv_solve_bond_given_q(q, al, CTX, W)
% KV_SOLVE_BOND_GIVEN_Q  Solve ONLY the bond market conditional on a trial
% tree price: P = iota*B/S_b with tau and div consistent with that P. The
% tree market is deliberately left as the residual, which is the object the
% diagnostic scan maps: F_k(q;alpha) = S_k(P(q,alpha),q,alpha) - Kbar.
%
% The inner loop is a damped fixed point on P and is SERIAL by nature -- it
% is a contraction, iterate k+1 reads iterate k. Parallelism belongs one
% level up, across independent (alpha,q) nodes.
    if nargin < 4, W = []; end
    st = struct('ok',false);
    pe = kv_prices_to_pe(al, CTX);
    P = CTX.iota*CTX.Bnom/0.30; o = [];
    for it = 1:80
        tau = kv_tau_of(al, P, CTX);
        dvd = kv_div_of(P, CTX);
        o = kv_stationary_block(CTX.r_b, q, dvd, tau, pe, W);
        if ~o.ok, return; end
        W = o.sol.V;
        Pn = CTX.iota*CTX.Bnom/max(o.Sb,1e-12);
        if abs(Pn-P) < 1e-13*max(1,abs(P)), P = Pn; break; end
        P = 0.5*P + 0.5*Pn;
    end
    st = struct('ok',true,'P',P,'Sb',o.Sb,'Sk',o.Sk,'sol',o.sol, ...
                'dist',o.dist,'dV',o.dV,'ddist',o.ddist);
end
