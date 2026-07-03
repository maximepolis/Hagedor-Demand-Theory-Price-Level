function wx = welfare_groups_extended(r, eq0, eq1, pg)
% WELFARE_GROUPS_EXTENDED  Consumption-equivalent welfare incidence of the
% green program by EXTENDED household groups (editorial-roadmap Step 5;
% complements welfare_by_group's wealth quintiles / top10 / bottom50).
%
% Groups reported (all cut on the BASELINE eq0 invariant distribution):
%   1. wealth quintiles              (= BONDHOLDING quintiles: in this
%      one-asset economy the only asset IS the government bond, so wealth
%      and bond positions coincide -- stated, not hidden)
%   2. income-state quintiles        (quintiles of the stationary marginal
%      over endowment states; 7 states => cuts are approximate, weights
%      handled exactly by splitting boundary states)
%   3. constrained vs unconstrained  (mass at the borrowing limit a = -abar)
%   4. high-MPC proxy                (top quartile of dC/dA measured from
%      the baseline consumption policy by forward differences on the asset
%      grid -- a PROXY for the windfall-MPC, labeled as such)
%   5. climate-exposure terciles     (exposure chi(e) = e^(-psi)/E[e^(1-psi)]
%      is monotone DECREASING in e, so exposure terciles are income terciles
%      reversed; ACTIVE only when pg.psi_inc > 0, else reported as inactive)
%
% CE transform identical to welfare_by_group (incl. the sigma>1 validity
% guard). Same interface: eq structs need .tau and .D (+ optional .vartheta).
%
% STATUS: machinery IMPLEMENTED; numbers are results only once run.

    wx = struct('ok', false, 'msg', '');

    pg0 = pg; pg1 = pg;
    if isfield(eq0, 'vartheta'), pg0.vartheta = eq0.vartheta; else, pg0.vartheta = 0; end
    if isfield(eq1, 'vartheta'), pg1.vartheta = eq1.vartheta; else, pg1.vartheta = 0; end
    [~, o0] = S_green(r, eq0.tau, eq0.D, pg0);
    [~, o1] = S_green(r, eq1.tau, eq1.D, pg1);
    if ~o0.feasible || ~o1.feasible
        wx.msg = 'welfare_groups_extended: a steady state is infeasible.';
        warning('welfare_groups_extended:infeasible', '%s', wx.msg);
        return;
    end
    V0 = o0.V; V1 = o1.V; dist0 = o0.dist;

    % ---- CE transform (same as welfare_by_group, incl. validity guard) ----
    if abs(pg.sigma - 1) < 1e-12
        lam = exp((V1 - V0) * (1 - pg.beta)) - 1;
    else
        cshift = 1 / ((1 - pg.sigma) * (1 - pg.beta));
        Vt0 = V0 + cshift; Vt1 = V1 + cshift;
        if pg.sigma > 1 && (max(Vt0(:)) >= 0 || max(Vt1(:)) >= 0)
            wx.msg = 'welfare_groups_extended: CE transform invalid (sigma>1, tilde-V >= 0).';
            warning('welfare_groups_extended:transform', '%s', wx.msg);
            return;
        end
        lam = (Vt1 ./ Vt0).^(1/(1 - pg.sigma)) - 1;
    end

    [na, ne] = size(dist0);
    aGrid = pg.aGrid(:);
    gmean = @(mask) sum(lam(mask) .* dist0(mask)) / max(sum(dist0(mask)), eps);

    % ---- 1. wealth (= bondholding) quintiles ----
    wa  = sum(dist0, 2); cwa = cumsum(wa) / sum(wa);
    lambda_wealth_q = nan(1,5);
    prev = 0;
    for q = 1:5
        hi = find(cwa >= q/5, 1, 'first'); if isempty(hi), hi = na; end
        mask = false(na, ne); mask(prev+1:hi, :) = true;
        lambda_wealth_q(q) = gmean(mask);
        prev = hi;
    end

    % ---- 2. income-state quintiles (stationary marginal over e) ----
    we  = sum(dist0, 1)'; cwe = cumsum(we) / sum(we);
    lambda_income_q = nan(1,5);
    prev = 0;
    for q = 1:5
        hi = find(cwe >= q/5 - 1e-12, 1, 'first'); if isempty(hi), hi = ne; end
        mask = false(na, ne); mask(:, prev+1:hi) = true;
        if hi > prev, lambda_income_q(q) = gmean(mask); end
        prev = max(prev, hi);
    end

    % ---- 3. constrained vs unconstrained ----
    maskC = false(na, ne); maskC(1, :) = true;      % at the borrowing limit
    lambda_constrained   = gmean(maskC);
    lambda_unconstrained = gmean(~maskC);
    share_constrained    = sum(dist0(1, :));

    % ---- 4. high-MPC proxy: top quartile of dC/dA (baseline policy) ----
    lambda_mpc = struct('hi', NaN, 'lo', NaN, 'thresh', NaN);
    if isfield(o0, 'polC') && ~isempty(o0.polC)
        dC = diff(o0.polC, 1, 1); dA = diff(aGrid);
        mpc = [dC ./ dA; dC(end, :) ./ dA(end)];    % na x ne, forward diff
        w   = dist0(:); [ms, ix] = sort(mpc(:), 'descend');
        cw  = cumsum(w(ix)) / sum(w);
        kq  = find(cw >= 0.25, 1, 'first');
        thr = ms(kq);
        maskM = mpc >= thr;
        lambda_mpc.hi = gmean(maskM);
        lambda_mpc.lo = gmean(~maskM);
        lambda_mpc.thresh = thr;
    end

    % ---- 5. climate-exposure terciles (active iff psi_inc > 0) ----
    psi = 0;
    if isfield(pg, 'psi_inc') && ~isempty(pg.psi_inc), psi = pg.psi_inc; end
    lambda_exposure = struct('active', psi > 0, 'hi', NaN, 'mid', NaN, 'lo', NaN);
    if psi > 0
        % chi(e) decreasing in e => high exposure = low-e states
        cuts = [1/3, 2/3, 1];
        prev = 0; vals = nan(1,3);
        for t = 1:3
            hi = find(cwe >= cuts(t) - 1e-12, 1, 'first'); if isempty(hi), hi = ne; end
            mask = false(na, ne); mask(:, prev+1:hi) = true;
            if hi > prev, vals(t) = gmean(mask); end
            prev = max(prev, hi);
        end
        lambda_exposure.hi = vals(1);   % lowest e = highest chi
        lambda_exposure.mid = vals(2);
        lambda_exposure.lo = vals(3);
    end

    wx.ok = true;
    wx.lambda_wealth_q   = lambda_wealth_q;    % = bondholding quintiles
    wx.lambda_income_q   = lambda_income_q;
    wx.lambda_constrained = lambda_constrained;
    wx.lambda_unconstrained = lambda_unconstrained;
    wx.share_constrained = share_constrained;
    wx.lambda_mpc        = lambda_mpc;
    wx.lambda_exposure   = lambda_exposure;
    wx.lambda_agg        = sum(sum(lam .* dist0));
    wx.msg = sprintf(['agg %+.2f%% | wealth-q(%%) %s | income-q(%%) %s | ' ...
        'constrained %+.2f%% (mass %.1f%%) vs unconstrained %+.2f%% | ' ...
        'high-MPC %+.2f%% vs rest %+.2f%%'], 100*wx.lambda_agg, ...
        mat2str(round(100*lambda_wealth_q, 2)), ...
        mat2str(round(100*lambda_income_q, 2)), ...
        100*lambda_constrained, 100*share_constrained, ...
        100*lambda_unconstrained, 100*lambda_mpc.hi, 100*lambda_mpc.lo);
end
