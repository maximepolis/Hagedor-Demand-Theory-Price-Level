function [x0, ok, why] = kv_zero_cross(x, y)
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
    x0 = NaN; ok = false; why = '';
    x = x(:).'; y = y(:).';
    g = isfinite(x) & isfinite(y);
    x = x(g); y = y(g);
    if numel(x) < 2
        why = sprintf('only %d usable point(s); a crossing needs two', numel(x));
        return;
    end
    [x, k] = sort(x); y = y(k);
    s = sign(y);
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
        why = sprintf('bracketed between x = %.4g (y = %+.6f) and x = %.4g (y = %+.6f)', ...
                      x(i), y(i), x(i+1), y(i+1));
    else
        why = 'the bracketing pair produced a non-finite interpolation';
    end
end
