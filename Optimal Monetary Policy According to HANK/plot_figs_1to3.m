%% Parameters 

% countercyclical iid HANK + utilitarian planner
ec.theta     = 1 - 0.15;
ec.R         = 1.04;
ec.gambar    = 2;
ec.rhobar    = 1/3;
ec.sigy      = 0.5;
ec.xibar     = 1+ec.rhobar*ec.gambar;
ec.kap       = 0.1;
ec.lam       = 1.1;
ec.dsigydy   = -3; 
ec.rhoz      = 0.95^4;
ec.rholam    = 0.9^4;
ec.rhovarsig = 0.68^4;
ec.rhozeta   = 0.83^4;
ec.sigz      = 0.00582*2;
ec.siglam    = 0.017*2;
ec.sigzeta   = 0.00569*2;
ec.sigvarsig = 0.688*2;
ec.alphaomu  = 0; % = alpha/mu

ec = makeec(ec);

n = 50;
sig_grid    = linspace(0.001*ec.sigbar,1,n);
varphi_grid = linspace(-6,0,n);
gambar_grid = linspace(0.001,5,n);


%%


Ups_sig_grid       = zeros(n,1);
del_sig_grid       = zeros(n,1);
Omega_sig_grid     = zeros(n,1);
varpi_sig_grid     = zeros(n,1);

Ups_varphi_grid    = zeros(n,1);
del_varphi_grid    = zeros(n,1);
Omega_varphi_grid  = zeros(n,1);
varpi_varphi_grid  = zeros(n,1);

Ups_gambar_grid    = zeros(n,1);
del_gambar_grid    = zeros(n,1);
Omega_gambar_grid  = zeros(n,1);
varpi_gambar_grid  = zeros(n,1);
gam_grid           = zeros(n,1);
LAM_grid           = zeros(n,1);

for i=1:n
    ecuse = ec;
    ecuse.sigbar = sig_grid(i);
    [Ups_sig_grid(i), del_sig_grid(i),Omega_sig_grid(i),~,varpi_sig_grid(i)] = make_compstats(ecuse);
    ecuse=ec;
    ecuse.varphi = varphi_grid(i);
    [Ups_varphi_grid(i), del_varphi_grid(i),Omega_varphi_grid(i),~,varpi_varphi_grid(i)] = make_compstats(ecuse);
    ecuse=ec;
    ecuse.gambar = gambar_grid(i);
    [Ups_gambar_grid(i), del_gambar_grid(i),Omega_gambar_grid(i),gam_grid(i),varpi_gambar_grid(i)] = make_compstats(ecuse);
end

%%

fig3 = figure()

