function [T_order, T] = dynamic_het1_g2_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if T_order >= 2
    return
end
[T_order, T] = hank_one_asset_steady_state.dynamic_het1_g1_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T);
T_order = 2;
if size(T, 1) < 3
    T = [T; NaN(3 - size(T, 1), 1)];
end
T(3) = getPowerDeriv(yh(7),(-1)/params(3),2);
end
