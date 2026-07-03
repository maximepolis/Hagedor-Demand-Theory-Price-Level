%% Clear the workspace
clear;
clear global;
clear all;
clc;
tic;

disp([datestr(now), ': Version 2.0: Pricing Carbon and the Valuation of Green and Dirty Assets']);
disp([datestr(now), ': Start Input']);
global save_data_at
save_data_at = ['C:\saves\Transition Risk\',datestr(now,'yymmdd_HHMM'),'\']; % Matrix-Speicherort
mkdir(save_data_at);
diary([save_data_at, 'Log']) % Diary with commands 
disp([datestr(now), ': Starting Calculations']); 

warning('off','MATLAB:dispatcher:InexactCaseMatch')
warning('off','all') 

%% Numerical Parameters
global production temperature policy tipping breakthrough MCsimulation damages transition 
% Different Model Specifications %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ClimateDisasters='on'; 
CalibrationFigures='on'; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
policy.start=1;
policy.number=2; % bau w/o damages for simulation, and three daamge states (bau, pigou, cap)
tipping.start=1;
tipping.number=2; % pre-tipping and 2 tipping states
breakthrough.start=1;
breakthrough.number=1; % pre-breakthrough and one breakthrough state

% Grid Calibration: DO NOT CHANGE THESE PARAMETERS. 
time.max=2200;
time.min=2020;
temperature.min=0;
temperature.max=5;
temperature.plot=4;
state.min=0.0001;
state.max=0.99;

% Grid Size
temperature.number=50;
state.number=100;
thin.divisor=10;
 
% Numer of Paths for MC-Simulation
simulation.number=20000;
simulation.steps=1; 

%% Model Parameters
MCsimulation=0;
Code_CalibrationAssetPrices_new;
Code_Calibration_DACCS;
production.Aeff= calib.A;
production.phi=calib.theta;
production.xi=0*[0.00068644 0.00068644];
production.delta=calib.delta_k;
production.eta=data.eta;
production.b0=[1.5,1]*540*10^9;
production.sigma=data.sigma;
production.rho12=0;
production.S0=0.876; % Calibrated to match 19.77% renewable energy, World Bank 2020
production.K0=116.*[1-production.S0 production.S0]./production.Aeff;
production.costs=@(i,n) 0.5.*i.^2.*production.phi(n);
pref.rho=[0.5 0.5]; % Golosov
pref.zeta=1./(1-pref.rho);
pref.kappa_green=1;
pref.kappa_brown=0.644; % Golosov
pref.kappa=[pref.kappa_green 1-pref.kappa_brown; 1-pref.kappa_green pref.kappa_brown];
reallocation.kappa=2;
leverage.phi=data.phi;
% Warming
temperature.sigma = 0.03333;
temperature.tcre = 0.0018;
temperature.depreciation = 0.0;
temperature.start = 1.27;

%% Solve for BAU from Trumps point of view (climate denier). It works!
Policy='off'; 
Tipping='off';
Breakthrough='off';
Business_as_usual='on';
damages=0;
MCsimulation=0;
mkdir([save_data_at, 'Solution_bau'])
save_solution_at=[save_data_at, 'Solution_bau','\'];

Code_Initiation;
Code_TerminalCondition;
Code_Solution;
%Code_PolicyFunctions;
damages=1;
MCsimulation=1;
%Code_MonteCarloSimulation;
%Code_PlotsSelection;

%% Solve for all three states from a rational social planner's point of view; 
Policy='on'; 
Tipping='on';
Breakthrough='on';
Business_as_usual='off';
transition='on'; Y0=1;
policy.start=1;
policy.number=2;
policy.start=1;
policy.number=2; 
tipping.start=1;
tipping.number=2; 
breakthrough.start=1;
breakthrough.number=1; 
damages=1;
MCsimulation=0;
mkdir([save_data_at, 'Solution_policy'])
save_solution_at=[save_data_at, 'Solution_policy','\'];

Code_Initiation;
Code_TerminalCondition;
Code_Solution;
damages=1;
MCsimulation=1;
%Code_SurfacePlots;
Code_MonteCarloSimulation;
Code_PlotPaths;

%% Save the Results
%clear actualelapsed ax_ D1 D2 data delta_brown_s1Old delta_brown_s1 delta_green_s1Old delta_brown_s1 dW1 dW2 dWtau elapsed_time entry_s entry_t error f2bau f2tax fitresult foc_i1_solve ft gof iter jump_temp matrix Matrix_LHS n options optresult p1 p2 p3 pdr1_s1Old pdr2_s1Old PDRs PDRss PDRtau PDRstau PDRtautau policy2015 policy_counter q r_s2 reallocation save_solution_at sparse_temp_s sparse_temp_tau tipping_counter U U_pol U_tipp ustility_s1Old ustility_s1prev V Vs Vss Vstau Vtau Vtautau X0 Z z1 z2 zData yData Y0 xlim_ xData temp_s temp_tau tempv1 tempv2 
save([save_data_at, 'Optimal'], '-v7.3');

elapsed_time=toc;
diary off


%clear -regexp ^ep ^f1 ^g1 ^f2 ^g2 ^chi ^delta ^j_ ^r_ ^rf_ ^ci ^cp ^cond ^d_ ^h ^sdf ^temp_ ^V ^jump_ ^K ^lpdr ^mu ^pdr ^tax ^Q ^PDR ^pi ^dW ^entry ^foc ^utility ^scc ^c_ ^i1 ^i2 
%clear elapsed_time actualelapsed tipping_counter policy_counter breakthrough_counter c D1 D2;
%clear elapsed_time actualelapsed tipping_counter policy_counter breakthrough_counter c D1 D2