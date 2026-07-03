function [T_order, T] = dynamic_het1_g1_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if T_order >= 1
    return
end
[T_order, T] = hank_one_asset_steady_state.dynamic_het1_resid_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T);
T_order = 1;
if size(T, 1) < 2
    T = [T; NaN(2 - size(T, 1), 1)];
end
T(2) = getPowerDeriv(yh(7),(-1)/params(3),1);
end
