% Code for "Self Fulfilling Fluctuations in HANK economies"
% produces figures in the supplementary appendix
%---------------------------------------------------------



%% Parameters
ec.rbar      = 0.04;
ec.lambar    = 0.0131;
ec.dc        = 1.1;
ec.gam       = 1/2;
ec.Theta_lb  = 21.98;
ec.Theta_ub  = 29.9;
ec.Theta     = 28.1;
ec.phi_pi    = 1.50;
ec.kap       = 0.01;
ec           = makeec(ec);

%IS curve nullcline
FIS = @(x,ec1) - ec1.sig.*( exp(-ec1.gam*ec1.Theta*x) -1 )/(ec1.phi_pi-1);
%PC nullcline
FPC = @(x,ec1) (ec1.kap/ec1.rho).*( exp(x) -1 );

%function defining steady state x
F = @(x,ec1) (ec1.phi_pi-1)*(ec1.kap/ec1.rho)*(exp(x)-1) + ec1.sig*( exp(-ec1.gam*ec1.Theta*x) - 1);

A0 = @(ec1) [ ec1.phi_x- ec1.upvarsig*ec1.gam*ec1.Theta, ec1.phi_pi-1; -ec1.kap, ec1.rho];

Abad = @(ec1,xx) [ ec1.phi_x- ec1.upvarsig*ec1.gam*ec1.Theta*exp(-ec1.gam*ec1.Theta*xx), ec1.phi_pi-1; -ec1.kap*exp(xx), ec1.rho];

%% Figure B.1a of the Appendix

ecDSC = ec;
ecDSC.Theta = 3;
ecDSC = makeec(ecDSC);

xtilDSC = fzero(@(x) F(x, ecDSC), [-10, -0.001]);
pigtilDSC = FPC(xtilDSC, ecDSC);

tmaxDSC = -250;
tspanDSC = [0 tmaxDSC];

x0DSC = [xtilDSC + 0.005 , pigtilDSC]; 

nx = 100;
xgrid = linspace(1.05*xtilDSC, 0.76, nx);


[~, xsDSC] = ode45(@(t, x) model(t, x, ecDSC), tspanDSC, x0DSC);

figure('Position', [100, 100, 500,500],'Color', 'w')
plot(xgrid, FIS(xgrid, ecDSC), 'b:', 'LineWidth', 2)
hold on
plot(xgrid, FPC(xgrid, ecDSC),'r:','LineWidth', 2)
xline(0, 'k:')
yline(0, 'k:')
xline(xtilDSC, 'k:')
yline(pigtilDSC, 'k:')
plot(xsDSC(:, 1), xsDSC(:, 2), 'k', 'LineWidth', 2)
set(gca,'FontSize',16)

scale_factor = 0.5;
num_arrows = 50;
indicesDSC = round(linspace(1, length(xsDSC)-1, num_arrows));


for i = 1:num_arrows
    start_pointDSC = xsDSC(indicesDSC(i), :);
    end_pointDSC = xsDSC(indicesDSC(i) + 1, :);
    arrow_vectorDSC = scale_factor*(start_pointDSC-end_pointDSC);
    quiver(start_pointDSC(1), start_pointDSC(2), arrow_vectorDSC(1), arrow_vectorDSC(2), 'k', 'LineWidth', 1.5, 'MaxHeadSize', 0.8, 'AutoScale', 'on');
end

xlim([xgrid(1) xgrid(end)]);
ylim([-0.25 0.1]);

xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')

filename = 'Figure_B1a.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure B.1b of the Appendix

ecHC = ec;
ecHC.Theta = 15.28;
ecHC = makeec(ecHC);

xtilHC   = fzero( @(x) F(x,ecHC),[-1,-0.001]);
pigtilHC = FPC(xtilHC,ecHC);

tmax = 400;
tspan = 0:tmax;

nx = 100;
xgrid = linspace(-0.4, 0.3, nx);

[~, xsHC]   = ode45(@(t, x) model(t, x, ecHC), tspan, [xtilHC pigtilHC+0.0001]);

lw = 2;


figure('Position', [100, 100, 500,500],'Color', 'w')
plot(xgrid, FIS(xgrid, ecHC), 'b:', 'LineWidth', lw)
hold on
plot(xgrid,FPC(xgrid,ecHC),'r:','LineWidth',lw)
xline(0, 'k:')
yline(0, 'k:')
xline(xtilHC, 'k:')
yline(pigtilHC, 'k:')
xlim([-0.4 0.3])
ylim([-0.08 0.03])
xticks([ -0.4000   -0.2000   0 0.15 0.3])
yticks([ -0.08 -0.06  -0.04 -0.02  0 0.02])
plot(xsHC(:, 1), xsHC(:, 2), 'k', 'LineWidth', 2.5)
set(gca,'FontSize',16)
xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')

scale_factor = 2;
num_arrows = 45;
indicesHC = round(linspace(1, length(xsHC)-1, num_arrows));


