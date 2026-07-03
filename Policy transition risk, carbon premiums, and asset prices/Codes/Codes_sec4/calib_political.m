function calib_political=calib_political(x)

global policy lambda12 lambda13 lambda23 lambda32 lambda31 lambda21 mu_plus mu_minus nu_plus nu_minus

lambda12=x(1);
lambda13=x(2);
lambda23=x(3);
lambda32=x(4);
lambda31=x(5);
lambda21=x(6);
mu_plus=x(7);
mu_minus=x(8);
nu_plus=x(9);
nu_minus=x(10);

disp(x)

Code_Calibration_PoliticalEconomy_aux;
Code_MonteCarloSimulation;

Calibration_targets=[0.48 0.28 0.24];
Calibration_outcome=[opt_percent lim_percent bau_percent];

calib_political=sum(((Calibration_outcome-Calibration_targets)./Calibration_targets).^2);

disp(calib_political)

end

