function [mu, ddiag] = stat_dist_agg(apol_idx, R, pg)
% STAT_DIST_AGG  Invariant distribution over (a,e,s) for the aggregate-risk
% economy (aggregate-risk plan, Stage A). Exact eigenvector, no simulation.
%
% Transition from (a,e,s): the household chooses real savings a' = aGrid(idx);
% the aggregate state moves s -> s' by Pi_agg, the idiosyncratic e -> e' by Pi,
% and next-period START wealth is w' = R(s,s') * a', which is bracketed on the
% grid by a lottery (the return scaling puts w' off the grid). The result is
% the ergodic joint distribution; the aggregate-state marginal is Pi_agg's
% stationary distribution, and the state-CONDITIONAL asset distribution is what
% clears each state's asset market (see solve_dtpl_aggrisk).
%
% INPUTS
%   apol_idx : na x ne x ns savings-policy indices (from solve_household_vfi_agg)
%   R        : ns x ns realized gross real returns
%   pg       : params (aGrid, Pi, Pi_agg, tol_dist, maxit_dist)
% OUTPUTS
%   mu    : na x ne x ns invariant distribution (sums to 1)
%   ddiag : struct .converged .iter .err

    aGrid = pg.aGrid(:);  Pi = pg.Pi;  Piagg = pg.Pi_agg;
    na = numel(aGrid);  ne = size(Pi,1);  ns = size(Piagg,1);
    N = na*ne*ns;  tol = pg.tol_dist;  maxit = pg.maxit_dist;
    idx = @(a,e,s) ((s-1)*ne + (e-1))*na + a;      % linear index

    rows = zeros(N*ne*ns*2,1); cols = rows; vals = rows;  p = 0;
    for s = 1:ns
        for e = 1:ne
            for a = 1:na
                ap = aGrid(apol_idx(a,e,s));       % chosen real savings
                frm = idx(a,e,s);
                for sp = 1:ns
                    wp = R(s,sp) * ap;             % next start wealth (off grid)
                    % linear lottery brackets on aGrid
                    if wp <= aGrid(1)
                        lo = 1; hi = 1; wl = 1;
                    elseif wp >= aGrid(end)
                        lo = na; hi = na; wl = 1;
                    else
                        hi = find(aGrid >= wp, 1); lo = hi - 1;
                        wl = (aGrid(hi) - wp) / (aGrid(hi) - aGrid(lo));
                    end
                    for ep = 1:ne
                        pr = Piagg(s,sp) * Pi(e,ep);
                        if pr <= 0, continue; end
                        p = p+1; rows(p)=frm; cols(p)=idx(lo,ep,sp); vals(p)=pr*wl;
                        if hi ~= lo
                            p = p+1; rows(p)=frm; cols(p)=idx(hi,ep,sp); vals(p)=pr*(1-wl);
                        end
                    end
                end
            end
        end
    end
    T = sparse(rows(1:p), cols(1:p), vals(1:p), N, N);   % row-stochastic

    d = ones(N,1)/N;  Tt = T';  err = Inf; it = 0;
    while it < maxit
        it = it + 1;
        dn = Tt * d;
        err = max(abs(dn - d));  d = dn;
        if err < tol, break; end
    end
    d = max(d,0);  d = d / sum(d);
    mu = reshape(d, na, ne, ns);
    ddiag = struct('converged', err < tol, 'iter', it, 'err', err);
    if ~ddiag.converged
        warning('stat_dist_agg:noconv', ...
            'joint distribution did not converge: err=%.3e after %d iters.', err, it);
    end
end
