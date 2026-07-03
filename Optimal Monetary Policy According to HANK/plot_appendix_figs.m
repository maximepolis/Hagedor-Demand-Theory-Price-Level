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

%% IRFs for utilitarian iid planner
T = 11;
[irf_discount,tc]    = optdynamics_iid(ec,0,0,-ec.sigzeta,0,T);
[irf_risk,~]        = optdynamics_iid(ec,0,0,0,ec.sigvarsig,T);
% IRF for RANK
[irfRANK_discount,tcRANK]= optdynamics_iid(ecRANK,0,0,-ecRANK.sigzeta,0,T);
[irfRANK_risk,~]    = optdynamics_iid(ecRANK,0,0,0,ecRANK.sigvarsig,T);
% % IRF for RANK tc in iid HANK
 irfRH_discount      = tcdynamics_iid(ec,tcRANK,0,0,-ec.sigzeta,0,T);
 irfRH_risk          = tcdynamics_iid(ec,tcRANK,0,0,0,ec.sigvarsig,T);

%% Appendix Figure J.1: Positive risk shock, utilitarian planner
tgrid = 0:T-1;

figure(9)

subplot(2,3,1)
plot(tgrid,irf_risk.yt*100,'b',tgrid,irfRANK_risk.yt*100,'r--','LineWidth',3);
title('(a) output','Interpreter','latex','FontSize',20)
ylabel('% pts')
grid on

