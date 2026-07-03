function yh = dynamic_het1_set_auxiliary_variables(y, x, params, steady_state, yh, xh, paramsh, step)
%
% Sets auxiliary variables for heterogeneous model dimension 1
% step: level of auxiliary variables to compute (0-based)
%

if step == 0
    yh(15)=(yh(11)^((-1)/params(15))-(params(20)+x(4))*yh(21))*(yh(9)<=0);
    yh(16)=(yh(11)^((-1)/params(15))*(1+params(17)*sign(yh(10)-(1+y(26))*yh(2))*(abs(yh(10)-(1+y(26))*yh(2))/((1+y(26))*yh(2)+params(16)))^(params(18)-1))-(params(20)+x(4))*yh(20))*(yh(10)<=0);
end

end
