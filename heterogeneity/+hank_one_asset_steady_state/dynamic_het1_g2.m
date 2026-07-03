function [g2_v, T_order, T] = dynamic_het1_g2(y, x, params, steady_state, yh, xh, paramsh, T_order, T)
if nargin < 9
    T_order = -1;
    T = NaN(3, 1);
end
[T_order, T] = hank_one_asset_steady_state.dynamic_het1_g2_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T);
g2_v = NaN(16, 1);
g2_v(1)=T(3);
g2_v(2)=(-params(1));
g2_v(3)=y(13);
g2_v(4)=xh(1);
g2_v(5)=1;
g2_v(6)=yh(8);
g2_v(7)=1;
g2_v(8)=(-1);
g2_v(9)=(-(y(13)*xh(1)*T(3)));
g2_v(10)=(-(y(13)*T(2)));
g2_v(11)=(-(xh(1)*T(2)));
g2_v(12)=params(2)*getPowerDeriv(yh(8),1/params(4),2);
g2_v(13)=(-T(1));
g2_v(14)=(-1);
g2_v(15)=(-T(3));
g2_v(16)=1;
end
