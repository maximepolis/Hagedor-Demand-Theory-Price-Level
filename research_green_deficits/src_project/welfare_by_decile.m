function wd = welfare_by_decile(r, eq0, eq1, pg)
% WELFARE_BY_DECILE  Consumption-equivalent welfare incidence of the green
% program at DECILE resolution, plus the top-5% and top-1% tail cuts.
%
% Same CE object as welfare_by_group (lambda(a,e) making a household at
% baseline state (a,e) indifferent between the no-program steady state eq0
% and the program steady state eq1; identical CRRA transform and sigma>1
% validity guard), with two refinements the quintile code does not need:
%
%   1. FRACTIONAL MASS-POINT SPLITTING. In the benchmark (abar = 0) a large
%      mass of households sits exactly at the borrowing limit, so hard grid
%      cuts cannot separate the bottom deciles: several deciles would share
%      one grid point. Each grid point's mass is therefore assigned
%      fractionally to the deciles its cumulative-weight interval overlaps,
%      so every decile has exactly 10% of baseline mass by construction.
%      (Households at the same (a,e) state are identical, so splitting
%      their mass is exact, not an approximation.)
%   2. TAIL CUTS AND TAIL HONESTY. Top-5% and top-1% cuts are reported,
%      together with the model's wealth share of each group, so that the
%      thin top tail of the one-asset Aiyagari wealth distribution (which
%      understates observed top concentration) is visible next to the
%      incidence numbers rather than hidden behind them.
%
% INPUTS   r        real rate of the policy stance
%          eq0, eq1 equilibrium structs with .tau and .D (+ optional .vartheta)
%          pg       project params
% OUTPUT   wd struct: .lambda_dec (1x10), .lambda_top5, .lambda_top1,
%          .lambda_agg, .wshare_dec (1x10), .wshare_top5, .wshare_top1,
%          .mass_constrained, .ok, .msg
%
% STATUS: IMPLEMENTED (machinery); numbers are results only once run.

    wd = struct('ok', false, 'msg', '');

    pg0 = pg; pg1 = pg;
    if isfield(eq0, 'vartheta'), pg0.vartheta = eq0.vartheta; else, pg0.vartheta = 0; end
    if isfield(eq1, 'vartheta'), pg1.vartheta = eq1.vartheta; else, pg1.vartheta = 0; end
    [~, o0] = S_green(r, eq0.tau, eq0.D, pg0);
    [~, o1] = S_green(r, eq1.tau, eq1.D, pg1);
    if ~o0.feasible || ~o1.feasible
        wd.msg = 'welfare_by_decile: one of the steady states infeasible.';
        warning('welfare_by_decile:infeasible', '%s', wd.msg);
        return;
    end
    V0 = o0.V; V1 = o1.V; dist0 = o0.dist;

    % ---- CE transform (identical to welfare_by_group) ----
    if abs(pg.sigma - 1) < 1e-12
        lam = exp((V1 - V0) * (1 - pg.beta)) - 1;
    else
        cshift = 1 / ((1 - pg.sigma) * (1 - pg.beta));
        Vt0 = V0 + cshift; Vt1 = V1 + cshift;
        if pg.sigma > 1 && (max(Vt0(:)) >= 0 || max(Vt1(:)) >= 0)
            wd.msg = 'welfare_by_decile: CE transform invalid (sigma>1, tilde-V >= 0).';
            warning('welfare_by_decile:transform', '%s', wd.msg);
            return;
        end
        lam = (Vt1 ./ Vt0).^(1/(1 - pg.sigma)) - 1;
    end

    aGrid = pg.aGrid(:);
    wa    = sum(dist0, 2);                    % na x 1 marginal over assets
    wa    = wa / sum(wa);
    cwHi  = cumsum(wa);                       % upper cumulative bound of point i
    cwLo  = [0; cwHi(1:end-1)];               % lower bound

    % mass of grid point i falling in cumulative range (lo, hi]
    overlap = @(lo, hi) max(0, min(cwHi, hi) - max(cwLo, lo));

    % group CE mean: within a grid point, mass splits across e-states in the
    % baseline proportions dist0(i,:)/wa(i), so the group mean weights each
    % (i,e) by dist0(i,e) * overlap_i / wa_i.
    lam_bar_i = sum(lam .* dist0, 2) ./ max(sum(dist0, 2), eps);  % E[lam | a_i]
    gmean  = @(lo, hi) sum(overlap(lo, hi) .* lam_bar_i) / max(sum(overlap(lo, hi)), eps);
    gshare = @(lo, hi) sum(overlap(lo, hi) .* aGrid) / max(sum(wa .* aGrid), eps);

    lambda_dec = nan(1, 10); wshare_dec = nan(1, 10);
    for d = 1:10
        lambda_dec(d) = gmean((d-1)/10, d/10);
        wshare_dec(d) = gshare((d-1)/10, d/10);
    end

    wd.ok = true;
    wd.lambda_dec  = lambda_dec;
    wd.lambda_top5 = gmean(0.95, 1);
    wd.lambda_top1 = gmean(0.99, 1);
    wd.lambda_agg  = sum(sum(lam .* dist0)) / sum(dist0(:));
    wd.wshare_dec  = wshare_dec;
    wd.wshare_top5 = gshare(0.95, 1);
    wd.wshare_top1 = gshare(0.99, 1);
    wd.mass_constrained = sum(dist0(1, :)) / sum(dist0(:));

    % sanity: decile means must average (mass-weighted, equal by construction)
    % to the aggregate
    if abs(mean(lambda_dec) - wd.lambda_agg) > 1e-6 * max(1, abs(wd.lambda_agg))
        warning('welfare_by_decile:aggcheck', ...
            'Decile means (%.6f) do not average to the aggregate (%.6f).', ...
            mean(lambda_dec), wd.lambda_agg);
    end

    wd.msg = sprintf(['CE by wealth decile (%%): %s | top5 %.2f, top1 %.2f, ' ...
        'aggregate %.2f (constrained mass %.1f%%)'], ...
        mat2str(round(100*lambda_dec, 2)), 100*wd.lambda_top5, ...
        100*wd.lambda_top1, 100*wd.lambda_agg, 100*wd.mass_constrained);
end