subplot(1,3,1)
plot(sig_grid',Ups_sig_grid,'b',sig_grid',del_sig_grid,'m--',sig_grid',varpi_sig_grid,'k:','LineWidth',2)
yline(1,'k','LineWidth',2)
legend('$\Upsilon(\Omega)$','$\delta(\Omega)$','$\varpi(\Omega)$','Interpreter','latex','FontSize',10,'Location','NorthWest')
title('$(a)$','Interpreter','latex','FontSize',20)
xlabel('$\sigma$','Interpreter','latex','FontSize',20)
xlim([sig_grid(1),sig_grid(end)])
grid on

subplot(1,3,2)
plot(gam_grid',Ups_gambar_grid,'b',gam_grid',del_gambar_grid,'m--',gam_grid',varpi_gambar_grid,'k:','LineWidth',2)
yline(1,'k','LineWidth',2)
% legend('$\Upsilon(\Omega)$','$\delta(\Omega)$','$\varpi(\Omega)$','Interpreter','latex','FontSize',20,'Location','NorthWest')
title('$(b)$','Interpreter','latex','FontSize',20)
xlabel('$\gamma$','Interpreter','latex','FontSize',20)
xlim([gam_grid(1),gam_grid(end)])
grid on


subplot(1,3,3)
plot(varphi_grid',Ups_varphi_grid,'b',varphi_grid',del_varphi_grid,'m--',varphi_grid',varpi_varphi_grid,'k:','LineWidth',2)
yline(1,'k','LineWidth',2)
% legend('$\Upsilon(\Omega)$','$\delta(\Omega)$','$\varpi(\Omega)$','Interpreter','latex','FontSize',20,'Location','NorthWest')
title('$(c)$','Interpreter','latex','FontSize',20)
xlabel('$\varphi$','Interpreter','latex','FontSize',20)
xlim([varphi_grid(1),varphi_grid(end)])
grid on

set(gcf, 'PaperPosition', [0 0 15 4]); 
set(gcf, 'PaperSize', [15 4]); 
saveas(gca,'figure3.eps','epsc') 

%%

varphi_grid        = linspace(-6,6,n);
Omega_varphi_grid  = zeros(n,1);

for i=1:n
    ecuse=ec;
    ecuse.varphi = varphi_grid(i);
    [~,~,Omega_varphi_grid(i),~,~] = make_compstats(ecuse);
end


fig1 = figure()
subplot(1,3,1)
plot(sig_grid',Omega_sig_grid,'b','LineWidth',2)
ylabel('$\Omega$','Interpreter','latex','FontSize',20)
title('$(a)$','Interpreter','latex','FontSize',20)
xlabel('$\sigma$','Interpreter','latex','FontSize',20)
xlim([sig_grid(1),sig_grid(end)])
grid on

subplot(1,3,2)
plot(gam_grid',Omega_gambar_grid,'b','LineWidth',2)
title('$(b)$','Interpreter','latex','FontSize',20)
xlabel('$\gamma$','Interpreter','latex','FontSize',20)
xlim([gam_grid(1),gam_grid(end)])
grid on


subplot(1,3,3)
plot(varphi_grid',Omega_varphi_grid,'b','LineWidth',2)
yline(0,'k','LineWidth',1)
title('$(c)$','Interpreter','latex','FontSize',20)
xlabel('$\varphi$','Interpreter','latex','FontSize',20)
xlim([varphi_grid(1),varphi_grid(end)])
grid on

set(gcf, 'PaperPosition', [0 0 15 4]); 
set(gcf, 'PaperSize', [15 4]); 
saveas(gca,'figure1.eps','epsc') 

%% Figure 2

ec.rhor = 0.5;

ecacy = ec;
ecacy.THETA = 1;


r0 = -1;
T = 11;
irf    = realpeg_dynamics_iid(ec,r0,T);
irfacy = realpeg_dynamics_iid(ecacy,r0,T);

tgrid = 0:T-1;


subplot(1,4,1)
plot(tgrid, irf.rt,'b','LineWidth',2)
grid on 
title('(a) $r_t$','Interpreter','latex','FontSize',20)
ylabel('% pts')

subplot(1,4,3)
plot(tgrid, irf.yt,'b','LineWidth',2)
grid on 
title('(c) $y_t$','Interpreter','latex','FontSize',20)

subplot(1,4,2)
plot(tgrid, irf.murt,'r--',tgrid, irf.mut,'b','LineWidth',2)
grid on 
title('(b) $\mu_t$','Interpreter','latex','FontSize',20)
legend('only $r$','total $\mu$','Interpreter','latex','FontSize',15,'Location','SouthEast') 

subplot(1,4,4)
plot(tgrid, irf.SIGrt,'r--',tgrid, irf.SIGact,'m:',tgrid, irf.SIGt,'b','LineWidth',2)
grid on 
title('(d) $\Sigma_t$','Interpreter','latex','FontSize',20)
legend('only $r$','total $\mu$','total','Interpreter','latex','FontSize',15,'Location','SouthEast') 


set(gcf, 'PaperPosition', [0 0 15 3]); 
set(gcf, 'PaperSize', [15 3]); 
saveas(gca,'figure2.eps','epsc') 

