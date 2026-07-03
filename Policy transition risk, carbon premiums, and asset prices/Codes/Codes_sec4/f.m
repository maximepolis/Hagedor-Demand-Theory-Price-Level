function f=f(delta, gamma, psi, theta, c, J, p)
    
    if psi==1
        f=delta*(1-gamma)*J*(log(c/p)*p-log((1-gamma)*J)/(1-gamma));
    else
        f=delta*theta*J*((c/p/(J*(1-gamma))^(1/(1-gamma)))^(1-1/psi)*p-1);
    end
end