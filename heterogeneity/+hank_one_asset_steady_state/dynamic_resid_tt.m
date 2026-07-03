function [T_order, T] = dynamic_resid_tt(y, x, params, steady_state, yagg, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 2
    T = [T; NaN(2 - size(T, 1), 1)];
end
T(1) = params(5)/(params(5)-1)/(2*params(6));
T(2) = T(1)*log(1+y(14))^2;
end
