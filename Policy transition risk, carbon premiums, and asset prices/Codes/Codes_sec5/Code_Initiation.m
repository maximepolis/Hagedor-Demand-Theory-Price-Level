production.A=(production.Aeff.*(production.eta./production.b0(2)).^(production.eta./(production.eta-1))).^(1-production.eta)./D(temperature.start,policy.start,tipping.start)./[pref.kappa(1,1), pref.kappa(2,2)].^(production.eta./pref.rho);
intensity.lambda=jump.lambda;

%% Time Grid
time.number = (time.max-time.min)*simulation.steps;
time.delta = (time.max-time.min)/time.number;
time.vector = (time.min:time.delta:time.max)';

%% For the Plots
width = 2;
xAxis=2015:time.delta:2115;
color.black = [0,0,0];
color.darkgray=[0.25,0.25,0.25];
color.gray=[0.5,0.5,0.5];
color.lightgray=[0.75,0.75,0.75];

%% Energy Costs
global policy tipping pref production budget breakthrough
production.b=zeros(2,time.number+1);
production.b(:,1)=production.b0;
production.b(2,:)=production.b(2,1);
production.b(1,:)=production.b(1,1);

%% Calibration Initial Energy Share (19.77% in 2020)
z1=(pref.kappa(1,1).*production.b(2)./pref.kappa(2,1)./(production.b(1,:))).^(1/(pref.rho(1)-1));
z2=(pref.kappa(1,2).*production.b(2)./pref.kappa(2,2)./(production.b(1,:))).^(1/(pref.rho(2)-1));
g1=((production.b(1,:))./(production.eta(1)*production.A(1).*(pref.kappa(1,1)+pref.kappa(2,1).*z1.^pref.rho(1)).^(production.eta(1)/pref.rho(1)-1).*pref.kappa(1,1))).^(1/(production.eta(1)-1));
g2=((production.b(1,:))./(production.eta(2)*production.A(2).*(pref.kappa(1,2)+pref.kappa(2,2).*z2.^pref.rho(2)).^(production.eta(2)/pref.rho(2)-1).*pref.kappa(1,2))).^(1/(production.eta(2)-1));
f1=g1.*z1;
f2=g2.*z2;
pi_energy=(g1.*production.K0(1)+g2.*production.K0(2))./((f1+g1).*production.K0(1)+(f2+g2).*production.K0(2));
disp(pi_energy(1));

