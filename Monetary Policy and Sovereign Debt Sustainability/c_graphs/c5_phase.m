%% Phase diagram


temp=results_inf.s;
results_inf.s_phase=nan(size(a));
for it1=1:size(temp,1)
    for it2=2:size(temp,2)
        if temp(it1,it2)*temp(it1,it2-1)<=0
            results_inf.s_phase(it1)=(z(it2)*temp(it1,it2-1)-z(it2-1)*temp(it1,it2))/(-temp(it1,it2)+temp(it1,it2-1));
        end
    end
end


myfigPD = figure;
set(myfigPD, 'Position', [50 50 500 400])
title('Phase diagram (repayment spells)','FontSize',12,'interpreter','latex')
hold on
plot(a,exp(results_inf.s_phase),'-','Color',[0.8,0.5,0.0],'linewidth',2)
plot(a,ones(size(a)),'-','Color',[0.3,0.7,0.5],'linewidth',2)
plot(a,exp(results_inf.def),'-','Color',[0.3,0.5,0.8],'linewidth',2)
plot(-sss_inf.a,exp(sss_inf.z),'*','Color',[0.9,0.8,0.2],'linewidth',2)

cd ..
cd a_inf
load z_finalworkspace.mat


phase.dt = 1/12;
phase.total    = 100/phase.dt;         % total number of periods that will be simulated
phase.e_shocks = zeros(phase.total,1); % no shocks, just go towards sss

            phase.z0=sss_inf.z+0.07;
            phase.a0=sss_inf.a;
            mytemp.a=phase.a0;
            mytemp.z=phase.z0;
            mytemp.zposD = floor((mytemp.z-parameters.zmin)/results.dz)+1;
            mytemp.zposU =  ceil((mytemp.z-parameters.zmin)/results.dz)+1;
            mytemp.wz    = (results.z(mytemp.zposU)-mytemp.z)/results.dz; % weight of posD
            mytemp.aposD = floor((mytemp.a-parameters.amin)/results.da)+1;
            mytemp.aposU =  ceil((mytemp.a-parameters.amin)/results.da)+1;
            mytemp.wa    = (results.a(mytemp.aposU)-mytemp.a)/results.da; % weight of posD
            mytemp.d     = mytemp.wa*mytemp.wz*results.d(mytemp.aposD,mytemp.zposD)  + (1-mytemp.wa)*mytemp.wz* results.d(mytemp.aposU,mytemp.zposD)  + mytemp.wa*(1-mytemp.wz)*results.d(mytemp.aposD,mytemp.zposU)  + (1-mytemp.wa)*(1-mytemp.wz)*results.d(mytemp.aposU,mytemp.zposU);
            phase.d0     = round(mytemp.d);
            if phase.d0==0
                phase = f5_sim(parameters,results,phase);
                phase.z=phase.z ./ (1-abs(phase.d_state-phase.d_state(1)));
                phase.a=phase.a ./ (1-abs(phase.d_state-phase.d_state(1)));
                plot(-phase.a,exp(phase.z),'color',[0.6 0 0],'linewidth',2)
            end



phase.dt = 1/12;
phase.total    = 1/phase.dt;           % total number of periods that will be simulated
phase.e_shocks = zeros(phase.total,1); % no shocks, just go towards sss

for mycolor=9:-1:1
    for z0=[-0.11:0.02:0.11]
        for a0=[-0.31:0.05:-0.01]

            phase.z0=z0;
            phase.a0=a0;
            mytemp.a=a0;
            mytemp.z=z0;
            mytemp.zposD = floor((mytemp.z-parameters.zmin)/results.dz)+1;
            mytemp.zposU =  ceil((mytemp.z-parameters.zmin)/results.dz)+1;
            mytemp.wz    = (results.z(mytemp.zposU)-mytemp.z)/results.dz; % weight of posD
            mytemp.aposD = floor((mytemp.a-parameters.amin)/results.da)+1;
            mytemp.aposU =  ceil((mytemp.a-parameters.amin)/results.da)+1;
            mytemp.wa    = (results.a(mytemp.aposU)-mytemp.a)/results.da; % weight of posD
            mytemp.d     = mytemp.wa*mytemp.wz*results.d(mytemp.aposD,mytemp.zposD)  + (1-mytemp.wa)*mytemp.wz* results.d(mytemp.aposU,mytemp.zposD)  + mytemp.wa*(1-mytemp.wz)*results.d(mytemp.aposD,mytemp.zposU)  + (1-mytemp.wa)*(1-mytemp.wz)*results.d(mytemp.aposU,mytemp.zposU);
            phase.d0     = round(mytemp.d);
            if phase.d0==0
                phase = f5_sim(parameters,results,phase);
                phase.z=phase.z ./ (1-abs(phase.d_state-phase.d_state(1)));
                phase.a=phase.a ./ (1-abs(phase.d_state-phase.d_state(1)));
                plot(-phase.a(1:mycolor+3),exp(phase.z(1:mycolor+3)),'color',[1.0 mycolor/10 mycolor/10].^0.3,'linewidth',2)
            end

        end
    end
    mycolor
end


phase.dt = 1/12;
phase.total    = 100/phase.dt;         % total number of periods that will be simulated
phase.e_shocks = zeros(phase.total,1); % no shocks, just go towards sss

            phase.z0=sss_inf.z+0.07;
            phase.a0=sss_inf.a;
            mytemp.a=phase.a0;
            mytemp.z=phase.z0;
            mytemp.zposD = floor((mytemp.z-parameters.zmin)/results.dz)+1;
            mytemp.zposU =  ceil((mytemp.z-parameters.zmin)/results.dz)+1;
            mytemp.wz    = (results.z(mytemp.zposU)-mytemp.z)/results.dz; % weight of posD
            mytemp.aposD = floor((mytemp.a-parameters.amin)/results.da)+1;
            mytemp.aposU =  ceil((mytemp.a-parameters.amin)/results.da)+1;
            mytemp.wa    = (results.a(mytemp.aposU)-mytemp.a)/results.da; % weight of posD
            mytemp.d     = mytemp.wa*mytemp.wz*results.d(mytemp.aposD,mytemp.zposD)  + (1-mytemp.wa)*mytemp.wz* results.d(mytemp.aposU,mytemp.zposD)  + mytemp.wa*(1-mytemp.wz)*results.d(mytemp.aposD,mytemp.zposU)  + (1-mytemp.wa)*(1-mytemp.wz)*results.d(mytemp.aposU,mytemp.zposU);
            phase.d0     = round(mytemp.d);
            if phase.d0==0
                phase = f5_sim(parameters,results,phase);
                phase.z=phase.z ./ (1-abs(phase.d_state-phase.d_state(1)));
                phase.a=phase.a ./ (1-abs(phase.d_state-phase.d_state(1)));
                plot(-phase.a,exp(phase.z),'->','color',[0.6 0 0],'linewidth',2,'MarkerIndices',[12 12])
            end

clear a0 z0 mytemp

plot(-sss_inf.a,exp(sss_inf.z),'*','Color',[0.9,0.8,0.2],'linewidth',2)

cd ..
cd c_graphs

ylim([exp(min(z))+0.005 exp(max(z))])
xlim([0 0.35])
xlabel('Debt, $b$','FontSize',12,'interpreter','latex')
ylabel('Income, $y$','FontSize',12,'interpreter','latex')
legend({'$db=0$','$dy=0$','Default threshold','Stochastic steady state','Path after a positive shock'},'Location','northwest', 'interpreter','latex','FontSize',10)

print -dpdf    p10_phase
savefig(myfigPD,'g10_phase.fig');


