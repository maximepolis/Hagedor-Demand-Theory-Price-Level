function [dist, diag] = stationary_distribution_twoasset_kv(sol, rb, q, d, tau, p)
% STATIONARY_DISTRIBUTION_TWOASSET_KV  Invariant distribution over (b,k,e)
% for the infrequent-adjustment two-asset household (variant (b)).
%
% Each period a node's mass splits lambda / (1-lambda):
%   adjusters   : policies (b',k') read off the x-grid solution at
%                 x = y - tau + (1+rb) b + (q+d) k; mass scatters with a
%                 BILINEAR lottery on the (b,k) grid;
%   non-adjusters: k' = k (on-grid), b' from the (b,k,e) policy; mass
%                 scatters with a linear lottery along b at fixed k.
% Income then mixes with Pi. All lottery indices are precomputed.
%
% OUTPUT  dist : (nb x nk x ne), sums to 1.   diag : .converged .iters .supnorm
%
% STATUS: scaffolded, untested pending a MATLAB run.

    bG = p.bGrid(:); kG = p.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(p.eGrid);
    lam = p.lambda_adj; Rb = 1 + rb;
    ynet = p.eGrid(:)' - tau;

    % ---- precompute adjuster lottery (per e): (b,k) node -> (b',k') ----
    AJ = struct('ib',{},'ik',{},'wb',{},'wk',{});
    for ie = 1:ne
        xbk = ynet(ie) + Rb*bG + (q + d)*kG';               % nb x nk
        bp  = interp1(p.xGridA, sol.polBa(:,ie), xbk, 'linear', 'extrap');
        kp  = interp1(p.xGridA, sol.polKa(:,ie), xbk, 'linear', 'extrap');
        bp  = min(max(bp, bG(1)), bG(end));
        kp  = min(max(kp, kG(1)), kG(end));
        ib  = discretize(bp, bG); ib = min(max(ib,1), nb-1);
        ik  = discretize(kp, kG); ik = min(max(ik,1), nk-1);
        wb  = (bp - bG(ib)) ./ (bG(ib+1) - bG(ib)); wb = min(max(wb,0),1);
        wk  = (kp - kG(ik)) ./ (kG(ik+1) - kG(ik)); wk = min(max(wk,0),1);
        AJ(ie) = struct('ib',ib,'ik',ik,'wb',wb,'wk',wk);
    end
    % ---- precompute non-adjuster lottery (per e): b -> b' at fixed k ----
    NA = struct('ib',{},'wb',{});
    for ie = 1:ne
        bp = squeeze(sol.polBn(:,:,ie));                    % nb x nk
        bp = min(max(bp, bG(1)), bG(end));
        ib = discretize(bp, bG); ib = min(max(ib,1), nb-1);
        wb = (bp - bG(ib)) ./ (bG(ib+1) - bG(ib)); wb = min(max(wb,0),1);
        NA(ie) = struct('ib',ib,'wb',wb);
    end

    dist = ones(nb, nk, ne)/(nb*nk*ne);
    diag = struct('converged', false, 'iters', 0, 'supnorm', Inf);
    kcols = repmat(1:nk, nb, 1);                            % nb x nk col ids
    for it = 1:p.maxit_dist
        pre = zeros(nb, nk, ne);                            % pre-income-mix
        for ie = 1:ne
            M = dist(:,:,ie);
            if ~any(M(:)), continue; end
            % adjusters: bilinear scatter
            A = AJ(ie);
            mA = lam * M;
            i11 = A.ib   + (A.ik-1)*nb;  i21 = A.ib+1 + (A.ik-1)*nb;
            i12 = A.ib   + A.ik*nb;      i22 = A.ib+1 + A.ik*nb;
            acc = accumarray(i11(:), mA(:).*(1-A.wb(:)).*(1-A.wk(:)), [nb*nk 1]) ...
                + accumarray(i21(:), mA(:).*A.wb(:)   .*(1-A.wk(:)), [nb*nk 1]) ...
                + accumarray(i12(:), mA(:).*(1-A.wb(:)).*A.wk(:),    [nb*nk 1]) ...
                + accumarray(i22(:), mA(:).*A.wb(:)   .*A.wk(:),     [nb*nk 1]);
            % non-adjusters: linear scatter along b at own k
            N = NA(ie);
            mN = (1 - lam) * M;
            j1 = N.ib   + (kcols-1)*nb;
            j2 = N.ib+1 + (kcols-1)*nb;
            acc = acc ...
                + accumarray(j1(:), mN(:).*(1-N.wb(:)), [nb*nk 1]) ...
                + accumarray(j2(:), mN(:).*N.wb(:),     [nb*nk 1]);
            pre(:,:,ie) = reshape(acc, nb, nk);
        end
        nxt = zeros(nb, nk, ne);                            % income mix
        for ie = 1:ne
            for jep = 1:ne
                nxt(:,:,jep) = nxt(:,:,jep) + p.Pi(ie, jep) * pre(:,:,ie);
            end
        end
        dv = max(abs(nxt(:) - dist(:)));
        dist = nxt;
        diag.iters = it; diag.supnorm = dv;
        if dv < p.tol_dist, diag.converged = true; break; end
    end
    dist = dist / sum(dist(:));
end
