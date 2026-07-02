function [eqs, out] = solve_green_steady_state(pg, policy, ad2)
% SOLVE_GREEN_STEADY_STATE  Find ALL stationary green equilibria (Definition 1):
% price levels P solving
%     Phi(P) = S(1+r_ss; tau(P), D(P)) - B/P = 0,
% where under the NOMINAL budget regime
%     tau(P) = (r_ss*B + Gg)/P,  D(P) = D0*exp(-theta_g*Gg/(P*delta_g)),
% and under the REAL mandate
%     tau(P) = r_ss*B/P + g_real,  D constant = climate_block(g_real).
%
% INPUTS
%   pg     : project params (theta_g may be overridden via policy.theta_g).
%   policy : struct with fields
%            .regime  'nominal' | 'real'
%            .i_ss, .mu, .Bnom
%            .Gg_nom  (nominal regime)  or  .g_real (real mandate)
%            .theta_g (optional override of pg.theta_g)
%   ad2    : S(tau,D) interpolant from build_S_interp_green at r_ss
%            (must have been built at the SAME r_ss; checked).
%
% OUTPUTS
%   eqs : struct array, one element per equilibrium (ascending P):
%         .P .D .Kg .g_real .tau .S .breal .resid_exact .W .gini_a .gini_y
%         (exact objects re-solved by S_green at the root, not interpolated)
%   out : diagnostics: .Pgrid .Phi .S_curve .BoverP .eps_S .r_ss .msg
%         .n_roots .regime .theta_g
%
% THEORY: Propositions 1 (existence/uniqueness), 3 (multiplicity), 4 (mandate);
% the elasticity diagnostic eps_S(P) is Definition 3, compared to -1.

    theta_g = pg.theta_g;
    if isfield(policy, 'theta_g') && ~isempty(policy.theta_g)
        theta_g = policy.theta_g;
    end
    pgl = pg; pgl.theta_g = theta_g;        % local copy for climate_block

    r_ss = (1 + policy.i_ss)/(1 + policy.mu) - 1;
    if abs(r_ss - ad2.r) > 1e-10
        error('solve_green_steady_state:rate', ...
            'ad2 built at r=%.6f but policy implies r_ss=%.6f.', ad2.r, r_ss);
    end
    B = policy.Bnom;

    % ---- tau(P), D(P) by regime ----
    switch lower(policy.regime)
        case 'nominal'
            Gg     = policy.Gg_nom;
            g_of_P = @(P) Gg ./ P;
        case 'real'
            g_of_P = @(P) policy.g_real + 0*P;
        otherwise
            error('solve_green_steady_state:regime', 'Unknown regime %s.', ...
                  policy.regime);
    end
    % climate version: 1 = reduced form D0*exp(-theta*Kg); 2 = carbon stock
    if isfield(pgl,'climate_version') && pgl.climate_version == 2
        D_of_P = @(P) climate_block2(g_of_P(P), pgl);
    else
        D_of_P = @(P) climate_block(g_of_P(P), pgl);
    end
    tau_of_P = @(P) r_ss * B ./ P + g_of_P(P);

    Phi = @(P) ad2.S_of(tau_of_P(P), D_of_P(P)) - B ./ P;

    % ---- scan + refine all roots ----
    Pgrid = linspace(pg.P_scan_min, pg.P_scan_max, pg.nP_scan);
    Phiv  = arrayfun(Phi, Pgrid);
    roots = [];
    for k = 1:numel(Pgrid)-1
        f1 = Phiv(k); f2 = Phiv(k+1);
        if isfinite(f1) && isfinite(f2) && f1 ~= 0 && sign(f1) ~= sign(f2)
            try
                pr = fzero(Phi, [Pgrid(k), Pgrid(k+1)], ...
                           optimset('TolX', pg.tol_root));
                if isfinite(pr) && pr > 0, roots(end+1,1) = pr; end %#ok<AGROW>
            catch
            end
        elseif isfinite(f1) && f1 == 0
            roots(end+1,1) = Pgrid(k); %#ok<AGROW>
        end
    end
    roots = sort(roots);
    if ~isempty(roots)
        roots = roots([true; diff(roots) > 1e-6]);
    end

    % ---- exact objects at each root (re-solve, do not interpolate) ----
    eqs = struct('P',{},'D',{},'Kg',{},'g_real',{},'tau',{},'S',{}, ...
                 'breal',{},'resid_exact',{},'W',{},'gini_a',{},'gini_y',{});
    for k = 1:numel(roots)
        P = roots(k);
        if isfield(pgl,'climate_version') && pgl.climate_version == 2
            [Dk, Kgk] = climate_block2(g_of_P(P), pgl);
        else
            [Dk, Kgk] = climate_block(g_of_P(P), pgl);
        end
        tk        = tau_of_P(P);
        [Sk, ok]  = S_green(r_ss, tk, Dk, pgl);
        eqs(k).P      = P;
        eqs(k).D      = Dk;
        eqs(k).Kg     = Kgk;
        eqs(k).g_real = g_of_P(P);
        eqs(k).tau    = tk;
        eqs(k).S      = Sk;
        eqs(k).breal  = B / P;
        eqs(k).resid_exact = Sk - B/P;     % interpolation error diagnostic
        eqs(k).W      = ok.W;
        eqs(k).gini_a = ok.gini_a;
        eqs(k).gini_y = ok.gini_y;
    end

    % ---- demand-elasticity diagnostic eps_S(P) (Definition 3) ----
    Scurve = Phiv + B ./ Pgrid;
    eps_S  = nan(size(Pgrid));
    lnP = log(Pgrid); lnS = log(Scurve);
    for k = 2:numel(Pgrid)-1
        if all(isfinite(lnS(k-1:k+1)))
            eps_S(k) = (lnS(k+1) - lnS(k-1)) / (lnP(k+1) - lnP(k-1));
        end
    end

    out = struct();
    out.Pgrid  = Pgrid;
    out.Phi    = Phiv;
    out.S_curve = Scurve;
    out.BoverP = B ./ Pgrid;
    out.eps_S  = eps_S;
    out.r_ss   = r_ss;
    out.regime = policy.regime;
    out.theta_g = theta_g;
    out.n_roots = numel(eqs);
    if isempty(eqs)
        out.msg = sprintf('%s regime, theta_g=%.2f: NO equilibrium on scan range.', ...
                          policy.regime, theta_g);
        warning('solve_green_steady_state:noroot', '%s', out.msg);
    elseif numel(eqs) == 1
        out.msg = sprintf('%s regime, theta_g=%.2f: UNIQUE P*=%.4f (D=%.3f).', ...
                          policy.regime, theta_g, eqs(1).P, eqs(1).D);
    else
        out.msg = sprintf(['%s regime, theta_g=%.2f: MULTIPLE equilibria P* = %s ' ...
                          '(climate sunspots, Proposition 3).'], policy.regime, ...
                          theta_g, mat2str([eqs.P], 4));
    end
end