%% S data (no abatement motive) under various assumptions: 
% rho=0.5, kappa=2, Swanson's Law, No damages
S =[0.875999999999984	0.873731748618786	0.871502381298040	0.869193721787712	0.866884543680243	0.864539235869856	0.862183775355939	0.859817535860244	0.857404379414004	0.854994244696317	0.852585591688187	0.850178193280701	0.847709839328362	0.845218442374405	0.842757433831704	0.840218275914209	0.837637549934277	0.835105271053837	0.832524926630889	0.829959712748892	0.827355119552735	0.824744131434438	0.822101945257027	0.819493850668632	0.816845562377026	0.814204328608192	0.811579011844447	0.808833519873806	0.806118232180957	0.803409346177303	0.800666675529222	0.797952065181123	0.795169291106414	0.792395048232800	0.789641676400775	0.786860082295916	0.783997735658187	0.781168828226081	0.778399649561335	0.775525659079787	0.772662604721859	0.769868357232434	0.766963874707727	0.764012147856475	0.761078445189642	0.758179509441356	0.755303815483887	0.752359667878982	0.749467199041932	0.746556753502869	0.743584855633091	0.740641433851171	0.737734962145847	0.734790979366437	0.731841508718125	0.728956579368386	0.726049344394528	0.723098457951841	0.720155337134449	0.717213713316746	0.714265190252735	0.711278102343045	0.708323966405976	0.705333310862126	0.702419766049361	0.699450941024521	0.696507328679008	0.693486424631894	0.690492099068948	0.687469811741332	0.684540166860138	0.681639279044405	0.678717863341061	0.675827675433206	0.672898470932194	0.669985681689279	0.667056504538403	0.664052458288892	0.661090476813787	0.658134754673722	0.655274787430848];
Su =[0.876000000000000	0.878845197335332	0.878799357987913	0.878188916901945	0.877236906671839	0.876328410056711	0.875198257749221	0.873988621359650	0.872511093003384	0.871308629152524	0.869838641915940	0.868488071670843	0.867004854598077	0.865450980897999	0.864148938218955	0.862626497944707	0.861025573516750	0.859634235945784	0.857587798319474	0.855958890564266	0.854386856580015	0.852619033180509	0.850689609811962	0.848952949569963	0.847350529369019	0.845577223164672	0.843624969116383	0.841892703281083	0.839920235547371	0.838099850315731	0.836192780472117	0.834439518134918	0.832664077717191	0.830685972176122	0.828712821559012	0.826747031865158	0.824632007248392	0.822482300361433	0.820707020144147	0.818958036586462	0.816632369136425	0.814405686897892	0.812865194490879	0.810571342076100	0.808449653061553	0.806871239301824	0.804423739620187	0.802215004784064	0.800117989408887	0.798095973263416	0.795853983209414	0.793732512712124	0.791697857218139	0.789299323722521	0.787669870197158	0.785518198876755	0.783383943458801	0.781181062952252	0.778985498641816	0.776955988614660	0.774825617474866	0.772247466421530	0.770263150263501	0.767792358268081	0.765703490859770	0.763348760140705	0.760963990954467	0.758491992813519	0.756655332744006	0.754402870714636	0.751987034071353	0.750131584806604	0.747843235992211	0.745320370713863	0.743532783100683	0.741263827503245	0.739415786737636	0.736483522212109	0.734274454087409	0.731767614751227	0.729255256201622];
Sd =[0.876000000000000	0.868528579732371	0.864146731150531	0.859957661159421	0.856103913563566	0.852320624466458	0.848462438195148	0.844774822131027	0.841320001532181	0.837616141735739	0.833886970568462	0.830224244493354	0.826875705154474	0.823095181872639	0.819365560743877	0.815897624001988	0.812501052421913	0.809061554208457	0.805209450109255	0.801878882305874	0.798376326394752	0.794714405872052	0.791149409069692	0.787402914157600	0.783787752733659	0.780305904813963	0.776404725152144	0.772601272989344	0.769136151235548	0.765224244614813	0.761860637171173	0.757779074391797	0.754193548623781	0.750608421715670	0.746578694157447	0.742645089784289	0.739207302170698	0.735265681693110	0.731873565414328	0.727929638912700	0.723577709639951	0.719900872066326	0.716448548601568	0.712496606569976	0.708514269673158	0.704520044715309	0.700567944457620	0.697190195357933	0.693366155100605	0.689225465008732	0.685376651456548	0.681452843473543	0.677892382313528	0.674502184886566	0.670442308235932	0.666947582305848	0.663235326790171	0.659313450419956	0.655938730930018	0.651751530640624	0.648219828794844	0.644521733345912	0.640643045342927	0.636822362611497	0.633174324603821	0.629439891756484	0.625679969051239	0.621823408389141	0.618453970994289	0.614870151199390	0.611326087066874	0.607515431722016	0.604201592517916	0.600881698638571	0.597214966431512	0.593516131553993	0.589785149489904	0.586276733645576	0.582691778271511	0.579670271041749	0.576408123004387];
S_data=S([1 11 21 31 41 51 61 71 81]);
rcp_time=[2020	2030	2040	2050	2060	2070	2080	2090	2100];
rcp_data=[12.444	14.554	17.432	20.781	24.097	26.374	27.715	28.531	28.817];
modified_rcp_data=rcp_data*10/rcp_data(1); 

%% Emissions
z1=(pref.kappa(1,1).*production.b(2)./pref.kappa(2,1)./(production.b(1,1:81).*cost_scaling(1,S))).^(1/(pref.rho(1)-1));
z2=(pref.kappa(1,2).*production.b(2)./pref.kappa(2,2)./(production.b(1,1:81).*cost_scaling(1,S))).^(1/(pref.rho(2)-1));
g1=((production.b(1,1:81).*cost_scaling(1,S))./(production.eta(1)*production.A(1).*(pref.kappa(1,1)+pref.kappa(2,1).*z1.^pref.rho(1)).^(production.eta(1)/pref.rho(1)-1).*pref.kappa(1,1))).^(1/(production.eta(1)-1));
g2=((production.b(1,1:81).*cost_scaling(1,S))./(production.eta(2)*production.A(2).*(pref.kappa(1,2)+pref.kappa(2,2).*z2.^pref.rho(2)).^(production.eta(2)/pref.rho(2)-1).*pref.kappa(1,2))).^(1/(production.eta(2)-1));
f1=g1.*z1;
f2=g2.*z2;
f2bau_data=f2([1 11 21 31 41 51 61 71 81]);

P_data=modified_rcp_data./(S_data.*f2bau_data);
time_data=rcp_time-2020;
[p, Output] = polyfit(time_data,P_data,3);

temperature.p=    p(4) +   p(3)*(time.vector-time.min) +  p(2)*(time.vector-time.min).^2 +  p(1)*(time.vector-time.min).^3;
temperature.p(81:end)=temperature.p(81);
sim_time=2020:2100;
sim_emissions=temperature.p(1:81).*S(1:81)'.*f2(1:81)';
sim_emissions_u=temperature.p(1:81).*Su(1:81)'.*f2(1:81)';
sim_emissions_d=temperature.p(1:81).*Sd(1:81)'.*f2(1:81)';

