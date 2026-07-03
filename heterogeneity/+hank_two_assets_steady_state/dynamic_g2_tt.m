function [T_order, T] = dynamic_g2_tt(y, x, params, steady_state, yagg, T_order, T)
if T_order >= 2
    return
end
[T_order, T] = hank_two_assets_steady_state.dynamic_g1_tt(y, x, params, steady_state, yagg, T_order, T);
T_order = 2;
if size(T, 1) < 32
    T = [T; NaN(32 - size(T, 1), 1)];
end
T(29) = getPowerDeriv(T(2),T(3),2);
T(30) = getPowerDeriv(y(55)/y(34),1-params(2),2);
T(31) = (-1)/(y(34)*y(34));
T(32) = (-((-y(56))*(y(34)+y(34))))/(y(34)*y(34)*y(34)*y(34));
end
