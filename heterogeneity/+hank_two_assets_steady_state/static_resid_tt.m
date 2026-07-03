function [T_order, T] = static_resid_tt(y, x, params, yagg, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 8
    T = [T; NaN(8 - size(T, 1), 1)];
end
T(1) = y(12)^params(2);
T(2) = y(18)/(params(19)+x(5))/T(1);
T(3) = (y(11)/y(12))^(1-params(2));
T(4) = T(3)*params(2)*(params(19)+y(22));
T(5) = params(13)/(params(13)-1)/2/params(1);
T(6) = T(5)*log(1+y(15))^2;
T(7) = params(4)/(1-params(4))/2/params(11);
T(8) = T(7)*log(1+y(1))^2;
end
