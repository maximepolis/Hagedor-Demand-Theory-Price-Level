function ecout = makeec(ec)

ecout = ec;

gr          = ecout.gambar*ecout.rhobar;
ecout.btil   = ecout.theta/ecout.R;
ecout.sigbar = (1+ gr)*ecout.sigy/(1 + ecout.btil*gr);
if ec.sigy>0
    ecout.varphi = ecout.dsigydy/ecout.sigy + ecout.gambar*(1-ecout.btil)/(1+ecout.btil*gr);
else
    ecout.varphi = 0;
end

ecout.w      = fzero(@(x) optw(x,ecout),[0.1,20]);
ecout.y      = (1+gr)/(1+gr - ec.rhobar*log(ecout.w));
ecout.sig    = ecout.sigbar*exp(ecout.varphi*(ecout.y-1)); 
ecout.gam   = ecout.gambar/ecout.y;
ecout.rho   = ecout.rhobar*ecout.y;
ecout.mu    = (1-ecout.btil)/(1 + gr*ecout.w);
ecout.LAM   = ( ecout.gam*ecout.mu*ecout.w*ecout.sig )^2;
ecout.THETA = 1 - ecout.LAM*ecout.varphi/ecout.gam;
ecout.OMEGA = (1-ecout.btil)*(ecout.w-1)/(1+gr*ecout.w);
ecout.bet   = (1/ecout.R)*exp(-ecout.LAM/2);
ecout.SIG   = (1-ecout.theta)*exp(ecout.LAM/2)/( 1-ecout.theta*exp(ecout.LAM/2) );










