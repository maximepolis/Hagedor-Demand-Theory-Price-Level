function [T_order, T] = dynamic_het1_g1_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if T_order >= 1
    return
end
[T_order, T] = hank_two_assets_steady_state.dynamic_het1_resid_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T);
T_order = 1;
if size(T, 1) < 24
    T = [T; NaN(24 - size(T, 1), 1)];
end
T(12) = T(2)*(-(1+y(26)));
T(13) = ((1+y(26))*yh(2)+params(16))*T(12)-(1+y(26))*T(4);
T(14) = ((1+y(26))*yh(2)+params(16))*((1+y(26))*yh(2)+params(16));
T(15) = T(13)/T(14);
T(16) = getPowerDeriv(T(5),params(18)-1,1);
T(17) = T(15)*T(16);
T(18) = getPowerDeriv(T(4),params(18),1);
T(19) = getPowerDeriv((1+y(26))*yh(2)+params(16),1-params(18),1);
T(20) = getPowerDeriv(T(5),params(18),1);
T(21) = T(2)/((1+y(26))*yh(2)+params(16));
T(22) = getPowerDeriv(yh(11),(-1)/params(15),1);
T(23) = (((1+y(26))*yh(2)+params(16))*T(2)*(-yh(2))-yh(2)*T(4))/T(14);
T(24) = T(16)*T(23);
end
