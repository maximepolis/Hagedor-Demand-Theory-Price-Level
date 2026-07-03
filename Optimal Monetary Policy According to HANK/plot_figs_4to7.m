%% Code for "Optimal Monetary Policy According to HANK"
%  Version: May 23, 2022
% -----------------------------------------------------------------------

%% Housekeeping
clear;
close all;
clc;

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

% RANK
ecRANK      = ec;
ecRANK.sigy = 0;

ecRANK = makeec(ecRANK);

% NU planner who sets initial tax of 0 pct
ecNU0 = ec;
ecNU0.alphaomu = 1;

%% IRFs

% IRFs for utilitarian iid planner
T = 11;
[irf_z,tc]          = optdynamics_iid(ec,-ec.sigz,0,0,0,T);
[irf_mkup,~]        = optdynamics_iid(ec,0,ec.siglam,0,0,T);
% IRF for RANK
[irfRANK_z,tcRANK]  = optdynamics_iid(ecRANK,-ecRANK.sigz,0,0,0,T);
[irfRANK_mkup,~]    = optdynamics_iid(ecRANK,0,ecRANK.siglam,0,0,T);
% IRF for RANK tc in iid HANK
irfRH_z             = tcdynamics_iid(ec,tcRANK,-ec.sigz,0,0,0,T);
irfRH_mkup          = tcdynamics_iid(ec,tcRANK,0,ec.siglam,0,0,T);

fprintf('Upsilon = %f\n',tc.Upsilon)
fprintf('delta = %f\n',tc.del)
fprintf('varkappa = %f\n',tc.varkappa)
%% Figure 4: Negative z shock, utilitarian planner
tgrid = 0:T-1;

figure(1)

subplot(2,3,1)
plot(tgrid,irf_z.gapt*100,'b',tgrid,irfRANK_z.gapt*100,'r--','LineWidth',3);
title('(a) output gap','Interpreter','latex','FontSize',20)
ylabel('% pts')
grid on

