function [d, info] = numerical_derivatives(f, x, h)
% NUMERICAL_DERIVATIVES  Central finite-difference derivative of a scalar-valued
% function f at points x. Used, e.g., to compute the local slope dS/dr of the
% asset-demand curve (the paper notes global monotonicity is NOT required for
% the determinacy result; the slope is reported only as a diagnostic).
%
% INPUTS
%   f : function handle, f(x) returns a scalar (or vector, elementwise per x).
%   x : point(s) at which to differentiate (scalar or vector).
%   h : (optional) step size. Default: 1e-4 * max(1,|x|).
%
% OUTPUTS
%   d    : central-difference derivative f'(x), same size as x.
%   info : struct with .method, .h, and .fwd/.bwd fallback flags.
%
% Uses one-sided differences if f returns NaN on one side (e.g. near the
% divergence asymptote of asset demand).

    if nargin < 3 || isempty(h)
        h = 1e-4 * max(1, abs(x));
    end
    if isscalar(h)
        h = h * ones(size(x));
    end

    d    = nan(size(x));
    used = repmat({'central'}, size(x));
    for k = 1:numel(x)
        xk = x(k); hk = h(k);
        fp = f(xk + hk);
        fm = f(xk - hk);
        if isfinite(fp) && isfinite(fm)
            d(k) = (fp - fm) / (2*hk);
        elseif isfinite(fp)
            f0 = f(xk);
            d(k) = (fp - f0) / hk;   % forward
            used{k} = 'forward';
        elseif isfinite(fm)
            f0 = f(xk);
            d(k) = (f0 - fm) / hk;   % backward
            used{k} = 'backward';
        else
            d(k) = NaN;
            used{k} = 'nan';
        end
    end

    info = struct();
    info.method = used;
    info.h      = h;
end