for i = 1:num_arrows
    start_pointHC = xsHC(indicesHC(i), :);
       
    end_pointHC = xsHC(indicesHC(i) + 1, :);
        
    arrow_vectorHC = scale_factor * (end_pointHC - start_pointHC);
       
    quiver(start_pointHC(1), start_pointHC(2), arrow_vectorHC(1), arrow_vectorHC(2), 'k', 'LineWidth', 1.5, 'MaxHeadSize', 0.5, 'AutoScale', 'off');
end


filename = 'Figure_B1b.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure B.1c of the Appendix

xtil   = fzero( @(x) F(x,ec),[-1,-0.001]);
pigtil = FPC(xtil,ec);

tmax = 450;
tspan = 0:tmax;

lw = 2;

nx = 100;
xgrid = linspace(1.1*xtil, 0.08, nx);

[~, xs]   = ode45(@(t, x) model(t, x, ec), tspan, [-0.0472, -0.0027]);
[~, xs1] = ode45(@(t, x) model(t, x, ec), tspan, [0.99*xtil, 0.99*pigtil]);
[~, xs2] = ode45(@(t, x) model(t, x, ec), tspan, [0.015, 0]);



figure('Position', [100, 100, 500,500],'Color', 'w')
plot(xgrid, FIS(xgrid, ec), 'b:', 'LineWidth', lw)
hold on
plot(xgrid,FPC(xgrid,ec),'r:','LineWidth',lw)
xline(0, 'k:')
yline(0, 'k:')
xline(xtil, 'k:')
yline(pigtil, 'k:')
plot(xs(:, 1), xs(:, 2), 'k', 'LineWidth', 2.5)
plot(xs1(:, 1), xs1(:, 2), 'Color',colors('deep carrot orange'),'LineWidth', lw)
plot(xs2(:, 1), xs2(:, 2), 'Color',colors('cadet grey'), 'LineWidth', lw)
xlim([-0.145 0.06])
ylim([-0.031 0.01])
yticks([   -0.03   -0.02  -0.01     0    0.01])
xticks([   -0.14   -0.11   -0.08   -0.05   -0.02     0 0.03 0.06])
set(gca,'FontSize',16)
xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')

scale_factor = 3.5;
scale_factor1 = 2;
num_arrows = 10;
indices0 = round(linspace(1, length(xs)-1, num_arrows));
indices1 = round(linspace(1, length(xs1)-1, num_arrows));
indices2 = round(linspace(1, length(xs2)-1, num_arrows));


