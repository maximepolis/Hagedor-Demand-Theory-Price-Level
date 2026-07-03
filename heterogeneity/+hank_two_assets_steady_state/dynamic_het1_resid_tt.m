function [T_order, T] = dynamic_het1_resid_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 11
    T = [T; NaN(11 - size(T, 1), 1)];
end
T(1) = yh(11)^((-1)/params(15));
T(2) = sign(yh(10)-(1+y(26))*yh(2));
T(3) = params(17)*T(2);
T(4) = abs(yh(10)-(1+y(26))*yh(2));
T(5) = T(4)/((1+y(26))*yh(2)+params(16));
T(6) = T(5)^(params(18)-1);
T(7) = params(17)/params(18);
T(8) = T(7)*T(4)^params(18);
T(9) = ((1+y(26))*yh(2)+params(16))^(1-params(18));
T(10) = 1-T(7)*(T(6)*T(2)*(-params(18))+(1-params(18))*T(5)^params(18));
T(11) = (1+y(26))*T(10);
end
