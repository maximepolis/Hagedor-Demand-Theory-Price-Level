function [x0, ok] = kv_zero_cross(x, y)
% KV_ZERO_CROSS  First sign change of y(x), located by linear interpolation.
%
% Returns ok = false rather than a number when the data do not bracket a
% crossing. A frontier reported from an unbracketed grid is an extrapolation
% wearing an interpolation's clothes, and this project has spent enough time
% on numbers that looked like measurements.
    x0 = NaN; ok = false;
    x = x(:).'; y = y(:).';
    g = isfinite(x) & isfinite(y);
    x = x(g); y = y(g);
    if numel(x) < 2, return; end
    [x, k] = sort(x); y = y(k);
    s = sign(y);
    i = find(s(1:end-1) .* s(2:end) < 0, 1, 'first');
    if isempty(i), return; end
    x0 = x(i) + (x(i+1) - x(i)) * (0 - y(i)) / (y(i+1) - y(i));
    ok = isfinite(x0);
end
