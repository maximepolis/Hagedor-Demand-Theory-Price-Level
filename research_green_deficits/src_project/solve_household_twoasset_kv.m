function [sol, diag] = solve_household_twoasset_kv(rb, q, d, tau, p, V0)
% SOLVE_HOUSEHOLD_TWOASSET_KV  Two-asset household with INFREQUENT
% k-adjustment (two-asset build plan, variant (b)): the Kaplan-Violante
% friction that generates wealthy hand-to-mouth households.
%
% Each period the household draws an adjustment opportunity with
% probability lambda:
%   ADJUSTER  (prob lambda): frictionless rebalancing; resources collapse
%     to cash-on-hand x = y - tau + (1+rb) b + (q+d) k, and the problem is
%     the Step 0 problem EXCEPT the continuation is V(b', k', e) -- the
%     composition matters next period, so (b', k') is a genuine 2D choice.
%   NON-ADJUSTER (prob 1-lambda): k' = k (shares kept; dividends d*k arrive
%     as liquid income), chooses only (c, b') from liquid resources
%     m = y - tau + (1+rb) b + d k.
%
% Bellman system (annual):
%   V(b,k,e)  = lambda Va(x(b,k,e), e) + (1-lambda) Vn(b,k,e)
%   Va(x,e)   = max_{a in [0,x), b' in [0,a]} u(x-a) + chi v(b')
%                 + beta EV(b', (a-b')/q, e)
%   Vn(b,k,e) = max_{b' in [0,m)} u(m-b') + chi v(b') + beta EV(b', k, e)
% where EV(.,.,e) = sum_e' Pi(e,e') V(.,.,e'). KEY SPEED FACT: (b',k') does
% not depend on e', so the e'-mixing commutes with interpolation -- EV is
% premixed once per sweep and every candidate needs ONE (bi)linear interp.
%
% Numerics: VFI with elementwise-vectorized golden searches. The adjuster
% is solved on a 1D x-grid per e (nested golden: outer total outlay a,
% inner liquid split b', bilinear interp into EV); the non-adjuster runs a
% single vector golden per (k,e) slice (1D interp in b). v'(0) = +inf
% keeps b' > 0, so the liquid grid starts at a small positive floor.
%
% INPUTS  rb, q, d, tau : prices/taxes as in Step 0.
%         p  : params with .bGrid (nb), .kGrid (nk), .xGridA (nx),
%              .eGrid/.Pi, .beta, .sigma, .chi_b, .zeta_b, .lambda_adj,
%              .tol_vfi, .maxit_vfi, .gold_outer, .gold_inner.
%         V0 : optional (nb x nk x ne) warm start ([] = none).
%
% OUTPUT  sol : .V (nb x nk x ne), .polBa/.polKa/.polCa (nx x ne, adjuster
%               policies on xGridA), .polBn/.polCn (nb x nk x ne,
%               non-adjuster), .x_of (fn handle x(b,k)), .m_of (m(b,k)).
%         diag: .converged .iters .supnorm
%
% STATUS: scaffolded, untested pending a MATLAB run.

    bG = p.bGrid(:); kG = p.kGrid(:); xG = p.xGridA(:);
    nb = numel(bG); nk = numel(kG); nx = numel(xG); ne = numel(p.eGrid);
    lam = p.lambda_adj; sig = p.sigma; zet = p.zeta_b; chi = p.chi_b;
    Rb = 1 + rb;
    ynet = p.eGrid(:)' - tau;                     % 1 x ne
    gold = (sqrt(5)-1)/2;
    go = p.gold_outer; gi = p.gold_inner;

    uof = @(c) uofc(c, sig);
    vof = @(b) vofb(b, zet);

    V = zeros(nb, nk, ne);
    for ie = 1:ne                                  % consume-liquid guess
        m0 = ynet(ie) + Rb*bG + d*kG';             % nb x nk
        V(:,:,ie) = uof(max(m0, 1e-8)) / (1 - p.beta);
    end
    if nargin >= 6 && ~isempty(V0) && isequal(size(V0), [nb nk ne])
        V = V0;
    end

    polBa = zeros(nx, ne); polKa = zeros(nx, ne); polCa = zeros(nx, ne);
    polBn = zeros(nb, nk, ne); polCn = zeros(nb, nk, ne);
    diag = struct('converged', false, 'iters', 0, 'supnorm', Inf);

    for it = 1:p.maxit_vfi
        % ---- premix continuation over e' (the speed fact) ----
        EV = zeros(nb, nk, ne);
        for ie = 1:ne
            for jep = 1:ne
                EV(:,:,ie) = EV(:,:,ie) + p.Pi(ie, jep) * V(:,:,jep);
            end
        end

        % ---- adjuster block: Va on the x-grid, vector golden over nodes ----
        Va = zeros(nx, ne);
        for ie = 1:ne
            EVe = EV(:,:,ie);
            % outer golden over total outlay a in [0, x)
            lo = zeros(nx,1); hi = max(xG - 1e-9, 0);
            a1 = hi - gold*(hi-lo); a2 = lo + gold*(hi-lo);
            f1 = va_of_a(a1); f2 = va_of_a(a2);
            for g1 = 1:go
                w = f1 < f2;
                lo(w)  = a1(w); a1(w) = a2(w); f1(w) = f2(w);
                a2(w)  = lo(w) + gold*(hi(w)-lo(w));
                f2(w)  = subeval(va_of_a(a2), w);
                nw = ~w;
                hi(nw) = a2(nw); a2(nw) = a1(nw); f2(nw) = f1(nw);
                a1(nw) = hi(nw) - gold*(hi(nw)-lo(nw));
                f1(nw) = subeval(va_of_a(a1), nw);
            end
            astar = 0.5*(lo+hi);
            [Va(:,ie), bstar, kstar, cstar] = va_of_a(astar);
            polBa(:,ie) = bstar; polKa(:,ie) = kstar; polCa(:,ie) = cstar;
        end

        % ---- non-adjuster block: vector golden per (k,e) slice ----
        Vn = zeros(nb, nk, ne);
        for ie = 1:ne
            for ik = 1:nk
                EVcol = EV(:, ik, ie);             % continuation in b at k
                m  = ynet(ie) + Rb*bG + d*kG(ik);  % nb x 1 liquid resources
                lo = zeros(nb,1); hi = max(m - 1e-9, 1e-12);
                a1 = hi - gold*(hi-lo); a2 = lo + gold*(hi-lo);
                f1 = vn_of_b(a1); f2 = vn_of_b(a2);
                for g1 = 1:go
                    w = f1 < f2;
                    lo(w)  = a1(w); a1(w) = a2(w); f1(w) = f2(w);
                    a2(w)  = lo(w) + gold*(hi(w)-lo(w));
                    f2(w)  = subeval(vn_of_b(a2), w);
                    nw = ~w;
                    hi(nw) = a2(nw); a2(nw) = a1(nw); f2(nw) = f1(nw);
                    a1(nw) = hi(nw) - gold*(hi(nw)-lo(nw));
                    f1(nw) = subeval(vn_of_b(a1), nw);
                end
                bstar = 0.5*(lo+hi);
                [Vn(:,ik,ie), cn] = vn_of_b(bstar);
                polBn(:,ik,ie) = bstar; polCn(:,ik,ie) = cn;
            end
        end

        % ---- combine on the (b,k) grid ----
        Vnew = zeros(nb, nk, ne);
        for ie = 1:ne
            xbk = ynet(ie) + Rb*bG + (q + d)*kG';  % nb x nk cash-on-hand
            VaI = interp1(xG, Va(:,ie), xbk, 'linear', 'extrap');
            Vnew(:,:,ie) = lam * VaI + (1 - lam) * Vn(:,:,ie);
        end
        dV = max(abs(Vnew(:) - V(:)));
        V = Vnew;
        diag.iters = it; diag.supnorm = dV;
        if dV < p.tol_vfi, diag.converged = true; break; end
    end

    sol = struct('V', V, 'polBa', polBa, 'polKa', polKa, 'polCa', polCa, ...
                 'polBn', polBn, 'polCn', polCn);
    sol.x_of = @(b, k) Rb*b + (q + d)*k;           % add ynet(e) - by caller
    sol.m_of = @(b, k) Rb*b + d*k;

    % ================= nested helpers (share the sweep scope) =============
    function [val, bch, kch, cch] = va_of_a(a)
        % adjuster value of total outlay a (vector over x-nodes): inner
        % vector golden over the liquid split b' in [bmin, a]
        cch = max(xG - a, 1e-10);
        bl = min(bG(1)*ones(size(a)), a); bh = a;
        b1 = bh - gold*(bh-bl); b2 = bl + gold*(bh-bl);
        h1 = split_val(b1, a); h2 = split_val(b2, a);
        for g2 = 1:gi
            w2 = h1 < h2;
            bl(w2) = b1(w2); b1(w2) = b2(w2); h1(w2) = h2(w2);
            b2(w2) = bl(w2) + gold*(bh(w2)-bl(w2));
            h2(w2) = subeval(split_val(b2, a), w2);
            nw2 = ~w2;
            bh(nw2) = b2(nw2); b2(nw2) = b1(nw2); h2(nw2) = h1(nw2);
            b1(nw2) = bh(nw2) - gold*(bh(nw2)-bl(nw2));
            h1(nw2) = subeval(split_val(b1, a), nw2);
        end
        bch = 0.5*(bl+bh);
        kch = max(a - bch, 0)/q;
        val = uof(cch) + chi*vof(bch) + p.beta * ev_bilin(EVe, bch, kch);
    end
    function h = split_val(bb, a)
        kk = max(a - bb, 0)/q;
        h  = chi*vof(bb) + p.beta * ev_bilin(EVe, bb, kk);
    end
    function [val, cn] = vn_of_b(bb)
        cn  = max(m - bb, 1e-10);
        val = uof(cn) + chi*vof(bb) + p.beta * ...
              interp1(bG, EVcol, min(max(bb, bG(1)), bG(end)), 'linear');
    end
    function v2 = ev_bilin(E, bq, kq)
        % bilinear interpolation of E (nb x nk) at vector points (bq, kq),
        % clamped to the grid box
        bq = min(max(bq, bG(1)), bG(end));
        kq = min(max(kq, kG(1)), kG(end));
        ib = discretize(bq, bG); ib = min(max(ib,1), nb-1);
        ik2 = discretize(kq, kG); ik2 = min(max(ik2,1), nk-1);
        wb = (bq - bG(ib)) ./ (bG(ib+1) - bG(ib));
        wk = (kq - kG(ik2)) ./ (kG(ik2+1) - kG(ik2));
        i11 = ib   + (ik2-1)*nb; i21 = ib+1 + (ik2-1)*nb;
        i12 = ib   + ik2*nb;     i22 = ib+1 + ik2*nb;
        v2 = (1-wb).*(1-wk).*E(i11) + wb.*(1-wk).*E(i21) ...
           + (1-wb).*wk.*E(i12)     + wb.*wk.*E(i22);
    end
end

function x = subeval(xfull, mask)
% helper: evaluate-full-then-mask (golden vectors update only masked lanes)
    x = xfull(mask);
end

function u = uofc(c, sig)
    if sig == 1, u = log(c); else, u = (c.^(1-sig))/(1-sig); end
end

function v = vofb(b, zet)
    bb = max(b, 1e-12);
    if abs(zet - 1) < 1e-12, v = log(bb);
    else, v = (bb.^(1-zet))/(1-zet); end
end
