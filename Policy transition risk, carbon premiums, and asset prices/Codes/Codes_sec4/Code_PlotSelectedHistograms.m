%% I) Interest Rates
histograms=figure(10);
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [1 1 1 1];
conditional=[1 2 1 1;...
             1 2 1 1;...
             1 2 1 1;...
             1 2 1 1;];
plotsize=[2 2];

sgtitle('PIGOU and T<2')
makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')


histograms=figure(11);
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [1 1 1 1];
conditional=[1 2 1 2;...
             1 2 1 2;...
             1 2 1 2;...
             1 2 1 2;];
plotsize=[2 2];

sgtitle('PIGOU and T>2')
makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')

histograms=figure(12);
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [1 1 1 1];
conditional=[1 3 1 1;...
             1 3 1 1;...
             1 3 1 1;...
             1 3 1 1;];
plotsize=[2 2];

sgtitle('CAP and T<2')
makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')

histograms=figure(13);
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [1 1 1 1];
conditional=[1 3 1 2;...
             1 3 1 2;...
             1 3 1 2;...
             1 3 1 2;];
plotsize=[2 2];

sgtitle('CAP and T>2')
makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')




%% II) Carbon Premium
histograms=figure(14);
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [2 2 2 2];
conditional=[1 2 1 1;...
             1 2 1 1;...
             1 2 1 1;...
             1 2 1 1;];
plotsize=[2 2];

sgtitle('PIGOU and T<2')
makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')


histograms=figure(15);
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [2 2 2 2];
conditional=[1 2 1 2;...
             1 2 1 2;...
             1 2 1 2;...
             1 2 1 2;];
plotsize=[2 2];

sgtitle('PIGOU and T>2')
makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')

histograms=figure(16);
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [2 2 2 2];
conditional=[1 3 1 1;...
             1 3 1 1;...
             1 3 1 1;...
             1 3 1 1;];
plotsize=[2 2];

sgtitle('CAP and T<2')
makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')

histograms=figure(17);
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;

year=[6 31 56 81];
variable = [2 2 2 2];
conditional=[1 3 1 2;...
             1 3 1 2;...
             1 3 1 2;...
             1 3 1 2;];
plotsize=[2 2];

sgtitle('CAP and T>2')
makehistogram(variable(1),conditional(1,:),year(1),data,conditions,[plotsize(1) plotsize(2) 1])
title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
makehistogram(variable(2),conditional(2,:),year(2),data,conditions,[plotsize(1) plotsize(2) 2])
title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
makehistogram(variable(3),conditional(3,:),year(3),data,conditions,[plotsize(1) plotsize(2) 3])
title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
makehistogram(variable(4),conditional(4,:),year(4),data,conditions,[plotsize(1) plotsize(2) 4])
title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')