function [J, r0, aux0] = ssj_transition_jacobian(logphat_free, ctx, h)
% SSJ_TRANSITION_JACOBIAN  The sequence-space (general-equilibrium) Jacobian of
% the nonlinear HANK-DTPL transition,
%     J(t,s) = d resid_t / d logphat_free_s,   t,s = 1..T-1,
% computed DIRECTLY by one-sided finite differences (T-1 residual re-solves),
% each residual being a full household backward + distribution forward pass
% (transition_residual_dtpl).
%
% This is the sequence-space Jacobian of \citet{auclertetal2021}, evaluated
% directly rather than through their fake-news recursion. The fake-news
% algorithm is the efficient route when the aggregate unknown is
% high-dimensional; here the aggregate unknown is a SCALAR per date (the log
% price level), so the T-1 direct re-solves are affordable and far more
% transparent, and the resulting J is exactly the object the Newton step
% inverts and the determinacy diagnostic reads.
%
% INPUTS
%   logphat_free : (T-1) x 1 base log-price path to linearize around.
%   ctx          : transition context (see solve_transition_ssj / build_ctx).
%   h            : (optional) finite-difference step in log price (default 1e-4).
%
% OUTPUTS
%   J    : (T-1) x (T-1) sequence-space Jacobian (columns = perturbed date s).
%   r0   : 1 x T base residual at logphat_free.
%   aux0 : base consistent paths (aux from transition_residual_dtpl).

    if nargin < 3 || isempty(h), h = 1e-4; end
    n = numel(logphat_free);
    x0 = logphat_free(:);

    [r0, aux0] = transition_residual_dtpl(x0, ctx);
    if ~aux0.feas
        error('ssj_transition_jacobian:infeasible', ...
              'base household problem infeasible at the linearization point.');
    end
    r0f = r0(1:n).';                       % free-date residuals (column)

    J = zeros(n, n);
    for s = 1:n
        xp = x0; xp(s) = xp(s) + h;
        rp = transition_residual_dtpl(xp, ctx);
        J(:, s) = (rp(1:n).' - r0f) / h;   % d resid_{1:T-1} / d logphat_s
    end
end
