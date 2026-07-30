function OmNext = push_forward_twoasset_kv(Om, pol, rb, q, dvd, tau, pe)
% PUSH_FORWARD_TWOASSET_KV  One-period push of the (b,k,e) distribution
% under the DATE-t policies of the KV transition.
%
% The asset-state timing makes this clean: the state (b,k) entering date t
% is predetermined, resources at date t are computed at DATE-t prices
% (realized return rb, tree price q, dividend dvd, tax tau, damage-scaled
% income in pe.eGrid), the date-t policies map them to (b',k'), and (b',k')
% IS the date-t+1 state. No date-t+1 object enters the push -- unlike the
% cash-on-hand formulation, where mis-dating the push was a real bug.
%
% Transition assembly mirrors stationary_distribution_twoasset_kv exactly
% (adjuster bilinear lottery from the xGridA policies, non-adjuster on-grid
% b' with the retained-dividend k-drift when payout < 1), applied ONCE.
%
% INPUT   Om (nb x nk x ne), pol from twoasset_kv_bellman_step, date-t
%         scalars, pe with date-t eGrid.
% OUTPUT  OmNext (nb x nk x ne), renormalized to sum(Om).

    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    N  = nb*nk*ne;
    lam = pe.lambda_adj; Rb = 1 + rb;
    ynet = pe.eGrid(:)' - tau;
    if isfield(pe, 'div_payout'), phi = min(max(pe.div_payout,0),1); else, phi = 1; end

    [IB, IK] = ndgrid(1:nb, 1:nk);
    src_bk = IB(:) + (IK(:)-1)*nb;

    gkD = pol.gk;
    if gkD > 0
        kNonD = pol.kNon(:);
        iknD  = discretize(kNonD, kG); iknD = min(max(iknD, 1), nk-1);
        wknD  = min(max((kNonD - kG(iknD))./(kG(iknD+1) - kG(iknD)), 0), 1);
    end

    rows = cell(ne,1); cols = cell(ne,1); vals = cell(ne,1);
    for ie = 1:ne
        xbk = ynet(ie) + Rb*bG + (q + dvd)*kG';
        xbk = min(max(xbk, pe.xGridA(1)), pe.xGridA(end));
        bp  = interp1(pe.xGridA, pol.polBa(:,ie), xbk, 'linear');
        kp  = interp1(pe.xGridA, pol.polKa(:,ie), xbk, 'linear');
        bp  = min(max(bp(:), bG(1)), bG(end));
        kp  = min(max(kp(:), kG(1)), kG(end));
        ib  = discretize(bp, bG); ib = min(max(ib,1), nb-1);
        ik  = discretize(kp, kG); ik = min(max(ik,1), nk-1);
        wb  = min(max((bp - bG(ib))./(bG(ib+1)-bG(ib)), 0), 1);
        wk  = min(max((kp - kG(ik))./(kG(ik+1)-kG(ik)), 0), 1);
        tgtA = [ib+(ik-1)*nb, ib+1+(ik-1)*nb, ib+ik*nb, ib+1+ik*nb];
        wA   = [(1-wb).*(1-wk), wb.*(1-wk), (1-wb).*wk, wb.*wk];
        jb   = reshape(pol.polBnIdx(:,:,ie), [], 1);
        if gkD > 0
            iknV = iknD(IK(:)); wknV = wknD(IK(:));
            tgtN = [jb + (iknV-1)*nb, jb + iknV*nb];
            src  = repmat(src_bk, 6, 1);
            tgt  = [tgtA(:,1); tgtA(:,2); tgtA(:,3); tgtA(:,4); ...
                    tgtN(:,1); tgtN(:,2)];
            w    = [lam*wA(:,1); lam*wA(:,2); lam*wA(:,3); lam*wA(:,4); ...
                    (1-lam)*(1-wknV); (1-lam)*wknV];
        else
            tgtN = jb + (IK(:)-1)*nb;
            src  = repmat(src_bk, 5, 1);
            tgt  = [tgtA(:,1); tgtA(:,2); tgtA(:,3); tgtA(:,4); tgtN];
            w    = [lam*wA(:,1); lam*wA(:,2); lam*wA(:,3); lam*wA(:,4); ...
                    (1-lam)*ones(nb*nk,1)];
        end
        keep = w > 0;
        src = src(keep); tgt = tgt(keep); w = w(keep);
        nsrc = numel(src);
        rr = zeros(nsrc*ne, 1); cc = rr; vv = rr;
        for jep = 1:ne
            pij = pe.Pi(ie, jep);
            idx = (jep-1)*nsrc + (1:nsrc);
            rr(idx) = src + (ie-1)*nb*nk;
            cc(idx) = tgt + (jep-1)*nb*nk;
            vv(idx) = pij * w;
        end
        rows{ie} = rr; cols{ie} = cc; vals{ie} = vv;
    end
    Tm = sparse(vertcat(rows{:}), vertcat(cols{:}), vertcat(vals{:}), N, N);
    v = Tm' * Om(:);
    v = max(v, 0);
    s0 = sum(Om(:));
    if sum(v) > 0, v = v * (s0 / sum(v)); end
    OmNext = reshape(v, nb, nk, ne);
end
