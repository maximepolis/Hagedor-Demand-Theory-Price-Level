function [g1, T_order, T] = dynamic_het1_g1(y, x, params, steady_state, yh, xh, paramsh, sparse_rowval, sparse_colval, sparse_colptr, T_order, T)
if nargin < 12
    T_order = -1;
    T = NaN(2, 1);
end
[T_order, T] = hank_one_asset_steady_state.dynamic_het1_g1_tt(y, x, params, steady_state, yh, xh, paramsh, T_order, T);
g1_v = NaN(24, 1);
    g1_v(1)=1+y(17);
    g1_v(2)=T(2);
    g1_v(3)=(-1);
    g1_v(4)=(-(y(13)*xh(1)*T(2)));
    g1_v(5)=(-T(2));
    g1_v(6)=y(13)*xh(1);
    g1_v(7)=params(2)*getPowerDeriv(yh(8),1/params(4),1);
    g1_v(8)=(-xh(1));
    g1_v(9)=1;
    g1_v(10)=(-1);
    g1_v(11)=yh(12);
    g1_v(12)=1;
    g1_v(13)=(-1);
    g1_v(14)=yh(10);
    g1_v(15)=(-(params(1)*(1+y(27))));
    g1_v(16)=y(13)*yh(8)+y(15)-y(16);
    g1_v(17)=(-(T(1)*y(13)));
    g1_v(18)=(-yh(8));
    g1_v(19)=yh(8)*xh(1);
    g1_v(20)=(-(T(1)*xh(1)));
    g1_v(21)=xh(1);
    g1_v(22)=(-xh(1));
    g1_v(23)=yh(4);
    g1_v(24)=(-(params(1)*yh(17)));
g1 = sparse(sparse_rowval, sparse_colval, g1_v, 6, 52);
end
