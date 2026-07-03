function [residual, T_order, T] = static_resid(y, x, params, yagg, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(2, 1);
end
[T_order, T] = hank_one_asset_steady_state.static_resid_tt(y, x, params, yagg, T_order, T);
residual = NaN(10, 1);
residual(1) = y(2)-y(1)/params(8);
residual(2) = y(5)-(y(1)-y(2)*y(3)-y(1)*T(2));
residual(3) = (y(4)*params(7)+1+params(10)+y(10))/(1+y(4))-1-y(7);
residual(4) = y(6)-y(7)*params(9)-x(1);
residual(5) = params(6)*(y(3)/params(8)-1/params(5))+log(1+y(4))/(1+y(7))+x(2)-log(1+y(4));
residual(6) = y(8)-params(9);
residual(7) = y(9)-y(2);
    residual(8) = (y(8)) - (yagg(1));
    residual(9) = (y(9)) - (yagg(2));
    residual(10) = (y(10)) - (x(3));
end
