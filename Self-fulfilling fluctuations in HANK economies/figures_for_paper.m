% Code for "Self Fulfilling Fluctuations in HANK economies"
% produces Figure 2a, 2b, 3a, 3b in the paper 
%---------------------------------------------------------



%% Parameters
ec.rbar      = 0.04;
ec.lambar    = 0.0131;
ec.dc        = 1.1;
ec.gam       = 1/2;
ec.Theta     = 28.1;
ec.phi_pi    = 1.50;
ec.kap       = 0.01;
ec           = makeec(ec);

%IS curve nullcline in the baseline
FIS = @(x,ec1) - ec1.sig.*( exp(-ec1.gam*ec1.Theta*x) -1 )/(ec1.phi_pi-1);
%PC nullcline in the baseline
FPC = @(x,ec1) (ec1.kap/ec1.rho).*( exp(x) -1 );

%function defining steady state x
F = @(x,ec1) (ec1.phi_pi-1)*(ec1.kap/ec1.rho)*(exp(x)-1) + ec1.sig*( exp(-ec1.gam*ec1.Theta*x) - 1);

A0 = @(ec1) [ ec1.phi_x- ec1.sig*ec1.gam*ec1.Theta, ec1.phi_pi-1; -ec1.kap, ec1.rho];

Abad = @(ec1,xx) [ ec1.phi_x- ec1.sig*ec1.gam*ec1.Theta*exp(-ec1.gam*ec1.Theta*xx), ec1.phi_pi-1; -ec1.kap*exp(xx), ec1.rho];


%% Phase diagram in acyclical risk case (Figure 2a)



ecACY = ec;
ecACY.Theta = 0;
ecACY = makeec(ecACY);

lw = 2;
nx = 100;
xmin = -0.175;
xmax = 0.06;
xgrid = linspace(xmin, xmax, nx);
tmax = 150;  tspan = 0:tmax;

[~, xs]  = ode45(@(t, x) model(t, x, ecACY), tspan,  [0.008, 0.0001]);

