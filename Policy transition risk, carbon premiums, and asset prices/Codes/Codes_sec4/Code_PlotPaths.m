graph.t=time.min + (1:time.delta:time.number+1)-1;
T_plot=time.min + 80;
omega=135;
Indicator =1;
% Thi following line is to avoid numerical issues at the lower end of the
% grid of rp2. If the grid is fine enough, e.g., 500 grid points in S, this
% line is irrelevant:
entries_ep2_0=find(simulation.S(omega,:)<=0.02);
simulation.ep2(simulation.S<0.01)=NaN;
width=1.5;
simulation.Emissions(:,81)=simulation.Emissions(:,80);
graph.output=[nanmean(simulation.Output,1);quantile(simulation.Output,0.95,1);quantile(simulation.Output,0.05,1);Indicator*simulation.Output(omega,:);];
graph.green_capital=[nanmean(simulation.K1,1);quantile(simulation.K1,0.95,1);quantile(simulation.K1,0.05,1);Indicator*simulation.K1(omega,:);];
graph.brown_capital=[nanmean(simulation.K2,1);quantile(simulation.K2,0.95,1);quantile(simulation.K2,0.05,1);Indicator*simulation.K2(omega,:);];
graph.green_investment=[nanmean(simulation.i1,1);quantile(simulation.i1,0.95,1);quantile(simulation.i1,0.05,1);Indicator*simulation.i1(omega,:);];
graph.brown_investment=[nanmean(simulation.i2,1);quantile(simulation.i2,0.95,1);quantile(simulation.i2,0.05,1);Indicator*simulation.i2(omega,:);];
graph.green_investment_rate=[nanmean(simulation.i1./simulation.Output.*simulation.K1,1);quantile(simulation.i1./simulation.Output.*simulation.K1,0.95,1);quantile(simulation.i1./simulation.Output.*simulation.K1,0.05,1);];
graph.brown_investment_rate=[nanmean(simulation.i2./simulation.Output.*simulation.K2,1);quantile(simulation.i2./simulation.Output.*simulation.K2,0.95,1);quantile(simulation.i2./simulation.Output.*simulation.K2,0.05,1);];
graph.T=[nanmean(simulation.T,1);quantile(simulation.T,0.95,1);quantile(simulation.T,0.05,1);Indicator*simulation.T(omega,:);];
graph.S=[nanmean(simulation.S,1);quantile(simulation.S,0.95,1);quantile(simulation.S,0.05,1);1-nanmean(simulation.pi_energy,1);Indicator*simulation.S(omega,:);];
graph.g=[nanmean(simulation.g,1);nanmean(simulation.g,1);quantile(simulation.g,0.95,1);quantile(simulation.g,0.05,1);Indicator*simulation.g(omega,:);];
graph.r=[nanmean(simulation.r.*simulation.K1,1);quantile(simulation.r.*simulation.K1,0.95,1);quantile(simulation.r.*simulation.K1,0.05,1);Indicator*simulation.r(omega,:).*simulation.K1(omega,:);];
graph.tax=[nanmean(simulation.tax,1);quantile(simulation.tax,0.95,1);quantile(simulation.tax,0.05,1);Indicator*simulation.tax(omega,:);];
graph.Emissions=[nanmean(simulation.Emissions,1);quantile(simulation.Emissions,0.95,1);quantile(simulation.Emissions,0.05,1);Indicator*simulation.Emissions(omega,:);];
graph.neg=[nanmean(simulation.neg,1);quantile(simulation.neg,0.95,1);quantile(simulation.neg,0.05,1);Indicator*simulation.neg(omega,:);];
graph.Cumulative_Emissions=[nanmean(simulation.Cumulative_Emissions,1);quantile(simulation.Cumulative_Emissions,0.95,1);quantile(simulation.Cumulative_Emissions,0.05,1);Indicator*simulation.Cumulative_Emissions(omega,:);];
graph.rf=[nanmean(simulation.rf,1);quantile(simulation.rf,0.95,1);quantile(simulation.rf,0.05,1);Indicator*simulation.rf(omega,:);];
graph.q1=[nanmean(simulation.q1,1);quantile(simulation.q1,0.95,1);quantile(simulation.q1,0.05,1);Indicator*simulation.q1(omega,:);];
graph.q2=[nanmean(simulation.q2,1);quantile(simulation.q2,0.95,1);quantile(simulation.q2,0.05,1);Indicator*simulation.q2(omega,:);];
graph.ep1=[nanmean(simulation.ep1,1);quantile(simulation.ep1,0.95,1);quantile(simulation.ep1,0.05,1);Indicator*simulation.ep1(omega,:);];
graph.ep2=[nanmean(simulation.ep2,1);quantile(simulation.ep2,0.95,1);quantile(simulation.ep2,0.05,1);Indicator*simulation.ep2(omega,:);];
graph.cp=[nanmean(simulation.ep2-simulation.ep1,1);quantile(simulation.ep2-simulation.ep1,0.95,1);quantile(simulation.ep2-simulation.ep1,0.05,1);Indicator*simulation.cp(omega,:);];
graph.cp(isnan(graph.ep2))=NaN;
simulation.Y(simulation.Y==3)=2;
graph.Y=[nanmean(simulation.Y,1);quantile(simulation.Y,0.95,1);quantile(simulation.Y,0.05,1);Indicator*simulation.Y(omega,:);];
graph.nu=[nanmean(simulation.nu,1);quantile(simulation.nu,0.95,1);quantile(simulation.nu,0.05,1);Indicator*simulation.nu(omega,:);];
graph.D=[nanmean(simulation.d,1);quantile(simulation.d,0.95,1);quantile(simulation.d,0.05,1);Indicator*simulation.d(omega,:);];
graph.netemissions=[nanmean(simulation.Emissions-simulation.d,1);quantile(simulation.Emissions-simulation.d,0.95,1);quantile(simulation.Emissions-simulation.d,0.05,1);Indicator*(simulation.Emissions(omega,:)-simulation.d(omega,:));];
graph.pdr1=[nanmean(1./simulation.pdr1,1);quantile(1./simulation.pdr1,0.95,1);quantile(1./simulation.pdr1,0.05,1);Indicator./simulation.pdr1(omega,:);];
graph.pdr2=[nanmean(1./simulation.pdr2,1);quantile(1./simulation.pdr2,0.95,1);quantile(1./simulation.pdr2,0.05,1);Indicator./simulation.pdr2(omega,:);];
graph.pdr2(graph.pdr2<1)=0;
graph.pdr2(isnan(graph.ep2))=NaN;
%graph.P1=[nanmean(simulation.div1./simulation.pdr1,1);quantile(simulation.div1./simulation.pdr1,0.95,1);quantile(simulation.div1./simulation.pdr1,0.05,1);Indicator*simulation.div1(omega,:)./simulation.pdr1(omega,:);];
%graph.P2=[nanmean(simulation.div2./simulation.pdr2,1);quantile(simulation.div2./simulation.pdr2,0.95,1);quantile(simulation.div2./simulation.pdr2,0.05,1);Indicator*simulation.div2(omega,:)./simulation.pdr2(omega,:);];
%graph.D1=[nanmean(simulation.div1,1);quantile(simulation.div1,0.95,1);quantile(simulation.div1,0.05,1);Indicator*simulation.div1(omega,:);];
%graph.D2=[nanmean(simulation.div2,1);quantile(simulation.div2,0.95,1);quantile(simulation.div2,0.05,1);Indicator*simulation.div2(omega,:);];
%graph.P1P2=[nanmean(simulation.D1.^2.6./simulation.pdr1./simulation.D2.^2.6.*simulation.pdr2,1);quantile(simulation.D1.^2.6./simulation.pdr1./simulation.D2.^2.6.*simulation.pdr2,0.95,1);quantile(simulation.D1.^2.6./simulation.pdr1./simulation.D2.^2.6.*simulation.pdr2;Indicator*simulation.D1(omega,:).^2.6./simulation.pdr1(omega,:)./simulation.D2(omega,:).^2.6.*simulation.pdr2(omega,:);];
graph.D1=[nanmean(simulation.div1,1);quantile(simulation.div1,0.95,1);quantile(simulation.div1,0.05,1);Indicator*simulation.div1(omega,:);];
graph.D2=[nanmean(simulation.div2,1);quantile(simulation.div2,0.95,1);quantile(simulation.div2,0.05,1);Indicator*simulation.div2(omega,:);];
graph.P1=[nanmean(simulation.div1./simulation.pdr1,1);quantile(simulation.div1./simulation.pdr1,0.95,1);quantile(simulation.div1./simulation.pdr1,0.05,1);Indicator*simulation.div1(omega,:)./simulation.pdr1(omega,:);];
graph.P2=[nanmean(simulation.div2./simulation.pdr2,1);quantile(simulation.div2./simulation.pdr2,0.95,1);quantile(simulation.div2./simulation.pdr2,0.05,1);Indicator*simulation.div2(omega,:)./simulation.pdr2(omega,:);];

%graph.D1=[nanmean(simulation.div1.^leverage.phi.*simulation.K1.^leverage.phi,1);quantile(simulation.div1.^leverage.phi.*simulation.K1.^leverage.phi,0.95,1);quantile(simulation.div1.^leverage.phi.*simulation.K1.^leverage.phi,0.05,1);Indicator*simulation.div1(omega,:).^leverage.phi.*simulation.K1(omega,:).^leverage.phi;];
%graph.D2=[nanmean(simulation.div2.^leverage.phi.*simulation.K2.^leverage.phi,1);quantile(simulation.div2.^leverage.phi.*simulation.K2.^leverage.phi,0.95,1);quantile(simulation.div2.^leverage.phi.*simulation.K2.^leverage.phi,0.05,1);Indicator*simulation.div2(omega,:).^leverage.phi.*simulation.K2(omega,:).^leverage.phi;];
%graph.P1=[nanmean(simulation.div1.^leverage.phi.*simulation.K1.^leverage.phi./simulation.pdr1,1);quantile(simulation.div1.^leverage.phi.*simulation.K1.^leverage.phi./simulation.pdr1,0.95,1);quantile(simulation.div1.^leverage.phi.*simulation.K1.^leverage.phi./simulation.pdr1,0.05,1);Indicator*simulation.div1(omega,:).^leverage.phi.*simulation.K1(omega,:).^leverage.phi./simulation.pdr1(omega,:);];
%graph.P2=[nanmean(simulation.div2.^leverage.phi.*simulation.K2.^leverage.phi./simulation.pdr2,1);quantile(simulation.div2.^leverage.phi.*simulation.K2.^leverage.phi./simulation.pdr2,0.95,1);quantile(simulation.div2.^leverage.phi.*simulation.K2.^leverage.phi./simulation.pdr1,0.05,1);Indicator*simulation.div2(omega,:).^leverage.phi.*simulation.K2(omega,:).^leverage.phi./simulation.pdr2(omega,:);];

%% Graphikparameter definieren
black = [0,0,0];
gray=[0.5,0.5,0.5];
lightgray=[0.7,0.7,0.7];


%% Sample Path PLOT
samplepath=figure();
set(samplepath,'Units','Pixels','Position',[0 0 800 600]);
hold on;

subplot(3,2,4)
p1=plot(graph.t,graph.tax,'black');
title('d) Carbon Tax [$/tC]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 2000])
yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(3,2,1)
p1=plot(graph.t,graph.S*100,'black');
title('a) Share of Brown Capital / Fossil Fuel [%]', 'FontWeight', 'normal');
axis([time.min  T_plot 0.0 100])
yticks(0:25:100)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(4),'Color', black, 'LineStyle',':', 'LineWidth', width);
if ~isnan(Indicator)
    lgnd=legend('mean path', '5% and 95% quantile', '', 'mean energy share', 'sample path');
else
    lgnd=legend('mean path', '5% and 95% quantile', '', 'mean energy share');
end
set(lgnd,'color','none');

subplot(3,2,3)
p1=plot(graph.t,graph.T,'black');
title('c) Temperature [\circC]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 4])
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(3,2,2)
p1=plot(graph.t,[graph.netemissions;zeros(1,82)],'black');
title('b) Net Emissions [GtC]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 30])
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(5),'Color', gray, 'LineStyle','-', 'LineWidth', 0.1);

subplot(3,2,5)
p1=plot(graph.t,[graph.output],'black');
title('e) Output [trillion USD]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 500])
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(3,2,5)
p1=plot(graph.t,[graph.output],'black');
title('e) Output [trillion USD]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 500])
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);


subplot(3,2,6)
p1=plot(graph.t,graph.Y,'black');
title('f) Political State', 'FontWeight', 'normal');
axis([time.min  T_plot 1 2])
yticks(1:1:3)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);



%% Sample Path PLOT
samplepath=figure();
set(samplepath,'Units','Pixels','Position',[0 0 800 800]);
hold on;

subplot(5,2,1)
p1=plot(graph.t,graph.P1/graph.P1(1,1),'black');
title('a) Normalized Green Share Price', 'FontWeight', 'normal');
%set(gca, 'YScale', 'log')
axis([time.min  T_plot 0 50])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
lgnd=legend('mean path', '5% and 95% quantile', '', 'sample path');

subplot(5,2,2)
p1=plot(graph.t,graph.P2/graph.P2(1,1),'black');
title('b) Normalized Brown Share Price', 'FontWeight', 'normal');
axis([time.min  T_plot 0 3])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(5,2,3)
p1=plot(graph.t,graph.D1,'black');
title('c) Normalized Green Dividend', 'FontWeight', 'normal');
%set(gca, 'YScale', 'log')
%axis([time.min  T_plot 0 2000])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(5,2,4)
p1=plot(graph.t,graph.D2,'black');
title('d) Normalized Brown Dividend', 'FontWeight', 'normal');
%axis([time.min  T_plot 0 2000])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(5,2,5)
p1=plot(graph.t,graph.pdr1,'black');
title('e) Green Price-dividend Ratio', 'FontWeight', 'normal');
%axis([time.min  T_plot 0 2000])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(5,2,6)
p1=plot(graph.t,graph.pdr2,'black');
title('f) Brown Price-dividend Ratio', 'FontWeight', 'normal');
axis([time.min  T_plot 0 40])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(5,2,7)
p1=plot(graph.t,graph.ep1*100,'black');
title('g) Green Risk Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot 6 12])
yticks(6:2:12)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(5,2,8)
p1=plot(graph.t,graph.ep2*100,'black');
title('h) Brown Risk Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot 6 12])
yticks(6:2:12)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(5,2,10)
p1=plot(graph.t,graph.cp*100, 'black');
title('j) Carbon Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot -2 6])
yticks(-2:2:6)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(5,2,9)
p1=plot(graph.t,graph.rf*100,'black');
title('i) Risk-free Rate [%]', 'FontWeight', 'normal');
axis([time.min  T_plot -1 2])
yticks(-1:1:2)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

saveas(samplepath,[save_data_at, 'Simulation_Path.fig'],'fig');
exportgraphics(samplepath,[save_data_at, 'Simulation_Path.pdf'],'Resolution',1000)


%% Sample Path PLOT
samplepath=figure();
set(samplepath,'Units','Pixels','Position',[0 0 800 800]);
hold on;

subplot(4,2,4)
p1=plot(graph.t,graph.tax,'black');
title('d) Carbon Tax [$/tC]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 2000])
yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(4,2,1)
p1=plot(graph.t,graph.S*100,'black');
title('a) Share of Brown Capital / Fossil Fuel [%]', 'FontWeight', 'normal');
axis([time.min  T_plot 0.0 100])
yticks(0:25:100)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(4),'Color', black, 'LineStyle',':', 'LineWidth', width);
if ~isnan(Indicator)
    lgnd=legend('mean path', '5% and 95% quantile', '', 'mean energy share', 'sample path');
else
    lgnd=legend('mean path', '5% and 95% quantile', '', 'mean energy share');
end
set(lgnd,'color','none');

subplot(4,2,3)
p1=plot(graph.t,graph.T,'black');
title('c) Temperature [\circC]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 4])
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
subplot(4,2,2)
p1=plot(graph.t,[graph.netemissions;zeros(1,82)],'black');
title('b) Emissions [GtC]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 30])
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(5),'Color', gray, 'LineStyle','-', 'LineWidth', 0.1);
subplot(4,2,5)
p1=plot(graph.t,graph.rf*100,'black');
title('e) Risk-free Rate [%]', 'FontWeight', 'normal');
axis([time.min  T_plot -1 2])
yticks(-1:1:2)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);


subplot(4,2,7)
p1=plot(graph.t,graph.pdr1,'black');
title('g) Green Price-dividend Ratio', 'FontWeight', 'normal');
%axis([time.min  T_plot 0 2000])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(4,2,8)
p1=plot(graph.t,graph.pdr2,'black');
title('h) Brown Price-dividend Ratio', 'FontWeight', 'normal');
axis([time.min  T_plot 0 20])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(4,2,6)
p1=plot(graph.t,graph.cp*100, 'black');
title('f) Carbon Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot -2 6])
yticks(-2:2:6)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

saveas(samplepath,[save_data_at, 'Simulation_Path.fig'],'fig');
exportgraphics(samplepath,[save_data_at, 'Simulation_Path.pdf'],'Resolution',1000)




%% Sample Path PLOT
samplepath=figure();
set(samplepath,'Units','Pixels','Position',[0 0 800 400]);
hold on;

subplot(2,2,1)
p1=plot(graph.t,graph.P1/graph.P1(1,1),'black');
title('a) Normalized Green Share Price', 'FontWeight', 'normal');
%set(gca, 'YScale', 'log')
axis([time.min  T_plot 0 50])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
lgnd=legend('mean path', '5% and 95% quantile', '', 'sample path');

subplot(2,2,2)
p1=plot(graph.t,graph.P2/graph.P2(1,1),'black');
title('b) Normalized Brown Share Price', 'FontWeight', 'normal');
axis([time.min  T_plot 0 3])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(2,2,3)
p1=plot(graph.t,graph.D1,'black');
title('c) Normalized Green Dividend', 'FontWeight', 'normal');
%set(gca, 'YScale', 'log')
%axis([time.min  T_plot 0 2000])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(2,2,4)
p1=plot(graph.t,graph.D2,'black');
title('d) Normalized Brown Dividend', 'FontWeight', 'normal');
%axis([time.min  T_plot 0 2000])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);


samplepath2=figure();
set(samplepath2,'Units','Pixels','Position',[0 0 800 600]);
hold on;

graph.cp(4,68:end)=NaN;
graph.pdr2(4,68:end)=NaN;
graph.ep2(4,68:end)=NaN;
subplot(3,2,1)
p1=plot(graph.t,graph.pdr1,'black');
title('a) Green Price-dividend Ratio', 'FontWeight', 'normal');
%axis([time.min  T_plot 0 2000])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(3,2,2)
p1=plot(graph.t,graph.pdr2,'black');
title('b) Brown Price-dividend Ratio', 'FontWeight', 'normal');
axis([time.min  T_plot 0 40])
%yticks(0:500:2000)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
lgnd=legend('mean path', '5% and 95% quantile', '', 'sample path');
set(lgnd,'color','none');

subplot(3,2,3)
p1=plot(graph.t,graph.ep1*100,'black');
title('c) Green Risk Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot 6 12])
yticks(6:2:12)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(3,2,4)
p1=plot(graph.t,graph.ep2*100,'black');
title('d) Brown Risk Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot 6 12])
yticks(6:2:12)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(3,2,5)
p1=plot(graph.t,graph.cp*100, 'black');
title('e) Carbon Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot -2 6])
yticks(-2:2:6)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(3,2,6)
p1=plot(graph.t,graph.rf*100,'black');
title('f) Risk-free Rate [%]', 'FontWeight', 'normal');
axis([time.min  T_plot -1 2])
yticks(-1:1:2)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

