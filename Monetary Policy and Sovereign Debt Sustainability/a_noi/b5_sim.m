% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022, based on codes from GALO NUNO AND BENJAMIN MOLL

close all
sim.dt = 1/12;

% first find the SSS

sim.total    = 100/sim.dt;        % total number of periods that will be simulated

sim.z0 = 0;  % value of z at the start of the simulation
sim.a0 = results.a(find(results.s(:,floor((sim.z0-parameters.zmin)/results.dz)+1)<=0,1,'first')); % value of a at the start of the simulation - this should be close to the SSS but then we'll refine it
sim.d0 = 0;

sim.e_shocks = zeros(sim.total,1); % no shocks, for finding SSS

sim = f5_sim(parameters,results,sim);

sss.a  = sim.a(end);
sss.z  = sim.z(end);
sss.s  = sim.s(end);
sss.c  = sim.c(end);
sss.V  = sim.V(end);
sss.pi = sim.pi(end);
sss.r  = sim.r(end);
sss.Q  = sim.Q(end);
sss.d  = sim.d_state(end);
sss.rdif = sim.rdif(end);
sss.rdef = sim.rdef(end);
sss.rinf = sim.rinf(end);

% simulate IRF without default

sim.total    = 50/sim.dt;            % total number of periods that will be simulated

sim.z0 = sss.z;
sim.a0 = sss.a;
sim.d0 = 0;

sim.e_shocks = zeros(sim.total,1);
sim.e_shocks(1) = 0.01/(parameters.sig*(sim.dt^0.5));
irf_p = f5_sim(parameters,results,sim);
sim.e_shocks(1) = -0.01/(parameters.sig*(sim.dt^0.5));
irf_n = f5_sim(parameters,results,sim);

myfig1 = figure;
set(myfig1,'Position',[100 100 800 600])

subplot(2,3,1)
plot(-irf_p.z,'--')
hold on
plot(irf_n.z)
title('z')

subplot(2,3,2)
plot((irf_p.a-sss.a),'--')
hold on
plot(-(irf_n.a-sss.a))
title('-a')

subplot(2,3,3)
plot((irf_p.a./exp(irf_p.z)-sss.a),'--')
hold on
plot(-(irf_n.a./exp(irf_n.z)-sss.a))
title('-aY')

subplot(2,3,4)
plot(-(irf_p.pi-sss.pi),'--')
hold on
plot(irf_n.pi-sss.pi)
title('pi')

subplot(2,3,5)
plot(-(irf_p.rdif-sss.rdif),'--')
hold on
plot(irf_n.rdif-sss.rdif)
title('r')

subplot(2,3,6)
plot(-(irf_p.rdef-sss.rdef),'--')
hold on
plot(irf_n.rdef-sss.rdef)
title('r real')

legend('- shock of size +1','shock of size -1')

print -dpdf     g51_irf
savefig(myfig1,'g51_irf.fig');


% simulate IRF under default

sim.d0 = 1;

sim.e_shocks = zeros(sim.total,1);

irf_def_baseline = f5_sim(parameters,results,sim);

sim.e_shocks(1) = 10;

irf_def_alternative = f5_sim(parameters,results,sim);

irf_def.a  = irf_def_alternative.a  - irf_def_baseline.a  ;
irf_def.z  = irf_def_alternative.z  - irf_def_baseline.z  ;
irf_def.s  = irf_def_alternative.s  - irf_def_baseline.s  ;
irf_def.c  = irf_def_alternative.c  - irf_def_baseline.c  ;
irf_def.pi = irf_def_alternative.pi - irf_def_baseline.pi ;
irf_def.r  = irf_def_alternative.r  - irf_def_baseline.r  ;
irf_def.Q  = irf_def_alternative.Q  - irf_def_baseline.Q  ;


% now simulate 1000 years with random shocks

sim.total    = 1000/sim.dt;            % total number of periods that will be simulated

sim.z0 = sss.z;
sim.a0 = sss.a;
sim.d0 = 0;

sim.rngseed1 = 123;                % RNG seed for calculating the shocks for the simulation
rng(sim.rngseed1);
sim.e_shocks = randn(sim.total,1); % random shocks, for random simulation

