function dxdt = model_inertial(t,x,ec)
% x(1) is x, x(2) is pi, x(3) is pi^b

GT = ec.gam*ec.Theta;

x1dot = ec.phi_pi*x(3) - x(2) + ec.sig*(exp(-GT*x(1)) -1);
x2dot = ec.rho.*x(2) - ec.kap*( exp(x(1))-1 );
x3dot = ec.alfa*(x(2) - x(3));

dxdt = [x1dot;
        x2dot;
        x3dot];
        