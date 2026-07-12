function TR = solve_dtpl_aggrisk(pg, Dvec, opts)
% SOLVE_DTPL_AGGRISK  Two-regime DTPL with aggregate climate risk (Stage A;
% appendix/AGGREGATE_RISK_PLAN.md). Finds the state-contingent price levels
% P = (P_1,...,P_ns) that clear the nominal-bond market in EVERY aggregate
% climate state,
%       S_s(P) = B / P_s,     s = 1..ns,
% where S_s is aggregate real bond demand of households currently in state s,
% read off the ergodic joint distribution over (a,e,s). The nominal bond is
% nominally safe but really risky: 1 + r(s->s') = (1+i) P_s / P_{s'}.
%
% This is a STATIONARY RECURRENT equilibrium with prices measurable in the
% current aggregate state; the within-state asset distribution is the ergodic
% state-conditional distribution -- exact as aggregate-state persistence -> 1,
% the natural first-pass analog of the deterministic steady state (labeled
% STOCHASTIC AGGREGATE RISK).
%
% INPUTS
%   pg    : project params (must carry pg.Pi_agg (ns x ns), pg.eGrid, pg.Pi,
%           pg.stationary_e, pg.aGrid, pg.beta, pg.sigma, pg.abar, tols).
%   Dvec  : 1 x ns no-abatement-vs-abated damage LEVELS per state (already the
%           post-program D_s; the caller sets these via the climate block).
%   opts  : optional .i_nom (default pg.i_ss), .Bnom (default pg.Bnom),
%           .xi (0.3 damping), .maxit (100), .tol (2e-3), .P0 (init),
%           .verbose (true).
% OUTPUT TR: .P (1 x ns), .S, .R (ns x ns), .tau, .mu, .converged, .iters,
%   .price_disp (max_s P_s / min_s P_s - 1), .r_disaster (worst realized real
%   return from the calm state), .Er_bond (ergodic expected real return),
%   .premium (Er_bond - i_nom, the excess of the bond's expected real return
%   over the nominal-rate benchmark), .msg.

    if nargin < 3, opts = struct(); end
    i_nom = getf(opts,'i_nom', pg.i_ss);
    B     = getf(opts,'Bnom',  pg.Bnom);
    xi    = getf(opts,'xi',    0.3);
    maxit = getf(opts,'maxit', 100);
    tol   = getf(opts,'tol',   2e-3);
    verb  = getf(opts,'verbose', true);
    g_g   = getf(opts,'g_g',   0);   % real green spending in the budget
                                     % (Stage B: the program is financed each
                                     % period, tau_s = r^ss b_s + g_g, so the
                                     % self-financing decomposition is well
                                     % posed; g_g = 0 recovers the Stage-A
                                     % pure damages comparative static)
    ns    = numel(Dvec);
    P     = getf(opts,'P0', (B / 1.2) * ones(1, ns));   % sensible start

    TR = struct('converged', false, 'msg', '');
    rbar = (1 + i_nom)/(1 + pg.mu) - 1;                 % real service rate

    S = nan(1,ns); R = []; mu = []; tau = nan(1,ns); it = 0;
    for it = 1:maxit
        % government budget each state: real interest service on the
        % state-contingent real debt b_s = B/P_s, plus the (real) green
        % program spending g_g (lump-sum financed; regime R1 analog)
        tau = rbar * (B ./ P) + g_g;
        [V, apol, R, hd] = solve_household_vfi_agg(P, Dvec, tau, pg, rbar);
        if ~hd.converged, TR.msg = 'agg VFI did not converge'; return; end
        [mu, dd] = stat_dist_agg(apol, R, pg);
        if ~dd.converged, TR.msg = 'agg distribution did not converge'; return; end
        % state-conditional aggregate real demand S_s = E[a'|s]
        for s = 1:ns
            ms = sum(sum(mu(:,:,s)));
            aae = pg.aGrid(apol(:,:,s));            % na x ne chosen savings
            S(s) = sum(sum(aae .* mu(:,:,s))) / max(ms, 1e-12);
        end
        resid  = (S - B./P);
        relerr = max(abs(resid) ./ (B./P));
        if verb
            fprintf('  it %2d: P=[%s] S=[%s] rel.resid=%.4f\n', it, ...
                num2str(P,'%.4f '), num2str(S,'%.4f '), relerr);
        end
        if relerr < tol, TR.converged = true; break; end
        upd = ((B./P) ./ S) .^ xi;                  % move P toward B/S
        upd = min(max(upd, 0.8), 1.2);              % trust region
        P   = P .* upd;
    end

    % ---- pack + safe-asset-risk diagnostics ----
    TR.P = P; TR.S = S; TR.R = R; TR.tau = tau; TR.mu = mu; TR.iters = it;
    TR.V = V; TR.apol = apol; TR.g_g = g_g; TR.Dvec = Dvec(:).';
    TR.price_disp = max(P)/min(P) - 1;              % state price dispersion
    % ergodic expected real return of the bond and the disaster return
    piagg = stat_of(pg.Pi_agg);                     % ergodic aggregate marginal
    Er = 0;
    for s = 1:ns
        for sp = 1:ns
            Er = Er + piagg(s) * pg.Pi_agg(s,sp) * (R(s,sp) - 1);
        end
    end
    TR.Er_bond  = Er;                               % expected net real return
    TR.rbar     = rbar;                             % deterministic real rate
    TR.premium  = Er - rbar;    % bond's expected excess real return over the
                                % deterministic real rate: >0 = climate-risk
                                % premium (households need compensation to hold
                                % an asset that loses value in the Severe state)
    [~, sC] = min(Dvec);                            % calm = lowest-damage state
    TR.r_disaster = min(R(sC,:)) - 1;               % worst real return from calm
    TR.msg = sprintf(['aggrisk %s in %d iters: P=[%s], price disp %.3f, ' ...
        'disaster real return %+.3f, premium %+.4f'], ...
        ternstr(TR.converged,'CONVERGED','NOT CONVERGED'), it, ...
        num2str(P,'%.4f '), TR.price_disp, TR.r_disaster, TR.premium);
end

% ---- helpers ----
function v = getf(o, f, d)
    if isfield(o, f) && ~isempty(o.(f)), v = o.(f); else, v = d; end
end
function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
function d = stat_of(Pmat)
    [V, Dg] = eig(Pmat');
    [~, k]  = min(abs(diag(Dg) - 1));
    d = real(V(:,k));  d = d / sum(d);  d = d(:)';
end