sim = f5_sim(parameters,results,sim);

sim.adef = sim.a .* (sim.d_state./sim.d_state);
sim.zdef = sim.z .* (sim.d_state./sim.d_state);
sim.pidef = sim.pi .* (sim.d_state./sim.d_state);
sim.rdef = (sim.r-parameters.r_bar) .* (sim.d_state./sim.d_state);

myfig2 = figure;
set(myfig2,'Position',[100 100 800 800])
subplot(6,1,1)
plot(-sim.a)
hold on
plot(-sim.adef)
title('-a')
subplot(6,1,2)
plot(-sim.a./exp(sim.z))
hold on
plot(-sim.adef./exp(sim.zdef))
title('-aY')
subplot(6,1,3)
plot(sim.z)
hold on
plot(sim.zdef)
title('z')
subplot(6,1,4)
plot(sim.d_state)
ylim([-0.5,1.5])
title('d-state')
subplot(6,1,5)
plot(sim.pi)
hold on
plot(sim.pidef)
title('pi')
subplot(6,1,6)
plot(sim.r-parameters.r_bar)
hold on
plot(sim.rdef)
title('r-rbar')
ylim([0.05,0.25])

print -dpdf     g52_sim
savefig(myfig2,'g52_sim.fig');


myfig3 = figure;
set(myfig3,'Position',[100 100 800 800])
mesh(results.z,results.a,results.d-1)
view([0,0,90])
hold on
plot(sim.z,sim.a,'color',[1.0 0 0],'linewidth',1)
print -dpdf     g53_sim_az
savefig(myfig3,'g53_sim_az.fig');




sim.r_repay = sim.r(sim.d_state==0);
sim.pi_repay = sim.pi(sim.d_state==0);

myfig4 = figure;
subplot(3,2,1)
plot(-sim.a,sim.pi,'.')
title('(-a,pi)')
subplot(3,2,2)
plot(sim.z,sim.pi,'.')
title('(z,pi)')
subplot(3,2,3)
plot(-sim.a,sim.r,'.')
title('(-a,r)')
subplot(3,2,4)
plot(sim.z,sim.r,'.')
title('(z,r)')
subplot(3,2,5)
plot(sim.r,sim.pi,'.')
title('(r,pi)')
subplot(3,2,6)
plot(sim.r_repay,sim.pi_repay,'.')
title('(r,pi) at repay')

print -dpdf     g54_corr
savefig(myfig4,'g54_corr.fig');

% look at inflation right before and after default

pi_def = [];
for t=50:sim.total-49
    if sim.d_state(t)-sim.d_state(t-1)==1
        pi_def = [pi_def ; sim.pi(t-49:t+49)'];
    end
end

pi_def_mean = mean(pi_def);
myfig5 = figure;
subplot(1,2,1)
plot(pi_def_mean)
grid
title('pi-def-mean (d=1 at t=50)')
subplot(1,2,2)
plot(pi_def')
grid
title('pi-def')

print -dpdf     g55_pi_def
savefig(myfig5,'g55_pi_def.fig');


% plot phase diagram (convergence paths starting from many different points)

phase.dt = 1/12;
phase.total    = 1/phase.dt;           % total number of periods that will be simulated
phase.e_shocks = zeros(phase.total,1); % no shocks, just go towards sss
phase.step=0.02;

myfig6 = figure;
set(myfig6,'Position',[100 100 800 800])
mesh(results.z,results.a,results.d-1)
view([0,0,90])
hold on

for mycolor=9:-1:1
    for z0=[parameters.zmin:phase.step:parameters.zmax]
        for a0=[parameters.amin+0.001:phase.step:parameters.amax]

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
            phase = f5_sim(parameters,results,phase);
            phase.z=phase.z ./ (1-abs(phase.d_state-phase.d_state(1)));
            phase.a=phase.a ./ (1-abs(phase.d_state-phase.d_state(1)));
            plot(phase.z(1:mycolor+3),phase.a(1:mycolor+3),'color',[1.0 mycolor/10 mycolor/10],'linewidth',2)

        end
    end
    mycolor
end
clear a0 z0 mytemp
print -dpdf     g56_phase
savefig(myfig6,'g56_phase.fig');


