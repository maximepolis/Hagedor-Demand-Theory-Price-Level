function [V, pol] = twoasset_kv_bellman_step(Vnext, rb, q, dvd, tau, pe)
% TWOASSET_KV_BELLMAN_STEP  ONE backward application of the KV Bellman
% operator, for the announcement transition.
%
% This is the per-date kernel of the infrequent-adjustment transition: the
% date-t value V_t(b,k,e) from the date-(t+1) value Vnext, with ALL flow
% objects (realized bond return rb, tree price q, dividend dvd, tax tau,
% damage-scaled income pe.eGrid) dated t. The asset-state formulation makes
% the dating unambiguous -- Vnext is a self-contained function of next
% period's holdings, so no next-period price ever enters this step, which
% is exactly the property that made the one-asset tier-2 solver immune to
% the backward-dating bug the cash-on-hand EGM formulation suffered.
%
% The maximization logic is IDENTICAL to one sweep of
% solve_household_twoasset_kv (candidate-outlay adjuster max, on-grid
% non-adjuster max, lambda-mix on the (b,k) grid); that solver iterates
% this map to a fixed point at constant prices, so at the terminal date the
% two agree by construction -- the consistency gate the driver checks.
%
% INPUT   Vnext (nb x nk x ne); scalars rb, q, dvd, tau; pe = params with
%         .eGrid ALREADY damage-scaled to date t.
% OUTPUT  V     (nb x nk x ne)  date-t value
%         pol   .polBa/.polKa/.polCa (nx x ne, adjuster on xGridA)
%               .polBn/.polBnIdx/.polCn (nb x nk x ne, non-adjuster)
%               .bch/.kch (nb x nk x ne, lambda-mixed choices for aggregation)
%               .n_nonfin (healed non-finite nodes, a feasibility telemetry)

    bG = pe.bGrid(:); kG = pe.kGrid(:); xG = pe.xGridA(:);
    nb = numel(bG); nk = numel(kG); nx = numel(xG); ne = numel(pe.eGrid);
    aC = pe.acGrid(:); sS = pe.sGrid(:)';
    nac = numel(aC); ns = numel(sS);
    lam = pe.lambda_adj; sig = pe.sigma; zet = pe.zeta_b; chi = pe.chi_b;
    Rb = 1 + rb;
    ynet = pe.eGrid(:)' - tau;
    if isfield(pe, 'bbar_liq'), bbar = pe.bbar_liq; else, bbar = 0; end
    if isfield(pe, 'div_payout'), phi = min(max(pe.div_payout,0),1); else, phi = 1; end
    gk = (1 - phi) * dvd / q;
    kNon = min(max(kG * (1 + gk), kG(1)), kG(end));
    if gk > 0
        iknI = discretize(kNon, kG); iknI = min(max(iknI, 1), nk-1);
        wknI = min(max((kNon - kG(iknI))./(kG(iknI+1) - kG(iknI)), 0), 1);
    else
        iknI = (1:nk)'; wknI = zeros(nk, 1);
    end

    % candidate portfolios at THIS date's tree price
    Bc = aC * sS;  Kc = (aC * (1 - sS)) / q;
    Bcl = min(max(Bc(:), bG(1)), bG(end));
    Kcl = min(max(Kc(:), kG(1)), kG(end));
    ibC = discretize(Bcl, bG); ibC = min(max(ibC,1), nb-1);
    ikC = discretize(Kcl, kG); ikC = min(max(ikC,1), nk-1);
    wbC = (Bcl - bG(ibC))./(bG(ibC+1)-bG(ibC));
    wkC = (Kcl - kG(ikC))./(kG(ikC+1)-kG(ikC));
    i11 = ibC   + (ikC-1)*nb; i21 = ibC+1 + (ikC-1)*nb;
    i12 = ibC   + ikC*nb;     i22 = ibC+1 + ikC*nb;
    flowCand = chi * vofb(Bc(:), zet, bbar);
    vb_row   = chi * vofb(bG, zet, bbar);

    % premix continuation over e'
    EV = zeros(nb, nk, ne);
    for ie = 1:ne
        for jep = 1:ne
            EV(:,:,ie) = EV(:,:,ie) + pe.Pi(ie, jep) * Vnext(:,:,jep);
        end
    end

    Xa = repmat(xG, 1, nac);
    Ca = Xa - repmat(aC', nx, 1);
    feas = Ca > 1e-10;
    Ua = -inf(nx, nac);
    Ua(feas) = uofc(Ca(feas), sig);

    polBa = zeros(nx, ne); polKa = zeros(nx, ne); polCa = zeros(nx, ne);
    polBn = zeros(nb, nk, ne); polCn = zeros(nb, nk, ne);
    polBnIdx = zeros(nb, nk, ne);
    Va = zeros(nx, ne);
    Vn = zeros(nb, nk, ne);
    for ie = 1:ne
        Ee = EV(:,:,ie);
        EVcand = (1-wbC).*(1-wkC).*Ee(i11) + wbC.*(1-wkC).*Ee(i21) ...
               + (1-wbC).*wkC.*Ee(i12)     + wbC.*wkC.*Ee(i22);
        Wc = flowCand + pe.beta * EVcand;
        Wmax_a = max(reshape(Wc, nac, ns), [], 2);
        [~, sIdx] = max(reshape(Wc, nac, ns), [], 2);
        [Va(:,ie), aIdx] = max(Ua + repmat(Wmax_a', nx, 1), [], 2);
        polCa(:,ie) = Ca(sub2ind([nx nac], (1:nx)', aIdx));
        sb = sS(sIdx(aIdx))';
        polBa(:,ie) = aC(aIdx) .* sb;
        polKa(:,ie) = aC(aIdx) .* (1 - sb) / q;
        for ik = 1:nk
            m = ynet(ie) + Rb*bG + phi*dvd*kG(ik);
            if gk > 0
                Eek = (1-wknI(ik))*Ee(:, iknI(ik)) + wknI(ik)*Ee(:, iknI(ik)+1);
            else
                Eek = Ee(:, ik);
            end
            cont = vb_row + pe.beta * Eek;
            Cm = repmat(m, 1, nb) - repmat(bG', nb, 1);
            Um = -inf(nb, nb);
            fm2 = Cm > 1e-10;
            Um(fm2) = uofc(Cm(fm2), sig);
            [Vn(:,ik,ie), jIdx] = max(Um + repmat(cont', nb, 1), [], 2);
            polBn(:,ik,ie) = bG(jIdx);
            polBnIdx(:,ik,ie) = jIdx;
            polCn(:,ik,ie) = max(m - bG(jIdx), 1e-10);
        end
    end

    V = zeros(nb, nk, ne);
    bch = zeros(nb, nk, ne); kch = zeros(nb, nk, ne);
    for ie = 1:ne
        xbk = ynet(ie) + Rb*bG + (q + dvd)*kG';
        xcl = min(max(xbk, xG(1)), xG(end));
        VaI = interp1(xG, Va(:,ie), xcl, 'linear');
        V(:,:,ie) = lam * VaI + (1 - lam) * Vn(:,:,ie);
        bpa = interp1(xG, polBa(:,ie), xcl, 'linear');
        kpa = interp1(xG, polKa(:,ie), xcl, 'linear');
        bch(:,:,ie) = lam*bpa + (1-lam)*polBn(:,:,ie);
        kch(:,:,ie) = lam*kpa + (1-lam)*repmat(kNon(:)', nb, 1);
    end

    % heal non-finite nodes (infeasible under an extreme trial price): carry
    % the continuation value forward so poison cannot spread across dates;
    % the count is returned as telemetry, not thrown.
    bad = ~isfinite(V);
    n_nonfin = sum(bad(:));
    if n_nonfin > 0
        V(bad) = Vnext(bad);
        still = ~isfinite(V);
        if any(still(:)), V(still) = min(V(isfinite(V)), [], 'all'); end
    end

    pol = struct('polBa', polBa, 'polKa', polKa, 'polCa', polCa, ...
                 'polBn', polBn, 'polBnIdx', polBnIdx, 'polCn', polCn, ...
                 'bch', bch, 'kch', kch, 'kNon', kNon, 'gk', gk, ...
                 'n_nonfin', n_nonfin);
end

function u = uofc(c, sig)
    if sig == 1, u = log(c); else, u = (c.^(1-sig))/(1-sig); end
end

function v = vofb(b, zet, bbar)
    if nargin < 3 || isempty(bbar), bbar = 0; end
    bb = max(b, 0) + bbar;
    if bbar <= 0, bb = max(bb, 1e-12); end
    if abs(zet - 1) < 1e-12
        v = log(bb);
        if bbar > 0, v = v - log(bbar); end
    else
        v = (bb.^(1-zet))/(1-zet);
        if bbar > 0, v = v - (bbar.^(1-zet))/(1-zet); end
    end
end