subplot(2,3,2)
plot(tgrid,irf_risk.pit*100,'b',tgrid,irfRANK_risk.pit*100,'r--','LineWidth',3);
title('(b) inflation','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,3)
plot(tgrid,irf_risk.SIGt*100,'b',tgrid,irfRH_risk.SIGt*100,'k:','LineWidth',3);
title('(c) $\Sigma_t$','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,4)
plot(tgrid,round(irf_risk.ynt,10)*100,'b',tgrid,round(irfRANK_risk.ynt,10)*100,'r--','LineWidth',3);
ylabel('% pts')
title('(d) $y^n_t$','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,5)
plot(tgrid,irf_risk.it*100,'b',tgrid,irfRANK_risk.it*100,'r--',tgrid,irfRH_risk.it*100,'k:','LineWidth',3);
hold on
title('(e) nominal rate','Interpreter','latex','FontSize',20)
ylim([-12,2])
grid on

subplot(2,3,6)
plot(tgrid,irf_risk.mut*100,'b',tgrid,irfRH_risk.mut*100,'k:','LineWidth',3);
title('(f) $\mu_t$','Interpreter','latex','FontSize',20)
grid on

set(gcf, 'PaperPosition', [0 0 14 7]); 
set(gcf, 'PaperSize', [14 7]); 
saveas(gca,'figureJ1.eps','epsc') 

%% Appendix Figure J.2: Negative zeta shock, utilitarian planner
tgrid = 0:T-1;

figure(10)

subplot(2,3,1)
plot(tgrid,irf_discount.yt*100,'b',tgrid,irfRANK_discount.yt*100,'r--','LineWidth',3);
title('(a) output','Interpreter','latex','FontSize',20)
ylabel('% pts')
grid on

subplot(2,3,2)
plot(tgrid,irf_discount.pit*100,'b',tgrid,irfRANK_discount.pit*100,'r--','LineWidth',3);
title('(b) inflation','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,3)
plot(tgrid,irf_discount.SIGt*100,'b',tgrid,irfRH_discount.SIGt*100,'k:','LineWidth',3);
title('(c) $\Sigma_t$','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,4)
plot(tgrid,(irf_discount.rt - irf_discount.rstart)*100,'b',tgrid,(irfRANK_discount.rt - irfRANK_discount.rstart)*100,'r--','LineWidth',3);
ylabel('% pts')
title('(d) $r - r^*_t$','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,5)
plot(tgrid,irf_discount.it*100,'b',tgrid,irfRANK_discount.it*100,'r--',tgrid,irfRH_discount.it*100,'k:','LineWidth',3);
hold on
title('(e) nominal rate','Interpreter','latex','FontSize',20)
grid on

subplot(2,3,6)
plot(tgrid,irf_discount.mut*100,'b',tgrid,irfRH_discount.mut*100,'k:','LineWidth',3);
title('(f) $\mu_t$','Interpreter','latex','FontSize',20)
grid on

set(gcf, 'PaperPosition', [0 0 14 7]); 
set(gcf, 'PaperSize', [14 7]); 
saveas(gca,'figureJ2.eps','epsc') 



%% HTM
T = 11;
% 0% HTM
ecHTM0  = ec;
ecHTM0.eta = 0;
ecHTM0 = makeecHTM(ecHTM0);

% % 30% HTM
ecHTM30 = ec;
ecHTM30.eta = 0.3;
ecHTM30 = makeecHTM(ecHTM30);


irfHTM30_z = optdynamicsHTM(ecHTM30,-ecHTM30.sigz,0,T);
irfHTM30_mkup = optdynamicsHTM(ecHTM30,0,ecHTM30.siglam,T);

irfHTM0_z = optdynamicsHTM(ecHTM0,-ecHTM0.sigz,0,T);
irfHTM0_mkup = optdynamicsHTM(ecHTM0,0,ecHTM0.siglam,T);

irfHTM30tc_z = tcdynamicsHTM(ecHTM30,tc,-ecHTM30.sigz,0,T);
irfHTM30tc_mkup = tcdynamicsHTM(ecHTM30,tc,0,ecHTM30.siglam,T);

%% Appendix Figure H.1: negative TFP shock HTM
tgrid = 0:T-1;

irf_z         = optdynamics_iid(ec,-ec.sigz,0,0,0,T);
irf_mkup      = optdynamics_iid(ec,0,ec.siglam,0,0,T);
irfRANK_z     = optdynamics_iid(ecRANK,-ecRANK.sigz,0,0,0,T);
irfRANK_mkup  = optdynamics_iid(ecRANK,0,ecRANK.siglam,0,0,T);

figure()
subplot(1,5,1)
plot(tgrid,100*irfRANK_z.gapt,'r--',tgrid,100*irfHTM30_z.gapt,'m-.',tgrid,100*irf_z.gapt,'b','LineWidth',2)
title('a) output gap','Interpreter','latex','FontSize',16)
ylabel('productivity shock')
ylabel('% pts')
grid on
subplot(1,5,2)
plot(tgrid,irfRANK_z.pit*100,'r--',tgrid,irfHTM30_z.pit*100,'m-.',tgrid,irf_z.pit*100,'b','LineWidth',2)
title('b) inflation','Interpreter','latex','FontSize',16)
grid on
subplot(1,5,3)
plot(tgrid,irfHTM30_z.SIGnht*100,'m-.',tgrid,irfHTM30tc_z.SIGnht*100,'k:','LineWidth',2)
title('c) $\Sigma^{nh}_t$','Interpreter','latex','FontSize',16)
grid on
subplot(1,5,4)
plot(tgrid,irfHTM30_z.SIGht*100,'m-.',tgrid,irfHTM30tc_z.SIGht*100,'k:','LineWidth',2)
title('d) $\Sigma^{h}$','Interpreter','latex','FontSize',16)
grid on
subplot(1,5,5)
plot(tgrid,irfHTM30_z.SIGt*100,'m-.',tgrid,irfHTM30tc_z.SIGt*100,'k:','LineWidth',2)
title('e) $\Sigma$','Interpreter','latex','FontSize',16)
grid on
set(gcf, 'PaperPosition', [0 0 15 3.5]); 
set(gcf, 'PaperSize', [15 3.5]); 
saveas(gca,'figureH1.eps','epsc') 

%% Appendix Figure H.2: positive markup shock HTM
figure()
subplot(1,5,1)
plot(tgrid,100*irfRANK_mkup.yt,'r--',tgrid,100*irfHTM30_mkup.yt,'m-.',tgrid,100*irf_mkup.yt,'b','LineWidth',2)
title('a) output','Interpreter','latex','FontSize',16)
ylabel('productivity shock')
ylabel('% pts')
grid on
subplot(1,5,2)
plot(tgrid,irfRANK_mkup.pit*100,'r--',tgrid,irfHTM30_mkup.pit*100,'m-.',tgrid,irf_mkup.pit*100,'b','LineWidth',2)
title('b) inflation','Interpreter','latex','FontSize',16)
grid on
subplot(1,5,3)
plot(tgrid,irfHTM30_mkup.SIGnht*100,'m-.',tgrid,irfHTM30tc_mkup.SIGnht*100,'k:','LineWidth',2)
title('c) $\Sigma^{nh}_t$','Interpreter','latex','FontSize',16)
grid on
subplot(1,5,4)
plot(tgrid,irfHTM30_mkup.SIGht*100,'m-.',tgrid,irfHTM30tc_mkup.SIGht*100,'k:','LineWidth',2)
title('d) $\Sigma^{h}$','Interpreter','latex','FontSize',16)
grid on
subplot(1,5,5)
plot(tgrid,irfHTM30_mkup.SIGt*100,'m-.',tgrid,irfHTM30tc_mkup.SIGt*100,'k:','LineWidth',2)
title('e) $\Sigma$','Interpreter','latex','FontSize',16)
grid on
set(gcf, 'PaperPosition', [0 0 15 3.5]); 
set(gcf, 'PaperSize', [15 3.5]); 
saveas(gca,'figureH2.eps','epsc') 

%% Persistent income risk

ecRW = ec;
ecRW.rhoxi = 1;
ecRW = makeecPERS(ecRW);

ecpers05 = ec;
ecpers05.rhoxi = 0.5;
ecpers05 = makeecPERS(ecpers05);

ecpers0 = ec;
ecpers0.rhoxi = 0;
ecpers0 = makeecPERS(ecpers0);

%%
T = 5;
tgrid = 0:4;

irf_RW_z = optdynamicsPERS(ecRW,-ecRW.sigz,0,T);
irf_RW_mkup = optdynamicsPERS(ecRW,0,ecRW.siglam,T);

irf_pers0_z = optdynamicsPERS(ecpers0,-ecpers0.sigz,0,T);
irf_pers0_mkup = optdynamicsPERS(ecpers0,0,ecpers0.siglam,T);

irf_pers05_z = optdynamicsPERS(ecpers05,-ecpers05.sigz,0,T);
irf_pers05_mkup = optdynamicsPERS(ecpers05,0,ecpers05.siglam,T);

irfRANK_z       = optdynamics_iid(ecRANK,-ecRANK.sigz,0,0,0,T);
irfRANK_mkup    = optdynamics_iid(ecRANK,0,ecRANK.siglam,0,0,T);

%% Appendix Figure I.1: negative productivity shock with persistent idiosyncratic risk

figure()
subplot(1,4,1)
plot(tgrid,irf_RW_z.gapt*100,'m:',tgrid,irf_pers0_z.gapt*100,'b',tgrid,irfRANK_z.gapt*100,'r--','LineWidth',2)
hold on
plot(tgrid,(irf_pers05_z.gapt)*100,'k-o','LineWidth',1)
grid on
title('(a) output gap','Interpreter','latex','FontSize',20)
subplot(1,4,2)
plot(tgrid,(irf_RW_z.pit)*100,'m:',tgrid,irf_pers0_z.pit*100,'b',tgrid,irfRANK_z.pit*100,'r--','LineWidth',2)
hold on
plot(tgrid,(irf_pers05_z.pit)*100,'k-o','LineWidth',1)
grid on
title('(b) inflation','Interpreter','latex','FontSize',20)
subplot(1,4,3)
plot(tgrid,(irf_RW_z.mut)*100,'m:',tgrid,irf_pers0_z.mut*100,'b','LineWidth',2)
hold on
plot(tgrid,(irf_pers05_z.mut)*100,'k-o','LineWidth',1)
grid on
title('(c) $\mu_t$ ','Interpreter','latex','FontSize',20)
subplot(1,4,4)
plot(tgrid,(irf_RW_z.sight)*100,'m:',tgrid,irf_pers0_z.sight*100,'b','LineWidth',2)
hold on
plot(tgrid,(irf_pers05_z.sight)*100,'k-o','LineWidth',1)
grid on
title('(d) $\sigma_{h,t}$','Interpreter','latex','FontSize',20)
set(gcf, 'PaperPosition', [0 0 15 3]); 
set(gcf, 'PaperSize', [15 3]); 
saveas(gca,'figureI1.eps','epsc')


