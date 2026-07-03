function f_min=f_min(a)

global opt_run

%% Simulation data
% OPT 2050 OPT 2100
K1_data=[621 3213]';
K2_data=[1722 2022]';
K_data=K1_data+K2_data;
S_data=K2_data./(K2_data+K1_data);

K1_data=[751 3896];
K2_data=[1415 382];
K_data=K1_data+K2_data;
S_data=K2_data./(K2_data+K1_data);

%% data from Rebonato et al. (2023)
% Taking the averages od the optimistic and pessimistic scenario 
% -> our OPT scenario
% The numbers are measured in GtCO2/3.6666 = GtC;
CSS_mid50=[3 6 9 12 15 16.5]/3.66666666667;
CSS_mid100=[6 12 18 24 30 33.5]/3.66666666667;
MAC_data=[105 110 140 200 280 400]*3.66666666667*100;

%% Parametrization of MACs
if opt_run==1
    MAC_50 =a(1)+a(2)*a(3)*S_data(1)^a(4)*exp(a(3)*CSS_mid50 /K_data(1));
    MAC_100=a(1)+a(2)*a(3)*S_data(2)^a(4)*exp(a(3)*CSS_mid100/K_data(2));
else
    MAC_50 =K_data(1)*a(1)*S_data(1)^a(2)+K_data(1)*a(3)*a(4)*S_data(1)^a(5)*exp(a(3)*S_data(1)^a(6)*D);
    MAC_100=K_data(2)*a(1)*S_data(2)^a(2)+K_data(2)*a(3)*a(4)*S_data(2)^a(5)*exp(a(3)*S_data(2)^a(6)*D);
end
%% Goal Function
f_50=(MAC_50./MAC_data-1).^2;
f_100=(MAC_100./MAC_data-1).^2;
f_min=sum(f_50)+sum(f_100);

end

