function [J, r0, aux0] = twoasset_transition_jacobian(x0, ctx, h)
% TWOASSET_TRANSITION_JACOBIAN  Sequence-space (general-equilibrium) Jacobian
% of the two-asset announcement transition,
%     J(i,j) = d resid_i / d x_j,   i,j = 1..2(T-1),
% by one-sided finite differences: 2(T-1) residual re-solves, each a full
% household backward pass plus distribution forward pass.
%
% This is the Jacobian of \citet{auclertetal2021}, evaluated directly rather
% than through the fake-news recursion. The fake-news route is the efficient
% one when the aggregate unknown is high-dimensional; here it is two scalars
% per date, so direct evaluation is affordable and the resulting J is exactly
% the object the Newton step inverts and the determinacy diagnostic reads.
%
% The block structure is informative and worth reading off the output:
%     [ dBond/dlogP   dBond/dlogq ]
%     [ dTree/dlogP   dTree/dlogq ]
% The off-diagonal blocks are the portfolio-substitution channel; if they
% vanished the two markets would decouple and the price level would be
% determined exactly as in the one-asset economy.
%
% INPUTS
%   x0  : 2(T-1) x 1 point to linearize at.
%   ctx : context (see twoasset_transition_residual).
%   h   : finite-difference step in log price. Default 1e-3. Do not shrink
%         this casually: the backward pass interpolates on a finite grid, so
%         the residual is only piecewise smooth at fine scales and too small
%         a step returns grid noise rather than a derivative. The one-asset
%         solver learned the same lesson.
%
% OUTPUTS
%   J    : 2(T-1) x 2(T-1) Jacobian.
%   r0   : base residual at x0.
%   aux0 : base auxiliary paths.

    if nargin < 3 || isempty(h), h = 1e-3; end
    x0 = x0(:); n = numel(x0);

    [r0, aux0] = twoasset_transition_residual(x0, ctx);
    if ~aux0.feas
        error('twoasset_transition_jacobian:infeasible', ...
              'residual infeasible at the linearization point (date %d).', aux0.tbad);
    end

    J = zeros(n, n);
    for j = 1:n
        xp = x0; xp(j) = xp(j) + h;
        [rp, auxp] = twoasset_transition_residual(xp, ctx);
        if ~auxp.feas
            xp = x0; xp(j) = xp(j) - h;              % fall back to a backward step
            [rp, auxp] = twoasset_transition_residual(xp, ctx);
            if ~auxp.feas
                J(:, j) = 0; J(j, j) = 1;            % neutral column, keep J invertible
                continue;
            end
            J(:, j) = (r0 - rp) / h;
            continue;
        end
        J(:, j) = (rp - r0) / h;
    end
end
