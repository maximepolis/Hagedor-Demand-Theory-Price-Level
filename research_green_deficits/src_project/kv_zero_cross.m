function [x0, ok, why, br] = kv_zero_cross(x, y)
% KV_ZERO_CROSS  First sign change of y(x), located by linear interpolation.
%
% Returns ok = false rather than a number when the data do not bracket a
% crossing. A frontier reported from an unbracketed grid is an extrapolation
% wearing an interpolation's clothes, and this project has spent enough time
% on numbers that looked like measurements.
%
% The third output says WHY, and specifically which SIDE the crossing must be
% on. "not bracketed" is a true statement that leaves the reader to work out
% whether to extend the grid up or down; with y monotone in x -- which is the
% case this is used for -- the sign of the endpoints answers that, and the
% answer is what the next run needs.
%
% OUTPUT  x0   the crossing, NaN when not bracketed
%         ok   true when x0 is a genuine interpolation
%         why  one line: how it was found, or which way to extend
%         br   [x_left x_right], the bracketing pair; empty when not
%              bracketed. The caller judges the bracket's WIDTH: a linear
%              interpolation across a wide bracket of a convex curve places
%              the crossing wrongly, and only the caller knows the grid
%              spacing that makes "wide" meaningful.
    [x0, ok, why, br] = deal(NaN, false, '', []);
    x = x(:).'; y = y(:).';
    g = isfinite(x) & isfinite(y);
    x = x(g); y = y(g);
    if numel(x) < 2
        why = sprintf('only %d usable point(s); a crossing needs two', numel(x));
        return;
    end
    [x, k] = sort(x); y = y(k);
    s = sign(y);
    % An EXACT zero at a grid point is a located crossing, not a failure.
    % The strict product test below returns "no sign change" for
    % y = [+, 0, -] because both adjacent products are zero -- reporting a
    % genuine crossing as NOT BRACKETED. Measure-zero for solver output,
    % but the diagnostic would be exactly wrong when it happened.
    iz = find(s == 0, 1, 'first');
    if ~isempty(iz)
        x0 = x(iz); ok = true; br = [x(iz), x(iz)];
        why = sprintf('y is exactly zero at x = %.4g', x(iz));
        return;
    end
    i = find(s(1:end-1) .* s(2:end) < 0, 1, 'first');
    if isempty(i)
        if all(y > 0)
            why = sprintf(['every value is POSITIVE on [%.4g, %.4g]; if y is ' ...
                'increasing in x the crossing lies BELOW %.4g -- extend the ' ...
                'grid downward'], x(1), x(end), x(1));
        elseif all(y < 0)
            why = sprintf(['every value is NEGATIVE on [%.4g, %.4g]; if y is ' ...
                'increasing in x the crossing lies ABOVE %.4g -- extend the ' ...
                'grid upward'], x(1), x(end), x(end));
        else
            % Zeros without a strict sign change: y touches 0 and returns.
            why = 'y touches zero without crossing it; refine near the contact';
        end
        return;
    end
    x0 = x(i) + (x(i+1) - x(i)) * (0 - y(i)) / (y(i+1) - y(i));
    ok = isfinite(x0);
    if ok
        br = [x(i), x(i+1)];
        why = sprintf('bracketed between x = %.4g (y = %+.6f) and x = %.4g (y = %+.6f)', ...
                      x(i), y(i), x(i+1), y(i+1));
    else
        why = 'the bracketing pair produced a non-finite interpolation';
    end
end
