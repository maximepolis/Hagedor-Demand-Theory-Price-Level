
%% run decomposition

disp(' ');disp('V decomposition with inflation');disp(' ');
Vdecomp   = c3_Vdecomposition_f(parameters, results_inf);
results_inf.Vdecomp=Vdecomp;

disp(' ');disp('V decomposition without inflation');disp(' ');
Vdecomp   = c3_Vdecomposition_f(parameters, results_noi);
results_noi.Vdecomp=Vdecomp;

disp(' ');disp(' ');

%% plot decomposition


myfig = figure;            
set(myfig, 'Position', [50 50 400 400])

grid
hold on
plot(a,results_inf.Vdecomp.Vc(:,z2) ./(1-results_inf.d(:,z2)),'-','Color',[0.2,0.4,0.8],'linewidth',2)
plot(a,results_inf.Vdecomp.Vpi(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.7,0.8,0.9],'linewidth',2)
plot(a,results_noi.Vdecomp.Vc(:,z2) ./(1-results_noi.d(:,z2)),':','Color',[0.8,0.2,0.1],'linewidth',2)
plot(a,results_noi.Vdecomp.Vpi(:,z2)./(1-results_noi.d(:,z2)),':','Color',[1.0,0.7,0.6],'linewidth',2)
plot(a,results_inf.Vdecomp.Vc(:,z2) ,'-','Color',[0.2,0.4,0.8],'linewidth',1)
plot(a,results_inf.Vdecomp.Vpi(:,z2),'-','Color',[0.7,0.8,0.9],'linewidth',1)
plot(a,results_noi.Vdecomp.Vc(:,z2) ,':','Color',[0.8,0.2,0.1],'linewidth',1)
plot(a,results_noi.Vdecomp.Vpi(:,z2),':','Color',[1.0,0.7,0.6],'linewidth',1)
plot(a,results_inf.Vdecomp.Vc(:,z2) ./(1-results_inf.d(:,z2)),'-','Color',[0.2,0.4,0.8],'linewidth',2)
ylim([-0.2 0.15])
xlim([0 0.4])

legend({'$V_c$ (baseline)', '$V_\pi$ (baseline)','$V_c$ (no inflation)','$V_\pi$ (no inflation)'},'Location','northeast', 'interpreter','latex','FontSize',10)
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')

print -dpdf    p15_Vdecomp
savefig(myfig,'g15_Vdecomp.fig');



%% plot decomposition (6 panels, not used)


myfig = figure;            
set(myfig, 'Position', [50 50 800 500])

subplot(2,3,1)
ylabel('Consumption, $V_c$','FontSize',12,'interpreter','latex')
title('(a) Income $y=0.95$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.Vdecomp.Vc(:,z1)./(1-results_inf.d(:,z1)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.Vdecomp.Vc(:,z1)./(1-results_noi.d(:,z1)),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(a,results_inf.Vdecomp.Vc(:,z1),'-','Color',[0.3,0.5,0.8],'linewidth',1)
plot(a,results_noi.Vdecomp.Vc(:,z1),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([-0.5 0.5])
xlim([0 0.4])

subplot(2,3,2)
ylabel('Consumption, $V_c$','FontSize',12,'interpreter','latex')
title('(b) Income $y=1.00$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.Vdecomp.Vc(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.Vdecomp.Vc(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(a,results_inf.Vdecomp.Vc(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
plot(a,results_noi.Vdecomp.Vc(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([-0.5 0.5])
xlim([0 0.4])

subplot(2,3,3)
ylabel('Consumption, $V_c$','FontSize',12,'interpreter','latex')
title('(c) Income $y=1.05$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.Vdecomp.Vc(:,z3)./(1-results_inf.d(:,z3)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.Vdecomp.Vc(:,z3)./(1-results_noi.d(:,z3)),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(a,results_inf.Vdecomp.Vc(:,z3),'-','Color',[0.3,0.5,0.8],'linewidth',1)
plot(a,results_noi.Vdecomp.Vc(:,z3),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([-0.5 0.5])
xlim([0 0.4])

subplot(2,3,4)
ylabel('Inflation, $V_\pi$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
title('(d) Income $y=0.95$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.Vdecomp.Vpi(:,z1)./(1-results_inf.d(:,z1)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.Vdecomp.Vpi(:,z1)./(1-results_noi.d(:,z1)),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(a,results_inf.Vdecomp.Vpi(:,z1),'-','Color',[0.3,0.5,0.8],'linewidth',1)
plot(a,results_noi.Vdecomp.Vpi(:,z1),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([-0.5 0.5])
xlim([0 0.4])

legend({'Baseline','No inflation'},'Location','northeast', 'interpreter','latex','FontSize',10)

subplot(2,3,5)
ylabel('Inflation, $V_\pi$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
title('(e) Income $y=1.00$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.Vdecomp.Vpi(:,z2)./(1-results_inf.d(:,z2)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.Vdecomp.Vpi(:,z2)./(1-results_noi.d(:,z2)),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(a,results_inf.Vdecomp.Vpi(:,z2),'-','Color',[0.3,0.5,0.8],'linewidth',1)
plot(a,results_noi.Vdecomp.Vpi(:,z2),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([-0.5 0.5])
xlim([0 0.4])

subplot(2,3,6)
ylabel('Inflation, $V_\pi$','FontSize',12,'interpreter','latex')
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
title('(f) Income $y=1.05$','FontSize',12,'interpreter','latex')
grid
hold on
plot(a,results_inf.Vdecomp.Vpi(:,z3)./(1-results_inf.d(:,z3)),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(a,results_noi.Vdecomp.Vpi(:,z3)./(1-results_noi.d(:,z3)),':','Color',[0.8,0.4,0.2],'linewidth',2)
plot(a,results_inf.Vdecomp.Vpi(:,z3),'-','Color',[0.3,0.5,0.8],'linewidth',1)
plot(a,results_noi.Vdecomp.Vpi(:,z3),':','Color',[0.8,0.4,0.2],'linewidth',1)
ylim([-0.5 0.5])
xlim([0 0.4])


print -dpdf    p85_Vdecomp
savefig(myfig,'g85_Vdecomp.fig');
