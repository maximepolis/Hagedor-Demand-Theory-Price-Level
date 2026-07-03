function ecout = makeec(ec)

ecout = ec;
ecout.xihbyxil     = (ecout.dc)^(1/ec.gam);
ecout.sig          = ec.lambar*( ecout.xihbyxil - 1 );
ecout.rho          = ec.rbar + ecout.sig;









