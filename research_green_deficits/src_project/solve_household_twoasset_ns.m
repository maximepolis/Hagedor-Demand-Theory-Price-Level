function [polB, polK, polC, V, diag] = solve_household_twoasset_ns(rb, q, d, tau, p, V0)
% SOLVE_HOUSEHOLD_TWOASSET_NS  Frictionless two-asset household with a
% NON-SEPARABLE liquidity aggregator (two-asset build plan, specification
% fork). This is the test of whether the one-asset lump-sum DISINFLATION
% survives once liquidity services are complementary to consumption rather
% than additively separable.
%
% Preferences: a CES bundle of consumption c and liquid balances b' feeds a
% CRRA felicity,
%   G(c,b) = [ (1-chi) c^rho + chi b^rho ]^(1/rho),  rho = 1 - 1/xi,
%   U(c,b) = G(c,b)^(1-sigma) / (1-sigma),
% with xi the elasticity of substitution between consumption and liquidity.
% xi -> inf recovers (near-)separability; xi < 1 makes c and b COMPLEMENTS,
% so a tax hike that raises the marginal utility of consumption now RAISES
% desired liquidity rather than lowering it -- the channel that can restore
% the lump-sum disinflation sign the separable model overturns.
%
% Non-separability couples the two first-order conditions, so there is no
% closed-form liquid split; we solve by a vectorized DISCRETE choice over a
% candidate grid of (total outlay a, liquid share s). As in the KV solver,
% the candidate portfolio (b',k') and its continuation value do NOT depend on
% the household's own cash-on-hand x, so the continuation is computed once per
% (e, sweep) and the per-x maximization is one matrix operation.
%
% Frictionless rebalancing => the state is cash-on-hand x = y - tau +
% (1+rb) b + (q+d) k, one-dimensional per income state e.
%
% INPUTS  rb,q,d,tau : prices/taxes. p uses .xGrid (cash-on-hand), .acGrid
%           (outlay candidates), .sGrid (share candidates), .eGrid/.Pi,
%           .beta, .sigma, .chi_b (liquidity weight), .xi_liq (subst. elast.),
%           .tol_vfi, .maxit_vfi. V0 optional (nx x ne) warm start.
% OUTPUT  polB,polK,polC (nx x ne on xGrid), V, diag.
%
% STATUS: scaffolded, untested pending a MATLAB run.

    xG = p.xGrid(:); aC = p.acGrid(:); sS = p.sGrid(:)';
    nx = numel(xG); nac = numel(aC); ns = numel(sS); ne = numel(p.eGrid);
    sig = p.sigma; chi = p.chi_b; xi = p.xi_liq;
    rho = 1 - 1/xi;                                  % CES exponent
    Rb = 1 + rb; Rk = q + d;
    ynet = p.eGrid(:)' - tau;
    diag = struct('converged', false, 'iters', 0, 'supnorm', Inf);

    % candidate portfolios (common across states)
    Bc = aC * sS; Kc = (aC * (1 - sS)) / q;         % nac x ns
    Bcl = min(max(Bc(:), 1e-10), Inf);
    bcand = Bcl;                                     % (nac*ns) x 1 liquid held
    % next-period cash-on-hand per candidate and per e' (nac*ns x ne)
    Xp = zeros(nac*ns, ne);
    for jep = 1:ne
        Xp(:, jep) = ynet(jep) + Rb*Bc(:) + Rk*Kc(:);
    end

    V = zeros(nx, ne);
    for ie = 1:ne
        V(:, ie) = ufun(max(xG*0.5,1e-6), max(xG*0.1,1e-8), rho, chi, sig) / (1 - p.beta);
    end
    if nargin >= 6 && ~isempty(V0) && isequal(size(V0),[nx ne]), V = V0; end

    polB = zeros(nx, ne); polK = zeros(nx, ne); polC = zeros(nx, ne);
    aMat = repmat(aC', nx, 1);                       % nx x nac (share-collapsed later)

    for it = 1:p.maxit_vfi
        Vnew = zeros(nx, ne);
        for ie = 1:ne
            % continuation value per candidate: E_e' V(x'(cand,e'))
            EVc = zeros(nac*ns, 1);
            for jep = 1:ne
                xp = min(max(Xp(:, jep), xG(1)), xG(end));
                EVc = EVc + p.Pi(ie, jep) * interp1(xG, V(:, jep), xp, 'linear');
            end
            % flow: U(c, b') with c = x - a(cand); vectorize over x and cand
            Wcont = reshape(EVc, nac, ns);           % continuation by (a,s)
            bMatc = reshape(bcand, nac, ns);
            % for each x, pick best (a,s). Loop over share (small ns), keep a
            % matrix max over outlay a; track argmax.
            bestV = -inf(nx, 1); bestA = ones(nx,1); bestS = ones(nx,1);
            cmat = repmat(xG, 1, nac) - repmat(aC', nx, 1);        % nx x nac
            feas = cmat > 1e-10;
            for js = 1:ns
                bmat = repmat(bMatc(:, js)', nx, 1);               % nx x nac
                Um = ufun(cmat, bmat, rho, chi, sig);             % elementwise
                Um(~feas) = -inf;
                cand = Um + repmat(p.beta*Wcont(:, js)', nx, 1);
                [vs, ia] = max(cand, [], 2);
                upd = vs > bestV;
                bestV(upd) = vs(upd); bestA(upd) = ia(upd); bestS(upd) = js;
            end
            Vnew(:, ie) = bestV;
            polC(:, ie)  = max(xG - aC(bestA), 1e-10);
            sChosen = sS(bestS)';
            polB(:, ie)  = aC(bestA) .* sChosen;
            polK(:, ie)  = aC(bestA) .* (1 - sChosen) / q;
        end
        % RELATIVE sup-norm over finite nodes -- future-proofs the solver for
        % a superstar income state (which inflates the value scale) and for
        % infeasible states carrying -inf (which would NaN-poison an absolute
        % or unmasked norm). Behaviourally identical at the current
        % non-superstar calibration up to the value scale.
        fin = isfinite(Vnew) & isfinite(V);
        if ~any(fin(:)), dV = Inf;
        else, dV = max(abs(Vnew(fin) - V(fin))) / max(1, max(abs(Vnew(fin)))); end
        V = Vnew;
        diag.iters = it; diag.supnorm = dV;
        if dV < p.tol_vfi, diag.converged = true; break; end
    end
end

function u = ufun(c, b, rho, chi, sig)
% CRRA over a CES(c,b) bundle
    cc = max(c, 1e-12); bb = max(b, 1e-12);
    G = ((1-chi)*cc.^rho + chi*bb.^rho).^(1/rho);
    if abs(sig - 1) < 1e-12
        u = log(G);
    else
        u = (G.^(1-sig))/(1-sig);
    end
end
