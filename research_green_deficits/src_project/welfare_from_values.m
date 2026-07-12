function wg = welfare_from_values(V0, V1, dist0, pg)
% WELFARE_FROM_VALUES  Consumption-equivalent welfare incidence from two
% ALREADY-COMPUTED value functions, aggregated over the baseline invariant
% distribution. The CE transform and the group aggregation are identical to
% welfare_by_group (which solves the two steady states itself); this variant
% takes the value functions directly so it can compare a steady state
% against a TRANSITION value function (V1 = date-1 value of the announced
% path, from transition_backward), the transition-inclusive incidence
% object.
%
%   CRRA sigma ~= 1:  Vtil = V + 1/((1-sigma)(1-beta))
%                     lambda = (Vtil1/Vtil0)^(1/(1-sigma)) - 1
%   sigma == 1 (log): lambda = exp((V1 - V0)(1-beta)) - 1
%
% INPUTS
%   V0, V1 : na x ne value functions (same grids).
%   dist0  : na x ne baseline invariant distribution (weights).
%   pg     : project params (sigma, beta, aGrid).
%
% OUTPUT wg: .lambda_q (1x5 wealth-quintile CE gains), .lambda_top10,
%   .lambda_bot50, .lambda_constr (borrowing-limit gridpoint), .lambda_agg,
%   .qcut, .ok, .msg.

    wg = struct('ok', false, 'msg', '');
    if ~isequal(size(V0), size(V1)) || ~isequal(size(V0), size(dist0))
        wg.msg = 'welfare_from_values: size mismatch across V0/V1/dist0.';
        warning('welfare_from_values:size', '%s', wg.msg);
        return;
    end

    if abs(pg.sigma - 1) < 1e-12
        lam = exp((V1 - V0) * (1 - pg.beta)) - 1;
    else
        cshift = 1 / ((1 - pg.sigma) * (1 - pg.beta));
        Vt0 = V0 + cshift;
        Vt1 = V1 + cshift;
        if pg.sigma > 1 && (max(Vt0(:)) >= 0 || max(Vt1(:)) >= 0)
            wg.msg = ['welfare_from_values: CE transform invalid ' ...
                      '(nonnegative tilde-V under sigma>1).'];
            warning('welfare_from_values:transform', '%s', wg.msg);
            return;
        end
        lam = (Vt1 ./ Vt0).^(1/(1 - pg.sigma)) - 1;
    end

    % baseline wealth quintiles (marginal over assets), as in welfare_by_group
    wa    = sum(dist0, 2);
    cwa   = cumsum(wa) / sum(wa);
    aGrid = pg.aGrid(:);
    qcut  = zeros(1, 4);
    for q = 1:4
        idx = find(cwa >= q/5, 1, 'first');
        qcut(q) = aGrid(idx);
    end
    lambda_q = nan(1, 5);
    edges = [-inf, qcut, inf];
    for q = 1:5
        sel = aGrid > edges(q) & aGrid <= edges(q+1);
        w = dist0(sel, :);
        if any(w(:) > 0)
            lambda_q(q) = sum(sum(lam(sel, :) .* w)) / sum(w(:));
        end
    end
    i10  = find(cwa >= 0.90, 1, 'first');
    selT = aGrid >= aGrid(i10);   wT = dist0(selT, :);
    i50  = find(cwa >= 0.50, 1, 'first');
    selB = aGrid <= aGrid(i50);   wB = dist0(selB, :);

    wg.lambda_q      = lambda_q;
    wg.lambda_top10  = sum(sum(lam(selT, :) .* wT)) / sum(wT(:));
    wg.lambda_bot50  = sum(sum(lam(selB, :) .* wB)) / sum(wB(:));
    wg.lambda_constr = sum(lam(1, :) .* dist0(1, :)) / max(sum(dist0(1, :)), eps);
    wg.lambda_agg    = sum(sum(lam .* dist0)) / sum(dist0(:));
    wg.qcut = qcut;
    wg.ok = true;
end
