function B = kv_budget_identities(TR, pgc, opts)
% KV_BUDGET_IDENTITIES  Check that a solved transition satisfies the
% government debt recursion at every date and in accumulated form.
%
% WHY THIS IS NOT REDUNDANT WITH THE SOLVER. The solver BUILDS b_path from the
% recursion, so recomputing it must agree -- that is the point. These
% identities do not test arithmetic; they test that the STORED paths are
% mutually consistent, which is the check that catches a fiscal rule that
% silently altered the real program or the surcharge between construction and
% reporting. A decomposition of paths that violate the budget identity is not
% a decomposition of anything.
%
% THE RECURSION, COPIED FROM THE SOLVER RATHER THAN REMEMBERED. An earlier
% version of this file assumed
%       b_{t+1} = ( b_t + (1-phi_t) g_t - xi_t ) / (1 + rbar)
% and reported residuals of 2.1 -- two hundred times the program -- on a run
% whose paths were in fact internally consistent. Two things were wrong, and
% both matter economically, not just numerically:
%
%   1. the lagged stock is carried at the REALIZED path rate r_t, not at the
%      stationary rbar. Along a transition the real rate moves, and debt
%      service moves with it; using rbar would price the outstanding stock at
%      a rate the government never faces.
%   2. the recursion starts from b_0 = B0 / P_0, the PRE-ANNOUNCEMENT real
%      stock, which is NOT b_path(1). b_path(1) is already the post-
%      announcement revaluation, and treating it as the initial condition
%      silently drops the announcement-date revaluation from the identity --
%      i.e. it would drop exactly the object this paper is about.
%
% The true recursion (solve_hank_dtpl_transition, the b_path loop) is
%
%       b_t = ( (1 + r_t) b_{t-1} + (1 - phi_t) g_t - xi_t ) / (1 + rbar),
%       b_0 = B0 / P_0.
%
% NORMALIZATIONS follow the acceptance protocol: the period residual by
% program expenditure, the accumulated residual by initial real debt.
%
% INPUT   TR    solved transition: .b_path .g_path .phi_path .r_path .P0
%               (.xi_path optional)
%         pgc   green parameters (Bnom, i_ss, mu)
%         opts  unused; accepted so callers can pass their solver opts
% OUTPUT  B .max_period_resid .pv_resid .period_resid .ok .msg

    if nargin < 3, opts = []; end %#ok<NASGU>
    B = struct('max_period_resid', NaN, 'pv_resid', NaN, 'period_resid', [], ...
               'rbar', NaN, 'T', 0, 'b0', NaN, 'bT', NaN, 'ok', false, 'msg', '');

    % A transition that did not solve has no paths to check. Say so rather
    % than dot-indexing an empty struct, which is how this crashed the first
    % time it met an INFEASIBLE consolidation.
    need = {'b_path','g_path','phi_path','r_path','P0'};
    if ~isstruct(TR) || isempty(TR)
        B.msg = 'no transition supplied (empty or non-struct)'; return;
    end
    miss = need(~isfield(TR, need));
    if ~isempty(miss)
        B.msg = ['transition is missing ' strjoin(miss, ', ')]; return;
    end

    rbar = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;
    b   = reshape(TR.b_path,   1, []);
    g   = reshape(TR.g_path,   1, []);
    phi = reshape(TR.phi_path, 1, []);
    r   = reshape(TR.r_path,   1, []);
    T   = min([numel(b), numel(g), numel(phi), numel(r)]);
    if T < 2, B.msg = 'path shorter than two dates'; return; end
    xi = zeros(1, T);
    if isfield(TR,'xi_path') && ~isempty(TR.xi_path)
        x = reshape(TR.xi_path, 1, []);
        xi(1:min(T,numel(x))) = x(1:min(T,numel(x)));
    end
    b = b(1:T); g = g(1:T); phi = phi(1:T); r = r(1:T);

    b0 = pgc.Bnom / TR.P0;                       % pre-announcement real stock
    pg = (1 - phi) .* g - xi;                    % primary gap, per date

    % ---- V4: the recursion, date by date, from the true initial condition
    b_imp = zeros(1, T); bprev = b0;
    for t = 1:T
        b_imp(t) = ((1 + r(t)) * bprev + pg(t)) / (1 + rbar);
        bprev = b_imp(t);
    end
    scale_g = max(mean(abs(g)), eps);
    B.period_resid     = (b_imp - b) / scale_g;
    B.max_period_resid = max(abs(B.period_resid));

    % ---- V5: the accumulated form, carrying the time-varying rate ---------
    % b_T = (prod a_t) b_0 + sum_t [prod_{s>t} a_s] pg_t/(1+rbar),  a_t =
    % (1+r_t)/(1+rbar). A per-period pass can hide a systematic sign error
    % that accumulation exposes, which is why both are reported.
    a = (1 + r) / (1 + rbar);
    acc = prod(a) * b0;
    for t = 1:T
        acc = acc + prod(a(t+1:T)) * pg(t) / (1 + rbar);
    end
    B.pv_resid = abs(acc - b(T)) / max(abs(b0), eps);

    B.rbar = rbar; B.T = T; B.b0 = b0; B.bT = b(T);
    B.ok = isfinite(B.max_period_resid) && isfinite(B.pv_resid);
end
