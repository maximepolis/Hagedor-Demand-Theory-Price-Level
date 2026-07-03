%% Equilibrium objects

myfig = figure;            
set(myfig, 'Position', [50 50 800 800])

subplot(3,3,1)
title('(a) Value function, $V$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.V_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.V_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.V_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.V_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([-0.2 0.1])
xlim([0 0.35])

legend({'Baseline','No inflation'},'Location','northeast', 'interpreter','latex','FontSize',10)


subplot(3,3,2)
title('(b) Inflation, $\pi$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.pi_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.pi_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.pi_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.pi_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.15])
xlim([0 0.35])

subplot(3,3,3)
title('(c) Consumption, $c$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.c_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.c_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.c_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.c_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0.8 1.2])
xlim([0 0.35])

subplot(3,3,4)
title('(d) Bond price, $Q$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,results_inf.Q_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.Q_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.Q_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.Q_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 1.2])
xlim([0 0.35])


subplot(3,3,5)
title('(e) Drift, $s$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,-results_inf.s_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,-results_noi.s_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,-results_inf.s_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,-results_noi.s_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([-0.15 0.15])
xlim([0 0.35])


subplot(3,3,6)
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
title('(f) Default frontier, $d(b,y)$','FontSize',12,'interpreter','latex')
text(0.03,1.03,'No default, $d=0$','FontSize',12,'interpreter','latex')
text(0.13,0.91,'Default, $d=1$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,exp(results_inf.def),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,exp(results_noi.def),':','Color',[0.8,0.4,0.2],'linewidth',2)
xlim([0 0.35])
ylim([exp(z(2)) 1.05])


subplot(3,3,7)
title('(g) Yield, $r$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,results_inf.r_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.r_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.r_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.r_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.50])
xlim([0 0.35])

subplot(3,3,8)
title('(h) Default premium','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,(results_inf.r_real_eff(:,z2)-parameters.r_bar)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,(results_noi.r_real_eff(:,z2)-parameters.r_bar)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a, results_inf.r_real_eff(:,z2)-parameters.r_bar,'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a, results_noi.r_real_eff(:,z2)-parameters.r_bar,':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.50])
xlim([0 0.35])

subplot(3,3,9)
title('(i) Inflation premium','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,(results_inf.r_eff(:,z2)-results_inf.r_real_eff(:,z2))./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,(results_noi.r_eff(:,z2)-results_noi.r_real_eff(:,z2))./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a, results_inf.r_eff(:,z2)-results_inf.r_real_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a, results_noi.r_eff(:,z2)-results_noi.r_real_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.50])
xlim([0 0.35])

print -dpdf    p01_objects
savefig(myfig,'g01_objects.fig');


%% Equilibrium objects (big version for appendix)


myfig = figure;            
set(myfig, 'Position', [50 50 800 1100])

subplot(6,3,1)
ylabel('Value function, $V$','FontSize',12,'interpreter','latex')
title('Income $y=0.95$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.V_eff(:,z1)./(1-results_inf.d(:,z1)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.V_eff(:,z1)./(1-results_noi.d(:,z1)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.V_eff(:,z1),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.V_eff(:,z1),':','Color',[0.8,0.4,0.2],'linewidth',1)
%ylim([-0.5 0.5])
xlim([0 0.4])

subplot(6,3,2)
title('Income $y=1$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.V_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.V_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.V_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.V_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
%ylim([-0.5 0.5])
xlim([0 0.4])

subplot(6,3,3)
title('Income $y=1.05$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.V_eff(:,z3)./(1-results_inf.d(:,z3)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.V_eff(:,z3)./(1-results_noi.d(:,z3)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.V_eff(:,z3),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.V_eff(:,z3),':','Color',[0.8,0.4,0.2],'linewidth',1)
%ylim([-0.5 0.5])
xlim([0 0.4])


subplot(6,3,4)
ylabel('Inflation, $\pi$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.pi_eff(:,z1)./(1-results_inf.d(:,z1)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.pi_eff(:,z1)./(1-results_noi.d(:,z1)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.pi_eff(:,z1),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.pi_eff(:,z1),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.25])
xlim([0 0.4])

subplot(6,3,5)
hold on
grid
plot(a,results_inf.pi_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.pi_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.pi_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.pi_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.25])
xlim([0 0.4])

subplot(6,3,6)
hold on
grid
plot(a,results_inf.pi_eff(:,z3)./(1-results_inf.d(:,z3)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.pi_eff(:,z3)./(1-results_noi.d(:,z3)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.pi_eff(:,z3),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.pi_eff(:,z3),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.25])
xlim([0 0.4])


subplot(6,3,7)
ylabel('Consumption, $c$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,results_inf.c_eff(:,z1)./(1-results_inf.d(:,z1)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.c_eff(:,z1)./(1-results_noi.d(:,z1)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.c_eff(:,z1),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.c_eff(:,z1),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0.8 1.25])
xlim([0 0.4])

subplot(6,3,8)
hold on
grid
plot(a,results_inf.c_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.c_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.c_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.c_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0.8 1.25])
xlim([0 0.4])

subplot(6,3,9)
hold on
grid
plot(a,results_inf.c_eff(:,z3)./(1-results_inf.d(:,z3)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.c_eff(:,z3)./(1-results_noi.d(:,z3)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.c_eff(:,z3),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.c_eff(:,z3),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0.8 1.25])
xlim([0 0.4])


subplot(6,3,10)
ylabel('Yields, $r$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,results_inf.r_eff(:,z1)./(1-results_inf.d(:,z1)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.r_eff(:,z1)./(1-results_noi.d(:,z1)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.r_eff(:,z1),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.r_eff(:,z1),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])

subplot(6,3,11)
hold on
grid
plot(a,results_inf.r_eff(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.r_eff(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.r_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.r_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])

subplot(6,3,12)
hold on
grid
plot(a,results_inf.r_eff(:,z3)./(1-results_inf.d(:,z3)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.r_eff(:,z3)./(1-results_noi.d(:,z3)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a,results_inf.r_eff(:,z3),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a,results_noi.r_eff(:,z3),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])


subplot(6,3,13)
ylabel('Default premium','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,(results_inf.r_real_eff(:,z1)-parameters.r_bar)./(1-results_inf.d(:,z1)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,(results_noi.r_real_eff(:,z1)-parameters.r_bar)./(1-results_noi.d(:,z1)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a, results_inf.r_real_eff(:,z1)-parameters.r_bar,'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a, results_noi.r_real_eff(:,z1)-parameters.r_bar,':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])

subplot(6,3,14)
hold on
grid
plot(a,(results_inf.r_real_eff(:,z2)-parameters.r_bar)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,(results_noi.r_real_eff(:,z2)-parameters.r_bar)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a, results_inf.r_real_eff(:,z2)-parameters.r_bar,'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a, results_noi.r_real_eff(:,z2)-parameters.r_bar,':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])

subplot(6,3,15)
hold on
grid
plot(a,(results_inf.r_real_eff(:,z3)-parameters.r_bar)./(1-results_inf.d(:,z3)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,(results_noi.r_real_eff(:,z3)-parameters.r_bar)./(1-results_noi.d(:,z3)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a, results_inf.r_real_eff(:,z3)-parameters.r_bar,'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a, results_noi.r_real_eff(:,z3)-parameters.r_bar,':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])


subplot(6,3,16)
ylabel('Inflation premium','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,(results_inf.r_eff(:,z1)-results_inf.r_real_eff(:,z1))./(1-results_inf.d(:,z1)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,(results_noi.r_eff(:,z1)-results_noi.r_real_eff(:,z1))./(1-results_noi.d(:,z1)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a, results_inf.r_eff(:,z1)-results_inf.r_real_eff(:,z1),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a, results_noi.r_eff(:,z1)-results_noi.r_real_eff(:,z1),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])

subplot(6,3,17)
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,(results_inf.r_eff(:,z2)-results_inf.r_real_eff(:,z2))./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,(results_noi.r_eff(:,z2)-results_noi.r_real_eff(:,z2))./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a, results_inf.r_eff(:,z2)-results_inf.r_real_eff(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a, results_noi.r_eff(:,z2)-results_noi.r_real_eff(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])

subplot(6,3,18)
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
hold on
grid
plot(a,(results_inf.r_eff(:,z3)-results_inf.r_real_eff(:,z3))./(1-results_inf.d(:,z3)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,(results_noi.r_eff(:,z3)-results_noi.r_real_eff(:,z3))./(1-results_noi.d(:,z3)),':','Color',[0.8,0.4,0.2],'linewidth',2)
% plot(a, results_inf.r_eff(:,z3)-results_inf.r_real_eff(:,z3),'-','Color',[0.3,0.5,0.8],'linewidth',1)
% plot(a, results_noi.r_eff(:,z3)-results_noi.r_real_eff(:,z3),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([0 0.6])
xlim([0 0.4])
legend({'Baseline','No inflation'},'Location','best', 'interpreter','latex','FontSize',10)


print -dpdf    p81_objects
savefig(myfig,'g81_objects.fig');


%% Generalized impulse response functions (negative shock)

irf_time=1:120;
irf_time=irf_time*irf_n_inf.dt;


irf_n_inf.s1=-(parameters.lambda+irf_n_inf.pi).*irf_n_inf.a;
irf_n_noi.s1=-(parameters.lambda+irf_n_noi.pi).*irf_n_noi.a;

irf_n_inf.s2=irf_n_inf.s-irf_n_inf.s1;
irf_n_noi.s2=irf_n_noi.s-irf_n_noi.s1;

sss_inf.s1=-(parameters.lambda+sss_inf.pi).*sss_inf.a;
sss_noi.s1=-(parameters.lambda+sss_noi.pi).*sss_noi.a;

sss_inf.s2=sss_inf.s-sss_inf.s1;
sss_noi.s2=sss_noi.s-sss_noi.s1;



myfig = figure;            
set(myfig, 'Position', [50 50 800 750])

subplot(3,3,1)
ylabel('Deviation from sss (%)','FontSize',10,'interpreter','latex')
title('(a) Income, $y$','FontSize',12,'interpreter','latex')
grid
hold on
plot(irf_time,exp(irf_n_inf.z(1:120))/exp(sss_inf.z)*100-100,'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(irf_time,exp(irf_n_noi.z(1:120))/exp(sss_noi.z)*100-100,':','Color',[0.8,0.4,0.2],'linewidth',2)

subplot(3,3,2)
title('(b) Debt, $b$','FontSize',12,'interpreter','latex')
grid
hold on
plot(irf_time,irf_n_inf.a(1:120)/sss_inf.a*100-100,'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(irf_time,irf_n_noi.a(1:120)/sss_noi.a*100-100,':','Color',[0.8,0.4,0.2],'linewidth',2)

disp(['IRF: max fall in debt with    inflation: ' num2str(-(max(irf_n_inf.a(1:120))-sss_inf.a))])
disp(['IRF: max fall in debt without inflation: ' num2str(-(max(irf_n_noi.a(1:120))-sss_noi.a))])

subplot(3,3,3)
title('(c) Bond price, $Q$','FontSize',12,'interpreter','latex')
grid
hold on
plot(irf_time,irf_n_inf.Q(1:120)/sss_inf.Q*100-100,'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(irf_time,irf_n_noi.Q(1:120)/sss_noi.Q*100-100,':','Color',[0.8,0.4,0.2],'linewidth',2)


subplot(3,3,4)
ylabel('Deviation from sss (p.p.)','FontSize',10,'interpreter','latex')
title('(d) Inflation, $\pi$','FontSize',12,'interpreter','latex')
grid
hold on
plot(irf_time,irf_n_inf.pi(1:120)*100-sss_inf.pi*100,'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(irf_time,irf_n_noi.pi(1:120)*100-sss_noi.pi*100,':','Color',[0.8,0.4,0.2],'linewidth',2)

subplot(3,3,5)
ylabel('Deviation from sss (%)','FontSize',10,'interpreter','latex')
title('(e) Consumption, $c$','FontSize',12,'interpreter','latex')
grid
hold on
plot(irf_time,irf_n_inf.c(1:120)/sss_inf.c*100-100,'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(irf_time,irf_n_noi.c(1:120)/sss_noi.c*100-100,':','Color',[0.8,0.4,0.2],'linewidth',2)
ylim([-4 0])


subplot(3,3,6)
title('(f) Motion in $(b,y)$ plane','FontSize',12,'interpreter','latex')
grid
hold on
%plot(a,exp(results_inf.def),'-','Color',[0.3,0.5,0.8],'linewidth',1)
%plot(a,exp(results_noi.def),':','Color',[0.8,0.4,0.2],'linewidth',1)
plot(-sss_inf.a,exp(sss_inf.z),'*','Color',[0.3,0.5,0.8],'linewidth',2)
plot(-sss_noi.a,exp(sss_noi.z),'*','Color',[0.8,0.4,0.2],'linewidth',2)
plot(-irf_n_inf.a,exp(irf_n_inf.z),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(-irf_n_noi.a,exp(irf_n_noi.z),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(-irf_n_inf.a(120:121),exp(irf_n_inf.z(120:121)),'<','Color',[0.3,0.5,0.8],'linewidth',2,'MarkerIndices',[2 2])
plot(-irf_n_noi.a(120:121),exp(irf_n_noi.z(120:121)),'<','Color',[0.8,0.4,0.2],'linewidth',2,'MarkerIndices',[2 2])
plot([-sss_inf.a -sss_inf.a],[1 0.992],'--v','Color',[0.3,0.5,0.8],'linewidth',1,'MarkerIndices',[2 2])
plot([-sss_noi.a -sss_noi.a],[1 0.992],'--v','Color',[0.8,0.4,0.2],'linewidth',1,'MarkerIndices',[2 2])
plot(a,exp(results_inf.def),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,exp(results_noi.def),':','Color',[0.8,0.4,0.2],'linewidth',2)
ylim([0.97 1.005])
xlim([0.16 0.24])
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
ylabel('Income, $y$','FontSize',12,'interpreter','latex')



subplot(3,3,7)
ylabel('Deviation from sss (p.p.)','FontSize',10,'interpreter','latex')
xlabel('Time (years)','FontSize',12,'interpreter','latex')
title('(g) Yield, $r$','FontSize',12,'interpreter','latex')
grid
hold on
plot(irf_time,irf_n_inf.r(1:120)*100-sss_inf.r*100,'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(irf_time,irf_n_noi.r(1:120)*100-sss_noi.r*100,':','Color',[0.8,0.4,0.2],'linewidth',2)
ylim([-0.5 3])


subplot(3,3,8)
title('(h) Default premium','FontSize',12,'interpreter','latex')
xlabel('Time (years)','FontSize',12,'interpreter','latex')
grid
hold on
plot(irf_time,irf_n_inf.rdef(1:120)*100-sss_inf.rdef*100,'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(irf_time,irf_n_noi.rdef(1:120)*100-sss_noi.rdef*100,':','Color',[0.8,0.4,0.2],'linewidth',2)
ylim([-0.5 3])


subplot(3,3,9)
title('(i) Inflation premium','FontSize',12,'interpreter','latex')
xlabel('Time (years)','FontSize',12,'interpreter','latex')
grid
hold on
plot(irf_time,irf_n_inf.rinf(1:120)*100-sss_inf.rinf*100,'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(irf_time,irf_n_noi.rinf(1:120)*100-sss_noi.rinf*100,':','Color',[0.8,0.4,0.2],'linewidth',2)
ylim([-0.5 3])
legend({'Baseline','No inflation'},'Location','best', 'interpreter','latex','FontSize',10)


print -dpdf    p02_IRF_n
savefig(myfig,'g02_IRF_n.fig');


%% Isowelfare frontier

temp=results_inf.V_eff-results_noi.V_eff;
temp=exp(parameters.rho*temp)*100-100;
cmap=[0.70,0.60,0.50
      0.75,0.65,0.55
      0.80,0.70,0.60
      0.85,0.75,0.65
      0.90,0.80,0.70
      0.95,0.85,0.75
      1.00,0.90,0.80
      0.80,0.90,1.00
      0.75,0.85,0.95
      0.70,0.80,0.90
      0.65,0.75,0.85];

myfig = figure;            
set(myfig, 'Position', [50 50 500 400])

xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
title('Welfare improvement with inflation, $V(b,y)-V^{\pi=0}(b,y)$','FontSize',12,'interpreter','latex')
grid
hold on
contourf(a,exp(z),temp',[-0.24:0.04:0.16])
colormap(cmap)
plot(a,exp(results_inf.def),'-','Color',[0.3,0.5,0.8],'linewidth',4)
plot(a,exp(results_noi.def),':','Color',[0.8,0.4,0.2],'linewidth',4)
xlim([0 0.4])
ylim([exp(z(2)) exp(z(end-1))])
legend({'$V(b,y)-V^{\pi=0}(b,y)$','Default threshold with inflation','Default threshold without inflation'},'Location','northwest', 'interpreter','latex','FontSize',10)
text(0.01,1.05,'Brown = welfare loss','FontSize',12,'interpreter','latex')
text(0.15,0.92,'Blue = welfare gain','FontSize',12,'interpreter','latex')

print -dpdf    p83_improvement
savefig(myfig,'g83_improvement.fig');

%%
cmap=[0.60,0.50,0.40
      0.65,0.55,0.45
      0.70,0.60,0.50
      0.75,0.65,0.55
      0.80,0.70,0.60
      0.85,0.75,0.65
      0.90,0.80,0.70
      0.95,0.85,0.75
      1.00,0.90,0.80
      0.80,0.90,1.00
      0.75,0.85,0.95
      0.70,0.80,0.90];



temp_frontier1 = nan(1000,1);
temp_frontier2 = nan(1000,1);
it_temp=0;
it_done=0;
temp_d=double(results_inf.d);
for temp1=1:size(temp,2)
    it_done=0;
    for temp2=size(temp,1):-1:2
        if temp(temp2,temp1)*temp(temp2-1,temp1)*(1-temp_d(temp2,temp1))<0
            if it_done==0
                it_temp=it_temp+1;
                it_done=1;
                temp_frontier1(it_temp)=(a(temp2)*abs(temp(temp2-1,temp1))+a(temp2-1)*abs(temp(temp2,temp1)))/(abs(temp(temp2,temp1))+abs(temp(temp2-1,temp1)));
                temp_frontier2(it_temp)=z(temp1);
            else
%                 temp_frontier1(it_temp+500)=(a(temp2)*abs(temp(temp2-1,temp1))+a(temp2-1)*abs(temp(temp2,temp1)))/(abs(temp(temp2,temp1))+abs(temp(temp2-1,temp1)));
%                 temp_frontier2(it_temp+500)=z(temp1);
            end
        end
    end
end

temp=results_inf.V_eff-results_noi.V_eff-100*results_inf.d;
temp=exp(parameters.rho*temp)*100-100;

myfig = figure;            
set(myfig, 'Position', [50 50 500 400])
contourf(a,exp(z),temp',[0 0])
xlim([0 0.4])

myfig = figure;            
set(myfig, 'Position', [50 50 500 400])

xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
title('Welfare improvement with inflation, $V(b,y)-V^{\pi=0}(b,y)$','FontSize',12,'interpreter','latex')
grid
hold on
contourf(a,exp(z),temp',[-0.24:0.04:0.12])
colormap(cmap)
plot(a,exp(results_inf.def),'-','Color',[0.3,0.5,0.8],'linewidth',4)
plot(a,exp(results_noi.def),':','Color',[0.8,0.4,0.2],'linewidth',4)
plot(temp_frontier1,exp(temp_frontier2),'-k','linewidth',2)
xlim([0 0.4])
ylim([exp(z(2)) exp(z(end-1))])
legend({'$V(b,y)-V^{\pi=0}(b,y)$','Default threshold with inflation','Default threshold without inflation'},'Location','northwest', 'interpreter','latex','FontSize',10)
text(0.01,1.05,'Brown = welfare loss','FontSize',12,'interpreter','latex')
text(0.15,0.92,'Blue = welfare gain','FontSize',12,'interpreter','latex')

print -dpdf    p03_improvement
savefig(myfig,'g03_improvement.fig');

clear temp temp1 temp2 temp_frontier1 temp_frontier2


%% Stationary distribution


myfig = figure;            
set(myfig, 'Position', [50 50 800 350])

subplot(1,2,1)
title('(a) Distribution (repayment spells), $g(b,y)$','FontSize',12,'interpreter','latex')
hold on
mesh(a,exp(z),results_inf.g')
view([0,0,90])
plot3(a,exp(results_inf.def),20*ones(size(a)),'-','Color',[1.0,0.4,0.4],'linewidth',2)
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
xlim([0 0.4])
ylim([exp(z(2)) exp(z(end-1))])

subplot(1,2,2)
title('(b) Comparison of distributions, $g(b,y=1)$','FontSize',12,'interpreter','latex')
hold on
plot(a,results_inf.g(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.g(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(-sss_inf.a,0,'*','Color',[0.3,0.5,0.8],'linewidth',2)
plot(-sss_noi.a,0,'*','Color',[0.8,0.4,0.2],'linewidth',2)
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
legend({'Baseline','No inflation','$b_{sss}$ baseline','$b_{sss}$ no inflation'},'Location','northeast', 'interpreter','latex','FontSize',10)
xlim([a(end) a(2)])

print -dpdf  -r300    p04_distribution
savefig(myfig,'g04_distribution.fig');

clear myfig
save z_finalworkspace


%% Stationary distribution (three panels)


myfig = figure;            
set(myfig, 'Position', [50 50 900 400])

subplot(2,2,[1 3])
title('(a) Distribution (repayment spells), $g(b,y)$','FontSize',12,'interpreter','latex')
hold on
mesh(a,exp(z),results_inf.g')
view([0,0,90])
plot3(a,exp(results_inf.def),20*ones(size(a)),'-','Color',[1.0,0.4,0.4],'linewidth',2)
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
xlim([0 0.4])
ylim([exp(z(2)) exp(z(end-1))])

subplot(2,2,2)
title('(b) Comparison of distributions, $g(b,y=1)$','FontSize',12,'interpreter','latex')
hold on
plot(a,results_inf.g(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.g(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(-sss_inf.a,0,'*','Color',[0.3,0.5,0.8],'linewidth',2)
plot(-sss_noi.a,0,'*','Color',[0.8,0.4,0.2],'linewidth',2)
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
xlim([a(end) a(2)])
legend({'Baseline','No inflation','$b_{sss}$ baseline','$b_{sss}$ no inflation'},'Location','northeast', 'interpreter','latex','FontSize',10)

subplot(2,2,4)
title('(c) Comparison of marginal distributions, $g(b)$','FontSize',12,'interpreter','latex')
hold on
plot(a,sum(results_inf.g,2)./sum(results_inf.g(:)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,sum(results_noi.g,2)./sum(results_noi.g(:)),':','Color',[0.8,0.4,0.2],'linewidth',2)
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
xlim([a(end) a(2)])
legend({'Baseline','No inflation'},'Location','south', 'interpreter','latex','FontSize',10)

print -dpdf  -r300    p04_distribution3
savefig(myfig,'g04_distribution3.fig');

clear myfig
save z_finalworkspace




%% Stationary distribution - with 3D views


myfig = figure;            
set(myfig, 'Position', [50 50 800 1100])

subplot(3,2,1)
mesh(exp(z),a,results_inf.g)
xlabel('Income, $y$','FontSize',12,'interpreter','latex')
ylabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
view([166,33])
title('(a) Distribution (repayment spells), $g(b,y)$','FontSize',12,'interpreter','latex')
ylim([min(a) max(a)])
xlim([exp(min(z))+0.005 exp(max(z))])

subplot(3,2,2)
mesh(exp(z),a,results_inf.g)
xlabel('Income, $y$','FontSize',12,'interpreter','latex')
ylabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
view([105,33])
title('(b) Distribution (repayment spells), $g(b,y)$','FontSize',12,'interpreter','latex')
ylim([min(a) max(a)])
xlim([exp(min(z))+0.005 exp(max(z))])

subplot(3,2,3)
title('(c) Distribution (repayment spells), $g(b,y)$','FontSize',12,'interpreter','latex')
hold on
mesh(a,exp(z),results_inf.g')
view([0,0,90])
plot3(a,exp(results_inf.def),20*ones(size(a)),'-','Color',[1.0,0.4,0.4],'linewidth',2)
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
xlim([min(a) max(a)])
ylim([exp(min(z))+0.005 exp(max(z))])

subplot(3,2,4)
title('(d) Distribution (default spells), $g_{def}(b,y)$','FontSize',12,'interpreter','latex')
hold on
mesh(a,exp(z),results_inf.g_def')
view([0,0,90])
plot3(a,exp(results_inf.def),20*ones(size(a)),'-','Color',[1.0,0.4,0.4],'linewidth',2)
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
xlim([min(a) max(a)])
ylim([exp(min(z))+0.005 exp(max(z))])

subplot(3,2,5)
title('(e) Distr. without inflation (repayment), $g(b,y)$','FontSize',12,'interpreter','latex')
hold on
mesh(a,exp(z),results_noi.g')
view([0,0,90])
plot3(a,exp(results_noi.def),20*ones(size(a)),'-','Color',[1.0,0.4,0.4],'linewidth',2)
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
xlim([min(a) max(a)])
ylim([exp(min(z))+0.005 exp(max(z))])

subplot(3,2,6)
title('(f) Distr. without inflation (default), $g_{def}(b,y)$','FontSize',12,'interpreter','latex')
hold on
mesh(a,exp(z),results_noi.g_def')
view([0,0,90])
plot3(a,exp(results_noi.def),20*ones(size(a)),'-','Color',[1.0,0.4,0.4],'linewidth',2)
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
xlim([min(a) max(a)])
ylim([exp(min(z))+0.005 exp(max(z))])


print -dpdf   -r300    p84_distribution
savefig(myfig,'g84_distribution.fig');

clear myfig
save z_finalworkspace

%% Episode: obs vs sim

skipper=size(obs.z,1)-size(episode_inf.z,1);

myfig = figure;            
set(myfig, 'Position', [50 50 800 500])

subplot(2,3,1)
title('(a) Income, $y$','FontSize',12,'interpreter','latex')
grid
hold on
plot([2002:episode_inf.dt:(2004-episode_inf.dt)],exp(obs.z),':','color',[0.1,0.5,0.1],'linewidth',3)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],exp(episode_inf.z),'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0.94 0.98])

subplot(2,3,2)
title('(b) Debt/GDP, $b/y$','FontSize',12,'interpreter','latex')
grid
hold on
plot([2002:episode_inf.dt:(2004-episode_inf.dt)],- obs.aY,':','color',[0.1,0.5,0.1],'linewidth',3)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],- episode_inf.aY,'-','color',[0.3,0.5,0.8],'linewidth',2)
% plot(2002,-obs.a0/exp(obs.z0),'*','color',[0.1,0.5,0.1],'linewidth',3)
% plot(2002,-obs.a0/exp(obs.z0),'*','color',[0.3,0.5,0.8],'linewidth',1)
ylim([0 0.25])

subplot(2,3,3)
title('(c) Inflation, $\pi$','FontSize',12,'interpreter','latex')
grid
hold on
plot([2002:episode_inf.dt:(2004-episode_inf.dt)],obs.pi,':','color',[0.1,0.5,0.1],'linewidth',3)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.pi,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0 0.2])
legend({'Data','Model'},'Location','southeast', 'interpreter','latex','FontSize',10)
ylim([0 0.25])

subplot(2,3,4)
title('(d) Spread','FontSize',12,'interpreter','latex')
grid
hold on
plot([2002:episode_inf.dt:(2004-episode_inf.dt)],obs.rdif,':','color',[0.1,0.5,0.1],'linewidth',3)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.rdif,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0 0.5])

subplot(2,3,5)
title('(e) Default premium','FontSize',12,'interpreter','latex')
grid
hold on
plot([2002:episode_inf.dt:(2004-episode_inf.dt)],obs.rdef,':','color',[0.1,0.5,0.1],'linewidth',3)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.rdef,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0 0.5])

subplot(2,3,6)
title('(f) Inflation premium','FontSize',12,'interpreter','latex')
grid
hold on
plot([2002:episode_inf.dt:(2004-episode_inf.dt)],obs.rinf,':','color',[0.1,0.5,0.1],'linewidth',3)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.rinf,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0 0.5])

print -dpdf    p05_episode
savefig(myfig,'g05_episode.fig');



%% Episode: inf vs noi


myfig = figure;            
set(myfig, 'Position', [50 50 800 500])

subplot(2,3,1)
title('(a) Debt/GDP, $b/y$','FontSize',12,'interpreter','latex')
grid
hold on
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],-episode_noi.aY,':','color',[0.8,0.4,0.2],'linewidth',2)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],-episode_inf.aY,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0 0.25])

subplot(2,3,2)
title('(b) Consumption, $c$','FontSize',12,'interpreter','latex')
grid
hold on
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_noi.c,':','color',[0.8,0.4,0.2],'linewidth',2)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.c,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0.8 1.2])

subplot(2,3,3)
title('(c) Inflation, $\pi$','FontSize',12,'interpreter','latex')
grid
hold on
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.pi,'-','color',[0.3,0.5,0.8],'linewidth',2)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_noi.pi,':','color',[0.8,0.4,0.2],'linewidth',2)

legend({'Baseline','No inflation'},'Location','south', 'interpreter','latex','FontSize',10)


subplot(2,3,4)
title('(d) Spread','FontSize',12,'interpreter','latex')
grid
hold on
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_noi.rdif,':','color',[0.8,0.4,0.2],'linewidth',2)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.rdif,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0 0.9])

subplot(2,3,5)
title('(e) Default premium','FontSize',12,'interpreter','latex')
grid
hold on
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_noi.rdif,':','color',[0.8,0.4,0.2],'linewidth',2)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.rdef,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0 0.9])

subplot(2,3,6)
title('(f) Inflation premium','FontSize',12,'interpreter','latex')
grid
hold on
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_noi.rdif*0,':','color',[0.8,0.4,0.2],'linewidth',2)
plot([(2002+skipper*episode_inf.dt):episode_inf.dt:(2004-episode_inf.dt)],episode_inf.rinf,'-','color',[0.3,0.5,0.8],'linewidth',2)
ylim([0 0.9])

print -dpdf    p06_episode
savefig(myfig,'g06_episode.fig');



%% Default frontier, big version, not used

temp=results_noi.V_def-results_noi.V;
results_noi.def=min(z)*ones(size(a));
for it1=1:size(temp,1)
    for it2=2:size(temp,2)
        if temp(it1,it2)*temp(it1,it2-1)<=0
            results_noi.def(it1)=(z(it2)*temp(it1,it2-1)-z(it2-1)*temp(it1,it2))/(-temp(it1,it2)+temp(it1,it2-1));
        end
    end
end

temp=results_inf.V_def-results_inf.V;
results_inf.def=min(z)*ones(size(a));
for it1=1:size(temp,1)
    for it2=2:size(temp,2)
        if temp(it1,it2)*temp(it1,it2-1)<=0
            results_inf.def(it1)=(z(it2)*temp(it1,it2-1)-z(it2-1)*temp(it1,it2))/(-temp(it1,it2)+temp(it1,it2-1));
        end
    end
end


myfig = figure;            
set(myfig, 'Position', [50 50 500 400])

xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
title('Default policy, $d(b,y)$','FontSize',12,'interpreter','latex')
text(0.1,1.05,'No default, $d=0$','FontSize',12,'interpreter','latex')
text(0.3,0.95,'Default, $d=1$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,exp(results_inf.def),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,exp(results_noi.def),':','Color',[0.8,0.4,0.2],'linewidth',2)
xlim([0 0.45])
ylim([exp(z(2)) exp(z(end-1))])
legend({'Baseline','No inflation'},'Location','northwest', 'interpreter','latex','FontSize',10)


print -dpdf    p82_default
savefig(myfig,'g82_default.fig');



%% Variance of consumption


myfig = figure;            
set(myfig, 'Position', [50 50 800 350])

subplot(1,2,1)
title('(a) Variance of consumption, inf-noi','FontSize',12,'interpreter','latex')
hold on
mesh(a,exp(z),results_inf.moments.c_var_surf'-results_noi.moments.c_var_surf')
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
view([150,25,15])
xlim([a(end) a(2)])
ylim([exp(z(2)) exp(z(end-1))])

subplot(1,2,2)
title('(a) Variance of consumption, inf-noi','FontSize',12,'interpreter','latex')
hold on
mesh(a,exp(z),(results_inf.moments.c_var_surf'-results_noi.moments.c_var_surf')./(1-results_inf.d'))
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
grid
view([150,25,15])
xlim([a(end) a(2)])
ylim([exp(z(2)) exp(z(end-1))])

print -dpdf  -r300    p88_cvar
savefig(myfig,'g88_cvar.fig');

clear myfig
save z_finalworkspace



