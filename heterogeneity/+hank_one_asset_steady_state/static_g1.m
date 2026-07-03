function [g1, T_order, T] = static_g1(y, x, params, yagg, sparse_rowval, sparse_colval, sparse_colptr, T_order, T)
if nargin < 9
    T_order = -1;
    T = NaN(3, 1);
end
[T_order, T] = hank_one_asset_steady_state.static_g1_tt(y, x, params, yagg, T_order, T);
g1_v = NaN(21, 1);
    g1_v(1)=(-(1/params(8)));
    g1_v(2)=(-(1-T(2)));
    g1_v(3)=1;
    g1_v(4)=y(3);
    g1_v(5)=(-1);
    g1_v(6)=y(2);
    g1_v(7)=params(6)*1/params(8);
    g1_v(8)=y(1)*T(1)*T(3)*2*log(1+y(4));
    g1_v(9)=((1+y(4))*params(7)-(y(4)*params(7)+1+params(10)+y(10)))/((1+y(4))*(1+y(4)));
    g1_v(10)=T(3)/(1+y(7))-T(3);
    g1_v(11)=1;
    g1_v(12)=1;
    g1_v(13)=(-1);
    g1_v(14)=(-params(9));
    g1_v(15)=(-log(1+y(4)))/((1+y(7))*(1+y(7)));
    g1_v(16)=1;
    g1_v(17)=1;
    g1_v(18)=1;
    g1_v(19)=1;
    g1_v(20)=T(3);
    g1_v(21)=1;
g1 = sparse(sparse_rowval, sparse_colval, g1_v, 10, 10);
end
