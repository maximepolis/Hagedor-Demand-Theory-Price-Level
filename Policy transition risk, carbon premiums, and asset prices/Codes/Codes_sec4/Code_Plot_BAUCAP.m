graph.t=time.min + (1:time.delta:time.number+1)-1;
T_plot=time.min + 80;
omega=105;
Indicator =NaN;
% Thi following line is to avoid numerical issues at the lower end of the
% grid of rp2. If the grid is fine enough, e.g., 500 grid points in S, this
% line is irrelevant:
entries_ep2_0=find(simulation.S(omega,:)<=0.02);
simulation.ep2(simulation.S<0.02)=NaN;
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
graph.Y=[nanmean(simulation.Y,1);quantile(simulation.Y,0.95,1);quantile(simulation.Y,0.05,1);Indicator*simulation.Y(omega,:);];
graph.nu=[nanmean(simulation.nu,1);quantile(simulation.nu,0.95,1);quantile(simulation.nu,0.05,1);Indicator*simulation.nu(omega,:);];
graph.D=[nanmean(simulation.d,1);quantile(simulation.d,0.95,1);quantile(simulation.d,0.05,1);Indicator*simulation.d(omega,:);];
graph.netemissions=[nanmean(simulation.Emissions-simulation.d,1);quantile(simulation.Emissions-simulation.d,0.95,1);quantile(simulation.Emissions-simulation.d,0.05,1);Indicator*(simulation.Emissions(omega,:)-simulation.d(omega,:));];
graph.pdr1=[nanmean(1./simulation.pdr1,1);quantile(1./simulation.pdr1,0.95,1);quantile(1./simulation.pdr1,0.05,1);Indicator./simulation.pdr1(omega,:);];
graph.pdr2=[nanmean(1./simulation.pdr2,1);quantile(1./simulation.pdr2,0.95,1);quantile(1./simulation.pdr2,0.05,1);Indicator./simulation.pdr2(omega,:);];

%% Graphikparameter definieren
black = [0,0,0];
gray=[0.5,0.5,0.5];
lightgray=[0.7,0.7,0.7];

if (Y0==1)

    transition=figure();
    set(transition,'Units','Pixels','Position',[0 0 400 800]);

    subplot(4,1,4)
    p1=plot(graph.t,graph.output,'black');
    title('d1) Output [trillion USD]', 'FontWeight', 'normal');
    axis([2020  T_plot 0 500])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(4,1,1)
    p1=plot(graph.t,graph.S*100,'black');
    title('a1) Share of Brown Capital / Fossil Fuel [%]', 'FontWeight', 'normal');
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

    subplot(4,1,3)
    p1=plot(graph.t,graph.T,'black');
    title('c1) Temperature [\circC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 5])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(4,1,2)
    p1=plot(graph.t,[graph.netemissions;zeros(1,82)],'black');
    title('b1) Emissions [GtC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 30])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(5),'Color', gray, 'LineStyle','-', 'LineWidth', 0.1);

else
       transition=figure();
    set(transition,'Units','Pixels','Position',[0 0 400 800]);

    subplot(4,1,4)
    p1=plot(graph.t,graph.output,'black');
    title('d2) Output [trillion USD]', 'FontWeight', 'normal');
    axis([2020  T_plot 0 500])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(4,1,1)
    p1=plot(graph.t,graph.S*100,'black');
    title('a2) Share of Brown Capital / Fossil Fuel [%]', 'FontWeight', 'normal');
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

    subplot(4,1,3)
    p1=plot(graph.t,graph.T,'black');
    title('c2) Temperature [\circC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 5])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(4,1,2)
    p1=plot(graph.t,[graph.netemissions;zeros(1,82)],'black');
    title('b2) Emissions [GtC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 30])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(5),'Color', gray, 'LineStyle','-', 'LineWidth', 0.1); 
end