%% Simulation data (needs to be recalibrated)
global NET opt_run
% OPT 2050 OPT 2100
K1_data=[751 3896];
K2_data=[1415 382];
K_data=K1_data+K2_data;
S_data=K2_data./(K2_data+K1_data);

%% data from Rebonato et al. (2023)
% Taking the averages od the optimistic and pessimistic scenario 
% -> our OPT scenario
% The numbers are measured in GtCO2/3.6666 = GtC;
CSS_mid50=[3 6 9 12 15 16.5]/3.66666666667;
CSS_mid100=[6 12 18 24 30 33]/3.66666666667;
MAC_data=[105 110 140 200 280 400]*3.6666666667*100;

%% Minimization
opt_run=1;
NET.a=fmincon(@f_min,[100 0.5 0.5 0.5],[],[],[],[],[0 0 0 0],[]);
NET.zeta=0.1;

if strcmp(CalibrationFigures,'on')==1
    figure(2)
    subplot(1,2,1)
    scatter(CSS_mid50,MAC_data, 'black')
    hold on
    p1=plot((0:1:17)/3.6666, MAC(S_data(1),(0:1:17)/3.6666,NET.a,K_data(1)));
    set(p1(1),'Color', [0 0 0], 'LineStyle','-', 'LineWidth', 1.5);
    title('a) Marginal costs in 2050 [$/tC] ', 'FontWeight', 'normal');
    xlabel('Carbon Removal [GtC]')
    legend('Rebonato et al. (2023) data', 'Exponential fit')
    axis([0 16.5/3.6666 0 1600])

    subplot(1,2,2)
    scatter(CSS_mid100,MAC_data, 'black')
    hold on
    p1=plot((0:1:34)/3.6666, MAC(S_data(2),(0:1:34)/3.6666,NET.a,K_data(2)));
    set(p1(1),'Color', [0 0 0], 'LineStyle','-', 'LineWidth', 1.5);
    title('b) Marginal costs in 2100 [$/tC] ', 'FontWeight', 'normal');
    xlabel('Carbon Removal [GtC]')
    axis([0 33.5/3.6666 0 1600])
end

opt_run=2;
% This fits a MAC of the form
% MAC=a(1)+a(2)*a(3)*S^a(4)*exp(a(3)*D/K);
% But we need a function that is homogeneous of degree one in K:
% MAC=K*b(1)*S^b(2)+K*b(3)*b(4)*S^b(5)*exp(b(3)*S^b(6)*D);
NET.b=ones(1,6);
% Now, a(1) is constant:
% K*b(1)*S^b(2) = a(1), i.e., K(2)/K(1)*(S(2)/S(1))^b(2)=1;
NET.b(2)=log(K_data(1)/K_data(2))/log(S_data(2)/S_data(1));
NET.b(1)=NET.a(1)/(K_data(1)*S_data(1).^NET.b(2));
% Furthermore, we have a(3)/K=b(3)*S^b(6), i.e., K(2)/K(1)*(S(2)/S(1))^b(6)=1;
NET.b(6)=NET.b(2);
NET.b(3)=NET.a(3)/(K_data(1)*S_data(1).^NET.b(6));
% Finally, K*b(3)*b(4)*S^b(5)=a(2)*a(3)*S^a(4)
% K(1)/K(2)*(S(1)/S(2))^b(5)=(S(1)/S(2))^a(4)
% b(5) = log(K(2)/K(1)/(S(2)/S(1))^a(4))/log(S(1)/S(2))
NET.b(5)= log(K_data(2)/K_data(1)/(S_data(2)/S_data(1))^NET.a(4))/log(S_data(1)/S_data(2));
NET.b(4)= NET.a(2)*NET.a(3)*S_data(2)^NET.a(4)/(K_data(2)*NET.b(3)*S_data(2)^NET.b(5));
NET.b(3)=1;
NET.a=NET.b;

NET.a(1)=NET.a(1)*10^(-3);
NET.a(4)=NET.a(4)*10^(-3);