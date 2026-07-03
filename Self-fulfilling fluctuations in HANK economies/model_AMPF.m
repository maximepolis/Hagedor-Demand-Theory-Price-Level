function dxdt = model_AMPF(t,x,ec)
% x(1) is x, x(2) is pi, x(3) is b^g

PHI = ec.phi_pi-1;
GT  = ec.gam*ec.Theta;

x1dot = PHI*x(2) + ec.sig*(exp(-GT*x(1)) -1);
x2dot = ec.rho.*x(2) - ec.kap*( exp(x(1))-1 );
x3dot = (ec.phi_pi-1)*ec.bstar*x(2) + ec.rbar*(1-ec.phi_b)*x(3) + (ec.phi_pi-1)*x(2)*x(3);

dxdt = [x1dot;
        x2dot;
        x3dot];
        