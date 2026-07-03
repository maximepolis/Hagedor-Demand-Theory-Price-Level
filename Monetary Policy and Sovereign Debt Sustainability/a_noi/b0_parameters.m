% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022, based on codes from GALO NUNO AND BENJAMIN MOLL

% PARAMETERS

parameters.ga     = 1.001;              % CRRA utility with parameter gamma
parameters.zmean  = 0;                  % mean O-U process (in levels)
parameters.mu     = 0.044710898;        % persistence O-U  (comes from the AR(1) estimated for Brazil in the excel file)
parameters.sig    = 0.026818925;        % sigma O-U        (comes from the AR(1) estimated for Brazil in the excel file)
parameters.rho    = 0.128940024624955;  % discount rate, pins down B/Y
parameters.r_bar  = 0.01*4;             % Interest rate
parameters.psi    = 1.870462366375443;  % Rotemberg param (sensitivity to inflation), pins down average inflation

parameters.lambda = 0.263687188143226;  % related to Macaulay debt duration and yield
parameters.delta  = 0.061;              % coupons

parameters.I     = 66;                  % number of a points 
parameters.J     = 49;                  % number of z points 

parameters.amin  = -0.52;               % Range a (beware that this takes negative values and actually starts at the most negative one)
parameters.amax  = 0;             

parameters.zmin  = -0.12;               % Range z
parameters.zmax  =  0.12;

parameters.da    = (parameters.amax-parameters.amin)/(parameters.I-1);
parameters.dz    = (parameters.zmax-parameters.zmin)/(parameters.J-1);

% Default  parameters
parameters.d0    = -0.322986351975180;  % Cost of default, pins down mean and variance of r-rbar
parameters.d1    =  0.360519305075112;  % Cost of default, pins down mean and variance of r-rbar
parameters.chi   = 1/6.5;               % Exlusion parameter  
parameters.theta = 0.5;                 % Surviving share of debt after a partial default episode
parameters.kappa = 0.0;                 % Cost of default, proportional to the amount of debt
parameters.zeta  = 27.772672471389964;  % Cost of inflation, proportional to GDP, pins down inflation variance
parameters.phi   = 8;                   % Default option arrival rate (trick to get a solution for the model, increase as much as possible; >6 is good, 12 or 50 is better but may not converge)

% algorighm parameters
parameters.relaxV  = 0.001;             % relaxation parameter for V
parameters.relaxQ  = 0.010;             % relaxation parameter for Q
parameters.relaxd  = 0.5;               % relaxation parameter for d
parameters.maxit   = 10000;             % maximum number of iterations in the HJB loop
parameters.maxitD  = 4;                 % maximum number of iterations in the outer loop
parameters.crit    = 1e-5;              % criterion HJB loop
parameters.Delta   = 1000;              % delta in HJB algorithm
parameters.critD   = 10;                % criterion outer loop


% observed data

% moments calculated with data from 2001-2019
obs.z0        = -0.0500447115157279;  % value of z at the start of the simulation, when we simulate from 2002 onwards
obs.e_shocks  = [ 2.23703854854913 ; -0.0156598709277965 ; -0.0156598709277965 ; -0.395227456825502 ; -0.0170741048912595 ; -0.0170741048912595 ; 0.817431101561511 ; -0.0139648151376016 ; -0.0139648151376016 ; 0.434127296908176 ; -0.012295265083383 ; -0.012295265083383 ; -1.39116036634928 ; -0.0174327898080836 ; -0.0174327898080836 ; -1.96841250615665 ; -0.0247019610424041 ; -0.0247019610424041 ; 0.314356083672989 ; -0.0234386619087654 ; -0.0234386619087654 ; 0.454888508402877 ; -0.0216564588044034 ; -0.0216564588044034];

