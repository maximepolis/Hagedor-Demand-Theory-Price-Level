function [T_order, T] = dynamic_resid_tt(y, x, params, steady_state, yagg, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 11
    T = [T; NaN(11 - size(T, 1), 1)];
end
T(1) = y(12)^params(2);
T(2) = y(40)/(params(19)+x(5))/T(1);
T(3) = 1/(1-params(2));
T(4) = (y(55)/y(34))^(1-params(2));
T(5) = y(56)/y(34);
T(6) = params(13)/(params(13)-1)/2/params(1);
T(7) = T(6)*log(1+y(37))^2;
T(8) = (y(34)/y(12)-1)^2;
T(9) = params(4)/(1-params(4))/2/params(11);
T(10) = T(9)*log(1+y(23))^2;
T(11) = T(4)*params(2)*(params(19)+y(66));
end
