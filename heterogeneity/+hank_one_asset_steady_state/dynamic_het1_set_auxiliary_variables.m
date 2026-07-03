function yh = dynamic_het1_set_auxiliary_variables(y, x, params, steady_state, yh, xh, paramsh, step)
%
% Sets auxiliary variables for heterogeneous model dimension 1
% step: level of auxiliary variables to compute (0-based)
%

if step == 0
    yh(11)=yh(7)^((-1)/params(3));
end

if step == 1
    yh(12)=(yh(7)^((-1)/params(3))-params(1)*(1+y(27))*yh(17))*(yh(10)<=0);
end

end
