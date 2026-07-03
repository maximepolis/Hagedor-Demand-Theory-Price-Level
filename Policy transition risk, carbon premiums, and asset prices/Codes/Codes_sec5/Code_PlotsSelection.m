graph.t=time.min + (1:time.delta:time.number+1)-1;
T_plot=time.min + 80;
omega=6;
Indicator =1;
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

%% BAU PLOT
if strcmp(Business_as_usual,'on')==1 || strcmp(transition,'off')==1
    bau=figure();
    set(bau,'Units','Pixels','Position',[0 0 800 800]);
    hold on;

    subplot(4,2,8)
    p1=plot(graph.t,graph.output);
    title('h) Output [trillion USD]', 'FontWeight', 'normal');
    axis([2020  T_plot 0 500])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(4,2,1)
    p1=plot(graph.t,graph.S*100);
    title('a) Share of Brown Capital / Fossil Fuel [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0.0 100])
    yticks(0:25:100)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(4),'Color', black, 'LineStyle',':', 'LineWidth', width);
    legend('mean path', '5% and 95% quantile', '', 'mean energy share')

    subplot(4,2,3)
    p1=plot(graph.t,graph.T);
    title('c) Temperature [\circC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 5])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    subplot(4,2,2)
    p1=plot(graph.t,graph.Emissions);
    title('b) Emissions [GtC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 30])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    subplot(4,2,7)
    p1=plot(graph.t,graph.rf*100);
    title('g) Risk-free Rate [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 1])
    yticks(0:0.25:1)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    subplot(4,2,5)
    p1=plot(graph.t,graph.ep1*100);
    title('e) Green Risk Premium [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 6.25 7.25])
    yticks(6.25:0.25:7.25)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    subplot(4,2,6)
    p1=plot(graph.t,graph.ep2*100);
    title('f) Brown Risk Premium [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 6.25 7.25])
    yticks(6.25:0.25:7.25)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);



    % %% Physical Risk Tipping
    if strcmp(Tipping,'on')==1
        no_state=zeros(time.number+1,tipping.number+1);
        no_tipping=zeros(time.number+1,tipping.number+1);
        for temp_run_t=1:time.number+1
            [~,temp_var1]=find(simulation.X(:,temp_run_t)==1);
            [~,temp_var2]=find(simulation.X(:,temp_run_t)==2);
            [~,temp_var3]=find(simulation.X(:,temp_run_t)==3);

            no_state(temp_run_t,1)=length(temp_var1);
            no_state(temp_run_t,2)=length(temp_var2);
            no_state(temp_run_t,3)=length(temp_var3);

            for temp_run_index=1:tipping.number+1
                [~,temp_tipping]=find(simulation.X(:,temp_run_t)==temp_run_index);
                no_tipping(temp_run_t,temp_run_index)=length(temp_tipping);
            end
        end

        subplot(4,2,4)
        temp_plot=area(graph.t,no_state/simulation.number*100);
        for tipping_counter = tipping.number+1 : -1: 1
            temp_plot(tipping_counter).FaceColor =[1, 1, 1]-(tipping_counter *[1, 1, 1]/(tipping.number+1));
        end
        axis([time.min  T_plot 0 100])
        title('d) Climate Tipping State [%]', 'FontWeight', 'normal');
        legend('Pre-tip state', 'Intermediate state', 'Post-tip state')
        yticks(0:25:100)
    end

    saveas(bau,[save_data_at, 'Simulation_BAU.fig'],'fig');
    exportgraphics(bau,[save_data_at, 'Simulation_BAU.pdf'],'Resolution',1000)

end

%% PIGOU PLOT
if strcmp(Business_as_usual,'off')==1 && strcmp(Policy,'off')==1
    pigou=figure();
    set(pigou,'Units','Pixels','Position',[0 0 800 800]);
    hold on;

    subplot(4,2,8)
    p1=plot(graph.t,graph.output);
    title('h) Output [trillion USD]', 'FontWeight', 'normal');
    axis([2020  T_plot 0 500])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(4,2,1)
    p1=plot(graph.t,graph.S*100);
    title('a) Share of Brown Capital / Fossil Fuel [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0.0 100])
    yticks(0:25:100)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(4),'Color', black, 'LineStyle',':', 'LineWidth', width);
    lgnd=legend('mean path', '5% and 95% quantile', '', 'mean energy share');
    set(lgnd,'color','none');

    subplot(4,2,3)
    p1=plot(graph.t,graph.T);
    title('c) Temperature [\circC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 3])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    subplot(4,2,2)
    p1=plot(graph.t,[graph.netemissions;zeros(1,82)]);
    title('b) Net Emissions [GtC]', 'FontWeight', 'normal');
    axis([time.min  T_plot -10 20])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(5),'Color', gray, 'LineStyle','-', 'LineWidth', 0.1);
    subplot(4,2,7)
    p1=plot(graph.t,graph.rf*100);
    title('g) Risk-free Rate [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 1])
    yticks(0:0.25:1)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    subplot(4,2,5)
    p1=plot(graph.t,graph.ep1*100);
    title('e) Green Risk Premium [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 6.5 7.5])
    yticks(6.5:0.25:7.5)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    subplot(4,2,6)
    p1=plot(graph.t,graph.ep2*100);
    title('f) Brown Risk Premium [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 6.5 7.5])
    yticks(6.5:0.25:7.5)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);



    % %% Physical Risk Tipping
    if strcmp(Tipping,'on')==1
        no_state=zeros(time.number+1,tipping.number+1);
        no_tipping=zeros(time.number+1,tipping.number+1);
        for temp_run_t=1:time.number+1
            [~,temp_var1]=find(simulation.X(:,temp_run_t)==1);
            [~,temp_var2]=find(simulation.X(:,temp_run_t)==2);
            [~,temp_var3]=find(simulation.X(:,temp_run_t)==3);

            no_state(temp_run_t,1)=length(temp_var1);
            no_state(temp_run_t,2)=length(temp_var2);
            no_state(temp_run_t,3)=length(temp_var3);

            for temp_run_index=1:tipping.number+1
                [~,temp_tipping]=find(simulation.X(:,temp_run_t)==temp_run_index);
                no_tipping(temp_run_t,temp_run_index)=length(temp_tipping);
            end
        end

        subplot(4,2,4)
        temp_plot=area(graph.t,no_state/simulation.number*100);
        for tipping_counter = tipping.number+1 : -1: 1
            temp_plot(tipping_counter).FaceColor =[1, 1, 1]-(tipping_counter *[1, 1, 1]/(tipping.number+1));
        end
        axis([time.min  T_plot 0 100])
        title('d) Climate Tipping State [%]', 'FontWeight', 'normal');
        legend('Pre-tip state', 'Intermediate state', 'Post-tip state')
        yticks(0:25:100)
    end

    saveas(pigou,[save_data_at, 'Simulation_BAU.fig'],'fig');
    exportgraphics(pigou,[save_data_at, 'Simulation_BAU.pdf'],'Resolution',1000)

end

%% BENCHMARK PLOTS
if strcmp(Business_as_usual,'off')==1
    markov=figure();
    set(markov,'Units','Pixels','Position',[0 0 800 400]);
    %% a) BAU, OPT, LIM area plot
    no_state=zeros(time.number+1,policy.number+1);
    no_tipping=zeros(time.number+1,policy.number+1);
    for temp_run_t=1:time.number+1
        [~,temp_var1]=find(simulation.Y(:,temp_run_t)==1);
        [~,temp_var2]=find(simulation.Y(:,temp_run_t)==2);
        [~,temp_var3]=find(simulation.Y(:,temp_run_t)==3);

        no_state(temp_run_t,1)=length(temp_var1);
        no_state(temp_run_t,2)=length(temp_var2);
        no_state(temp_run_t,3)=length(temp_var3);

        for temp_run_index=1:tipping.number+1
            [~,temp_tipping]=find(simulation.Y(:,temp_run_t)==temp_run_index);
            no_tipping(temp_run_t,temp_run_index)=length(temp_tipping);
        end
    end

    subplot(2,2,1)
    temp_plot=area(graph.t,no_state/simulation.number*100);
    for tipping_counter = policy.number+1 : -1: 1
        temp_plot(tipping_counter).FaceColor =[1, 1, 1]-(tipping_counter *[1, 1, 1]/(policy.number+1));
    end
    axis([time.min  T_plot 0 100])
    title('a) Policy State [%]', 'FontWeight', 'normal')
    yticks(0:25:100)
    legend('BAU', 'PIGOU', 'CAP')


    %% b) Climate Tipping Plot
    no_state=zeros(time.number+1,tipping.number+1);
    no_tipping=zeros(time.number+1,tipping.number+1);
    for temp_run_t=1:time.number+1
        [~,temp_var1]=find(simulation.X(:,temp_run_t)==1);
        [~,temp_var2]=find(simulation.X(:,temp_run_t)==2);
        [~,temp_var3]=find(simulation.X(:,temp_run_t)==3);

        no_state(temp_run_t,1)=length(temp_var1);
        no_state(temp_run_t,2)=length(temp_var2);
        no_state(temp_run_t,3)=length(temp_var3);

        for temp_run_index=1:tipping.number+1
            [~,temp_tipping]=find(simulation.X(:,temp_run_t)==temp_run_index);
            no_tipping(temp_run_t,temp_run_index)=length(temp_tipping);
        end
    end

    subplot(2,2,2)
    temp_plot=area(graph.t,no_state/simulation.number*100);
    for tipping_counter = tipping.number+1 : -1: 1
        temp_plot(tipping_counter).FaceColor =[1, 1, 1]-(tipping_counter *[1, 1, 1]/(tipping.number+1));
    end
    axis([time.min  T_plot 0 100])
    title('b) Climate Tipping State [%]', 'FontWeight', 'normal');
    legend('Pre-tip State', 'Intermediate State', 'Post-tip State')
    yticks(0:25:100)

    %% c) Breakthrough Plot
    no_state=zeros(time.number+1,breakthrough.number+1);
    no_tipping=zeros(time.number+1,breakthrough.number+1);
    for temp_run_t=1:time.number+1
        [~,temp_var1]=find(simulation.B(:,temp_run_t)==1);
        [~,temp_var2]=find(simulation.B(:,temp_run_t)==2);

        no_state(temp_run_t,1)=length(temp_var1);
        no_state(temp_run_t,2)=length(temp_var2);

        for temp_run_index=1:tipping.number+1
            [~,temp_tipping]=find(simulation.B(:,temp_run_t)==temp_run_index);
            no_tipping(temp_run_t,temp_run_index)=length(temp_tipping);
        end
    end

    subplot(2,2,3)
    temp_plot=area(graph.t,no_state/simulation.number*100);
    temp_plot(1).FaceColor =lightgray;
    temp_plot(2).FaceColor =black;
    axis([time.min  T_plot 0 100])
    legend('Current Technology', 'Negative Emission Technology')
    title('c) Technological State [%]', 'FontWeight', 'normal');
    yticks(0:25:100)
    %% d) temperature area plot
    temp.number=2;
    simulation.Z=simulation.T;
    simulation.Z(simulation.T<1.8)=4;
    simulation.Z(simulation.T>2.5)=3;
    simulation.Z(simulation.Z<3)=2;
    simulation.Z(simulation.Z==4)=1;


    no_state=zeros(time.number+1,temp.number+1);
    no_tipping=zeros(time.number+1,temp.number+1);
    for temp_run_t=1:time.number+1
        [~,temp_var1]=find(simulation.Z(:,temp_run_t)==1);
        [~,temp_var2]=find(simulation.Z(:,temp_run_t)==2);
        [~,temp_var3]=find(simulation.Z(:,temp_run_t)==3);

        no_state(temp_run_t,1)=length(temp_var1);
        no_state(temp_run_t,2)=length(temp_var2);
        no_state(temp_run_t,3)=length(temp_var3);

        for temp_run_index=1:tipping.number+1
            [~,temp_tipping]=find(simulation.Z(:,temp_run_t)==temp_run_index);
            no_tipping(temp_run_t,temp_run_index)=length(temp_tipping);
        end
    end

    subplot(2,2,4)
    temp_plot=area(graph.t,no_state/simulation.number*100);
    for tipping_counter = temp.number+1 : -1: 1
        temp_plot(tipping_counter).FaceColor =[1, 1, 1]-(tipping_counter *[1, 1, 1]/(temp.number+1));
    end
    axis([time.min  T_plot 0 100])
    title('d) Temperature Range [%]', 'FontWeight', 'normal');
    legend('T<1.8\circC', '1.8\circC\leqT<2.5\circC', 'T>2.5\circC')
    yticks(0:25:100)


    %% d) temperature area plot 4 areas
    temp.number=3;
    simulation.Z=simulation.T;
    temp_T=simulation.T;

    simulation.Z(temp_T<1.8)=1;
    temp_T(simulation.Z==1)=NaN;
    simulation.Z(temp_T<2)=2;
    temp_T(simulation.Z==2)=NaN;
    simulation.Z(temp_T<2.5)=3;
    temp_T(simulation.Z==3)=NaN;
    simulation.Z(temp_T>2.5)=4;
    
    no_state=zeros(time.number+1,temp.number+1);
    no_tipping=zeros(time.number+1,temp.number+1);
    for temp_run_t=1:time.number+1
        [~,temp_var1]=find(simulation.Z(:,temp_run_t)==1);
        [~,temp_var2]=find(simulation.Z(:,temp_run_t)==2);
        [~,temp_var3]=find(simulation.Z(:,temp_run_t)==3);
        [~,temp_var4]=find(simulation.Z(:,temp_run_t)==4);

        no_state(temp_run_t,1)=length(temp_var1);
        no_state(temp_run_t,2)=length(temp_var2);
        no_state(temp_run_t,3)=length(temp_var3);
        no_state(temp_run_t,4)=length(temp_var4);

        for temp_run_index=1:4
            [~,temp_tipping]=find(simulation.Z(:,temp_run_t)==temp_run_index);
            no_tipping(temp_run_t,temp_run_index)=length(temp_tipping);
        end
    end

    subplot(2,2,4)
    temp_plot=area(graph.t,no_state/simulation.number*100);
    for tipping_counter = temp.number+1 : -1: 1
        temp_plot(tipping_counter).FaceColor =[1, 1, 1]-(tipping_counter *[1, 1, 1]/(temp.number+1));
    end
    axis([time.min  T_plot 0 100])
    title('d) Temperature Range [%]', 'FontWeight', 'normal');
    legend('T<1.8\circC', '1.8\circC\leqT<2.0\circC', '2.0\circC\leqT<2.5\circC','T>2.5\circC')
    yticks(0:25:100)

    saveas(markov,[save_data_at, 'Simulation_Markov.fig'],'fig');
    exportgraphics(markov,[save_data_at, 'Simulation_Markov.pdf'],'Resolution',1000)


    transition=figure();
    set(transition,'Units','Pixels','Position',[0 0 800 400]);

    subplot(2,2,4)
    p1=plot(graph.t,graph.output,'black');
    title('d) Output [trillion USD]', 'FontWeight', 'normal');
    axis([2020  T_plot 0 500])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(2,2,1)
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

    subplot(2,2,3)
    p1=plot(graph.t,graph.T,'black');
    title('c) Temperature [\circC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 4])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(2,2,2)
    p1=plot(graph.t,[graph.netemissions;zeros(1,82)],'black');
    title('b) Net Emissions [GtC]', 'FontWeight', 'normal');
    axis([time.min  T_plot -10 20])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(5),'Color', gray, 'LineStyle','-', 'LineWidth', 0.1);

    saveas(transition,[save_data_at, 'Simulation_Transition.fig'],'fig');
    exportgraphics(transition,[save_data_at, 'Simulation_Transition.pdf'],'Resolution',1000)


    %% Taxes Plot
    taxes=figure();
    set(taxes,'Units','Pixels','Position',[0 0 800 200]);

    subplot(1,2,1)
    p1=plot(graph.t,graph.tax,'black');
    title('a) Unconditional Carbon Tax [$/tC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 2000])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    if ~isnan(Indicator)
        legend('mean path', '5% and 95% quantile', '', 'sample path');
    else
        legend('mean path', '5% and 95% quantile');
    end

    cond_tax=simulation.tax;
    cond_tax(simulation.Y==1)=NaN;
    graph.cond_tax=[nanmean(cond_tax,1);quantile(cond_tax,0.95,1);quantile(cond_tax,0.05,1);Indicator*cond_tax(omega,:);];

    subplot(1,2,2)
    p1=plot(graph.t,graph.cond_tax,'black');
    title('b) Conditional Carbon Tax [$/tC]', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 2000])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    saveas(taxes,[save_data_at, 'Simulation_Taxes.fig'],'fig');
    exportgraphics(taxes,[save_data_at, 'Simulation_Taxes.pdf'],'Resolution',1000)

    %% Assetpricing Plot
    assetpricing=figure();
    set(assetpricing,'Units','Pixels','Position',[0 0 800 600]);
    subplot(3,2,1)
    p1=plot(graph.t,graph.rf*100, 'black');
    title('a) Risk-free Rate [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot -2 2])
    yticks(-2:1:2)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    if ~isnan(Indicator)
        lgnd=legend('mean path', '5% and 95% quantile', '', 'sample path');
    else
        lgnd=legend('mean path', '5% and 95% quantile');
    end
    set(lgnd,'color','none');

    subplot(3,2,2)
    p1=plot(graph.t,graph.cp*100, 'black');
    title('b) Carbon Premium [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot -1 3])
    yticks(-1:1:3)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(3,2,4)
    p1=plot(graph.t,graph.ep2*100, 'black');
    title('d) Brown Risk Premium [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 6 10])
    yticks(6:1:10)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(3,2,3)
    p1=plot(graph.t,graph.ep1*100, 'black');
    title('c) Green Risk Premium [%]', 'FontWeight', 'normal');
    axis([time.min  T_plot 6 10])
    yticks(6:1:10)
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(3,2,5)
    p1=plot(graph.t,graph.pdr1, 'black');
    title('e) Green Price-dividend Ratio', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 30])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    subplot(3,2,6)
    p1=plot(graph.t,graph.pdr2, 'black');
    title('f) Brown Price-dividend Ratio', 'FontWeight', 'normal');
    axis([time.min  T_plot 0 30])
    set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
    set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
    set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

    saveas(assetpricing,[save_data_at, 'Simulation_AssetPricing.fig'],'fig');
    exportgraphics(assetpricing,[save_data_at, 'Simulation_AssetPricing.pdf'],'Resolution',1000)

end

%saveas(graph.fig,[save_data_at, 'Simulation_Path_',num2str(omega-1),'_State_',num2str(Y0),'.fig'],'fig');
%exportgraphics(graph.fig,[save_data_at, 'Simulation_Path_',num2str(omega-1),'_State_',num2str(Y0),'.pdf'],'Resolution',1000)



% table_intensities=[lambda_pol(temperature.start ,production.S0,1,2), lambda_pol(temperature.start ,production.S0,1,3), lambda_pol(temperature.start ,production.S0,2,3), lambda_pol(temperature.start ,production.S0,2,1), lambda_pol(temperature.start ,production.S0,3,1), lambda_pol(temperature.start ,production.S0,3,2);
%     lambda_pol(2 ,production.S0,1,2), lambda_pol(2 ,production.S0,1,3), lambda_pol(2 ,production.S0,2,3), lambda_pol(2 ,production.S0,2,1), lambda_pol(2 ,production.S0,3,1), lambda_pol(2 ,production.S0,3,2);
% lambda_pol(temperature.start ,0.1,1,2), lambda_pol(temperature.start ,0.1,1,3), lambda_pol(temperature.start ,0.1,2,3), lambda_pol(temperature.start ,0.1,2,1), lambda_pol(temperature.start ,0.1,3,1), lambda_pol(temperature.start ,0.1,3,2);
%     lambda_pol(2 ,0.1,1,2), lambda_pol(2 ,0.1,1,3), lambda_pol(2 ,0.1,2,3), lambda_pol(2 ,0.1,2,1), lambda_pol(2 ,0.1,3,1), lambda_pol(2 ,0.1,3,2);
%     ]


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
    lgnd=legend('mean path', '5% and 95% quantile');
end
set(lgnd,'color','none');

subplot(4,2,3)
p1=plot(graph.t,graph.T,'black');
title('c) Temperature [\circC]', 'FontWeight', 'normal');
axis([time.min  T_plot 0 3])
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
subplot(4,2,2)
p1=plot(graph.t,[graph.netemissions;zeros(1,82)],'black');
title('b) Net Emissions [GtC]', 'FontWeight', 'normal');
axis([time.min  T_plot -10 20])
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(5),'Color', gray, 'LineStyle','-', 'LineWidth', 0.1);
subplot(4,2,5)
p1=plot(graph.t,graph.rf*100,'black');
title('e) Risk-free Rate [%]', 'FontWeight', 'normal');
axis([time.min  T_plot -2 2])
yticks(-2:1:2)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
subplot(4,2,7)
p1=plot(graph.t,graph.ep1*100,'black');
title('g) Green Risk Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot 6 10])
yticks(6:1:10)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
subplot(4,2,8)
p1=plot(graph.t,graph.ep2*100,'black');
title('h) Brown Risk Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot 6 10])
yticks(6:1:10)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

subplot(4,2,6)
p1=plot(graph.t,graph.cp*100, 'black');
title('f) Carbon Premium [%]', 'FontWeight', 'normal');
axis([time.min  T_plot -1 3])
yticks(-1:1:3)
set(p1(1),'Color', black, 'LineStyle','-', 'LineWidth', width);
set(p1(2),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);
set(p1(3),'Color', lightgray, 'LineStyle','--', 'LineWidth', width);

saveas(samplepath,[save_data_at, 'Simulation_Path.fig'],'fig');
exportgraphics(samplepath,[save_data_at, 'Simulation_Path.pdf'],'Resolution',1000)


graph.tax(1,6:25:end)/3.6666
graph.cond_tax(1,6:25:end)/3.6666
graph.cp(1,6:25:end)*100