if strcmp(CalibrationFigures,'on')==1
    figure(1)
    subplot(1,2,1)
    scatter(rcp_time,P_data, 'black')
    hold on
    p1=plot(sim_time, temperature.p(1:81));
    set(p1(1),'Color', color.black, 'LineStyle','-', 'LineWidth', 1.5);
    title('a) p(t), Polynomial Fit', 'FontWeight', 'normal');
    legend('Simulated data', 'Polynomial fit')
    subplot(1,2,2)
    scatter(rcp_time,modified_rcp_data, 'black')
    hold on
    p1=plot(sim_time, [sim_emissions sim_emissions_u sim_emissions_d]');
    set(p1(1),'Color', color.black, 'LineStyle','-', 'LineWidth', 1.5);
    set(p1(2),'Color', color.lightgray, 'LineStyle','--', 'LineWidth', 1.5);
    set(p1(3),'Color', color.lightgray, 'LineStyle','--', 'LineWidth', 1.5);
    axis([2020 2100 8 30])
    title('b) BAU Emissions [GtC]', 'FontWeight', 'normal');
    legend('mod. RCP8.5 data', 'Median path', '90%-CI')
end

%% State Grid
state.delta = (state.max-state.min)/state.number;
state.vector = (state.min:state.delta:state.max)';

%% Markov chains
X0=1;
Y0=1;
B0=1;
if strcmp(Tipping,'on')==1
    tipping.vector=1:tipping.number+1;
else
    tipping.number=0;
    tipping.vector=1:tipping.number+1;
end
if strcmp(Breakthrough,'on')==1
    breakthrough.vector=1:breakthrough.number+1;
else
    breakthrough.number=0;
    breakthrough.vector=1:breakthrough.number+1;
end
if strcmp(Policy,'on')==1
    policy.vector=1:policy.number+1;
else
    policy.number=0;
    policy.vector=1:policy.number+1;
end


%% Temperature Grid
temperature.delta = (temperature.max-temperature.min)/temperature.number;
temperature.vector = (temperature.min:temperature.delta:temperature.max)';

[temperature.mesh,state.mesh] = meshgrid(temperature.vector,state.vector);

if  strcmp(Policy,'on')==1
    budget.temperature=2;
    budget.k=floor((budget.temperature-temperature.min)./temperature.delta)+1;
    %temperature.sigma=0;
end
%% Sparse Grid
thin.temperature.number=temperature.number/thin.divisor;
thin.state.number=state.number/thin.divisor;
thin.temperature.delta=(temperature.max-temperature.min)/thin.temperature.number;
thin.state.delta=(state.max-state.min)/thin.state.number;
thin.temperature.vector=(temperature.min:thin.temperature.delta:temperature.max)';
thin.state.vector = (state.min:thin.state.delta:state.max)';
[thin.temperature.mesh,thin.state.mesh] = meshgrid(thin.temperature.vector,thin.state.vector);
thin.investment_green_s1 = 0.06*thin.state.mesh./thin.state.mesh;

%% r refers to what remains after a disaster shock, i.e., l=1-r is the relative GDP loss; the calibration is taken from Barro, Jin
intensity.alpha=jump.alpha;
% CDF for simulation purposes
intensity.func_cdf=@(z) z.^intensity.alpha;
intensity.func_inv_cdf=@(y) y.^(1/intensity.alpha);
% PDF
intensity.func_density=@(z) intensity.alpha*z.^(intensity.alpha-1);
% Expected Loss
intensity.func_expected_loss=@(z)intensity.alpha*z.^intensity.alpha;
intensity.expected_loss=1-integral(intensity.func_expected_loss,0,1);
% Term in HJB Equation
intensity.expected_loss_power=1-jump.moment(1-pref.gamma);
% Term in Pricing PDE Equation
intensity.expected_loss_power_omega=1-jump.moment(data.phi-pref.gamma);
% Term in Risk-free Rate
intensity.rf_adjustment=-jump.moment(-pref.gamma)+jump.moment(1-pref.gamma)*(1/pref.psi-pref.gamma)/(1-pref.gamma);
% Jump Risk Premium
intensity.func_sdf_adjustment=@(z) intensity.alpha.*z.^(intensity.alpha-1).*z.^(-pref.gamma);
intensity.sdf_adjustment=integral(intensity.func_sdf_adjustment,0,1);

%% r refers to what remains after a disaster shock, i.e., l=1-r is the relative GDP loss; the calibration is taken from Barro, Jin
% climate indicator is zero if we are in the BAU state (like climate
% denying, but only for policy making. Financial markets are more prudent
% than Trump and price in climate risks.
climate.alpha= 65.7;
if strcmp(ClimateDisasters,'off')==1 %|| (MCsimulation==0 && damages==0)
    climate.lambda0=0;
    climate.lambda1=0;
    climate.lambda=0;
    climate.indicator=@(policy) 0;
else
    climate.lambda0=0;
    climate.lambda1=0.096;
    climate.lambda=climate.lambda0+climate.lambda1*temperature.mesh;
    if (MCsimulation==0 && damages==0)
        climate.indicator=@(policy) 0;
    else
        climate.indicator=@(policy) 1;
    end
end
climate.moment=@(n) 1-climate.alpha/(climate.alpha+n);
% CDF for simulation purposes
climate.func_cdf=@(z) z.^climate.alpha;
climate.func_inv_cdf=@(y) y.^(1/climate.alpha);
% PDF
climate.func_density=@(z) climate.alpha*z.^(climate.alpha-1);
% Expected Loss
climate.func_expected_loss=@(z)climate.alpha*z.^climate.alpha;
climate.expected_loss=1-integral(climate.func_expected_loss,0,1);
% Term in HJB Equation
climate.expected_loss_power=1-climate.moment(1-pref.gamma);
% Term in Pricing PDE Equation
climate.expected_loss_power_omega=1-climate.moment(data.phi-pref.gamma);
% Term in Risk-free Rate
climate.rf_adjustment=-climate.moment(-pref.gamma)+climate.moment(1-pref.gamma)*(1/pref.psi-pref.gamma)/(1-pref.gamma);
% Jump Risk Premium
climate.func_sdf_adjustment=@(z) climate.alpha.*z.^(climate.alpha-1).*z.^(-pref.gamma);
climate.sdf_adjustment=integral(climate.func_sdf_adjustment,0,1);

%% Brownian Motions and Increments
rng(1)
dW1=randn(simulation.number,time.number)*time.delta;
rng(2)
dW2=randn(simulation.number,time.number)*time.delta;
rng(3)
dWtau=randn(simulation.number,time.number)*time.delta;
rng(4)
U=rand(simulation.number,time.number+1);
rng(5)
Uc=rand(simulation.number,time.number+1);
rng(6)
Z=1-intensity.func_inv_cdf(rand(simulation.number,time.number+1));
rng(7)
Zc=1-climate.func_inv_cdf(rand(simulation.number,time.number+1));
rng(8)
U_pol_forward=rand(simulation.number,time.number+1);
rng(9)
U_pol_backward=rand(simulation.number,time.number+1);
rng(10)
U_tipp=rand(simulation.number,time.number+1);
rng(11)
U_tipp2=rand(simulation.number,time.number+1);
rng(12)
U_bt=rand(simulation.number,time.number+1);
%% Variation
state.variation=...
    production.sigma(1).^2+2.*production.sigma(1).*production.sigma(2).*production.rho12+production.sigma(2).^2;
capital.variation=...
    (1-state.mesh).^2.*production.sigma(1).^2+state.mesh.^2.*production.sigma(2).^2+2.*state.mesh.*(1-state.mesh).*production.sigma(1).*production.sigma(2).*production.rho12;
capital.covariation=...
    -(1-state.mesh).*production.sigma(1).^2+state.mesh.*production.sigma(2).^2+(1-2.*state.mesh).*production.sigma(1).*production.sigma(2).*production.rho12;
temperature.variation=temperature.sigma.^2.*temperature.mesh(:,:).^2;

%% Initialize Grid
[j_Omega1z, j_Omega2z, j_chi1z, j_chi2z, j_vb, j_cb, j_vz, j_cz, j_vx, j_cx, delta_brown_s1, delta_brown_s1Old, delta_green_s1, delta_green_s1Old, d_s1, chi1_s1, chi2_s1, pdr1_s1, pdr2_s1, utility_s1, r_s1, r_s2, i1_s1, i2_s1, c_s1, g1_s1, g2_s1, f1_s1, f2_s1, emissions_s1]  = deal(zeros(state.number+1, temperature.number+1, policy.number+1, tipping.number+1, breakthrough.number+1));        % Create Indirect Utility , consumption, and portfolio matrix with dimension (Wealth+1)x(HousePrice+1)x(House Square m)
[PDRs, PDRtau, PDRstau, PDRss, PDRtautau, Vs, Vtau, Vstau, Vss, Vtautau] = deal(zeros(state.number+1, temperature.number+1, policy.number+1, tipping.number+1, breakthrough.number+1));
[pi_energy_s1,pi_s1,ep1_s1,ep2_s1,pdr2_s1,pdr1_s1,rf_s1] = deal(zeros(state.number+1, temperature.number+1, policy.number+1, tipping.number+1, breakthrough.number+1));






