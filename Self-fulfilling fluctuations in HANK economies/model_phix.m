function dxdt = model_phix(t,x,ec)

PHI = ec.phi_pi-1;
GT  = ec.gam*ec.Theta;


x1dot = PHI*x(2) + ec.phi_x*x(1)+ ec.sig*( exp(-GT*x(1)) -1 );
x2dot =  ec.rho.*x(2) - ec.kap*( exp(x(1)) - 1 );

dxdt = [x1dot;
        x2dot];
        