figure('Position', [100, 100, 500, 500], 'Color', 'w')
plot(xgrid, FIS(xgrid, ecACY), 'k-.', 'LineWidth', lw); 
hold on
plot(xgrid, FPC(xgrid, ecACY), 'k:', 'LineWidth', lw);
plot(0,0,'ko','MarkerSize',7,'MarkerFaceColor','k');
plot(xs(:,1),  xs(:,2),  'k', 'LineWidth', lw,'Color',[0.6 0.6 0.6]);           
xline(0,'k:','LineWidth',0.5)
yline(0,'k:','LineWidth',0.5)
xlim([xmin xmax])
ylim([-0.03 0.01])
xticks([-0.11 -0.09 -0.04 0 0.03 0.06])
yticks([-0.03 -0.02 -0.01 0 0.01])
set(gca,'FontSize',12,'LineWidth',1,'Box','off')
text(-0.1, 0.0012, '$\dot{x}=0$', 'Interpreter','latex','FontSize',20)
text(0.043, 0.009, '$\dot{\pi}=0$', 'Interpreter','latex','FontSize',20)
text(-0.04, -0.02, 'divergent', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
text(-0.04, -0.022, 'trajectory', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
ax = gca;
ax.Position = [0.1304 0.1100 0.7746 0.8150];
pos = ax.Position;  
text_data = [-0.01, -0.019]; 
target_data = [0.01, -0.012]; 
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color',[0.6 0.6 0.6], 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);

num_arrows = 3;
arrow_indices = round(linspace(70, length(xs)-15, num_arrows));
ax = gca;
pos = ax.Position;
drawnow;
for i = 1:num_arrows
    start_point = xs(arrow_indices(i), :);
    end_point   = xs(arrow_indices(i)+1, :);
    start_norm = [(start_point(1)-ax.XLim(1))/diff(ax.XLim), ...
                  (start_point(2)-ax.YLim(1))/diff(ax.YLim)];
    end_norm   = [(end_point(1)-ax.XLim(1))/diff(ax.XLim), ...
                  (end_point(2)-ax.YLim(1))/diff(ax.YLim)];
    start_norm = min(max(start_norm, 0), 1);
    end_norm   = min(max(end_norm, 0), 1);
    start_fig = pos(1:2) + start_norm.*pos(3:4);
    end_fig   = pos(1:2) + end_norm.*pos(3:4);
    annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
               'Color',[0.6 0.6 0.6], 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);
end
xlabel('$x$','Interpreter','latex','FontSize',24)
ylabel('$\pi$','Interpreter','latex','FontSize',24)

print(gcf, 'Figure2a.eps', '-depsc', '-r600');

%% Hopf supercritical cycle (Figure 2b)

xtil   = fzero( @(x) F(x,ec),[-1,-0.001]);
pigtil = FPC(xtil,ec);
tmax = 115;  
tspan = 0:tmax;
tmax1 = 500; 
tspan1 = 0:tmax1;
lw = 2;
nx = 100;
xgrid = linspace(1.1*xtil, 0.08, nx);

[~, xs]  = ode45(@(t, x) model(t, x, ec), tspan,  [-0.0472, -0.0027]);
[~, xs1] = ode45(@(t, x) model(t, x, ec), tspan1, [0.015, 0]);

figure('Position', [100, 100, 500, 500], 'Color', 'w')
plot(xgrid, FIS(xgrid, ec), 'k-.', 'LineWidth', lw); 
hold on
plot(xgrid, FPC(xgrid, ec), 'k:', 'LineWidth', lw);
plot(0,0,'ko','MarkerSize',7,'MarkerFaceColor','k') 
plot(xtil,pigtil,'ko','MarkerSize',7,'MarkerFaceColor','k')
plot(xs(:,1),  xs(:,2),  'k', 'LineWidth', lw);           % stable cycle
plot(xs1(:,1), xs1(:,2), 'Color',[0.6 0.6 0.6],'LineWidth', lw); % converging path
xline(0,'k:','LineWidth',0.5)
yline(0,'k:','LineWidth',0.5)
xlim([-0.145 0.06])
ylim([-0.031 0.01])
yticks([-0.03 -0.02 -0.01 0 0.01])
xticks([-0.14 -0.09 -0.04 0 0.03 0.06])
set(gca,'FontSize',12,'LineWidth',1,'Box','off')
xlabel('$x$','Interpreter','latex','FontSize',24)
ylabel('$\pi$','Interpreter','latex','FontSize',24)


ax = gca;  % current axes
ax.Position = [0.1304 0.1100 0.7746 0.8150];
pos = ax.Position;
num_arrows = 3;
indices1 = round(linspace(15, length(xs1)-1, num_arrows));
for i = 1:num_arrows
    start_point1 = xs1(indices1(i), :);
    end_point1   = xs1(indices1(i) + 1, :);
    start_norm = [(start_point1(1)-ax.XLim(1))/diff(ax.XLim), ...
                  (start_point1(2)-ax.YLim(1))/diff(ax.YLim)];
    end_norm   = [(end_point1(1)-ax.XLim(1))/diff(ax.XLim), ...
                  (end_point1(2)-ax.YLim(1))/diff(ax.YLim)];
    start_fig = pos(1:2) + start_norm.*pos(3:4);
    end_fig   = pos(1:2) + end_norm.*pos(3:4);
    annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
               'Color',[0.6 0.6 0.6], 'LineWidth',1.5, ...
               'HeadLength',10, 'HeadWidth',10);
end

