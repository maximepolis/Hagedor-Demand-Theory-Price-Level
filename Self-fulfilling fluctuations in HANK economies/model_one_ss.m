function dxdt = model_one_ss(t,x,ec,threshold)

PHI = ec.phi_pi-1;
GT  = ec.gam*ec.Theta;

if x>threshold
    x1dot = PHI*x(2) + ec.sig*( exp(-GT*x(1)) -1 );
else
    x1dot = PHI*x(2);
end
x2dot =  ec.rho.*x(2) - ec.kap*( exp(x(1)) - 1 );

dxdt = [x1dot;
        x2dot];
        