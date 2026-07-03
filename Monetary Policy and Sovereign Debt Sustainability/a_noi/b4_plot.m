% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022, based on codes from GALO NUNO AND BENJAMIN MOLL

% the plots in this folder are for diagnosis during development and
% calibration of the model, the final plots for the paper are in the
% c_graphs folder

close all

%%

myfig1 = figure;            
set(myfig1, 'Position', [50 50 1000 800])

subplot(221)
icut = parameters.I;
acut = results.a(1:icut);
vcut = results.V(1:icut,:);
z    = results.z;
set(gca,'FontSize',14)
mesh(acut,z,vcut')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Value function $v(a,y)$','FontSize',14,'interpreter','latex')

subplot(222)
ccut = results.c(1:icut,:);
set(gca,'FontSize',14)
mesh(acut,z,ccut')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Consumption $c(a,y)$','FontSize',14,'interpreter','latex')

subplot(223)
dcut = results.d(1:icut,:) +0;
%dcut = vcut_def > vcut;
set(gca,'FontSize',14)
mesh(acut,z,dcut')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Default $d(a,y)$','FontSize',14,'interpreter','latex')

subplot(224)
Qcut = results.Q(1:icut,:);
set(gca,'FontSize',14)
mesh(acut,z,Qcut')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Bond price $Q(a,y)$','FontSize',14,'interpreter','latex')

print -dpdf     g41_VcdQ
savefig(myfig1,'g41_VcdQ.fig');


%%

myfig2 = figure;
set(myfig2, 'Position', [50 50 1000 800])

results.c_default_1 = results.c ./ (1-results.d);
results.c_default_2 = results.c ./ results.d;

