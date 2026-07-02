function ecout = makeecPERS(ec)

ecout = ec;

gr          = ecout.gambar*ecout.rhobar;
ecout.btil   = ecout.theta/ecout.R;
ecout.sigbar = (1+ gr)*ecout.sigy/(1 + ecout.btil*gr);
if ec.sigy>0
    ecout.varphi = ecout.dsigydy/ecout.sigy + ec.gambar*(1-ec.btil)/(1+ec.btil*gr);
else
    ecout.varphi = 0;
end

options     = optimoptions('fsolve','Display','off','MaxFunEvals',1e9,'TolFun',1e-12,'TolX',1e-12,'MaxIter',1e9);
[ecout.w,fval]     = fsolve(@(xin) optwPERS(xin,ecout),10,options);
if abs(fval)>1e-9
    warning('david childers')
end


ecout.y     = (1+gr)/(1+gr - ec.rhobar*log(ecout.w));
ecout.sig   = ecout.sigbar*exp(ecout.varphi*(ecout.y-1)); 
ecout.gam   = ecout.gambar/ecout.y;
ecout.rho   = ecout.rhobar*ecout.y;
ecout.mu    = (1-ecout.btil)/(1 + gr*ecout.w);
ecout.sigh  = ecout.w*ecout.sig/(1-ecout.btil*ecout.rhoxi);
ecout.LAM   = ( ecout.gam*ecout.mu*ecout.sigh )^2;
ecout.bet   = (1/ecout.R)*exp(-ecout.LAM/2);
ecout.SIG  = (1-ecout.theta)*exp(ecout.LAM/2)/( 1-ecout.theta*exp(ecout.LAM/2) );


DR       = 1 - (ecout.btil/ecout.bet)*(1-ecout.LAM);  
bb       = ec.btil/ecout.bet;
LAMoversigh = (ecout.gam*ecout.gam*ecout.mu*ecout.mu*ecout.w*ecout.sig/(1-ecout.btil*ecout.rhoxi));


ecout.m3       = 1/(1-ecout.btil);
ecout.m5       = ( (1-bb) )*LAMoversigh/( (1-ecout.btil)*( DR*(1-ecout.rhoxi) + ecout.rhoxi*(1-bb)^2 ) );
ecout.m1       = ecout.sigh*ecout.m5*ecout.btil*(1-ecout.rhoxi)/(1-bb);
ecout.m4       = ecout.gam*( 1 + (1-(1/ecout.bet))*ecout.m1 - ecout.varphi*ecout.m5*ecout.w*ecout.sig/ecout.gam   );


