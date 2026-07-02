function out = optw(xin,ec)

w = xin(1);

gr = ec.gambar*ec.rhobar;

y = (1+gr)/(1+gr - ec.rhobar*log(w));

mu = (1-ec.btil)/(1 + gr*w);

gam = ec.gambar/y;

sig = ec.sigbar*exp(ec.varphi*(y-1)); 

LAM = ( gam*mu*w*sig )^2;

THETA = 1 -LAM*ec.varphi/gam;

OMEGA = (THETA-1+LAM)/( 1-LAM );

out = OMEGA - (1-ec.btil)*(w-1)/(1+gr*w) ;

