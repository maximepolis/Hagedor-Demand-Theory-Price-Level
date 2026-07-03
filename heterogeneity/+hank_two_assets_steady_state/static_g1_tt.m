function [T_order, T] = static_g1_tt(y, x, params, yagg, T_order, T)
if T_order >= 1
    return
end
[T_order, T] = hank_two_assets_steady_state.static_resid_tt(y, x, params, yagg, T_order, T);
T_order = 1;
if size(T, 1) < 10
    T = [T; NaN(10 - size(T, 1), 1)];
end
T(9) = getPowerDeriv(y(11)/y(12),1-params(2),1);
T(10) = getPowerDeriv(T(2),1/(1-params(2)),1);
end
