function B = kv_budget_identities(TR, pgc, opts)
% KV_BUDGET_IDENTITIES  Check that a solved transition satisfies the
% government budget recursion at every date and in present value.
%
% WHY THIS IS NOT REDUNDANT WITH THE SOLVER. The solver BUILDS b_path from the
% recursion, so recomputing it must agree -- which is exactly the point. These
% identities do not test the arithmetic; they test that the STORED paths are
% mutually consistent, and they are the check that catches a fiscal rule which
% silently altered the real program or the surcharge between construction and
% reporting. That is the failure mode that would make the whole C1/C2/C4
% decomposition meaningless while every number still looked plausible: a
% decomposition of paths that do not satisfy the budget identity is not a
% decomposition of anything.
%
% THE RECURSION, exactly as solve_hank_dtpl_transition writes it:
%
%     b_{t+1} = ( b_t + (1 - phi_t) g_t - xi_t ) / (1 + rbar)
%
% so the per-period primary gap is pg_t = (1 - phi_t) g_t - xi_t, and running
% the recursion backward from the terminal stock gives the present-value form
%
%     b_1 = (1+rbar)^{T-1} b_T - sum_{t=1}^{T-1} (1+rbar)^{t-1} pg_t.
%
% NORMALIZATIONS follow the acceptance protocol: the period residual is
% divided by program expenditure and the present-value residual by INITIAL
% DEBT, because those are the magnitudes each error would have to be small
% relative to in order to be economically ignorable.
%
% INPUT   TR    a solved transition (needs .b_path .g_path .phi_path .xi_path)
%         pgc   green parameters (for rbar)
%         opts  unused; accepted so callers can pass their solver opts
% OUTPUT  B .max_period_resid .pv_resid .period_resid (1 x T-1)
%           .rbar .T .b1 .bT .pv_gap .ok

    if nargin < 3, opts = []; end %#ok<NASGU>
    rbar = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;
    b   = reshape(TR.b_path, 1, []);
    g   = reshape(TR.g_path, 1, []);
    phi = reshape(TR.phi_path, 1, []);
    T   = numel(b);
    xi  = zeros(1, T);
    if isfield(TR, 'xi_path') && ~isempty(TR.xi_path)
        xi = reshape(TR.xi_path, 1, []);
        if numel(xi) < T, xi(end+1:T) = 0; end
        xi = xi(1:T);
    end
    n = min([T, numel(g), numel(phi)]);
    pg = (1 - phi(1:n)) .* g(1:n) - xi(1:n);      % primary gap, per date

    % ---- V4: the recursion, date by date --------------------------------
    b_next_implied = (b(1:n-1) + pg(1:n-1)) / (1 + rbar);
    resid = b_next_implied - b(2:n);
    scale_g = max(mean(abs(g(1:n))), eps);        % program expenditure
    B.period_resid     = resid / scale_g;
    B.max_period_resid = max(abs(B.period_resid));

    % ---- V5: the same recursion, in present value ------------------------
    % b_1 must equal the compounded terminal stock net of the compounded
    % primary gaps. A period-by-period pass can hide a systematic sign error
    % that this accumulates; that is why both are reported.
    disc = (1 + rbar) .^ (0:(n-2));
    b1_implied = (1 + rbar)^(n-1) * b(n) - sum(disc .* pg(1:n-1));
    B.pv_gap  = b1_implied - b(1);
    B.pv_resid = abs(B.pv_gap) / max(abs(b(1)), eps);   % relative to INITIAL debt

    B.rbar = rbar; B.T = n; B.b1 = b(1); B.bT = b(n);
    B.ok = isfinite(B.max_period_resid) && isfinite(B.pv_resid);
end
