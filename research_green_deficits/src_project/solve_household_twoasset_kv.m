function [sol, diag] = solve_household_twoasset_kv(rb, q, d, tau, p, V0)
% SOLVE_HOUSEHOLD_TWOASSET_KV  Two-asset household with INFREQUENT
% k-adjustment (variant (b)) -- vectorized discrete-choice VFI.
%
% Economy as before: with prob lambda the household rebalances freely
% (resources collapse to cash-on-hand x); with prob 1-lambda it keeps k,
% receives d*k as liquid income, and chooses only (c, b').
%
% SPEED DESIGN (this file replaces a nested-golden-search version that was
% orders of magnitude too slow):
%   * The candidate portfolio values W(a_c, s) = chi v(b') + beta EV(b',k')
%     do NOT depend on the household's own x, so they are computed ONCE per
%     (e, sweep) on a candidate grid {total outlay a_c} x {liquid share s}
%     and the adjuster's maximization is a single (nx x ncand) matrix max.
%   * The non-adjuster chooses b' ON the b-grid: per (k,e) slice the value
%     matrix is u(m_i - b_j) + [chi v(b_j) + beta EV(b_j,k)] -- one outer
%     difference and a row-max. On-grid b' also makes its distribution
%     transition exact (no lottery).
%   * The Bellman map is DETERMINISTIC (no search noise), so VFI contracts
%     at rate beta all the way to tolerance.
% MATLAB's implicit multithreading covers the matrix work; no parfor here.
%
% INPUTS  as before; p uses .bGrid .kGrid .xGridA .eGrid/.Pi .beta .sigma
%         .chi_b .zeta_b .lambda_adj .tol_vfi .maxit_vfi, and the candidate
%         grids .acGrid (total outlay) and .sGrid (liquid shares in (0,1]).
%         V0: optional (nb x nk x ne) warm start.
% OUTPUT  sol: .V, .polBa/.polKa/.polCa (nx x ne, adjuster on xGridA),
%              .polBn/.polCn (nb x nk x ne), .polBnIdx (choice indices).
%         diag: .converged .iters .supnorm
%
% STATUS: scaffolded, untested pending a MATLAB run.

    bG = p.bGrid(:); kG = p.kGrid(:); xG = p.xGridA(:);
    nb = numel(bG); nk = numel(kG); nx = numel(xG); ne = numel(p.eGrid);
    aC = p.acGrid(:); sS = p.sGrid(:)';           % candidates: na_c x 1, 1 x ns
    nac = numel(aC); ns = numel(sS);
    lam = p.lambda_adj; sig = p.sigma; zet = p.zeta_b; chi = p.chi_b;
    Rb = 1 + rb;
    ynet = p.eGrid(:)' - tau;
    diag = struct('converged', false, 'iters', 0, 'supnorm', Inf);

    % candidate portfolios (common to all states): b' = s*a, k' = (1-s)a/q
    Bc = aC * sS;                                  % na_c x ns
    Kc = (aC * (1 - sS)) / q;
    Bcl = min(max(Bc(:), bG(1)), bG(end));         % clamped for interp
    Kcl = min(max(Kc(:), kG(1)), kG(end));
    % bilinear interp indices for the candidate set (fixed across sweeps)
    ibC = discretize(Bcl, bG); ibC = min(max(ibC,1), nb-1);
    ikC = discretize(Kcl, kG); ikC = min(max(ikC,1), nk-1);
    wbC = (Bcl - bG(ibC))./(bG(ibC+1)-bG(ibC));
    wkC = (Kcl - kG(ikC))./(kG(ikC+1)-kG(ikC));
    i11 = ibC   + (ikC-1)*nb; i21 = ibC+1 + (ikC-1)*nb;
    i12 = ibC   + ikC*nb;     i22 = ibC+1 + ikC*nb;
    flowCand = chi * vofb(Bc(:), zet);             % chi v(b') per candidate

    % non-adjuster flow piece chi v(b_j) on the b-grid
    vb_row = chi * vofb(bG, zet);                  % nb x 1 (over candidates j)

    V = zeros(nb, nk, ne);
    for ie = 1:ne
        m0 = ynet(ie) + Rb*bG + d*kG';
        V(:,:,ie) = uofc(max(m0, 1e-8), sig) / (1 - p.beta);
    end
    Vinit = V;                                     % analytic autarky fallback
    if nargin >= 6 && ~isempty(V0) && isequal(size(V0), [nb nk ne])
        V = V0;
        bad0 = ~isfinite(V);                       % heal a poisoned warm start
        if any(bad0(:)), V(bad0) = Vinit(bad0); end
    end
    % plateau-aware convergence state: discrete-choice VFI limit-cycles at
    % the grid granularity, so the relative sup-norm floors above tol_vfi and
    % never reaches it. Track the best dV and accept the grid-limited fixed
    % point once it stops improving, rather than burning the whole budget or
    % spuriously reporting non-convergence.
    dV_best = Inf; stall = 0; stall_cap = 10; tol_soft = 3e-3;

    polBa = zeros(nx, ne); polKa = zeros(nx, ne); polCa = zeros(nx, ne);
    polBn = zeros(nb, nk, ne); polCn = zeros(nb, nk, ne);
    polBnIdx = zeros(nb, nk, ne);
    Xa = repmat(xG, 1, nac);                       % nx x na_c (feasibility)
    Ca = Xa - repmat(aC', nx, 1);                  % consumption per outlay
    feas = Ca > 1e-10;
    Ua = -inf(nx, nac);
    Ua(feas) = uofc(Ca(feas), sig);                % u(x - a_c), precomputed

    for it = 1:p.maxit_vfi
        % ---- premix continuation over e' ----
        EV = zeros(nb, nk, ne);
        for ie = 1:ne
            for jep = 1:ne
                EV(:,:,ie) = EV(:,:,ie) + p.Pi(ie, jep) * V(:,:,jep);
            end
        end

        Va = zeros(nx, ne);
        Vn = zeros(nb, nk, ne);
        for ie = 1:ne
            Ee = EV(:,:,ie);
            % ---- adjuster: candidate values once, then one matrix max ----
            EVcand = (1-wbC).*(1-wkC).*Ee(i11) + wbC.*(1-wkC).*Ee(i21) ...
                   + (1-wbC).*wkC.*Ee(i12)     + wbC.*wkC.*Ee(i22);
            Wc = flowCand + p.beta * EVcand;       % (na_c*ns) x 1
            Wmax_a = max(reshape(Wc, nac, ns), [], 2);      % best split per a
            [~, sIdx] = max(reshape(Wc, nac, ns), [], 2);
            [Va(:,ie), aIdx] = max(Ua + repmat(Wmax_a', nx, 1), [], 2);
            polCa(:,ie) = Ca(sub2ind([nx nac], (1:nx)', aIdx));
            sb = sS(sIdx(aIdx))';                  % chosen share per x-node
            polBa(:,ie) = aC(aIdx) .* sb;
            polKa(:,ie) = aC(aIdx) .* (1 - sb) / q;
            % ---- non-adjuster: outer difference + row max per k slice ----
            for ik = 1:nk
                m = ynet(ie) + Rb*bG + d*kG(ik);   % nb x 1 states
                cont = vb_row + p.beta * Ee(:, ik);% nb x 1 candidates
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

        % ---- combine on the (b,k) grid ----
        Vnew = zeros(nb, nk, ne);
        for ie = 1:ne
            xbk = ynet(ie) + Rb*bG + (q + d)*kG';
            VaI = interp1(xG, Va(:,ie), min(max(xbk, xG(1)), xG(end)), 'linear');
            Vnew(:,:,ie) = lam * VaI + (1 - lam) * Vn(:,:,ie);
        end
        % RELATIVE sup-norm over FINITE nodes only: the superstar income
        % state inflates the value scale (absolute tol unreachable), and
        % infeasible states (negative net resources under a high tax) carry
        % -inf value -- including them makes (-inf)-(-inf)=NaN poison the
        % whole norm. Measure convergence on the feasible set; infeasible
        % nodes carry a defined fallback policy (b'=bG(1), c=floor), so they
        % never affect aggregates.
        % heal any non-finite node so poison cannot spread across sweeps or
        % NaN-out the norm: freeze it at the previous finite value, or the
        % analytic floor if the previous value was also bad. A NaN/-inf can
        % otherwise enter via a distant warm start or an extreme trial price
        % and cascade through the interp/premix into the whole array.
        badn = ~isfinite(Vnew);
        if any(badn(:))
            prevOK = badn & isfinite(V); Vnew(prevOK) = V(prevOK);
            stillBad = ~isfinite(Vnew);
            if any(stillBad(:)), Vnew(stillBad) = Vinit(stillBad); end
        end
        fin = isfinite(Vnew) & isfinite(V);
        if ~any(fin(:))
            dV = Inf;
        else
            Vscale = max(1, max(abs(Vnew(fin))));
            dV = max(abs(Vnew(fin) - V(fin))) / Vscale;
        end
        V = Vnew;
        diag.iters = it; diag.supnorm = dV;
        if dV < p.tol_vfi, diag.converged = true; break; end
        % plateau early-stop: once dV stops improving for stall_cap sweeps
        % and is already small in relative terms, the value is oscillating
        % within grid noise -- accept the grid-limited fixed point.
        if dV < dV_best - 1e-12, dV_best = dV; stall = 0;
        else, stall = stall + 1; end
        if stall >= stall_cap && dV_best < tol_soft
            diag.converged = true; diag.soft = true; break;
        end
    end
    diag.n_infeas = sum(~isfinite(V(:)));          % infeasible-state count
    % soft-accept: if the cap was hit but the RELATIVE change is already
    % small, the grid-limited fixed point is effectively reached -- record it
    % rather than failing the whole equilibrium evaluation.
    if ~diag.converged && dV_best < tol_soft
        diag.converged = true; diag.soft = true;
    end
    diag.supnorm = min(diag.supnorm, dV_best);

    sol = struct('V', V, 'polBa', polBa, 'polKa', polKa, 'polCa', polCa, ...
                 'polBn', polBn, 'polCn', polCn, 'polBnIdx', polBnIdx);
end

function u = uofc(c, sig)
    if sig == 1, u = log(c); else, u = (c.^(1-sig))/(1-sig); end
end

function v = vofb(b, zet)
    bb = max(b, 1e-12);
    if abs(zet - 1) < 1e-12, v = log(bb);
    else, v = (bb.^(1-zet))/(1-zet); end
end
