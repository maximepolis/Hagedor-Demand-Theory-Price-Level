function opt = optimal_policy_green(pg)
% OPTIMAL_POLICY_GREEN  Proposition 5: optimal nominal accommodation of the
% green program. Along a grid of nominal growth rates mu (with i_ss fixed,
% so r_ss = (1+i_ss)/(1+mu) - 1 falls as mu rises), solve the program
% equilibrium and evaluate utilitarian steady-state welfare
%     W(mu) = integral of V dOmega
% at the exact equilibrium. Tradeoff: higher mu erodes the real interest
% burden on concentrated bond wealth (risk-sharing gain, Acharya-Challe-Dogra
% motive) but raises the price level, eroding real green spending (damages and
% risk up) and lowering the return on the buffer asset.
%
% INPUT
%   pg : project params (uses mu_grid, taugrid_mu, Dgrid_mu, Gg_nom, i_ss,
%        Bnom, theta_g).
%
% OUTPUT
%   opt : struct with .mu_grid .W .P .D .tau .r .n_roots .mu_star .W_star
%         and .msg. NaN entries mark grid points with no equilibrium.
%
% NOTE: each mu requires its OWN S(tau,D) interpolant because r_ss changes;
% the per-mu grids are deliberately small (pg.taugrid_mu x pg.Dgrid_mu).

    mus = pg.mu_grid;
    n   = numel(mus);
    opt = struct('mu_grid',mus, 'W',nan(1,n), 'P',nan(1,n), 'D',nan(1,n), ...
                 'tau',nan(1,n), 'r',nan(1,n), 'n_roots',zeros(1,n));

    for k = 1:n
        mu  = mus(k);
        r_k = (1 + pg.i_ss)/(1 + mu) - 1;
        opt.r(k) = r_k;
        fprintf('\n[optimal policy] mu=%.3f (r_ss=%+.4f) ...\n', mu, r_k);
        if pg.beta*(1+r_k) >= pg.betaR_max
            fprintf('  skipped: beta(1+r) out of computable range.\n');
            continue;
        end

        ad2k = build_S_interp_green(r_k, pg, pg.taugrid_mu, pg.Dgrid_mu);
        polk = struct('regime','nominal','i_ss',pg.i_ss,'mu',mu, ...
                      'Bnom',pg.Bnom,'Gg_nom',pg.Gg_nom);
        [eqk, outk] = solve_green_steady_state(pg, polk, ad2k);
        opt.n_roots(k) = outk.n_roots;
        if isempty(eqk), fprintf('  no equilibrium at this mu.\n'); continue; end

        ek = eqk(1);            % green-boom equilibrium if multiple
        opt.W(k)   = ek.W;      % exact welfare from S_green at the root
        opt.P(k)   = ek.P;
        opt.D(k)   = ek.D;
        opt.tau(k) = ek.tau;
        fprintf('  P*=%.4f  D=%.4f  tau=%.4f  W=%.4f\n', ek.P, ek.D, ek.tau, ek.W);
    end

    [Wmax, imax] = max(opt.W);
    if isfinite(Wmax)
        opt.mu_star = mus(imax);
        opt.W_star  = Wmax;
        interior = imax > 1 && imax < n;
        opt.msg = sprintf(['Optimal nominal growth mu* = %.3f (W=%.4f)%s. ' ...
            'Tradeoff: bondholder levy / tax relief vs real-green-spending ' ...
            'erosion (Proposition 5).'], opt.mu_star, Wmax, ...
            ternary(interior, ' [interior]', ' [boundary of grid -- widen mu_grid]'));
    else
        opt.mu_star = NaN; opt.W_star = NaN;
        opt.msg = 'No equilibrium at any mu on the grid.';
        warning('optimal_policy_green:none', '%s', opt.msg);
    end
    fprintf('\n%s\n', opt.msg);
end

% -------------------------------------------------------------------------
function s = ternary(cond, a, b)
    if cond, s = a; else, s = b; end
end
