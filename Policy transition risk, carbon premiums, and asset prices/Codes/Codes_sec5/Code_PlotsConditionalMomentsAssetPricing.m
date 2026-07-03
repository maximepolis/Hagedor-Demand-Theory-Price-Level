data=NaN(simulation.number, time.number+1, 7);
conditions=NaN(simulation.number, time.number+1, 4);
% Thi following line is to avoid numerical issues at the lower end of the
% grid of rp2. If the grid is fine enough, e.g., 500 grid points in S, this
% line is irrelevant:
simulation.ep2(simulation.S<0.02)=NaN;

data(:,:,1)=simulation.rf;
data(:,:,2)=simulation.ep1;
data(:,:,3)=simulation.ep2;
data(:,:,4)=simulation.cp;
data(:,:,5)=simulation.pdr1.^(-1);
data(:,:,6)=simulation.pdr2.^(-1);
data(:,:,7)=simulation.tax;
conditions(:,:,1)=simulation.X;
conditions(:,:,2)=simulation.Y;
conditions(:,:,3)=simulation.B;
conditions(:,:,4)=simulation.T;
conditions(:,:,5)=simulation.S;

%% Conditioned on the Climate Tipping State
simulation.rf_conditional_tipping=NaN(simulation.number, time.number+1, 4);
simulation.ep1_conditional_tipping=NaN(simulation.number, time.number+1, 4);
simulation.ep2_conditional_tipping=NaN(simulation.number, time.number+1, 4);
simulation.cp_conditional_tipping=NaN(simulation.number, time.number+1, 4);
simulation.pdr1_conditional_tipping=NaN(simulation.number, time.number+1, 4);
simulation.pdr2_conditional_tipping=NaN(simulation.number, time.number+1, 4);
rf_conditional_tipping=NaN(3, 4);
ep1_conditional_tipping=NaN(3, 4);
ep2_conditional_tipping=NaN(3, 4);
cp_conditional_tipping=NaN(3, 4);
pdr1_conditional_tipping=NaN(3, 4);
pdr2_conditional_tipping=NaN(3, 4);

for cond_index=1:3
    
    simulation.rf_temp=simulation.rf;
    simulation.ep1_temp=simulation.ep1;
    simulation.ep2_temp=simulation.ep2;
    simulation.cp_temp=simulation.cp;
    simulation.pdr1_temp=simulation.pdr1.^(-1);
    simulation.pdr2_temp=simulation.pdr2.^(-1);

    if cond_index==1     % conditioned on X=1
        simulation.rf_temp(simulation.X~=1)=NaN;
        simulation.ep1_temp(simulation.X~=1)=NaN;
        simulation.ep2_temp(simulation.X~=1)=NaN;
        simulation.cp_temp(simulation.X~=1)=NaN;
        simulation.pdr1_temp(simulation.X~=1)=NaN;
        simulation.pdr2_temp(simulation.X~=1)=NaN;
    elseif cond_index==2 % conditioned on X=2
        simulation.rf_temp(simulation.X~=2)=NaN;
        simulation.ep1_temp(simulation.X~=2)=NaN;
        simulation.ep2_temp(simulation.X~=2)=NaN;
        simulation.cp_temp(simulation.X~=2)=NaN;
        simulation.pdr1_temp(simulation.X~=2)=NaN;
        simulation.pdr2_temp(simulation.X~=2)=NaN;
    elseif cond_index==3 % conditioned on X=3
        simulation.rf_temp(simulation.X~=3)=NaN;
        simulation.ep1_temp(simulation.X~=3)=NaN;
        simulation.ep2_temp(simulation.X~=3)=NaN;
        simulation.cp_temp(simulation.X~=3)=NaN;
        simulation.pdr1_temp(simulation.X~=3)=NaN;
        simulation.pdr2_temp(simulation.X~=3)=NaN;
    end
    simulation.rf_conditional_tipping(:,:,cond_index)=simulation.rf_temp;
    simulation.ep1_conditional_tipping(:,:,cond_index)=simulation.ep1_temp;
    simulation.ep2_conditional_tipping(:,:,cond_index)=simulation.ep2_temp;
    simulation.cp_conditional_tipping(:,:,cond_index)=simulation.cp_temp;
    simulation.pdr1_conditional_tipping(:,:,cond_index)=simulation.pdr1_temp;
    simulation.pdr2_conditional_tipping(:,:,cond_index)=simulation.pdr2_temp;

    for time_index=1:4
        year=[2025 2050 2075 2100]-2020+1;
        nbins=[10 40 40];

        rf_conditional_tipping(cond_index,time_index)=100*round(nanmean(simulation.rf_conditional_tipping(:,year(time_index),cond_index)),4);
        ep1_conditional_tipping(cond_index,time_index)=100*round(nanmean(simulation.ep1_conditional_tipping(:,year(time_index),cond_index)),4);
        ep2_conditional_tipping(cond_index,time_index)=100*round(nanmean(simulation.ep2_conditional_tipping(:,year(time_index),cond_index)),4);
        cp_conditional_tipping(cond_index,time_index)=100*round(nanmean(simulation.cp_conditional_tipping(:,year(time_index),cond_index)),4);
        pdr1_conditional_tipping(cond_index,time_index)=round(nanmean(simulation.pdr1_conditional_tipping(:,year(time_index),cond_index)),2);
        pdr2_conditional_tipping(cond_index,time_index)=round(nanmean(simulation.pdr2_conditional_tipping(:,year(time_index),cond_index)),2);
    end
