function [T_order, T] = dynamic_het1_g2_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if T_order >= 2
    return
end
[T_order, T] = hank_two_assets_steady_state.dynamic_het1_g1_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T);
T_order = 2;
if size(T, 1) < 35
    T = [T; NaN(35 - size(T, 1), 1)];
end
T(25) = getPowerDeriv(yh(11),(-1)/params(15),2);
T(26) = (-(T(13)*((1+y(26))*((1+y(26))*yh(2)+params(16))+(1+y(26))*((1+y(26))*yh(2)+params(16)))))/(T(14)*T(14));
T(27) = getPowerDeriv(T(5),params(18)-1,2);
T(28) = T(16)*T(26)+T(15)*T(15)*T(27);
T(29) = (T(14)*(yh(2)*T(12)+((1+y(26))*yh(2)+params(16))*(-T(2))-(T(4)+(1+y(26))*T(2)*(-yh(2))))-T(13)*(yh(2)*((1+y(26))*yh(2)+params(16))+yh(2)*((1+y(26))*yh(2)+params(16))))/(T(14)*T(14));
T(30) = T(16)*T(29)+T(15)*T(23)*T(27);
T(31) = (-((((1+y(26))*yh(2)+params(16))*T(2)*(-yh(2))-yh(2)*T(4))*(yh(2)*((1+y(26))*yh(2)+params(16))+yh(2)*((1+y(26))*yh(2)+params(16)))))/(T(14)*T(14));
T(32) = T(23)*T(23)*T(27)+T(16)*T(31);
T(33) = getPowerDeriv(T(4),params(18),2);
T(34) = getPowerDeriv((1+y(26))*yh(2)+params(16),1-params(18),2);
T(35) = getPowerDeriv(T(5),params(18),2);
end
