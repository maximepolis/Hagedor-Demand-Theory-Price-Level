function ecout = makeecHTM(ec)

ecout = ec;

gr          = ecout.gambar*ecout.rhobar;
ecout.btil   = ecout.theta/ecout.R;
ecout.sigbar = (1+ gr)*ecout.sigy/(1 + ecout.btil*gr);
if ec.sigy>0
    ecout.varphi = ecout.dsigydy/ecout.sigy + ec.gambar*(1-ec.btil)/(1+ec.btil*gr);
else
    ecout.varphi = 0;
end

options     = optimset('TolX',1e-20,'TolFun',1e-20);

ecout.w     = fzero(@(xin) optwHTM(xin,ecout),[0.1,30],options);

ecout.y     = (1+gr)/(1+gr - ec.rhobar*log(ecout.w));
ecout.sig   = ecout.sigbar*exp(ecout.varphi*(ecout.y-1)); 
ecout.gam   = ecout.gambar/ecout.y;
ecout.rho   = ecout.rhobar*ecout.y;
ecout.mu    = (1-ecout.btil)/(1 + gr*ecout.w);
ecout.muHTM = 1/(1 + gr*ecout.w);
ecout.LAM   = ( ecout.gam*ecout.mu*ecout.w*ecout.sig )^2;
ecout.bet   = (1/ecout.R)*exp(-ecout.LAM/2);
ecout.SIGnh = (1-ecout.theta)*exp(ecout.LAM/2)/( 1-ecout.theta*exp(ecout.LAM/2) );
ecout.SIGh  = exp(0.5*ecout.LAM/( (1-ecout.btil)^2 ));
ecout.SIG   =  (1 - ecout.eta)*ecout.SIGnh + ecout.eta*ecout.SIGh;


