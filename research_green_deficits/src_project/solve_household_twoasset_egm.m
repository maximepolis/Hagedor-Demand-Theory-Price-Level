function [polB, polK, polC, C, V, diag] = solve_household_twoasset_egm(rb, q, d, tau, p, C0)
% SOLVE_HOUSEHOLD_TWOASSET_EGM  Endogenous-grid solver for the frictionless
% two-asset household (two-asset build plan, Step 0) -- the fast default.
%
% Same economy as solve_household_twoasset (state (x,e), liquid bond b with
% convenience utility chi*v(b), tree k at price q, frictionless rebalancing),
% solved on consumption policies rather than values. Interior optimality:
%
%   k-FOC (k'>0):  u'(c) = beta * Rk * E[u'(c'(x'))],  Rk = (q+d)/q,
%   split (k'>0):  chi v'(b') = u'(c) * sprd,          sprd = 1 - Rb/Rk,
%   b-FOC (k'=0):  u'(c) = chi v'(b') + beta * Rb * E[u'(c'(x'))], b' = a,
%
% with a = b' + q k' the total outlay and x' = y(e') - tau + Rb b' + Rk (a q
% k')/q = y(e') - tau + Rk a - (Rk - Rb) b'. The EGM iterates on c(x,e) over
% an exogenous a-grid: per (a,e) node an inner damped fixed point on b'
% (fast: the b' feedback into x' is second-order), then the endogenous grid
% x = c + a. Nodes whose unconstrained liquid demand reaches a are recomputed
% on the k'=0 branch, where the b-FOC gives c in closed form (no inner loop).
% Because v'(0) = +inf (zeta >= 1), b' > 0 and a > 0 always: there is no
% zero-saving corner, and the lowest a-node anchors the constrained region.
%
% This solves the exact joint FOCs, unlike the VFI's within-search split
% substitution (which is exact only at the optimum); the two are
% cross-validated by the driver's self-test.
%
% INPUTS  rb, q, d, tau, p : as in solve_household_twoasset; p additionally
%           uses .aGrid2 (exogenous total-outlay grid; built by the driver),
%           .tol_pol (policy sup-norm tol), .maxit_pol.
%         C0 : optional (nx x ne) warm-start consumption policy ([] = none).
% OUTPUTS polB, polK, polC : (nx x ne) policies on p.xGrid.
%         C    : converged consumption policy (pass back as next C0).
%         V    : values on p.xGrid, computed ONLY if p.compute_V = true
%                ([] otherwise -- the evaluation costs as much as the policy
%                iteration and no equilibrium loop needs it).
%         diag : .converged .iters .supnorm .sprd .neg_spread
%
% STATUS: scaffolded, untested pending a MATLAB run.

    nx = numel(p.xGrid); ne = numel(p.eGrid);
    xG = p.xGrid(:); aG = p.aGrid2(:); na = numel(aG);
    Rb = 1 + rb; Rk = (q + d)/q; sprd = 1 - Rb/Rk;
    diag = struct('converged', false, 'iters', 0, 'supnorm', Inf, ...
                  'sprd', sprd, 'neg_spread', sprd <= 0);
    polB = []; polK = []; polC = []; V = [];
    if sprd <= 0, C = []; return; end

    sig = p.sigma; zet = p.zeta_b; chi = p.chi_b;
    up    = @(c) c.^(-sig);
    upinv = @(m) m.^(-1/sig);
    ynet  = p.eGrid(:)' - tau;                        % 1 x ne (next period)

    % initial consumption guess: consume a fixed fraction of cash-on-hand
    if nargin >= 6 && ~isempty(C0) && isequal(size(C0), [nx ne])
        C = C0;
    else
        C = 0.35 * repmat(max(xG, 1e-6), 1, ne);
    end
    Bsplit = repmat(min(aG, 1), 1, ne);               % b' cache per (a,e)

    for it = 1:p.maxit_pol
        Cn = zeros(na, ne); Bn = zeros(na, ne); Xn = zeros(na, ne);
        for ie = 1:ne
            b = Bsplit(:, ie);                        % na x 1 warm start
            % ---- branch K: interior k' (inner fixed point on b') ----
            % Loose inner tolerance: the b' feedback into x' is second-order
            % and b is warm-started across sweeps, so 1-3 iterations suffice
            % once the policy settles; the OUTER policy iteration drives the
            % final accuracy. (Tight 1e-9 here just burned interp1 calls.)
            cK = []; %#ok<NASGU>
            for inner = 1:20
                % x'(a, e') and marginal continuation under the k-FOC
                Emu = zeros(na, 1);
                for jep = 1:ne
                    xp = ynet(jep) + Rk*aG - (Rk - Rb)*b;
                    cp = interp1(xG, C(:, jep), xp, 'linear', 'extrap');
                    cp = max(cp, 1e-10);
                    Emu = Emu + p.Pi(ie, jep) * up(cp);
                end
                cK   = upinv(p.beta * Rk * Emu);
                bnew = (chi ./ (up(cK) * sprd)).^(1/zet);
                bnew = min(bnew, aG);
                dif  = max(abs(bnew - b));
                b    = 0.5*b + 0.5*bnew;
                if dif < 1e-7, break; end
            end
            % ---- branch B: k' = 0 where liquid demand hits the outlay ----
            % on those nodes b' = a and the b-FOC prices consumption directly
            atB = (chi ./ (up(cK) * sprd)).^(1/zet) >= aG - 1e-12;
            if any(atB)
                EmuB = zeros(na, 1);
                for jep = 1:ne
                    xpB = ynet(jep) + Rb*aG;          % b'=a, k'=0
                    cpB = interp1(xG, C(:, jep), xpB, 'linear', 'extrap');
                    cpB = max(cpB, 1e-10);
                    EmuB = EmuB + p.Pi(ie, jep) * up(cpB);
                end
                vpa_ = max(aG, 1e-12).^(-zet);        % v'(a)
                cB   = upinv(chi * vpa_ + p.beta * Rb * EmuB);
                cK(atB) = cB(atB);
                b(atB)  = aG(atB);
            end
            Cn(:, ie) = cK; Bn(:, ie) = b; Xn(:, ie) = cK + aG;
        end
        Bsplit = Bn;
        % ---- map back to the exogenous x-grid ----
        Cx = zeros(nx, ne);
        for ie = 1:ne
            [xs, ord] = sort(Xn(:, ie)); cs = Cn(ord, ie);
            % strictly increasing guard for interp1
            for i2 = 2:na
                if xs(i2) <= xs(i2-1), xs(i2) = xs(i2-1) + 1e-12; end
            end
            Cx(:, ie) = interp1(xs, cs, xG, 'linear', 'extrap');
            % below the lowest endogenous node: scale consumption down
            % proportionally (a>0 always; the node anchors the bottom)
            lowmask = xG < xs(1);
            if any(lowmask)
                Cx(lowmask, ie) = cs(1) * max(xG(lowmask), 1e-10) / xs(1);
            end
            Cx(:, ie) = min(max(Cx(:, ie), 1e-10), xG - 1e-10);
        end
        dC = max(abs(Cx(:) - C(:)) ./ (1 + abs(C(:))));
        C  = Cx;
        diag.iters = it; diag.supnorm = dC;
        if dC < p.tol_pol, diag.converged = true; break; end
    end

    % ---- policies on the x-grid ----
    polC = C;
    Atot = repmat(xG, 1, ne) - C;                     % total outlay a(x,e)
    Atot = max(Atot, 1e-12);
    polB = zeros(nx, ne);
    for ie = 1:ne
        % liquid split at the converged consumption (same two-branch rule)
        bint = (chi ./ (up(C(:, ie)) * sprd)).^(1/zet);
        polB(:, ie) = min(bint, Atot(:, ie));
    end
    polK = (Atot - polB) / q;

    % ---- policy evaluation for V (OPT-IN: set p.compute_V = true) ----
    % No equilibrium loop needs V (only welfare exercises do), and this
    % evaluation costs as much as the policy iteration itself, so it is
    % skipped unless explicitly requested.
    if ~(isfield(p, 'compute_V') && p.compute_V)
        V = [];
        return;
    end
    flowu = zeros(nx, ne);
    for ie = 1:ne
        cc = C(:, ie); bb = max(polB(:, ie), 1e-12);
        if sig == 1, uu = log(cc); else, uu = (cc.^(1-sig))/(1-sig); end
        if abs(zet - 1) < 1e-12, vv = log(bb);
        else, vv = (bb.^(1-zet))/(1-zet); end
        flowu(:, ie) = uu + chi * vv;
    end
    V = flowu / max(1e-10, 1 - p.beta);               % level guess
    for itv = 1:2000
        Vn = flowu;
        for ie = 1:ne
            cont = zeros(nx, 1);
            for jep = 1:ne
                xp = ynet(jep) + Rb*polB(:, ie) + (q + d)*polK(:, ie);
                cont = cont + p.Pi(ie, jep) * ...
                       interp1(xG, V(:, jep), xp, 'linear', 'extrap');
            end
            Vn(:, ie) = Vn(:, ie) + p.beta * cont;
        end
        dV = max(abs(Vn(:) - V(:)));
        V = Vn;
        if dV < 1e-8 * max(1, max(abs(V(:)))), break; end
    end
end
