function [T_order, T] = dynamic_het1_resid_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 1
    T = [T; NaN(1 - size(T, 1), 1)];
end
T(1) = yh(7)^((-1)/params(3));
end
