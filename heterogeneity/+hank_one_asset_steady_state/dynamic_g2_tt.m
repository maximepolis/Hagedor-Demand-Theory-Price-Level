function [T_order, T] = dynamic_g2_tt(y, x, params, steady_state, yagg, T_order, T)
if T_order >= 2
    return
end
[T_order, T] = hank_one_asset_steady_state.dynamic_g1_tt(y, x, params, steady_state, yagg, T_order, T);
T_order = 2;
if size(T, 1) < 5
    T = [T; NaN(5 - size(T, 1), 1)];
end
T(5) = (-1)/((1+y(14))*(1+y(14)));
end
