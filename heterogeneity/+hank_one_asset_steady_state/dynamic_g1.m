function [g1, T_order, T] = dynamic_g1(y, x, params, steady_state, yagg, sparse_rowval, sparse_colval, sparse_colptr, T_order, T)
if nargin < 10
    T_order = -1;
    T = NaN(4, 1);
end
[T_order, T] = hank_one_asset_steady_state.dynamic_g1_tt(y, x, params, steady_state, yagg, T_order, T);
g1_v = NaN(28, 1);
    g1_v(1)=params(7)/(1+y(14));
    g1_v(2)=T(3);
    g1_v(3)=(-(1/params(8)));
    g1_v(4)=(-(1-T(2)));
    g1_v(5)=log(1+y(24))*(-y(21))/(y(11)*y(11))/(1+y(27));
    g1_v(6)=1;
    g1_v(7)=y(13);
    g1_v(8)=(-1);
    g1_v(9)=y(12);
    g1_v(10)=params(6)*1/params(8);
    g1_v(11)=y(11)*T(1)*T(3)*2*log(1+y(14));
    g1_v(12)=(-(params(7)*y(4)+1+params(10)+y(10)))/((1+y(14))*(1+y(14)));
    g1_v(13)=(-T(3));
    g1_v(14)=1;
    g1_v(15)=1;
    g1_v(16)=(-1);
    g1_v(17)=(-params(9));
    g1_v(18)=1;
    g1_v(19)=1;
    g1_v(20)=1;
    g1_v(21)=1;
    g1_v(22)=1;
    g1_v(23)=log(1+y(24))*1/y(11)/(1+y(27));
    g1_v(24)=T(4)/(1+y(27));
    g1_v(25)=(-(y(21)/y(11)*log(1+y(24))))/((1+y(27))*(1+y(27)));
    g1_v(26)=(-1);
    g1_v(27)=1;
    g1_v(28)=(-1);
g1 = sparse(sparse_rowval, sparse_colval, g1_v, 10, 33);
end
