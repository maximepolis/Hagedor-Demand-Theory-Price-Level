function [Upsilon, del, OM, gam, varpi] = make_compstats(ec)

ecout = ec;

gr           = ecout.gambar*ecout.rhobar;
ecout.btil   = ecout.theta/ecout.R;
ecout.sigbar = ec.sigbar;
ecout.varphi = ec.varphi;
ecout.w      = fzero(@(x) optw(x,ecout),[0.1,2]);
ecout.y      = (1+gr)/(1+gr - ec.rhobar*log(ecout.w));
ecout.sig    = ecout.sigbar*exp(ecout.varphi*(ecout.y-1)); 
ecout.gam    = ecout.gambar/ecout.y;
ecout.rho    = ecout.rhobar*ecout.y;
ecout.mu     = (1-ecout.btil)/(1 + gr*ecout.w);
ecout.LAM    = ( ecout.gam*ecout.mu*ecout.w*ecout.sig )^2;
ecout.THETA  = 1 - ecout.LAM*ecout.varphi/ecout.gam;
ecout.OMEGA  = (1-ecout.btil)*(ecout.w-1)/(1+gr*ecout.w);
ecout.bet    = (1/ecout.R)*exp(-ecout.LAM/2);
ecout.SIG    = (1-ecout.theta)*exp(ecout.LAM/2)/( 1-ecout.theta*exp(ecout.LAM/2) );

OS      =  ecout.OMEGA/(1-ecout.btil+ecout.OMEGA);
LS      = (1+ecout.LAM)/(1-ecout.LAM);
dr_z     = 1 - ecout.btil*ecout.rhoz*(1-ecout.LAM);


Upsilon  = 1 + gr*OS*( ecout.OMEGA*( 2/( ecout.LAM*(1-ecout.LAM)  ) - 1)  - 1);
del      = (1/Upsilon)*( 1 + LS*gr*ecout.OMEGA/(dr_z*(1+ecout.rhobar)) );
OM       = ecout.OMEGA; 
gam      = ecout.gam;
varkappa = (1/(1+ecout.rhobar))*(1+((1-ecout.btil)/ec.OMEGA))*ecout.LAM/dr_z;

varpi    = (del - varkappa)/(1-varkappa);



 




