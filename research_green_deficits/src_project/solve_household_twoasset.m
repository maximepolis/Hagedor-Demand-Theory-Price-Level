function [V, polB, polK, polC, diag] = solve_household_twoasset(rb, q, d, tau, p)
% SOLVE_HOUSEHOLD_TWOASSET  Frictionless two-asset household problem
% (two-asset build plan, Step 0 / variant (a)).
%
% Households hold liquid nominal bonds b (real return rb, liquidity utility
% chi*v(b)) and tree shares k (price q, real dividend d). With frictionless
% within-period rebalancing, beginning-of-period portfolio composition
% matters only through total cash-on-hand
%     x = y(e) - tau + (1+rb) b + (q + d) k,
% so the state is (x, e): the one-dimensional wealth aggregation is EXACT in
% this variant by construction, not an approximation. (What this variant
% cannot produce is wealthy hand-to-mouth households; that requires the
% infrequent-adjustment variant (b) of the build plan.)
%
% PROBLEM
%   V(x,e) = max_{c, b'>=0, k'>=0} u(c) + chi*v(b') + beta E[V(x',e')|e]
%   c = x - b' - q k',   x' = y(e') - tau + (1+rb) b' + (q+d) k'.
%
% INTERIOR FOCs (both assets held):
%   u'(c)   = chi v'(b') + beta (1+rb) E Vx
%   q u'(c) = beta (q+d) E Vx
% which combine to the closed-form liquid demand given consumption:
%   chi v'(b') = u'(c) * sprd,  sprd = 1 - (1+rb) q/(q+d)  (>0 in equilibrium),
% so with v(b) = b^(1-zeta)/(1-zeta):  b'(c) = (chi / (u'(c) sprd))^(1/zeta).
% The solver optimizes over total outlay a = b' + q k' (golden search per
% node) and applies the closed-form split with corner handling (k'=0 when the
% implied b' exceeds a; b'=0 never binds while sprd>0 and chi>0).
%
% INPUTS
%   rb  : real return on the liquid nominal bond (policy-set).
%   q   : tree price (market-clearing unknown).
%   d   : real dividend per share.
%   tau : lump-sum tax (levy handled upstream by scaling p.eGrid).
%   p   : params with .xGrid (cash-on-hand grid), .eGrid, .Pi, .beta,
%         .sigma (CRRA), .chi_b, .zeta_b (liquidity weight / curvature),
%         .tol_vfi, .maxit_vfi.
%
% OUTPUTS
%   V, polB, polK, polC : (nx x ne) value and policies.
%   diag : .converged .iters .supnorm .sprd
%
% STATUS: scaffolded, untested pending a MATLAB run (no MATLAB in the
% authoring environment); wired for main_twoasset_step0.

    nx = numel(p.xGrid); ne = numel(p.eGrid);
    xG = p.xGrid(:);
    up    = @(c) c.^(-p.sigma);
    Ret_b = 1 + rb;  Ret_k = (q + d)/q;
    sprd  = 1 - Ret_b/Ret_k;                               % convenience wedge
    diag  = struct('converged', false, 'iters', 0, 'supnorm', Inf, 'sprd', sprd);
    if sprd <= 0
        % bonds dominated with no convenience compensation: liquid demand
        % explodes at the closed form; signal the caller to raise q.
        V = []; polB = []; polK = []; polC = [];
        diag.msg = 'sprd <= 0: (q+d)/q must exceed 1+rb';
        return;
    end

    % terminal guess: consume everything
    V = repmat(log(max(xG, 1e-8)), 1, ne);
    if p.sigma ~= 1
        V = repmat((max(xG,1e-8).^(1-p.sigma))/(1-p.sigma), 1, ne);
    end
    polB = zeros(nx, ne); polK = zeros(nx, ne); polC = zeros(nx, ne);
    ynet = p.eGrid(:)' - tau;                              % 1 x ne next-period base

    gold = (sqrt(5)-1)/2;
    for it = 1:p.maxit_vfi
        Vn = V;
        for ie = 1:ne
            for ix = 1:nx
                x = xG(ix);
                amax_ = x - 1e-10;                          % leave c > 0
                if amax_ <= 0
                    Vn(ix,ie) = -1e12; polB(ix,ie) = 0; polK(ix,ie) = 0;
                    polC(ix,ie) = max(x, 1e-10);
                    continue;
                end
                % golden search over total outlay a in [0, amax_]
                lo = 0; hi = amax_;
                a1 = hi - gold*(hi-lo); a2 = lo + gold*(hi-lo);
                f1 = obj(a1); f2 = obj(a2);
                for gs = 1:60
                    if hi - lo < 1e-10 * max(1, hi), break; end
                    if f1 < f2
                        lo = a1; a1 = a2; f1 = f2;
                        a2 = lo + gold*(hi-lo); f2 = obj(a2);
                    else
                        hi = a2; a2 = a1; f2 = f1;
                        a1 = hi - gold*(hi-lo); f1 = obj(a1);
                    end
                end
                astar = 0.5*(lo+hi);
                [fstar, bstar, kstar, cstar] = obj(astar);
                % also check the a=0 corner explicitly
                [f0, b0c, k0c, c0c] = obj(0);
                if f0 > fstar
                    astar = 0; fstar = f0; bstar = b0c; kstar = k0c; cstar = c0c; %#ok<NASGU>
                end
                Vn(ix,ie) = fstar; polB(ix,ie) = bstar;
                polK(ix,ie) = kstar; polC(ix,ie) = cstar;
            end
        end
        dV = max(abs(Vn(:) - V(:)));
        V = Vn;
        if dV < p.tol_vfi
            diag.converged = true; diag.iters = it; diag.supnorm = dV;
            break;
        end
        diag.iters = it; diag.supnorm = dV;
    end

    % ---- nested objective: value of total outlay a at node (x, e-loop vars) ----
    function [val, bch, kch, cch] = obj(a)
        cch = x - a;
        if cch <= 0, val = -1e12; bch = 0; kch = 0; cch = 1e-10; return; end
        % closed-form liquid split given c (interior), then corners
        bint = (p.chi_b / (up(cch) * sprd))^(1/p.zeta_b);
        bch  = min(bint, a);                                % k' >= 0 corner
        kch  = (a - bch)/q;
        % continuation: x' per e', interpolate EVe? EV is conditional on
        % CURRENT e (mixing over e'), but x' depends on e', so mix explicitly:
        xp = ynet + Ret_b*bch + (q+d)*kch;                  % 1 x ne (per e')
        EVmix = 0;
        for jep = 1:ne
            EVmix = EVmix + p.Pi(ie, jep) * interp_lin(xG, V(:, jep), xp(jep));
        end
        val = uofc(cch) + p.chi_b * vofb(bch) + p.beta * EVmix;
    end
    function u = uofc(c)
        if p.sigma == 1, u = log(c); else, u = (c^(1-p.sigma))/(1-p.sigma); end
    end
    function v = vofb(b)
        bb = max(b, 1e-12);
        if abs(p.zeta_b - 1) < 1e-12, v = log(bb);
        else, v = (bb^(1-p.zeta_b))/(1-p.zeta_b); end
    end
end

function y = interp_lin(xg, yg, x)
% linear interpolation with linear extrapolation (monotone grid)
    n = numel(xg);
    if x <= xg(1)
        t = (x - xg(1))/(xg(2)-xg(1)); y = yg(1) + t*(yg(2)-yg(1));
    elseif x >= xg(n)
        t = (x - xg(n-1))/(xg(n)-xg(n-1)); y = yg(n-1) + t*(yg(n)-yg(n-1));
    else
        i = find(xg <= x, 1, 'last');
        t = (x - xg(i))/(xg(i+1)-xg(i)); y = yg(i) + t*(yg(i+1)-yg(i));
    end
end
