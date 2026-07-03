function [T_order, T] = dynamic_g1_tt(y, x, params, steady_state, yagg, T_order, T)
if T_order >= 1
    return
end
[T_order, T] = hank_two_assets_steady_state.dynamic_resid_tt(y, x, params, steady_state, yagg, T_order, T);
T_order = 1;
if size(T, 1) < 28
    T = [T; NaN(28 - size(T, 1), 1)];
end
T(12) = 1/(1+y(23));
T(13) = 1/y(34);
T(14) = getPowerDeriv(y(55)/y(34),1-params(2),1);
T(15) = getPowerDeriv(y(12),params(2),1);
T(16) = (-(y(40)/(params(19)+x(5))*T(15)));
T(17) = T(16)/(T(1)*T(1));
T(18) = getPowerDeriv(T(2),T(3),1);
T(19) = (-y(34))/(y(12)*y(12));
T(20) = 2*(y(34)/y(12)-1);
T(21) = T(19)*T(20);
T(22) = 1/y(12);
T(23) = (-y(56))/(y(34)*y(34));
T(24) = T(20)*T(22);
T(25) = 1/(1+y(37));
T(26) = y(62)/y(40)*1/(1+y(59));
T(27) = 1/(params(19)+x(5))/T(1);
T(28) = (-y(40))/((params(19)+x(5))*(params(19)+x(5)))/T(1);
end
