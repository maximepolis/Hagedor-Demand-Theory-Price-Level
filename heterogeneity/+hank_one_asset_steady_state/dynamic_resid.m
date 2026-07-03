function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, yagg, T_order, T)
if nargin < 7
    T_order = -1;
    T = NaN(2, 1);
end
[T_order, T] = hank_one_asset_steady_state.dynamic_resid_tt(y, x, params, steady_state, yagg, T_order, T);
residual = NaN(10, 1);
residual(1) = y(12)-y(11)/params(8);
residual(2) = y(15)-(y(11)-y(12)*y(13)-y(11)*T(2));
residual(3) = (params(7)*y(4)+1+params(10)+y(10))/(1+y(14))-1-y(17);
residual(4) = y(16)-y(17)*params(9)-x(1);
residual(5) = params(6)*(y(13)/params(8)-1/params(5))+y(21)/y(11)*log(1+y(24))/(1+y(27))+x(2)-log(1+y(14));
residual(6) = y(18)-params(9);
residual(7) = y(19)-y(12);
    residual(8) = (y(18)) - (yagg(1));
    residual(9) = (y(19)) - (yagg(2));
    residual(10) = (y(20)) - (x(3));
end
