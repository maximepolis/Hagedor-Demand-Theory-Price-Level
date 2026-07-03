function Gval = eval_G(m,ec)


% omemgm = 1- exp(-ec.gam*m);
% 
% A = ec.etabar*ec.G + ec.etabar*(1-ec.G)*omemgm;
% 
% gtinv = 1/(ec.gam*ec.Theta);
% 
% Gval = -(ec.rho*ec.upvarsig*omemgm/A) + ec.kap*(ec.phi_pi-1)*( (A^(gtinv))*exp(-m)/( (A - omemgm)^gtinv )  - 1);


Omega = -(1/(ec.gam*ec.Theta))*log( 1 - (1/ec.etabar)*(1-exp(-ec.gam*m))/(ec.G + (1-ec.G)*(1-exp(-ec.gam*m)) ) );

Gval = ec.kap*(ec.phi_pi-1)*(exp(Omega - m) - 1) - ec.rho*ec.sig*(1-exp(-ec.gam*m))/(ec.etabar*ec.G + ec.etabar*(1-ec.G)*(1-exp(-ec.gam*m)));