subplot(2,3,2)
plot(tgrid,irf_z.pit*100,'b',tgrid,irfRANK_z.pit*100,'r--','LineWidth',3);
title('(b) inflation','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,3)
plot(tgrid,irf_z.SIGt*100,'b',tgrid,irfRH_z.SIGt*100,'k:','LineWidth',3);
title('(c) $\Sigma_t$','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,4)
plot(tgrid,irf_z.ytildet*100,'b',tgrid,irfRANK_z.ytildet*100,'r--','LineWidth',3);
ylabel('% pts')
title('(d) $y^n_t$','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,5)
plot(tgrid,irf_z.it*100,'b',tgrid,irfRANK_z.it*100,'r--',tgrid,irfRH_z.it*100,'k:','LineWidth',3);
hold on
title('(e) nominal rate','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,6)
plot(tgrid,irf_z.mut*100,'b',tgrid,irfRH_z.mut*100,'k:','LineWidth',3);
title('(f) $\mu_t$','Interpreter','latex','FontSize',20)
grid on

set(gcf, 'PaperPosition', [0 0 14 7]); 
set(gcf, 'PaperSize', [14 7]); 
saveas(gca,'figure4.eps','epsc') 

%% Figure 5: Positive markup shock, utilitarian planner

figure(2)

subplot(2,3,1)
plot(tgrid,irf_mkup.yt*100,'b',tgrid,irfRANK_mkup.yt*100,'r--','LineWidth',3);
title('(a) output','Interpreter','latex','FontSize',20)
ylabel('% pts')
grid on

subplot(2,3,2)
plot(tgrid,irf_mkup.pit*100,'b',tgrid,irfRANK_mkup.pit*100,'r--','LineWidth',3);
title('(b) inflation','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,3)
plot(tgrid,irf_mkup.SIGt*100,'b',tgrid,irfRH_mkup.SIGt*100,'k:','LineWidth',3);
title('(c) $\Sigma_t$','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,4)
plot(tgrid,irf_mkup.ynt*100,'b',tgrid,irfRANK_mkup.ynt*100,'r--','LineWidth',3);
ylabel('% pts')
title('(d) $y^n_t$','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,5)
plot(tgrid,irf_mkup.it*100,'b',tgrid,irfRANK_mkup.it*100,'r--',tgrid,irfRH_mkup.it*100,'k:','LineWidth',3);
hold on
title('(e) nominal rate','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,6)
plot(tgrid,irf_mkup.mut*100,'b',tgrid,irfRH_mkup.mut*100,'k:','LineWidth',3);
title('(f) $\mu_t$','Interpreter','latex','FontSize',20)
grid on

set(gcf, 'PaperPosition', [0 0 14 7]); 
set(gcf, 'PaperSize', [14 7]); 
saveas(gca,'figure5.eps','epsc') 

%% Unequal profits

ec100 = ec;
ec100.etad=1;

ec10 = ec;
ec10.etad = 0.1;

ec50 = ec;
ec50.etad = 0.5;

T=11;
tgrid = 0:T-1;

irfRANK_mkup  = optdynamics_iid(ecRANK,0,ecRANK.siglam,0,0,T);
irf_mkup      = optdynamics_profits(ec100,0,ec100.siglam,0,0,T); 
irf10_mkup    = optdynamics_profits(ec10,0,ec10.siglam,0,0,T); 
irf50_mkup    = optdynamics_profits(ec50,0,ec50.siglam,0,0,T); 

%% Figure 6

figure(5)
subplot(1,5,1)
plot(tgrid,irf_mkup.yt*100,'b',tgrid,irf10_mkup.yt*100,'m:','LineWidth',2);
hold on
plot(tgrid,irf50_mkup.yt*100,'k-o','LineWidth',1);
plot(tgrid,irfRANK_mkup.yt*100,'r--','LineWidth',2);
title('(a) output','Interpreter','latex','FontSize',20)
ylabel('% pts')
grid on
subplot(1,5,2)
plot(tgrid,irf_mkup.pit*100,'b',tgrid,irf10_mkup.pit*100,'m:','LineWidth',2);
hold on
plot(tgrid,irf50_mkup.pit*100,'k-o','LineWidth',1)
plot(tgrid,irfRANK_mkup.pit(1:T)*100,'r--','LineWidth',2);
title('(b) inflation','Interpreter','latex','FontSize',20)
grid on
subplot(1,5,3)
plot(tgrid,irf_mkup.SIGt*100,'b',tgrid,irf10_mkup.SIGt*100,'m:','LineWidth',2)
hold on
plot(tgrid,irf50_mkup.SIGt*100,'k-o','LineWidth',1)
title('(c) $\Sigma_t$','Interpreter','latex','FontSize',20)
grid on
subplot(1,5,4)
plot(tgrid,irf_mkup.Vt*100,'b',tgrid,irf10_mkup.Vt*100,'m:','LineWidth',2)
hold on
plot(tgrid,irf50_mkup.Vt*100,'k-o','LineWidth',1)
title('(d) $\widetilde{\mathcal{V}}_t$','Interpreter','latex','FontSize',20)
grid on
subplot(1,5,5)
plot(tgrid,irf10_mkup.dCt*100,'m:','LineWidth',2)
hold on
plot(tgrid,irf50_mkup.dCt*100,'k-o','LineWidth',1)
title('(e) $\mathcal{C}^d_t - \mathcal{C}^{nd}_t$','Interpreter','latex','FontSize',20)
grid on

set(gcf, 'PaperPosition', [0 0 15 3.5]); 
set(gcf, 'PaperSize', [15 3.5]); 
saveas(gca,'figure6.eps','epsc') 





%% IRF for NU planners
T = 5;
tgrid = 0:T-1;

%RANK
[irfRANK_z,~]       = optdynamics_iid(ecRANK,-ecRANK.sigz,0,0,0,T);
[irfRANK_mkup,~]    = optdynamics_iid(ecRANK,0,ecRANK.siglam,0,0,T);

% utilitarian planner
[irf_z,~]          = optdynamics_iid(ec,-ec.sigz,0,0,0,T);
[irf_mkup,~]       = optdynamics_iid(ec,0,ec.siglam,0,0,T);

% NU planner who sets initial tax of 0 pct
[irfNU0_z,tcNU0]   = optdynamics_iid(ecNU0,-ecNU0.sigz,0,0,0,T);
[irfNU0_mkup,~]    = optdynamics_iid(ecNU0,0,ecNU0.siglam,0,0,T);


%% Figure 7

figure(3)
subplot(1,4,1)
plot(tgrid,irf_z.yt*100,'b',tgrid,irfNU0_z.yt*100,'m:','LineWidth',2);
hold on
plot(tgrid,irfRANK_z.yt*100,'r--','LineWidth',2)
title('(a) output','Interpreter','latex','FontSize',20)
ylabel('% pts')
grid on

subplot(1,4,2)
plot(tgrid,irf_z.pit*100,'b',tgrid, irfNU0_z.pit*100,'m:','LineWidth',2);
hold on
plot(tgrid,irfRANK_z.pit*100,'r--','LineWidth',2)
title('(b) inflation','Interpreter','latex','FontSize',20)
grid on

subplot(1,4,3)
plot(tgrid,irf_z.it*100,'b',tgrid, irfRANK_z.it*100,'r--',tgrid, irfNU0_z.it*100,'m:','LineWidth',2);
hold on
title('(c) nominal rate','Interpreter','latex','FontSize',20)
grid on


subplot(1,4,4)
plot(tgrid,irf_z.mut*100,'b',tgrid, irfNU0_z.mut*100,'m:','LineWidth',2);
hold on
title('(d) $\mu_t$','Interpreter','latex','FontSize',20)
grid on


set(gcf, 'PaperPosition', [0 0 15 3]); 
set(gcf, 'PaperSize', [15 3]); 
saveas(gca,'figure7.eps','epsc') 

