function [residual, T_order, T] = dynamic_het1_resid(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if nargin < 9
    T_order = -1;
    T = NaN(1, 1);
end
[T_order, T] = hank_one_asset_steady_state.dynamic_het1_resid_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T);
residual = NaN(6, 1);
residual(1) = T(1)-params(1)*(1+y(27))*yh(17)-yh(12);
residual(2) = (1+y(17))*yh(4)+y(13)*yh(8)*xh(1)+xh(1)*(y(15)-y(16))-yh(7)-yh(10);
residual(3) = params(2)*yh(8)^(1/params(4))-T(1)*y(13)*xh(1);
    residual(4) = (yh(9)) - (yh(8)*xh(1));
    residual(5) = (yh(11)) - (T(1));
residual(6) = yh(10)*yh(12);
end
