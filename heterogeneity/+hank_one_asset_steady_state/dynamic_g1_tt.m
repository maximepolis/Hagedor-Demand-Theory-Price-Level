function [T_order, T] = dynamic_g1_tt(y, x, params, steady_state, yagg, T_order, T)
if T_order >= 1
    return
end
[T_order, T] = hank_one_asset_steady_state.dynamic_resid_tt(y, x, params, steady_state, yagg, T_order, T);
T_order = 1;
if size(T, 1) < 4
    T = [T; NaN(4 - size(T, 1), 1)];
end
T(3) = 1/(1+y(14));
T(4) = y(21)/y(11)*1/(1+y(24));
end
