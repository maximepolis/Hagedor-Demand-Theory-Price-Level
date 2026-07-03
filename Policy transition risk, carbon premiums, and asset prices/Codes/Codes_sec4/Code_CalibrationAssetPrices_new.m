global pref
data.phi=2.6;
pref.delta=0.0346;
pref.gamma=2.977;
pref.psi=1.5;
data.sigma=[0.02 0.02];
pref.theta=(1-pref.gamma)./(1-1/pref.psi);
%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%
data.chi=[0.63 0.63];
data.eta=[0.043 0.043];
data.q=[1.55 1.55];
data.mu=0.0252;
data.T0=1.27;
%%%%%%%%%%%%%%%%%%%%%%%%% Jump Size given Intensity %%%%%%%%%%%%%%
jump.lambda=0.06;
jump.alpha=5;
jump.disaster_threshold=0.1;
% CDF for simulation purposes
jump.density=@(z) jump.alpha.*z.^(jump.alpha-1);
jump.moment=@(n) 1-jump.alpha/(jump.alpha+n);
jump.moment1=@(n) jump.alpha/(jump.alpha+n);
jump.exp_size=jump.moment(1);
jump.disaster_probability=integral(jump.density,0,1-jump.disaster_threshold)*jump.lambda;
jump.exp_size_given_disaster=1-jump.alpha*(1-jump.disaster_threshold)/(jump.alpha+1);
%%%%%%%%%%%%%%%%%%%%%%% Calibration %%%%%%%%%%%%%%%%%%%%%%%%
calib.A=data.q./data.chi.*(pref.delta+(1./pref.psi-1).*(data.mu-0.5*pref.gamma.*data.sigma.^2-jump.lambda./(1-pref.gamma).*jump.moment(1-pref.gamma)));
calib.i=calib.A.*(1-data.chi-data.eta);
calib.theta=(1-1./data.q)./calib.i;
calib.delta_k=calib.i-0.5*calib.theta.*calib.i.^2-data.mu;
%%%%%%%%%%%%%%%%%%%%%% Check %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
check.mu=-calib.delta_k+calib.i-0.5.*calib.theta.*calib.i.^2;
check.mu_net=check.mu-jump.moment(1).*jump.lambda;
check.exp_loss=jump.moment(1).*jump.lambda;
check.r=pref.delta+check.mu./pref.psi-0.5.*pref.gamma*(1+1/pref.psi).*data.sigma.^2-jump.lambda.*(-jump.moment(-pref.gamma))-jump.lambda.*jump.moment(1-pref.gamma).*(1/pref.psi-pref.gamma)/(1-pref.gamma);
check.rp=data.phi*pref.gamma.*data.sigma.^2+(jump.moment1(-pref.gamma)-jump.moment1(data.phi-pref.gamma)+jump.moment1(data.phi)-1)*jump.lambda;
check.y=check.rp+check.r-check.mu_net;
check.pdr=1./check.y;
check.r_star=check.r+pref.gamma.*data.sigma.^2+(jump.moment1(-pref.gamma)-jump.moment1(1-pref.gamma)+jump.moment1(1)-1)*jump.lambda-check.mu_net;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
calib.b=(calib.A-calib.i).^(1/(1-pref.psi)).*(pref.delta./(1-calib.theta.*calib.i)).^(-pref.psi/(1-pref.psi));
calib.v=calib.b(1).^(1-pref.gamma);
calib.phi=data.phi;