text(-0.11, -0.01, '$\dot{x}=0$', 'Interpreter','latex','FontSize',20)
text(0.010, 0.01, '$\dot{\pi}=0$', 'Interpreter','latex','FontSize',20)
text(-0.12, 0.005, 'stable cycle', 'Interpreter','latex','FontSize',20)
text(-0.02, -0.015, 'trajectory', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
text(-0.02, -0.017, 'converging', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
text(-0.02, -0.019, 'to cycle', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
text(-0.08, -0.025, 'untargeted', 'Interpreter','latex','FontSize',20)
text(-0.08, -0.027, 'steady state', 'Interpreter','latex','FontSize',20)

% Arrow pointing to stable cycle
text_data = [-0.10, 0.004];  
target_data = [-0.04, -0.001]; 
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color','k', 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);

% Arrow pointing to convergent trajectory
text_data = [0.005, -0.014]; 
target_data = [-0.01, -0.006]; 
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color',[0.6 0.6 0.6], 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);

% Arrow pointing to untrageted ss
ax = gca;
pos = ax.Position; 
text_data = [-0.08, -0.026];  
target_data = [0.95*xtil, 0.995*pigtil];  
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color','k', 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);

print(gcf, 'Figure2b.eps', '-depsc', '-r600');

%% Phase diagram with phi_r>1  (Figure 3a)

ecUNI = ec;
ecUNI.phi_r=1.5;
ecUNI = makeec(ecUNI);

%IS curve nullcline with phi_r>1
FISUNI = @(x) (ecUNI.phi_r-1)*ecUNI.sig.*( exp(-ecUNI.gam*ecUNI.Theta*x) -1)/(ecUNI.phi_pi-1);
%PC nullcline in the baseline
FPCUNI = @(x) (ecUNI.kap/ecUNI.rho).*( exp(x) -1 );

lw = 2;
nx = 100;
xmin = -0.12;
xmax = 0.08;
xgrid = linspace(xmin, xmax, nx);
tmax = 280;  
tspan = 0:tmax;

[~, xs]  = ode45(@(t, x) model_phir(t, x, ecUNI), tspan,  [0.005, 0.0001]);

figure('Position', [100, 100, 500, 500], 'Color', 'w')
plot(xgrid, FISUNI(xgrid), 'k-.', 'LineWidth', lw); 
hold on
plot(xgrid, FPCUNI(xgrid), 'k:', 'LineWidth', lw);
plot(0,0,'ko','MarkerSize',7,'MarkerFaceColor','k');
xline(0,'k:','LineWidth',0.5);
yline(0,'k:','LineWidth',0.5);
plot(xs(:,1),  xs(:,2),  'k', 'LineWidth', lw,'Color',[0.6 0.6 0.6]);
xlim([xmin xmax])
ylim([-0.02 0.01])
yticks([-0.03 -0.02 -0.01 0 0.01])
xticks([-0.14 -0.09 -0.04 0 0.03 0.06])
set(gca,'FontSize',12,'LineWidth',1,'Box','off')
text(-0.115, 0.006, '$\dot{x}=0$', 'Interpreter','latex','FontSize',20)
text(0.043, 0.009, '$\dot{\pi}=0$', 'Interpreter','latex','FontSize',20)
text(-0.04, -0.016, 'divergent', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
text(-0.04, -0.018, 'trajectory', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])

% Arrow pointing to divergent trajectory
ax = gca;
ax.Position = [0.1304 0.1100 0.7746 0.8150];
pos = ax.Position;  
text_data = [-0.02, -0.0155]; 
target_data = [-0.03, -0.011]; 
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color',[0.6 0.6 0.6], 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);


num_arrows = 2;
arrow_indices = round(linspace(70, length(xs)-15, num_arrows));
ax = gca;
pos = ax.Position;
drawnow;

for i = 1:num_arrows
    start_point = xs(arrow_indices(i), :);
    end_point   = xs(arrow_indices(i)+1, :);
    start_norm = [(start_point(1)-ax.XLim(1))/diff(ax.XLim), ...
                  (start_point(2)-ax.YLim(1))/diff(ax.YLim)];
    end_norm   = [(end_point(1)-ax.XLim(1))/diff(ax.XLim), ...
                  (end_point(2)-ax.YLim(1))/diff(ax.YLim)];
    start_norm = min(max(start_norm, 0), 1);
    end_norm   = min(max(end_norm, 0), 1);
    start_fig = pos(1:2) + start_norm.*pos(3:4);
    end_fig   = pos(1:2) + end_norm.*pos(3:4);
    annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
               'Color',[0.6 0.6 0.6], 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);
end
xlabel('$x$','Interpreter','latex','FontSize',24)
ylabel('$\pi$','Interpreter','latex','FontSize',24)

print(gcf, 'Figure3a.eps', '-depsc', '-r600');


%% whatever it takes (Figure 3b)

nx = 100;
xmin = -0.13;
xmax = 0.08;
xgrid = linspace(xmin, xmax, nx);
threshold = -0.1;
idx_below = xgrid <= threshold;
idx_above = xgrid > threshold;

FIS_whatever = @(x,ec1) (x>threshold).*(- ec1.sig.*( exp(-ec1.gam*ec1.Theta*x) -1 )/(ec1.phi_pi-1));

x_jump = threshold;
y1 = FIS_whatever(x_jump - 1e-6, ec);
y2 = FIS_whatever(x_jump + 1e-6, ec);
tmax = 500;
tspan = [0,tmax];
tspan1 = [0,115];

lw = 2;

[~, xs]   = ode45(@(t, x) model_one_ss(t, x, ec,threshold), tspan1, [0.0050    0.0052]);
[~, xs1] = ode45(@(t, x) model(t, x, ec), tspan, [0.015, 0]);

figure('Position', [100, 100, 500, 500], 'Color', 'w')
plot(xgrid(idx_below), FIS_whatever(xgrid(idx_below), ec), 'k-.', 'LineWidth', lw); 
hold on
plot(xgrid(idx_above), FIS_whatever(xgrid(idx_above), ec), 'k-.', 'LineWidth', lw); 
plot(xgrid, FPC(xgrid, ec), 'k:', 'LineWidth', lw);
plot(x_jump,y2,'k','Marker','s','MarkerSize',7,'MarkerFaceColor','k')   
plot(x_jump,0,'k','Marker','s','MarkerSize',7,'MarkerFaceColor','w')
plot(0,0,'ko','MarkerSize',7,'MarkerFaceColor','w')
xline(threshold,'k:','LineWidth',0.5)
xline(0,'k:','LineWidth',0.5)
yline(0,'k:','LineWidth',0.5)
plot(xs(:,1),  xs(:,2),  'k', 'LineWidth', lw);           % stable cycle
plot(xs1(:,1), xs1(:,2), 'Color',[0.6 0.6 0.6],'LineWidth', lw); % converging path
xlim([xmin xmax])
ylim([-0.031 0.01])
xlim([xmin xmax])
yticks([-0.03 -0.02 -0.01 0 0.01])
xticks([-0.14 -0.09 -0.04 0 0.03 0.06])
set(gca,'FontSize',12,'LineWidth',1,'Box','off')
xlabel('$x$','Interpreter','latex','FontSize',24)
ylabel('$\pi$','Interpreter','latex','FontSize',24)

% Arrows
ax = gca;  % current axes
ax.Position = [0.1304 0.1100 0.7746 0.8150];
pos = ax.Position;
num_arrows = 3;

indices1 = round(linspace(15, length(xs1)-1, num_arrows));
for i = 1:num_arrows
    start_point1 = xs1(indices1(i), :);
    end_point1   = xs1(indices1(i) + 1, :);
    start_norm = [(start_point1(1)-ax.XLim(1))/diff(ax.XLim), ...
                  (start_point1(2)-ax.YLim(1))/diff(ax.YLim)];
    end_norm   = [(end_point1(1)-ax.XLim(1))/diff(ax.XLim), ...
                  (end_point1(2)-ax.YLim(1))/diff(ax.YLim)];
    start_fig = pos(1:2) + start_norm.*pos(3:4);
    end_fig   = pos(1:2) + end_norm.*pos(3:4);
    annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
               'Color',[0.6 0.6 0.6], 'LineWidth',1.5, ...
               'HeadLength',10, 'HeadWidth',10);
end

text(-0.1, -0.005, '$\dot{x}=0$', 'Interpreter','latex','FontSize',20)
text(0.010, 0.01, '$\dot{\pi}=0$', 'Interpreter','latex','FontSize',20)
text(-0.12, 0.005, 'stable cycle', 'Interpreter','latex','FontSize',20)
text(-0.02, -0.015, 'trajectory', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
text(-0.02, -0.017, 'converging', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
text(-0.02, -0.019, 'to cycle', 'Interpreter','latex','FontSize',20,'Color',[0.6 0.6 0.6])
text(threshold-0.003, -0.0323, '$\widetilde{x}$', 'Interpreter','latex','FontSize',20,'Color','k')

% Arrow pointing to stable cycle
text_data = [-0.10, 0.004];  % location of 'stable cycle' text
% Target point on black trajectory
target_data = [-0.04, -0.001];  % adjust index for best arrow
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color','k', 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);

% Arrow pointing to convergent trajectory
text_data = [0.005, -0.014]; 
target_data = [-0.01, -0.006]; 
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color',[0.6 0.6 0.6], 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);

% Arrow pointing up to xdot=0
text_data = [-0.09, -0.004];
% Target point on black trajectory
target_data = [-0.105, -0.0005];
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color','k', 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);

% Arrow pointing down to xdot=0
text_data = [-0.085, -0.006];  % location of 'stable cycle' text
% Target point on black trajectory 
target_data = [-0.09, -0.013];
start_norm = [(text_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (text_data(2)-ax.YLim(1))/diff(ax.YLim)];
end_norm   = [(target_data(1)-ax.XLim(1))/diff(ax.XLim), ...
              (target_data(2)-ax.YLim(1))/diff(ax.YLim)];
start_fig = pos(1:2) + start_norm.*pos(3:4);
end_fig   = pos(1:2) + end_norm.*pos(3:4);
annotation('arrow', [start_fig(1) end_fig(1)], [start_fig(2) end_fig(2)], ...
           'Color','k', 'LineWidth',1.5, 'HeadLength',10, 'HeadWidth',10);

print(gcf, 'Figure3b.eps', '-depsc', '-r600');