function dxdt = model_changeeta(t,x,ec)
% x(1) is x, x(2) is pi, x(3) is m

g  = 1/ec.gam;
GT = ec.gam*ec.Theta;
PHI =ec.phi_pi - 1;

x1dot = PHI*x(2) + ec.sig*(exp(-GT*x(1)) -1) -g*ec.lambar*( (exp(-ec.gam*ec.Theta*x(1)) - 1)*(ec.G + (1-ec.G)*(1 - exp(-ec.gam*x(3)) )) + (1/ec.etabar)*(1 - exp(-ec.gam*x(3))) );
x2dot = ec.rho.*x(2) - ec.kap*( exp(x(1) - x(3))-1 );
x3dot = -g*ec.lambar*( (exp(-ec.gam*ec.Theta*x(1)) - 1)*(ec.G + (1-ec.G)*(1 - exp(-ec.gam*x(3)) )) + (1/ec.etabar)*(1 - exp(-ec.gam*x(3))) );





dxdt = [x1dot;
        x2dot;
        x3dot];
        