for i = 1:num_arrows
    start_point0 = xs(indices0(i), :);
    start_point1 = xs1(indices1(i), :);
    start_point2 = xs2(indices2(i), :);
    
    end_point0 = xs(indices0(i) + 1, :);
    end_point1 = xs1(indices1(i) + 1, :);
    end_point2 = xs2(indices2(i) + 1, :);
    
    arrow_vector0 = scale_factor*1.5* (end_point0 - start_point0);
    arrow_vector1 = scale_factor * (end_point1 - start_point1);
    arrow_vector2 = scale_factor * (end_point2 - start_point2);
    
    quiver(start_point0(1), start_point0(2), arrow_vector0(1), arrow_vector0(2), 'k', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
    quiver(start_point1(1), start_point1(2), arrow_vector1(1), arrow_vector1(2), 'Color',colors('deep carrot orange'), 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
    quiver(start_point2(1), start_point2(2), arrow_vector2(1), arrow_vector2(2), 'Color',colors('cadet grey'), 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
end



filename = 'Figure_B1c.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure B.1d of the Appendix

ecID = ec;
ecID.Theta = 1.1 * (ec.rho/(ec.sig*ec.gam));
ecID = makeec(ecID);

xtilID = fzero(@(x) F(x, ecID), [-1, -0.001]);
pigtilID = FPC(xtilID, ecID);

tmax = 600;
tspan = 0:tmax;

tmax2 = 150;
tspan2 = 0:tmax2;


nx = 100;
xgrid = linspace(-0.1, 0.04, nx);

[~, xs3] = ode45(@(t, x) model(t, x, ecID), tspan, [0.99 * xtilID, 0.99 * pigtilID]);
[~, xs4] = ode45(@(t, x) model(t, x, ecID), tspan2, [0.03, 0.0]);

figure('Position', [100, 100, 500,500],'Color', 'w')
plot(xgrid, FIS(xgrid, ecID), 'b:', 'LineWidth', 2)
hold on
plot(xgrid, FPC(xgrid, ecID), 'r:','LineWidth', 2)
xline(0, 'k:')
yline(0, 'k:')
xline(xtilID, 'k:')
yline(pigtilID, 'k:')
plot(xs3(:, 1), xs3(:, 2), 'k', 'LineWidth', 2)
plot(xs4(:, 1), xs4(:, 2), 'Color', colors('cadet grey'), 'LineWidth', 2)
set(gca,'FontSize',16)
ax = gca; 
ax.YAxis.Exponent = 0;
xticks([   -0.1   -0.075   -0.050   -0.025    0   0.02    0.04])
yticks([   -0.0250   -0.0200   -0.0150   -0.0100   -0.0050         0 0.006 ])

scale_factor = 4;
scale_factor2 = 3;
num_arrows = 15;
indices3 = round(linspace(1, length(xs3)-1, num_arrows));
indices4 = round(linspace(1, length(xs4)-1, num_arrows));

for i = 1:num_arrows
    start_point3 = xs3(indices3(i), :);
    start_point4 = xs4(indices4(i), :);
    
    end_point3 = xs3(indices3(i) + 1, :);
    end_point4 = xs4(indices4(i) + 1, :);
    
    arrow_vector3 = scale_factor * (end_point3 - start_point3);
    arrow_vector4 = scale_factor2 * (end_point4 - start_point4);
    
    quiver(start_point3(1), start_point3(2), arrow_vector3(1), arrow_vector3(2), 'Color', colors('black'), 'LineWidth', 1.5, 'MaxHeadSize', 1, 'AutoScale', 'off');
    quiver(start_point4(1), start_point4(2), arrow_vector4(1), arrow_vector4(2), 'Color', colors('cadet grey'), 'LineWidth', 1.5, 'MaxHeadSize', 1, 'AutoScale', 'off');
end

xlim([-0.1 0.04]);
ylim([-0.025 0.006]);

xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')

filename = 'Figure_B1d.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure D1 of the Appendix

ecAMPF = ec;
ecAMPF.phi_b = 5;
ecAMPF.bstar = 0;


tspan=0:950;

x0=[0.0381  0.0055 0.0];
x1=[0.01    0.001  0.0];

[~, xs]  = ode45(@(t, x) model_AMPF(t, x, ecAMPF), tspan, x0);
[~, xs1] = ode45(@(t, x) model_AMPF(t, x, ecAMPF), tspan, x1);

figure('Position', [100, 100, 500, 500],'Color', 'w')
plot3(xs(:,1), xs(:,2), xs(:,3),'Color',colors('slate gray'),'LineWidth',2)
hold on
plot3(xs1(:,1), xs1(:,2), xs1(:,3),'Color',colors('deep carrot orange'),'LineWidth',2)

% point at origin
plot3(0,0,0,'ko','MarkerSize',5,'MarkerFaceColor','k'); 

set(gca,'FontSize',16)
xlabel('$x$','Interpreter','latex','FontSize',20)
ylabel('$\pi$','Interpreter','latex','FontSize',20)
zlabel('$b^g$','Interpreter','latex','FontSize',20)
grid on

% choose every Nth point for arrows
N = 50;  
idx = 1:N:length(xs1)-1;

% differences for arrow directions
u = xs1(idx+1,1) - xs1(idx,1);
v = xs1(idx+1,2) - xs1(idx,2);
w = xs1(idx+1,3) - xs1(idx,3);

% draw arrows
quiver3(xs1(idx,1), xs1(idx,2), xs1(idx,3), ...
        u, v, w, ...
        0, 'Color', colors('deep carrot orange'), 'LineWidth', 1.5, 'MaxHeadSize', 1);

filename = 'Figure_D1.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure E.1a of the Appendix

ecphix_lo = ec;
ecphix_lo.phi_x = 0.01;
ecphix_lo = makeec(ecphix_lo);

%IS curve nullcline
FIS_phix = @(x,ec1) -( ec1.phi_x*x + ec1.sig.*( exp(-ec1.gam*ec1.Theta*x) -1 ))/(ec1.phi_pi-1);

%function defining steady state x
F_phix = @(x,ec1) (ec1.phi_pi-1)*(ec1.kap/ec1.rho)*(exp(x)-1) + ec1.phi_x*x + ec1.sig*( exp(-ec1.gam*ec1.Theta*x) - 1);

xtil_phixlo   = fzero(@(x) F_phix(x,ecphix_lo),[-2 -0.001]);
pigtil_phixlo = FPC(xtil_phixlo,ecphix_lo);

xgridlo = linspace(1.05*xtil_phixlo,0.1,1000);
FISgrid_phixlo = FIS_phix(xgridlo,ecphix_lo);
FPCgrid_phixlo = FPC(xgridlo,ecphix_lo);

tspan11 = [0 130];
tspan = [0 390];
x0 = [0.0670   -0.0060];
x1 = [0.01   0.00];
[~, xs_phixlo]   = ode45(@(t, x) model_phix(t, x, ecphix_lo), tspan11, x0);
[~, xs_phixlo1]   = ode45(@(t, x) model_phix(t, x, ecphix_lo), tspan, x1);

scale_factor = 1;
num_arrows = 15;
num_arrows1 = 45;
indicesxs_phixlo = round(linspace(1, length(xs_phixlo)-1, num_arrows));
indicesxs_phixlo1 = round(linspace(1, length(xs_phixlo1)-1, num_arrows1));

figure('Position', [100, 100, 500,500],'Color', 'w')
plot(xs_phixlo(:,1),xs_phixlo(:,2),'LineWidth',2,'Color',colors('black'))
hold on
plot(xs_phixlo1(:,1),xs_phixlo1(:,2),'LineWidth',2,'Color',colors('battleship grey'))
plot(xgridlo, FISgrid_phixlo,'b:',xgridlo,FPCgrid_phixlo,'r:','LineWidth',2)
for i = 1:num_arrows
    start_pointxs_phixlo = xs_phixlo(indicesxs_phixlo(i), :);
       
    end_pointxs_phixlo = xs_phixlo(indicesxs_phixlo(i) + 1, :);
        
    arrow_vectorxs_phixlo = scale_factor * (end_pointxs_phixlo - start_pointxs_phixlo);
       
    quiver(start_pointxs_phixlo(1), start_pointxs_phixlo(2), arrow_vectorxs_phixlo(1), arrow_vectorxs_phixlo(2), 'Color',colors('black'), 'LineWidth', 1.5, 'MaxHeadSize', 0.3, 'AutoScale', 'off');
end
for i = 1:num_arrows1
    
    start_pointxs_phixlo1 = xs_phixlo1(indicesxs_phixlo1(i), :);
       
    end_pointxs_phixlo1 = xs_phixlo1(indicesxs_phixlo1(i) + 1, :);
        
    arrow_vectorxs_phixlo1 = scale_factor * (end_pointxs_phixlo1 - start_pointxs_phixlo1);
       
    quiver(start_pointxs_phixlo1(1), start_pointxs_phixlo1(2), arrow_vectorxs_phixlo1(1), arrow_vectorxs_phixlo1(2), 'Color',colors('battleship grey'), 'LineWidth', 1.5, 'MaxHeadSize', 0.3, 'AutoScale', 'off');
end
xline(0,'k:','LineWidth',1)
yline(0,'k:','LineWidth',1)
xline(xtil_phixlo,'k:','LineWidth',1)
yline(pigtil_phixlo,'k:','LineWidth',1)

xlim([xgridlo(1) xgridlo(end)])
ylim([-0.035 0.01])
yticks([   -0.0250   -0.0150   -0.0050  0   0.005])
set(gca,'FontSize',16)

xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')

filename = 'Figure_E1a.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure E.1b of the Appendix
ecphix_hi = ec;
ecphix_hi.phi_x = 0.5;
ecphix_hi = makeec(ecphix_hi);


xtil_phixhi   = fzero(@(x) F_phix(x,ecphix_hi),[-2 -0.001]);
pigtil_phixhi = FPC(xtil_phixhi,ecphix_hi);


tspan = [0 -200];
x0 = [xtil_phixhi,pigtil_phixhi-.0001];

[~, xs_phix]   = ode45(@(t, x) model_phix(t, x, ecphix_hi), tspan, x0);

xgrid_phixhi = linspace(1.05*xtil_phixhi,0.06,100);
FISgrid_phixhi = FIS_phix(xgrid_phixhi,ecphix_hi);
FPCgrid_phixhi = FPC(xgrid_phixhi,ecphix_hi);


figure('Position', [100, 100, 500,500],'Color', 'w')
plot(xgrid_phixhi, FISgrid_phixhi,'b:',xgrid_phixhi,FPCgrid_phixhi,'r:','LineWidth',2)
hold on
scale_factor = 1.05;
num_arrows = 35;
indicesxs_phix = round(linspace(1, length(xs_phix)-1, num_arrows));

for i = 1:num_arrows
    start_pointxs_phix = xs_phix(indicesxs_phix(i), :);
       
    end_pointxs_phix = xs_phix(indicesxs_phix(i) + 1, :);
        
    arrow_vectorxs_phix = scale_factor * (start_pointxs_phix - end_pointxs_phix);
       
    quiver(start_pointxs_phix(1), start_pointxs_phix(2), arrow_vectorxs_phix(1), arrow_vectorxs_phix(2), 'Color',colors('black'), 'LineWidth', 0.8, 'MaxHeadSize', 1, 'AutoScale', 'on');
end
hold on
plot(xs_phix(:,1),xs_phix(:,2),'LineWidth',2,'Color',colors('black'))
xline(0,'k:','LineWidth',1)
yline(0,'k:','LineWidth',1)
xline(xtil_phixhi,'k:','LineWidth',1)
yline(pigtil_phixhi,'k:','LineWidth',1)
xlim([xgrid_phixhi(1) xgrid_phixhi(end)])
ylim([-0.08,0.12])
set(gca,'FontSize',16)


xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')



filename = 'Figure_E1b.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure E.2a of the Appendix 

ecTTphix_lo = ec;
ecTTphix_lo.Theta = 32;
ecTTphix_lo.phi_x = 0.001;
ecTTphix_lo = makeec(ecTTphix_lo);

xtil_phixlo   = fzero(@(x) F_phix(x,ecTTphix_lo),[-2 -0.001]);
pigtil_phixlo = FPC(xtil_phixlo,ecTTphix_lo);

xgridlo = linspace(1.05*xtil_phixlo,0.1,1000);
FISgrid_phixlo = FIS_phix(xgridlo,ecTTphix_lo);
FPCgrid_phixlo = FPC(xgridlo,ecTTphix_lo);

tspan = [0 530];
x0 = [xtil_phixlo   0.95*pigtil_phixlo];
% x1 = [0.01   0.00];
[~, xs_phixlo]   = ode45(@(t, x) model_phix(t, x, ecTTphix_lo), tspan, x0);


scale_factor = 1.5;
num_arrows = 45;
indicesxs_phixlo = round(linspace(1, length(xs_phixlo)-1, num_arrows));

figure('Position', [100, 100, 500,500],'Color', 'w')
plot(xs_phixlo(:,1),xs_phixlo(:,2),'LineWidth',2,'Color',colors('black'))
hold on
plot(xgridlo, FISgrid_phixlo,'b:',xgridlo,FPCgrid_phixlo,'r:','LineWidth',2)
for i = 1:num_arrows
    start_pointxs_phixlo = xs_phixlo(indicesxs_phixlo(i), :);
       
    end_pointxs_phixlo = xs_phixlo(indicesxs_phixlo(i) + 1, :);
        
    arrow_vectorxs_phixlo = scale_factor * (end_pointxs_phixlo - start_pointxs_phixlo);
       
    quiver(start_pointxs_phixlo(1), start_pointxs_phixlo(2), arrow_vectorxs_phixlo(1), arrow_vectorxs_phixlo(2), 'Color',colors('black'), 'LineWidth', 1.5, 'MaxHeadSize', 0.3, 'AutoScale', 'off');
end
xline(0,'k:','LineWidth',1)
yline(0,'k:','LineWidth',1)
xline(xtil_phixlo,'k:','LineWidth',1)
yline(pigtil_phixlo,'k:','LineWidth',1)

xlim([xgridlo(1) xgridlo(end)])
ylim([-0.025 0.005])
yticks([   -0.0250   -0.0150   -0.0050  0   0.005])
set(gca,'FontSize',16)

xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')

filename = 'Figure_E2a.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure E.2b of the Appendix

ecTTphix_med = ec;
ecTTphix_med.Theta = 32;
ecTTphix_med.phi_x = 0.01;
ecTTphix_med = makeec(ecTTphix_med);

xtil_phixmed   = fzero(@(x) F_phix(x,ecTTphix_med),[-2 -0.001]);
pigtil_phixmed = FPC(xtil_phixmed,ecTTphix_med);

xgridlo = linspace(1.05*xtil_phixmed,0.1,1000);
FISgrid_phixmed = FIS_phix(xgridlo,ecTTphix_med);
FPCgrid_phixmed = FPC(xgridlo,ecTTphix_med);

tspan11 = [0 1030];

x0 = [-0.0072   -0.0094];
[~, xs_phixmed]   = ode45(@(t, x) model_phix(t, x, ecTTphix_med), tspan11, x0);

scale_factor = 1.5;
num_arrows = 15;
indicesxs_phixmed = round(linspace(1, length(xs_phixmed)-1, num_arrows));

figure('Position', [100, 100, 500,500])
plot(xs_phixmed(:,1),xs_phixmed(:,2),'LineWidth',2,'Color',colors('black'))
hold on
plot(xgridlo, FISgrid_phixmed,'b:',xgridlo,FPCgrid_phixmed,'r:','LineWidth',2)
for i = 1:num_arrows
    start_pointxs_phixlo = xs_phixmed(indicesxs_phixmed(i), :);
       
    end_pointxs_phixlo = xs_phixmed(indicesxs_phixmed(i) + 1, :);
        
    arrow_vectorxs_phixlo = scale_factor * (end_pointxs_phixlo - start_pointxs_phixlo);
       
    quiver(start_pointxs_phixlo(1), start_pointxs_phixlo(2), arrow_vectorxs_phixlo(1), arrow_vectorxs_phixlo(2), 'Color',colors('black'), 'LineWidth', 1.5, 'MaxHeadSize', 0.3, 'AutoScale', 'off');
end
xline(0,'k:','LineWidth',1)
yline(0,'k:','LineWidth',1)
xline(xtil_phixmed,'k:','LineWidth',1)
yline(pigtil_phixmed,'k:','LineWidth',1)

xlim([xgridlo(1) xgridlo(end)])
ylim([-0.025 0.01])
set(gca,'FontSize',16)

xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')

filename = 'Figure_E2b.eps';
print(gcf, filename, '-depsc', '-r600');


%% Figure E.2c of the Appendix

ecTTphix_hi = ec;
ecTTphix_hi.Theta = 32;
ecTTphix_hi.phi_x = 0.5;
ecTTphix_hi = makeec(ecTTphix_hi);


xtil_phixhi   = fzero(@(x) F_phix(x,ecTTphix_hi),[-2 -0.001]);
pigtil_phixhi = FPC(xtil_phixhi,ecTTphix_hi);


tspan = [0 -200];
x0 = [xtil_phixhi,pigtil_phixhi-.0001];

[~, xs_phix]   = ode45(@(t, x) model_phix(t, x, ecTTphix_hi), tspan, x0);

xgrid_phixhi = linspace(1.05*xtil_phixhi,0.06,100);
FISgrid_phixhi = FIS_phix(xgrid_phixhi,ecTTphix_hi);
FPCgrid_phixhi = FPC(xgrid_phixhi,ecTTphix_hi);


figure('Position', [100, 100, 500,500],'Color', 'w')
plot(xgrid_phixhi, FISgrid_phixhi,'b:',xgrid_phixhi,FPCgrid_phixhi,'r:','LineWidth',2)
hold on
scale_factor = 1.05;
num_arrows = 35;
indicesxs_phix = round(linspace(1, length(xs_phix)-1, num_arrows));

for i = 1:num_arrows
    start_pointxs_phix = xs_phix(indicesxs_phix(i), :);
       
    end_pointxs_phix = xs_phix(indicesxs_phix(i) + 1, :);
        
    arrow_vectorxs_phix = scale_factor * (start_pointxs_phix - end_pointxs_phix);
       
    quiver(start_pointxs_phix(1), start_pointxs_phix(2), arrow_vectorxs_phix(1), arrow_vectorxs_phix(2), 'Color',colors('black'), 'LineWidth', 0.8, 'MaxHeadSize', 1, 'AutoScale', 'on');
end
hold on
plot(xs_phix(:,1),xs_phix(:,2),'LineWidth',2,'Color',colors('black'))
xline(0,'k:','LineWidth',1)
yline(0,'k:','LineWidth',1)
xline(xtil_phixhi,'k:','LineWidth',1)
yline(pigtil_phixhi,'k:','LineWidth',1)
xlim([xgrid_phixhi(1) 0.05])
ylim([-0.065,0.1])
set(gca,'FontSize',16)


xlabel('$x$','Interpreter','latex','FontSize',30,'FontWeight','bold')
ylabel('$\pi$','Interpreter','latex','FontSize',30,'FontWeight','bold')



filename = 'Figure_E2c.eps';
print(gcf, filename, '-depsc', '-r600');


%% Figure E.3a of the Appendix

ec3dcyc = ec;
ec3dcyc.alfa = 9;

%function defining steady state x
xtil3dcyc   = fzero( @(x) F(x,ec3dcyc),[-1,-0.001]);
pigtil3dcyc = FPC(xtil,ec3dcyc);

tspan=[0, 250];
tspan2=[0, 1000];

x0=[0.09 0.0085 0.01];
x1=[0.0264  -0.0005 -0.0005];
x2=[0.0188,0.0066,0.0066]; 

[~, xs]  = ode45(@(t, x) model_inertial(t, x, ec3dcyc), tspan, x0);
[~, zs]   = ode45(@(t, x) model_inertial(t, x, ec3dcyc), tspan2, x1);
[~, cycs] = ode45(@(t, x) model_inertial(t, x, ec3dcyc), tspan2, x2);

figure('Position', [100, 100, 500, 500])
plot3(xs(:,1), xs(:,2), xs(:,3),'Color',colors('slate gray'),'LineWidth',2)
hold on
plot3(zs(:,1), zs(:,2), zs(:,3), 'Color', colors('deep carrot orange'),'LineWidth',1.5);
plot3(cycs(:,1), cycs(:,2), cycs(:,3), 'k','LineWidth',2);
set(gca,'FontSize',16)

scatter3(0,0,0,50,'k','fill')
text(-0.1,-0.005,-0.00005,'targeted steady state','Interpreter','latex','FontSize',15)
scatter3(xtil,pigtil,pigtil,50,'k','fill')
text(0.95*xtil,0.98*pigtil,pigtil,'untargeted steady state','Interpreter','latex','FontSize',15)
grid on
xlabel('$x$','Interpreter','latex','FontSize',25)
ylabel('$\pi$','Interpreter','latex','FontSize',25)
zlabel('$\pi^b $','Interpreter','latex','FontSize',25)

% Formatting
grid on
box on
axis tight
axis vis3d
view(30, 30)
camlight headlight

set(gca, ...
    'FontSize', 16, ...
    'LineWidth', 1.2, ...
    'TickLabelInterpreter', 'latex', ...
    'GridAlpha', 0.2, ...
    'GridLineStyle', '--', ...
    'BoxStyle', 'full', ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'ZMinorTick', 'on')



filename = 'Figure_E3a.eps';
print(gcf, filename, '-depsc', '-r600');

%% Figure E.3b of the Appendix

ec3dh = ec3dcyc;
ec3dh.alfa = 1.028;

tspan = [0 1850];

x0=[-0.0805   -0.0073   -0.0077];

[~, xh]  = ode45(@(t, x) model_inertial(t, x, ec3dh), tspan, x0);

figure('Position', [100, 100, 500, 500])
plot3(xh(:,1), xh(:,2), xh(:,3),'k','LineWidth',2)
set(gca,'FontSize',16)
hold on
scatter3(0,0,0,50,'k','fill')
text(-0.1,-0.005,-0.00005,'targeted steady state','Interpreter','latex','FontSize',15)
scatter3(xtil,pigtil,pigtil,50,'k','fill')
text(0.95*xtil,0.98*pigtil,pigtil,'untargeted steady state','Interpreter','latex','FontSize',15)
grid on
xlabel('$x$','Interpreter','latex','FontSize',25)
ylabel('$\pi$','Interpreter','latex','FontSize',25)
zlabel('$\pi^b$','Interpreter','latex','FontSize',25)

% Formatting
grid on
box on
axis tight
axis vis3d
view(30, 30)
camlight headlight

set(gca, ...
    'FontSize', 16, ...
    'LineWidth', 1.2, ...
    'TickLabelInterpreter', 'latex', ...
    'GridAlpha', 0.2, ...
    'GridLineStyle', '--', ...
    'BoxStyle', 'full', ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'ZMinorTick', 'on')




filename = 'Figure_E3b.eps';
print(gcf, filename, '-depsc', '-r600');


%% Figure E.4a of the Appendix

ecHTM = ec;
ecHTM.etabar = 0.30;
ecHTM.Theta  = 9.92;
ecHTM = makeecHTM(ecHTM);


% find second steady state
m_ubar = fzero(@(m) eval_G(m,ecHTM),[-0.13,-0.01]);
x_ubar = -(1/(ecHTM.gam*ecHTM.Theta))*log(1 - (1-exp(-ecHTM.gam*m_ubar))/(ecHTM.etabar*ecHTM.G + ecHTM.etabar*(1-ecHTM.G)*(1 - exp(-ecHTM.gam*m_ubar))) );
pi_ubar = (ecHTM.kap/ecHTM.rho)*(exp(x_ubar - m_ubar) -1 );
 
tspan = 0:1000; 
x0 = [-0.5394   -0.0747   -0.1085];


[~, xs_hc]  = ode45(@(t, x) model_changeeta(t, x, ecHTM), tspan, x0);

% Create figure
figure('Position', [100, 100, 600, 600], 'Color', 'w')

% Plot 3D trajectories
plot3(xs_hc(:,1), xs_hc(:,2), xs_hc(:,3), 'Color', [0.44, 0.5, 0.56], 'LineWidth', 2)
hold on

% Mark the origin
plot3(0, 0, 0, 'kx', 'MarkerSize', 10, 'LineWidth', 2)
plot3(x_ubar, pi_ubar, m_ubar, 'bx', 'MarkerSize', 10, 'LineWidth', 2)

% Axis labels
xlabel('$x_t$', 'Interpreter', 'latex', 'FontSize', 18)
ylabel('$\pi_t$', 'Interpreter', 'latex', 'FontSize', 18)
zlabel('$m_t$', 'Interpreter', 'latex', 'FontSize', 18)

% Formatting
grid on
box on
axis tight
axis vis3d
view([45 -25])
camlight headlight

set(gca, ...
    'FontSize', 16, ...
    'LineWidth', 1.2, ...
    'TickLabelInterpreter', 'latex', ...
    'GridAlpha', 0.2, ...
    'GridLineStyle', '--', ...
    'BoxStyle', 'full', ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'ZMinorTick', 'on')

print(gcf, 'Figure_E4a.eps', '-depsc', '-r600')


%% Figure E.4b of the Appendix

ecHTM.Theta = 21.98;

tspan = [0 800]; 
tspan1 = [0 1000]; 
x0 = [-0.0222   -0.0043    0.0002];
x1 = [0.010, 0.0010, 0];

[~, xs]  = ode45(@(t, x) model_changeeta(t, x, ecHTM), tspan1, x0);
[~, xs1]  = ode45(@(t, x) model_changeeta(t, x, ecHTM), tspan, x1);

% Create figure
figure('Position', [100, 100, 600, 600], 'Color', 'w')

% Plot 3D trajectories
plot3(xs(:,1), xs(:,2), xs(:,3), 'b', 'LineWidth', 2)
hold on
plot3(xs1(:,1), xs1(:,2), xs1(:,3), 'Color', [0.44, 0.5, 0.56], 'LineWidth', 2)

% Plot direction arrows
n_arrows = 28;
arrow_length = 0.0007;
head_size = 0.08;
line_thickness = 0.5;

% Indices for arrow placement
idx = round(linspace(1, length(xs) - 1, n_arrows));
idx1 = round(linspace(1, length(xs1) - 1, n_arrows));

% Compute direction vectors using finite differences
dvecs = xs(idx + 1, :) - xs(idx, :);
dvecs1 = xs1(idx1 + 1, :) - xs1(idx1, :);

% Normalize and scale vectors
dvecs = arrow_length * dvecs ./ vecnorm(dvecs, 2, 2);
dvecs1 = arrow_length * dvecs1 ./ vecnorm(dvecs1, 2, 2);

% Add arrows along trajectory 1
quiver3(xs(idx,1), xs(idx,2), xs(idx,3), ...
        dvecs(:,1), dvecs(:,2), dvecs(:,3), ...
        0, 'Color','b' , ...
        'LineWidth', line_thickness, ...
        'MaxHeadSize', head_size)

% Add arrows along trajectory 2
quiver3(xs1(idx1,1), xs1(idx1,2), xs1(idx1,3), ...
        dvecs1(:,1), dvecs1(:,2), dvecs1(:,3), ...
        0, 'Color', [0.44, 0.5, 0.56], ...
        'LineWidth', line_thickness, ...
        'MaxHeadSize', head_size)

% Mark the origin
plot3(0, 0, 0, 'kx', 'MarkerSize', 10, 'LineWidth', 2)

% Axis labels
xlabel('$x_t$', 'Interpreter', 'latex', 'FontSize', 18)
ylabel('$\pi_t$', 'Interpreter', 'latex', 'FontSize', 18)
zlabel('$m_t$', 'Interpreter', 'latex', 'FontSize', 18)

% Formatting
grid on
box on
axis tight
axis vis3d
view([45 -25])
camlight headlight

set(gca, ...
    'FontSize', 16, ...
    'LineWidth', 1.2, ...
    'TickLabelInterpreter', 'latex', ...
    'GridAlpha', 0.2, ...
    'GridLineStyle', '--', ...
    'BoxStyle', 'full', ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'ZMinorTick', 'on')

print(gcf, 'Figure_E4b.eps', '-depsc', '-r600')

%% Figure E.4c of the Appendix
ecHTM.Theta = 28.1;

tspan = [0 500]; 
x0 = [-0.001, -0.001, 0];
x1 = [0.0010, 0.0010, 0];

[ts, xs]    = ode45(@(t, x) model_changeeta(t, x, ecHTM), tspan, x0);
[ts1, xs1]  = ode45(@(t, x) model_changeeta(t, x, ecHTM), tspan, x1);

% Create figure
figure('Position', [100, 100, 600, 600], 'Color', 'w')

% Plot 3D trajectories
plot3(xs(:,1), xs(:,2), xs(:,3), 'Color', [0.44, 0.5, 0.56], 'LineWidth', 2)
hold on
plot3(xs1(:,1), xs1(:,2), xs1(:,3), 'b', 'LineWidth', 2)

% Plot direction arrows
n_arrows = 28;
arrow_length = 0.0007;
head_size = 0.08;
line_thickness = 0.5;

% Indices for arrow placement
idx = round(linspace(1, length(xs) - 1, n_arrows));
idx1 = round(linspace(1, length(xs1) - 1, n_arrows));

% Compute direction vectors using finite differences
dvecs = xs(idx + 1, :) - xs(idx, :);
dvecs1 = xs1(idx1 + 1, :) - xs1(idx1, :);

% Normalize and scale vectors
dvecs = arrow_length * dvecs ./ vecnorm(dvecs, 2, 2);
dvecs1 = arrow_length * dvecs1 ./ vecnorm(dvecs1, 2, 2);

% Add arrows along trajectory 1
quiver3(xs(idx,1), xs(idx,2), xs(idx,3), ...
        dvecs(:,1), dvecs(:,2), dvecs(:,3), ...
        0, 'Color', [0.44, 0.5, 0.56], ...
        'LineWidth', line_thickness, ...
        'MaxHeadSize', head_size)

% Add arrows along trajectory 2
quiver3(xs1(idx1,1), xs1(idx1,2), xs1(idx1,3), ...
        dvecs1(:,1), dvecs1(:,2), dvecs1(:,3), ...
        0, 'Color', 'b', ...
        'LineWidth', line_thickness, ...
        'MaxHeadSize', head_size)

% Mark the origin
plot3(0, 0, 0, 'kx', 'MarkerSize', 10, 'LineWidth', 2)

% Axis labels
xlabel('$x_t$', 'Interpreter', 'latex', 'FontSize', 18)
ylabel('$\pi_t$', 'Interpreter', 'latex', 'FontSize', 18)
zlabel('$m_t$', 'Interpreter', 'latex', 'FontSize', 18)

% Formatting
grid on
box on
axis tight
axis vis3d
view([45 -25])
camlight headlight

set(gca, ...
    'FontSize', 16, ...
    'LineWidth', 1.2, ...
    'TickLabelInterpreter', 'latex', ...
    'GridAlpha', 0.2, ...
    'GridLineStyle', '--', ...
    'BoxStyle', 'full', ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'ZMinorTick', 'on')

% Export figure
print(gcf, 'Figure_E4c.eps', '-depsc', '-r600')