obs.a0        = -0.196248454240522*exp(obs.z0);  % value of aY at the start of the simulation, when we simulate from 2002 onwards
obs.aY        = -[ 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.196248454240522 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466 ; 0.179224062182466];
obs.z         = [ -0.0325391934361363 ; -0.0325391934361363 ; -0.0325391934361363 ; -0.0354777893360172 ; -0.0354777893360172 ; -0.0354777893360172 ; -0.0290170859745551 ; -0.0290170859745551 ; -0.0290170859745551 ; -0.0255479761449777 ; -0.0255479761449777 ; -0.0255479761449777 ; -0.0362230903634 ; -0.0362230903634 ; -0.0362230903634 ; -0.0513274912875552 ; -0.0513274912875552 ; -0.0513274912875552 ; -0.048702518510531 ; -0.048702518510531 ; -0.048702518510531 ; -0.0449993301622555 ; -0.0449993301622555 ; -0.0449993301622555];
obs.pi        = [ 0.0761988576963742 ; 0.0751267006102796 ; 0.0774840100274115 ; 0.0798441667346059 ; 0.0776912994559986 ; 0.076614182768588 ; 0.0751303892317854 ; 0.0745969907891686 ; 0.0793112003247778 ; 0.0844517514427594 ; 0.109326240740946 ; 0.125302733566877 ; 0.144669827889006 ; 0.158472963513868 ; 0.165730779893564 ; 0.167693991900039 ; 0.172358493612167 ; 0.165705619446737 ; 0.15429794039921 ; 0.150744540910287 ; 0.151432989583007 ; 0.139836844982107 ; 0.110184550237007 ; 0.0930051280040003];
obs.rdif      = [ 0.16603652173913 ; 0.158458 ; 0.139417142857143 ; 0.158548181818182 ; 0.184605217391304 ; 0.247969047619048 ; 0.265219545454545 ; 0.249944090909091 ; 0.24175619047619 ; 0.288723333333333 ; 0.295987272727273 ; 0.276724545454546 ; 0.2652 ; 0.24859 ; 0.23223 ; 0.21351 ; 0.209892608695652 ; 0.201944761904762 ; 0.183649090909091 ; 0.178097272727273 ; 0.156126666666667 ; 0.147952083333333 ; 0.139188636363636 ; 0.127479545454545];
obs.rdef      = [ 0.0826104347826087 ; 0.0825195 ; 0.0722314285714286 ; 0.0745390909090909 ; 0.0910765217391304 ; 0.129803333333333 ; 0.16461 ; 0.185295454545455 ; 0.179518095238095 ; 0.189794583333333 ; 0.159255 ; 0.144659090909091 ; 0.128133043478261 ; 0.1251145 ; 0.107455238095238 ; 0.0910481818181818 ; 0.08141 ; 0.0788614285714286 ; 0.0808240909090909 ; 0.0798504545454546 ; 0.0717214285714286 ; 0.0677641666666667 ; 0.0616781818181818 ; 0.0548254545454546];
obs.rinf      = [ 0.0834260869565217 ; 0.0759385 ; 0.0671857142857143 ; 0.0840090909090909 ; 0.093528695652174 ; 0.118165714285714 ; 0.100609545454545 ; 0.0646486363636364 ; 0.0622380952380952 ; 0.09892875 ; 0.136732272727273 ; 0.132065454545455 ; 0.137066956521739 ; 0.1234755 ; 0.124774761904762 ; 0.122461818181818 ; 0.128482608695652 ; 0.123083333333333 ; 0.102825 ; 0.0982468181818181 ; 0.0844052380952381 ; 0.0801879166666666 ; 0.0775104545454546 ; 0.0726540909090908];

obs.aY_mean     = -0.0933721092623512;
obs.pi_mean     = 0.0632046874389947;
obs.rdif_mean   = 0.112264504198259;
obs.rinf_mean   = 0.0665483805807914;
obs.rdef_mean   = 0.0457161236174676;

obs.aY_std      = 0.0486226968270697;
obs.pi_std      = 0.0266307066903917;
obs.rdif_std    = 0.0462978770471928;
obs.rinf_std    = 0.022529660454977;
obs.rdef_std    = 0.029341705608116;

obs.aY_m         =     obs.aY(end-12);
obs.rdif_m       = min(obs.rdif(1:end-12));
obs.rdef_m       = min(obs.rdef(1:end-12));
obs.rinf_m       = min(obs.rinf(1:end-12));
obs.pi_m         = min(obs.pi(1:end-12));

obs.aY_M         =     obs.aY(end);
obs.rdif_M       = max(obs.rdif(1:end));
obs.rdef_M       = max(obs.rdef(1:end));
obs.rinf_M       = max(obs.rinf(1:end));
obs.pi_M         = max(obs.pi(1:end));

obs.aY_up         = obs.aY_M   - obs.aY_m   ;
obs.rdif_up       = obs.rdif_M - obs.rdif_m ;
obs.rdef_up       = obs.rdef_M - obs.rdef_m ;
obs.rinf_up       = obs.rinf_M - obs.rinf_m ;
obs.pi_up         = obs.pi_M   - obs.pi_m   ;

% obs contains the full episode, parameters.obs contains only the part we simulate with the model

parameters.obs=obs;

skipper=11; % skip the first observations, to set the sample actually simualted with the model
if skipper>0
    parameters.obs.z0        = obs.z(skipper,1);
    parameters.obs.e_shocks  = obs.e_shocks(skipper+1:end);
    parameters.obs.a0        = obs.aY(skipper,1)*exp(obs.z(skipper,1));
    parameters.obs.aY        = obs.aY(skipper+1:end);
    parameters.obs.z         = obs.z(skipper+1:end);
    parameters.obs.pi        = obs.pi(skipper+1:end);
    parameters.obs.rdif      = obs.rdif(skipper+1:end);
    parameters.obs.rdef      = obs.rdef(skipper+1:end);
    parameters.obs.rinf      = obs.rinf(skipper+1:end);
end


