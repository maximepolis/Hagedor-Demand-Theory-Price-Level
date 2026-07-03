function [residual, T_order, T] = static_resid(y, x, params, yagg, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(8, 1);
end
[T_order, T] = hank_two_assets_steady_state.static_resid_tt(y, x, params, yagg, T_order, T);
residual = NaN(22, 1);
residual(1) = params(1)*(y(16)-1/params(13))+log(1+y(15))/(1+y(17))+x(2)-log(1+y(15));
residual(2) = y(13)+y(14)-(1+y(17))*y(14);
    residual(3) = (y(11)) - (T(2)^(1/(1-params(2))));
    residual(4) = (y(16)) - (y(11)*y(10)/(1-params(2))/y(18));
residual(5) = 1-y(9);
residual(6) = y(9)+y(16)*T(4)-(1-(1-params(10)))-y(9)*(1+y(17)+x(6));
residual(7) = y(18)*T(6)-y(7);
residual(8) = y(12)-y(12)*(1-params(10))-y(8);
residual(9) = x(1)+params(21)+y(15)*params(5)-y(6);
residual(10) = (y(17)*params(7)+params(22)+x(3))/y(10)/y(11)-y(5);
residual(11) = y(17)-params(6)-y(3);
residual(12) = (y(13)+y(14))*params(9)/y(14)+(1+y(17))*(1-params(9))-1-y(4);
residual(13) = 1+y(6)-(1+y(15))*(1+y(17));
residual(14) = y(15)-y(1);
residual(15) = y(11)*T(8)-y(2);
residual(16) = x(7)+log(1+y(1))*(params(20)+x(4))+params(11)*(params(14)*y(11)^(1+1/params(12))-y(11)*y(10)*(1-y(5))*y(19)/params(4))-log(1+y(1));
residual(17) = y(14)+params(7)-y(20)-y(21);
residual(18) = params(8)-y(21);
    residual(19) = (y(19)) - (yagg(1));
    residual(20) = (y(20)) - (yagg(2));
    residual(21) = (y(21)) - (yagg(3));
    residual(22) = (y(22)) - (x(5));
end