ccut_d1 = results.c_default_1(1:icut,:);
ccut_d2 = results.c_default_2(1:icut,:);
set(gca,'FontSize',14)
mesh(acut,z,ccut_d1')
hold on
mesh(acut,z,ccut_d2')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Consumption $c(a,y)$','FontSize',14,'interpreter','latex')

print -dpdf     g42_c
savefig(myfig2,'g42_c.fig');



%%

myfig3 = figure;            
set(myfig3, 'Position', [50 50 1200 600])

subplot(121)
vcut_def = results.V_def(1:icut,:);
set(gca,'FontSize',14)
mesh(acut,z,vcut_def')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Value function - default $v(a,y)$','FontSize',14,'interpreter','latex')
% zlim([-6 -5])

subplot(122)
acut = results.a(1:icut);
s    =  results.s .* (1-results.d);
sscut = s(1:icut,:);
set(gca,'FontSize',14)
mesh(acut,z,sscut')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Savings $s(a,y)$','FontSize',14,'interpreter','latex')

print -dpdf     g43_Vdef_s
savefig(myfig3,'g43_Vdef_s.fig');


%%

myfig4 = figure;            
set(myfig4, 'Position', [50 50 1200 600])

subplot(121)
gcut = results.g(1:icut,:);
set(gca,'FontSize',14)
mesh(acut,z,gcut')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Distribution $g(a,y)$','FontSize',14,'interpreter','latex')

subplot(122)
ttdcut = results.ttd(1:icut,:);
set(gca,'FontSize',14)
mesh(acut,z,ttdcut')
view([45 25])
xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
xlim([parameters.amin max(acut)])
ylim([parameters.zmin parameters.zmax])
title('Time to default','FontSize',14,'interpreter','latex')

print -dpdf     g44_g
savefig(myfig4,'g44_g.fig');



if parameters.inflation ==0
    
    load ../a_inf/iter_data g g_def
    
    inf_g=g;
    inf_g_def=g_def;
    g=results.g;
    g_def=results.g_def;

    myfig4b = figure;            
    set(myfig4b, 'Position', [50 50 700 1000])

    subplot(321)
    plot(-results.a,sum(inf_g,2)*parameters.dz,'linewidth',2)
    hold on
    plot(-results.a,sum(g,2)*parameters.dz,':','linewidth',2)
    title('marginal distribution in repayment','FontSize',12,'interpreter','latex')
    xlabel('assets')
    
    subplot(322)
    plot(results.z,sum(inf_g,1)*parameters.da,'linewidth',2)
    hold on
    plot(results.z,sum(g,1)*parameters.da,':','linewidth',2)
    title('marginal distribution in repayment','FontSize',12,'interpreter','latex')
    xlabel('output')
    
    subplot(323)
    plot(-results.a,sum(inf_g_def,2)*parameters.dz,'linewidth',2)
    hold on
    plot(-results.a,sum(g_def,2)*parameters.dz,':','linewidth',2)
    title('marginal distribution in default','FontSize',12,'interpreter','latex')
    xlabel('assets')
    
    subplot(324)
    plot(results.z,sum(inf_g_def,1)*parameters.da,'linewidth',2)
    hold on
    plot(results.z,sum(g_def,1)*parameters.da,':','linewidth',2)
    title('marginal distribution in default','FontSize',12,'interpreter','latex')
    xlabel('output')
    
    subplot(325)
    plot(-results.a,sum(inf_g+inf_g_def,2)*parameters.dz,'linewidth',2)
    hold on
    plot(-results.a,sum(g+g_def,2)*parameters.dz,':','linewidth',2)
    title('marginal distribution, total','FontSize',12,'interpreter','latex')
    xlabel('assets')
    
    subplot(326)
    plot(results.z,sum(inf_g+inf_g_def,1)*parameters.da,'linewidth',2)
    hold on
    plot(results.z,sum(g+g_def,1)*parameters.da,':','linewidth',2)
    title('marginal distribution, total','FontSize',12,'interpreter','latex')
    xlabel('output')
    legend('with inflation','without inflation','FontSize',12,'interpreter','latex','location','south')
    
    print -dpdf     g45_g
    savefig(myfig4b,'g45_g.fig');

end


%%

if parameters.inflation ==1
    myfig5 = figure;            
    set(myfig5, 'Position', [50 50 800 800])
    picut = results.pi(1:icut,:);
    set(gca,'FontSize',14)
    mesh(acut,z,picut')
    view([5 25])
    xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
    ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
    xlim([parameters.amin max(acut)])
    ylim([parameters.zmin parameters.zmax])
    title('Inflation $\pi(a,y)$','FontSize',14,'interpreter','latex')
    print -dpdf     g45_pi
    savefig(myfig5,'g45_pi.fig');

    results.pi_default_1 = results.pi ./ (1-results.d);
    results.pi_default_2 = results.pi ./ results.d;
    myfig6 = figure;            
    set(myfig6, 'Position', [50 50 800 800])
    picut_1 = results.pi_default_1(1:icut,:);
    picut_2 = results.pi_default_2(1:icut,:);
    set(gca,'FontSize',14)
    mesh(acut,z,picut_1')
    hold on
    mesh(acut,z,picut_2')
    view([5 25])
    xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
    ylabel('Income, log$(y)$','FontSize',14,'interpreter','latex')
    xlim([parameters.amin max(acut)])
    ylim([parameters.zmin parameters.zmax])
    title('Inflation $\pi(a,y)$','FontSize',14,'interpreter','latex')
    print -dpdf     g46_pi_d
    savefig(myfig6,'g46_pi_d.fig');

    zcut0=min(find(results.z>=0));
    zcutp=min(find(results.z>=0.05-1e-10));
    zcutm=min(find(results.z>=-0.05-1e-10));
    myfig7 = figure;            
    set(myfig7, 'Position', [50 50 800 800])
    plot(acut,picut(:,zcut0),'-','Color',[0.1,0.2,1],'linewidth',1)
    hold on
    plot(acut,picut(:,zcutm),'-','Color',[1,0.1,0.1],'linewidth',1)
    plot(acut,picut(:,zcutp),'-','Color',[0,0.5,0.1],'linewidth',1)
    plot(acut,picut_1(:,zcut0),'-','Color',[0.1,0.3,1],'linewidth',3)
    plot(acut,picut_1(:,zcutm),'-','Color',[1,0.1,0.1],'linewidth',3)
    plot(acut,picut_1(:,zcutp),'-','Color',[0,0.5,0.1],'linewidth',3)
    view([180,-90])
    xlabel('(-) Debt, $a$','FontSize',14,'interpreter','latex')
    title('Inflation $\pi(a,y)$','FontSize',14,'interpreter','latex')
    legend({['log$(y)$=' num2str(z(zcut0))],['log$(y)$=' num2str(z(zcutm))],['log$(y)$=' num2str(z(zcutp))]},'Location','best', 'interpreter','latex','FontSize',10)
    grid
    print -dpdf     g47_pi_2D
    savefig(myfig7,'g47_pi_2D.fig');
    clear zcut0 zcutp zcutm
    
end




myfig8 = figure;
set(myfig8,'Position',[100 100 800 400])
subplot(1,2,1)
surf(results.z,results.a,results.s)
title('savings outside default','FontSize',14,'interpreter','latex')
subplot(1,2,2)
surf(results.z,results.a,results.s_def)
title('savings under default','FontSize',14,'interpreter','latex')
print -dpdf     g48_s
savefig(myfig8,'g48_s.fig');

myfig9 = figure;
set(myfig9,'Position',[100 100 400 400])
surf(results.z,results.a,results.s_eff)
title('savings (eff)','FontSize',14,'interpreter','latex')
print -dpdf     g48_s_eff
savefig(myfig8,'g48_s_eff.fig');
