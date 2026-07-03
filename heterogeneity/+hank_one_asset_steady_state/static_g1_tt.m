function [T_order, T] = static_g1_tt(y, x, params, yagg, T_order, T)
if T_order >= 1
    return
end
[T_order, T] = hank_one_asset_steady_state.static_resid_tt(y, x, params, yagg, T_order, T);
T_order = 1;
if size(T, 1) < 3
    T = [T; NaN(3 - size(T, 1), 1)];
end
T(3) = 1/(1+y(4));
end
