function [eq, out] = solve_regime_equilibrium(pg, regime, r_ss, Pspan)
% SOLVE_REGIME_EQUILIBRIUM  Exact stationary equilibrium under a general
% financing regime (roadmap U4). Unlike solve_green_steady_state, which runs
% on the (tau, D) interpolant with lump-sum taxes only, this solver evaluates
% S_green EXACTLY at every trial price level and supports a proportional
% levy, so it can price regimes that mix lump-sum, carbon-tax-style, and
% rebate financing.
%
% EQUILIBRIUM CONDITION
%   Phi(P) = S(1+r_ss; tau_ls(P), D(P); vartheta(P)) - B/P = 0,
% where the regime supplies the maps P -> (tau_ls, vartheta, D, g). The
% aggregate government budget must satisfy, at any P,
%   tau_ls(P) + vartheta(P)*(1-D(P)) = r_ss*B/P + g(P),
% which the caller constructs and this function CHECKS at the root.
%
% INPUTS
%   pg     : project params (pg.vartheta is overridden per evaluation).
%   regime : struct with .name and function handles .tau_ls(P), .vartheta(P),
%            .D(P), .g(P), plus .Bnom.
%   r_ss   : real rate of the stance.
%   Pspan  : [Plo, Phi] search interval (coarse scan + bisection inside).
%
% OUTPUTS
%   eq  : struct .P .D .tau_ls .vartheta .g .S .breal .W .gini_a .resid
%         (empty if no sign change on the span).
%   out : .Pscan .Phiscan .n_evals .msg .gbc_resid
%
% COST: each evaluation is a full household solve; the coarse scan uses 7
% points and bisection ~10 more (couple of minutes at na=500, beta~0.93).

    B = regime.Bnom;
    n_evals = 0;

    function [phi, S, Wv, gini] = PhiOf(P)
        pgl = pg;
        pgl.vartheta = regime.vartheta(P);
        [S, o] = S_green(r_ss, regime.tau_ls(P), regime.D(P), pgl);
        n_evals = n_evals + 1;
        if isfinite(S), phi = S - B/P; else, phi = NaN; end
        if nargout > 2, Wv = o.W; gini = o.gini_a; end
    end

    % ---- coarse scan ----
    Pscan = linspace(Pspan(1), Pspan(2), 7);
    Phis  = nan(size(Pscan));
    for k = 1:numel(Pscan), Phis(k) = PhiOf(Pscan(k)); end

    eq = [];
    kx = find(isfinite(Phis(1:end-1)) & isfinite(Phis(2:end)) & ...
              sign(Phis(1:end-1)) ~= sign(Phis(2:end)), 1, 'first');
    if isempty(kx)
        out = pack_out();
        out.msg = sprintf(['regime %s: no sign change on [%g, %g] ' ...
            '(Phi ends: %+.3f / %+.3f) -- existence failure or widen span.'], ...
            regime.name, Pspan(1), Pspan(2), Phis(find(isfinite(Phis),1,'first')), ...
            Phis(find(isfinite(Phis),1,'last')));
        warning('solve_regime_equilibrium:noroot', '%s', out.msg);
        return;
    end

    % ---- bisection ----
    lo = Pscan(kx); hi = Pscan(kx+1);
    flo = Phis(kx);
    for it = 1:12
        mid = 0.5*(lo + hi);
        fm  = PhiOf(mid);
        if ~isfinite(fm), lo = mid; continue; end   % shrink away from NaN edge
        if sign(fm) == sign(flo), lo = mid; flo = fm; else, hi = mid; end
        if (hi - lo) < 5e-4, break; end
    end
    Pstar = 0.5*(lo + hi);
    [phis, Ss, Ws, gini] = PhiOf(Pstar);

    eq = struct();
    eq.P        = Pstar;
    eq.D        = regime.D(Pstar);
    eq.tau_ls   = regime.tau_ls(Pstar);
    eq.vartheta = regime.vartheta(Pstar);
    eq.g        = regime.g(Pstar);
    eq.S        = Ss;
    eq.breal    = B / Pstar;
    eq.W        = Ws;
    eq.gini_a   = gini;
    eq.resid    = phis;
    % interface compatibility with welfare_by_group (expects .tau, .D)
    eq.tau      = eq.tau_ls;

    out = pack_out();
    % government-budget identity check at the root
    out.gbc_resid = (eq.tau_ls + eq.vartheta*(1 - eq.D)) ...
                    - (r_ss*B/Pstar + eq.g);
    out.msg = sprintf(['regime %-12s P*=%.4f  D=%.4f  tau_ls=%+.4f  ' ...
        'vartheta=%.4f  |Phi|=%.1e  gbc=%.1e'], regime.name, Pstar, eq.D, ...
        eq.tau_ls, eq.vartheta, abs(phis), abs(out.gbc_resid));
    if abs(out.gbc_resid) > 1e-8
        warning('solve_regime_equilibrium:gbc', ...
            'Regime %s: government budget identity residual %.2e.', ...
            regime.name, out.gbc_resid);
    end

    function o = pack_out()
        o = struct('Pscan', Pscan, 'Phiscan', Phis, 'n_evals', n_evals, ...
                   'msg', '', 'gbc_resid', NaN);
    end
end
