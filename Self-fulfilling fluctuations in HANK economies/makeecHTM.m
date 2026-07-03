function ecout = makeecHTM(ec)

ecout = ec;
ecout.xihbyxil     = (ecout.dc)^(1/ec.gam);
ecout.sig          = ec.lambar*( ecout.xihbyxil - 1 );
ecout.rho          = ec.rbar + ecout.sig;
ecout.G         = (1-ec.etabar)*(ec.dc-1)/(1 + (1-ec.etabar)*(ec.dc-1));
ecout.sigbar    = ec.lambar*(ecout.xihbyxil - 1 - (1/ec.gam)*ecout.G);



