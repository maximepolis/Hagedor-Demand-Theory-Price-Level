function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, yagg, T_order, T)
if nargin < 7
    T_order = -1;
    T = NaN(11, 1);
end
[T_order, T] = hank_two_assets_steady_state.dynamic_resid_tt(y, x, params, steady_state, yagg, T_order, T);
residual = NaN(22, 1);
residual(1) = params(1)*(y(38)-1/params(13))+y(62)/y(40)*log(1+y(59))/(1+y(61))+x(2)-log(1+y(37));
residual(2) = y(57)+y(58)-(1+y(61))*y(36);
    residual(3) = (y(33)) - (T(2)^T(3));
    residual(4) = (y(38)) - (y(33)*y(32)/(1-params(2))/y(40));
residual(5) = 1+(y(34)/y(12)-1)/(params(10)*params(3))-y(31);
residual(6) = T(5)*y(53)+y(60)*T(11)-(T(5)-(1-params(10))+(T(5)-1)^2/(params(3)*2*params(10)))-y(31)*(1+y(61)+x(6));
residual(7) = y(40)*T(7)-y(29);
residual(8) = y(34)-y(12)*(1-params(10))+y(12)*T(8)/(params(3)*2*params(10))-y(30);
residual(9) = x(1)+params(21)+y(37)*params(5)-y(28);
residual(10) = (y(39)*params(7)+params(22)+x(3))/y(32)/y(33)-y(27);
residual(11) = y(39)-params(6)-y(25);
residual(12) = params(9)*(y(36)+y(35))/y(14)+(1-params(9))*(1+y(39))-1-y(26);
residual(13) = 1+y(6)-(1+y(37))*(1+y(39));
residual(14) = (1+y(37))*y(32)/y(10)-1-y(23);
residual(15) = y(33)*T(10)-y(24);
residual(16) = x(7)+(params(20)+x(4))*log(1+y(45))+params(11)*(params(14)*y(33)^(1+1/params(12))-y(33)*y(32)*(1-y(27))*y(41)/params(4))-log(1+y(23));
residual(17) = y(36)+params(7)-y(42)-y(43);
residual(18) = params(8)-y(43);
    residual(19) = (y(41)) - (yagg(1));
    residual(20) = (y(42)) - (yagg(2));
    residual(21) = (y(43)) - (yagg(3));
    residual(22) = (y(44)) - (x(5));
end
