function [residual, T_order, T] = dynamic_het1_resid(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if nargin < 9
    T_order = -1;
    T = NaN(11, 1);
end
[T_order, T] = hank_two_assets_steady_state.dynamic_het1_resid_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T);
residual = NaN(8, 1);
residual(1) = T(1)-(params(20)+x(4))*yh(21)-yh(15);
residual(2) = T(1)*(1+T(3)*T(6))-(params(20)+x(4))*yh(20)-yh(16);
residual(3) = (1+y(26))*yh(2)+(1+y(25))*yh(1)-T(8)*T(9)+(1-y(27))*y(32)*y(33)*xh(1)-yh(11)-yh(10)-yh(9);
    residual(4) = (yh(14)) - (T(1)*xh(1));
    residual(5) = (yh(12)) - (T(1)*T(11));
    residual(6) = (yh(13)) - (T(1)*(1+y(25)));
residual(7) = yh(9)*yh(15);
residual(8) = yh(10)*yh(16);
end
