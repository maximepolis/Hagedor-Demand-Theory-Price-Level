function V = kv_shapley_coalition(mask, p0, p1, dist0, CTX, mode)
% KV_SHAPLEY_COALITION  One of the eight subsets of the driver set
% {tau, q, div} in the exact finite-change Shapley decomposition.
%
% The eight coalitions are INDEPENDENT: each re-solves the household problem
% at its own driver vector and reads off aggregate bond demand. Nothing is
% carried between them, which is why they parallelise exactly rather than
% approximately -- the warm start CTX.W0 is a fixed input shared by all
% eight, not a chain, so it is identical under any evaluation order.
%
% mode 'policy' : policies at the coalition's drivers, distribution held at
%       dist0. This is the POLICY block.
% mode 'dist'   : the coalition's own stationary distribution, aggregated
%       with BASELINE policies. This is the DISTRIBUTION block.
%
% Lifted into its own file because a parfor body cannot see a script's local
% functions.
    pr = p0;
    if mask(1), pr.tau = p1.tau; pr.alpha = p1.alpha; end
    if mask(2), pr.q   = p1.q;   end
    if mask(3), pr.dvd = p1.dvd; end

    W = []; if isfield(CTX,'W0'), W = CTX.W0; end
    pe = kv_prices_to_pe(pr.alpha, CTX);

    switch mode
        case 'policy'
            o = kv_stationary_block(CTX.r_b, pr.q, pr.dvd, pr.tau, pe, W, dist0);
            if o.ok, V = o.Sb; else, V = NaN; end
        case 'dist'
            o = kv_stationary_block(CTX.r_b, pr.q, pr.dvd, pr.tau, pe, W);
            if ~o.ok, V = NaN; return; end
            pe0 = kv_prices_to_pe(p0.alpha, CTX);
            o2 = kv_stationary_block(CTX.r_b, p0.q, p0.dvd, p0.tau, pe0, W, o.dist);
            if o2.ok, V = o2.Sb; else, V = NaN; end
        otherwise
            error('kv_shapley_coalition: unknown mode %s', mode);
    end
end
