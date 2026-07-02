function [z, P] = rouwenhorst(n, rho, sigma)
% Rouwenhorst discretization of AR(1): z' = rho z + eps, std(eps)=sigma
    p = (1+rho)/2;
    P = [p 1-p; 1-p p];
    for i = 3:n
        z1 = zeros(i); z1(1:i-1,1:i-1) = P;
        z2 = zeros(i); z2(1:i-1,2:i)   = P;
        z3 = zeros(i); z3(2:i,1:i-1)   = P;
        z4 = zeros(i); z4(2:i,2:i)     = P;
        P  = p*z1 + (1-p)*z2 + (1-p)*z3 + p*z4;
        P(2:i-1,:) = P(2:i-1,:)/2;
    end
    fi  = sigma*sqrt((n-1)/(1-rho^2));
    z   = linspace(-fi, fi, n)';
end