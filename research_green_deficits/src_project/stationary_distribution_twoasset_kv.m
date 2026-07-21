function [dist, diag] = stationary_distribution_twoasset_kv(sol, rb, q, d, tau, p)
% STATIONARY_DISTRIBUTION_TWOASSET_KV  Invariant distribution over (b,k,e)
% for the infrequent-adjustment household -- sparse-matrix power iteration.
%
% The full one-period transition (adjust/no-adjust split, portfolio
% lotteries, income mixing) is assembled ONCE as a sparse stochastic matrix
% T over the N = nb*nk*ne states; the invariant distribution is then the
% fixed point of cheap sparse matrix-vector products. Non-adjusters choose
% b' on-grid (see the solver), so their transition needs no lottery; the
% adjusters' off-grid (b',k') uses a bilinear lottery.
%
% OUTPUT  dist (nb x nk x ne, sums to 1); diag .converged .iters .supnorm
%
% STATUS: scaffolded, untested pending a MATLAB run.

    bG = p.bGrid(:); kG = p.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(p.eGrid);
    N  = nb*nk*ne;
    lam = p.lambda_adj; Rb = 1 + rb;
    ynet = p.eGrid(:)' - tau;

    rows = cell(ne,1); cols = cell(ne,1); vals = cell(ne,1);
    [IB, IK] = ndgrid(1:nb, 1:nk);
    src_bk = IB(:) + (IK(:)-1)*nb;                  % nb*nk source (b,k) ids
    for ie = 1:ne
        % ---- adjuster leg: policies at x(b,k,e), bilinear lottery ----
        xbk = ynet(ie) + Rb*bG + (q + d)*kG';
        xbk = min(max(xbk, p.xGridA(1)), p.xGridA(end));
        bp  = interp1(p.xGridA, sol.polBa(:,ie), xbk, 'linear');
        kp  = interp1(p.xGridA, sol.polKa(:,ie), xbk, 'linear');
        bp  = min(max(bp(:), bG(1)), bG(end));
        kp  = min(max(kp(:), kG(1)), kG(end));
        ib  = discretize(bp, bG); ib = min(max(ib,1), nb-1);
        ik  = discretize(kp, kG); ik = min(max(ik,1), nk-1);
        wb  = min(max((bp - bG(ib))./(bG(ib+1)-bG(ib)), 0), 1);
        wk  = min(max((kp - kG(ik))./(kG(ik+1)-kG(ik)), 0), 1);
        tgtA = [ib+(ik-1)*nb, ib+1+(ik-1)*nb, ib+ik*nb, ib+1+ik*nb];
        wA   = [(1-wb).*(1-wk), wb.*(1-wk), (1-wb).*wk, wb.*wk];
        % ---- non-adjuster leg: exact node (on-grid b'), same k ----
        jb   = reshape(sol.polBnIdx(:,:,ie), [], 1);
        tgtN = jb + (IK(:)-1)*nb;
        % ---- assemble (source, target) pairs, income mixing over e' ----
        src = repmat(src_bk, 5, 1);
        tgt = [tgtA(:,1); tgtA(:,2); tgtA(:,3); tgtA(:,4); tgtN];
        w   = [lam*wA(:,1); lam*wA(:,2); lam*wA(:,3); lam*wA(:,4); ...
               (1-lam)*ones(nb*nk,1)];
        keep = w > 0;
        src = src(keep); tgt = tgt(keep); w = w(keep);
        nsrc = numel(src);
        rr = zeros(nsrc*ne, 1); cc = rr; vv = rr;
        for jep = 1:ne
            pij = p.Pi(ie, jep);
            idx = (jep-1)*nsrc + (1:nsrc);
            rr(idx) = src + (ie-1)*nb*nk;
            cc(idx) = tgt + (jep-1)*nb*nk;
            vv(idx) = pij * w;
        end
        rows{ie} = rr; cols{ie} = cc; vals{ie} = vv;
    end
    T = sparse(vertcat(rows{:}), vertcat(cols{:}), vertcat(vals{:}), N, N);

    v = ones(N,1)/N;
    diag = struct('converged', false, 'iters', 0, 'supnorm', Inf);
    Tt = T';                                        % iterate v <- T' v
    for it = 1:p.maxit_dist
        vn = Tt * v;
        dv = max(abs(vn - v));
        v = vn;
        diag.iters = it; diag.supnorm = dv;
        if dv < p.tol_dist, diag.converged = true; break; end
    end
    v = max(v, 0); v = v / sum(v);
    dist = reshape(v, nb, nk, ne);
end
