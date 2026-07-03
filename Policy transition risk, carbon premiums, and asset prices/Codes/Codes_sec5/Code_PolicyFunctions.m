q=0.9;

entry_s=[floor(state.number*q),floor(state.number*0.5),floor(state.number*(1-q))];
entry_t=floor(1:temperature.number*temperature.plot/temperature.max);

time.plot=1;

if strcmp(Business_as_usual,'on')==1
    load([save_data_at, 'Solution_bau\Z1_solution_', num2str(time.plot)]);
else
    load([save_data_at, 'Solution_policy\Z1_solution_', num2str(time.plot)]);
end
n=0;
for breakthrough_counter=breakthrough.number+1:-1:1
    for policy_counter=policy.number+1:-1:1
        for tipping_counter=tipping.number+1:-1:1
            n=n+1;
            policy2015.tax=tax_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.q1=Q1_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.q2=Q2_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.rf=rf_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.ep1=ep1_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.ep2=ep2_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.ep2(41,:)=0.5*(policy2015.ep2(40,:)+policy2015.ep2(42,:));
            policy2015.pdr1=pdr1_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.pdr2=pdr2_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.i2=i2_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.i1=i1_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.f2=f2_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.f1=f1_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.g1=g1_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.g2=g2_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.E=f2_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )'.*state.mesh(entry_s,entry_t)'.*temperature.p(1)+f1_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )'.*(1-state.mesh(entry_s,entry_t))'.*temperature.p(1);
            policy2015.r=r_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )';
            policy2015.c=c_s1(entry_s,entry_t, policy_counter,tipping_counter,breakthrough_counter )'/calib.A(1);
            x_axis=temperature.vector(entry_t);
            % Graphen
            graph.fig=figure(n);
            set(graph.fig,'Units','Pixels','Position',[0 0 800 600]);
            % Limits of the x-axis.
            xlim_ = [Inf -Inf];
            % Axes for the plot.
            ax_ = axes;
            set(ax_,'Units','normalized','OuterPosition',[0 0 1 0.75]);
            set(ax_,'Box','on');
            axes(ax_);
            hold on;

            color.brown=[0.3 0.3 0.3];
            color.green=[0.7, 0.7, 0.7];
            color.black=(color.brown+color.green)/2;%[0.25, 0.25, 0.25];

            subplot(3,3,1)
            p1=plot(x_axis, policy2015.c);
            title('a) Consumption Rate, C / Y', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 min(min(policy2015.c))*0.95 max(max(policy2015.c))*1.05])
            subplot(3,3,2)
            p1=plot(x_axis, policy2015.r);
            title('b) Reallocation, r', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 0 max(max(policy2015.r))*1.20+10^(-15)])
            subplot(3,3,3)
            p1=plot(x_axis, policy2015.tax*sum(production.K0)*10^12);
            title('        c) Carbon Tax, \tau', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 0 max(max(policy2015.tax))*sum(production.K0)*10^12*1.05+1])
            subplot(3,3,7)
            p1=plot(x_axis, policy2015.rf);
            title('      g) Risk-free Rate, r_f', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 min(min(policy2015.rf))*0.95 max(max(policy2015.rf))*1.05])


            subplot(3,3,4)
            p1=plot(x_axis, policy2015.f2*production.K0(2)*10^12);
            title('           d) Brown Sector: Fossil Fuel, F_2', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 min(min(policy2015.f2*production.K0(2)*10^12))*0.95 max(max(policy2015.f2*production.K0(2)*10^12))*1.05+10^(-15)])
            subplot(3,3,5)
            p1=plot(x_axis, policy2015.g2*production.K0(2)*10^12);
            title('e) Brown Sector: Renewables, G_2', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 min(min(policy2015.g2*production.K0(2)*10^12))*0.95 max(max(policy2015.g2*production.K0(2)*10^12))*1.05+10^(-15)])
            subplot(3,3,6)
            p1=plot(x_axis, policy2015.g1*production.K0(1)*10^12);
            title(' f) Green Sector: Renewables, G_1', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 min(min(policy2015.g1*production.K0(1)*10^12))*0.95 max(max(policy2015.g1*production.K0(1)*10^12))*1.05+10^(-15)])
            subplot(3,3,8)
            p1=plot(x_axis, policy2015.ep1);
            title(' h) Green Premium, rp_1', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 min(min(policy2015.ep1))*0.95 max(max(policy2015.ep1))*1.05+10^(-15)])
            subplot(3,3,9)
            p1=plot(x_axis, policy2015.ep2);
            title(' j) Dirty Premium, rp_2', 'FontWeight', 'normal');
            set(p1(1),'Color', color.brown, 'LineStyle','-', 'LineWidth', width);
            set(p1(2),'Color', color.black, 'LineStyle','-', 'LineWidth', width);
            set(p1(3),'Color', color.green, 'LineStyle','-', 'LineWidth', width);
            axis([0 4 min(min(policy2015.ep2))*0.95 max(max(policy2015.ep2))*1.05+10^(-15)])
           

            

        end
    end
end