end



%% Conditioned on the Political State
simulation.rf_conditional_pol=NaN(simulation.number, time.number+1, 4);
simulation.ep1_conditional_pol=NaN(simulation.number, time.number+1, 4);
simulation.ep2_conditional_pol=NaN(simulation.number, time.number+1, 4);
simulation.cp_conditional_pol=NaN(simulation.number, time.number+1, 4);
simulation.pdr1_conditional_pol=NaN(simulation.number, time.number+1, 4);
simulation.pdr2_conditional_pol=NaN(simulation.number, time.number+1, 4);
rf_conditional_pol=NaN(3, 4);
ep1_conditional_pol=NaN(3, 4);
ep2_conditional_pol=NaN(3, 4);
cp_conditional_pol=NaN(3, 4);
pdr1_conditional_pol=NaN(3, 4);
pdr2_conditional_pol=NaN(3, 4);

for cond_index=1:3
    
    simulation.rf_temp=simulation.rf;
    simulation.ep1_temp=simulation.ep1;
    simulation.ep2_temp=simulation.ep2;
    simulation.cp_temp=simulation.cp;
    simulation.pdr1_temp=simulation.pdr1.^(-1);
    simulation.pdr2_temp=simulation.pdr2.^(-1);

    if cond_index==1     % conditioned on Y=1
        simulation.rf_temp(simulation.Y~=1)=NaN;
        simulation.ep1_temp(simulation.Y~=1)=NaN;
        simulation.ep2_temp(simulation.Y~=1)=NaN;
        simulation.cp_temp(simulation.Y~=1)=NaN;
        simulation.pdr1_temp(simulation.Y~=1)=NaN;
        simulation.pdr2_temp(simulation.Y~=1)=NaN;
    elseif cond_index==2 % conditioned on X=2
        simulation.rf_temp(simulation.Y~=2)=NaN;
        simulation.ep1_temp(simulation.Y~=2)=NaN;
        simulation.ep2_temp(simulation.Y~=2)=NaN;
        simulation.cp_temp(simulation.Y~=2)=NaN;
        simulation.pdr1_temp(simulation.Y~=2)=NaN;
        simulation.pdr2_temp(simulation.Y~=2)=NaN;
    elseif cond_index==3 % conditioned on X=3
        simulation.rf_temp(simulation.Y~=3)=NaN;
        simulation.ep1_temp(simulation.Y~=3)=NaN;
        simulation.ep2_temp(simulation.Y~=3)=NaN;
        simulation.cp_temp(simulation.Y~=3)=NaN;
        simulation.pdr1_temp(simulation.Y~=3)=NaN;
        simulation.pdr2_temp(simulation.Y~=3)=NaN;
    end
    simulation.rf_conditional_pol(:,:,cond_index)=simulation.rf_temp;
    simulation.ep1_conditional_pol(:,:,cond_index)=simulation.ep1_temp;
    simulation.ep2_conditional_pol(:,:,cond_index)=simulation.ep2_temp;
    simulation.cp_conditional_pol(:,:,cond_index)=simulation.cp_temp;
    simulation.pdr1_conditional_pol(:,:,cond_index)=simulation.pdr1_temp;
    simulation.pdr2_conditional_pol(:,:,cond_index)=simulation.pdr2_temp;

    for time_index=1:4
        year=[2025 2050 2075 2100]-2020+1;
        nbins=[10 40 40];

        rf_conditional_pol(cond_index,time_index)=100*round(nanmean(simulation.rf_conditional_pol(:,year(time_index),cond_index)),4);
        ep1_conditional_pol(cond_index,time_index)=100*round(nanmean(simulation.ep1_conditional_pol(:,year(time_index),cond_index)),4);
        ep2_conditional_pol(cond_index,time_index)=100*round(nanmean(simulation.ep2_conditional_pol(:,year(time_index),cond_index)),4);
        cp_conditional_pol(cond_index,time_index)=100*round(nanmean(simulation.cp_conditional_pol(:,year(time_index),cond_index)),4);
        pdr1_conditional_pol(cond_index,time_index)=round(nanmean(simulation.pdr1_conditional_pol(:,year(time_index),cond_index)),2);
        pdr2_conditional_pol(cond_index,time_index)=round(nanmean(simulation.pdr2_conditional_pol(:,year(time_index),cond_index)),2);
    end
