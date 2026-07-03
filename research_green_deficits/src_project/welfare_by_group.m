function wg = welfare_by_group(r, eq0, eq1, pg)
% WELFARE_BY_GROUP  Consumption-equivalent welfare incidence of the green
% program by wealth group (roadmap U2; paper Section "Welfare incidence").
%
% For each state (a,e), the permanent consumption transfer lambda(a,e) that
% makes a household at that state indifferent between the no-program steady
% state (eq0) and the program steady state (eq1):
%   CRRA sigma ~= 1:  Vtil = V - 1/((1-sigma)(1-beta))   (strip the "-1" term)
%                     lambda = (Vtil1/Vtil0)^(1/(1-sigma)) - 1
%   sigma == 1 (log): lambda = exp((V1 - V0)(1-beta)) - 1
% Group aggregation over the BASELINE invariant distribution: quintiles of
% baseline wealth, plus the top-10% / bottom-50% split. The state-by-state
% comparison asks "how much does a household currently at (a,e) gain?" --
% the standard steady-state incidence object; transition paths are a
% separate (dynamic) exercise.
%
% INPUTS
%   r        : real rate of the policy stance.
%   eq0, eq1 : equilibrium structs with fields .tau and .D (from
%              solve_green_steady_state / self_financing_decomposition).
%   pg       : project params (climate/incidence fields respected via S_green).
%
% OUTPUT
%   wg : struct with .lambda_q (1x5, quintile CE gains), .lambda_top10,
%        .lambda_bot50, .lambda_agg (baseline-weighted mean), .qcut (asset
%        cutoffs), .ok, .msg.
%
% STATUS: IMPLEMENTED (machinery); numbers are results only once run.

    wg = struct('ok', false, 'msg', '');

    % exact household solutions at the two steady states
    [~, o0] = S_green(r, eq0.tau, eq0.D, pg);
    [~, o1] = S_green(r, eq1.tau, eq1.D, pg);
    if ~o0.feasible || ~o1.feasible
        wg.msg = 'welfare_by_group: one of the steady states infeasible.';
        warning('welfare_by_group:infeasible', '%s', wg.msg);
        return;
    end
    V0 = o0.V; V1 = o1.V; dist0 = o0.dist;

    % consumption-equivalent lambda(a,e)
    if abs(pg.sigma - 1) < 1e-12
        lam = exp((V1 - V0) * (1 - pg.beta)) - 1;
    else
        cshift = 1 / ((1 - pg.sigma) * (1 - pg.beta));
        Vt0 = V0 - cshift;
        Vt1 = V1 - cshift;
        % for sigma > 1 both Vt are negative; ratio positive
        lam = (Vt1 ./ Vt0).^(1/(1 - pg.sigma)) - 1;
    end

    % baseline wealth quintiles (marginal over assets)
    wa   = sum(dist0, 2);                       % na x 1
    cwa  = cumsum(wa) / sum(wa);
    aGrid = pg.aGrid(:);
    qcut = zeros(1, 4);
    for q = 1:4
        idx = find(cwa >= q/5, 1, 'first');
        qcut(q) = aGrid(idx);
    end

    lambda_q = nan(1, 5);
    edges = [-inf, qcut, inf];
    for q = 1:5
        sel = aGrid > edges(q) & aGrid <= edges(q+1);
        w   = dist0(sel, :);
        if sum(w(:)) > 0
            lambda_q(q) = sum(sum(lam(sel, :) .* w)) / sum(w(:));
        end
    end

    % top-10% / bottom-50%
    i90 = find(cwa >= 0.90, 1, 'first');
    i50 = find(cwa >= 0.50, 1, 'first');
    selT = false(size(aGrid)); selT(i90:end) = true;
    selB = false(size(aGrid)); selB(1:i50)   = true;
    wT = dist0(selT, :); wB = dist0(selB, :);
    lambda_top10 = sum(sum(lam(selT, :) .* wT)) / sum(wT(:));
    lambda_bot50 = sum(sum(lam(selB, :) .* wB)) / sum(wB(:));

    wg.ok = true;
    wg.lambda_q     = lambda_q;
    wg.lambda_top10 = lambda_top10;
    wg.lambda_bot50 = lambda_bot50;
    wg.lambda_agg   = sum(sum(lam .* dist0));
    wg.qcut         = qcut;
    wg.msg = sprintf(['CE gains by wealth quintile (%%): %s | top10 %.2f, ' ...
        'bottom50 %.2f, aggregate %.2f'], ...
        mat2str(round(100*lambda_q, 2)), 100*lambda_top10, ...
        100*lambda_bot50, 100*wg.lambda_agg);
end