end

%% Conditioned on the technological State
simulation.rf_conditional_break=NaN(simulation.number, time.number+1, 4);
simulation.ep1_conditional_break=NaN(simulation.number, time.number+1, 4);
simulation.ep2_conditional_break=NaN(simulation.number, time.number+1, 4);
simulation.cp_conditional_break=NaN(simulation.number, time.number+1, 4);
simulation.pdr1_conditional_break=NaN(simulation.number, time.number+1, 4);
simulation.pdr2_conditional_break=NaN(simulation.number, time.number+1, 4);
rf_conditional_break=NaN(2, 4);
ep1_conditional_break=NaN(2, 4);
ep2_conditional_break=NaN(2, 4);
cp_conditional_break=NaN(2, 4);
pdr1_conditional_break=NaN(2, 4);
pdr2_conditional_break=NaN(2, 4);

for cond_index=1:2
    
    simulation.rf_temp=simulation.rf;
    simulation.ep1_temp=simulation.ep1;
    simulation.ep2_temp=simulation.ep2;
    simulation.cp_temp=simulation.cp;
    simulation.pdr1_temp=simulation.pdr1.^(-1);
    simulation.pdr2_temp=simulation.pdr2.^(-1);

    if cond_index==1     % conditioned on Y=1
        simulation.rf_temp(simulation.B~=1)=NaN;
        simulation.ep1_temp(simulation.B~=1)=NaN;
        simulation.ep2_temp(simulation.B~=1)=NaN;
        simulation.cp_temp(simulation.B~=1)=NaN;
        simulation.pdr1_temp(simulation.B~=1)=NaN;
        simulation.pdr2_temp(simulation.B~=1)=NaN;
    elseif cond_index==2 % conditioned on X=2
        simulation.rf_temp(simulation.B~=2)=NaN;
        simulation.ep1_temp(simulation.B~=2)=NaN;
        simulation.ep2_temp(simulation.B~=2)=NaN;
        simulation.cp_temp(simulation.B~=2)=NaN;
        simulation.pdr1_temp(simulation.B~=2)=NaN;
        simulation.pdr2_temp(simulation.B~=2)=NaN;
    end
    simulation.rf_conditional_break(:,:,cond_index)=simulation.rf_temp;
    simulation.ep1_conditional_break(:,:,cond_index)=simulation.ep1_temp;
    simulation.ep2_conditional_break(:,:,cond_index)=simulation.ep2_temp;
    simulation.cp_conditional_break(:,:,cond_index)=simulation.cp_temp;
    simulation.pdr1_conditional_break(:,:,cond_index)=simulation.pdr1_temp;
    simulation.pdr2_conditional_break(:,:,cond_index)=simulation.pdr2_temp;

    for time_index=1:4
        year=[2025 2050 2075 2100]-2020+1;
        nbins=[10 40 40];

        rf_conditional_break(cond_index,time_index)=100*round(nanmean(simulation.rf_conditional_break(:,year(time_index),cond_index)),4);
        ep1_conditional_break(cond_index,time_index)=100*round(nanmean(simulation.ep1_conditional_break(:,year(time_index),cond_index)),4);
        ep2_conditional_break(cond_index,time_index)=100*round(nanmean(simulation.ep2_conditional_break(:,year(time_index),cond_index)),4);
        cp_conditional_break(cond_index,time_index)=100*round(nanmean(simulation.cp_conditional_break(:,year(time_index),cond_index)),4);
        pdr1_conditional_break(cond_index,time_index)=round(nanmean(simulation.pdr1_conditional_break(:,year(time_index),cond_index)),2);
        pdr2_conditional_break(cond_index,time_index)=round(nanmean(simulation.pdr2_conditional_break(:,year(time_index),cond_index)),2);
    end
end

%% Table 
% Table4b=[...
% Year(1)    ;
% Year(2)    ;
% Year(3)    ;
% Year(4)    ;
%     ];


%% Histograms
figure_counter=10;
histograms=figure(figure_counter);
figure_counter=figure_counter+1;
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [4 4 4 4];
% CAP, Temperature between 1.8 and 2 degrees, S(brown)>10%
%conditional=[0 3 0 3 2;...
%             0 3 0 3 2;...
%             0 3 0 3 2;...
%             0 3 0 3 2;];

conditional=[0 0 1 0 0;...
             0 0 1 0 0;...
             0 0 1 0 0;...
             0 0 1 0 0;];

unconditional=[0 0 2 0 0;...
             0 0 2 0 0;...
             0 0 2 0 0;...
             0 0 2 0 0;];

plotsize=[2 2];

% makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
% title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
% makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
% title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
% makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
% title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
% makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
% title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')

makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
hold on 
makehistogram(variable(1),unconditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
hold on 
makehistogram(variable(2),unconditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
hold on 
makehistogram(variable(3),unconditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
hold on 
makehistogram(variable(4),unconditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')

