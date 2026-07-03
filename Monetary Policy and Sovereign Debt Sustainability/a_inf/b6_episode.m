% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022, based on codes from GALO NUNO AND BENJAMIN MOLL

close all

episode.dt=1/12;

episode.d0 = 0;
episode.z0       = parameters.obs.z0;         % value of z at the start of the simulation
episode.a0       = parameters.obs.a0;         % value of a at the start of the simulation
episode.e_shocks = parameters.obs.e_shocks;
episode.total    = size(episode.e_shocks,1);  % total number of periods that will be simulated

episode = f5_sim(parameters,results,episode);

episode.aY = episode.a ./ exp(episode.z);
episode.rdif = episode.r - parameters.r_bar;


skipper=size(obs.z,1)-size(episode.z,1);

myfig1 = figure;  
set(myfig1,'Position',[100 100 700 700])

subplot(231)
plot([2002:episode.dt:(2004-episode.dt)],obs.z,'-','color',[0.8 0.2 0.2],'linewidth',1)
hold on
plot([(2002+skipper*episode.dt):episode.dt:(2004-episode.dt)],episode.z,'-','color',[0.0 0.1 1.0],'linewidth',2)
title('z','FontSize',14,'interpreter','latex')

subplot(232)
plot([2002:episode.dt:(2004-episode.dt)],obs.aY,'-','color',[0.8 0.2 0.2],'linewidth',1)
hold on
plot([(2002+skipper*episode.dt):episode.dt:(2004-episode.dt)],episode.aY,'-','color',[0.0 0.1 1.0],'linewidth',2)
legend('observed','simulated','FontSize',10,'interpreter','latex','location','east')
title('aY','FontSize',14,'interpreter','latex')

subplot(233)
plot([2002:episode.dt:(2004-episode.dt)],obs.pi,'-','color',[0.8 0.2 0.2],'linewidth',1)
hold on
plot([(2002+skipper*episode.dt):episode.dt:(2004-episode.dt)],episode.pi,'-','color',[0.0 0.1 1.0],'linewidth',2)
title('pi','FontSize',14,'interpreter','latex')

subplot(234)
plot([2002:episode.dt:(2004-episode.dt)],obs.rdif,'-','color',[0.8 0.2 0.2],'linewidth',1)
hold on
plot([(2002+skipper*episode.dt):episode.dt:(2004-episode.dt)],episode.rdif,'-','color',[0.0 0.1 1.0],'linewidth',2)
title('r dif','FontSize',14,'interpreter','latex')

% default premia in the data is the difference between the yield of the Brazil bond in dollars and the American bond in dollars
% default premia in the model is the difference between r of the real bond and r_bar
subplot(235)
plot([2002:episode.dt:(2004-episode.dt)],obs.rdef,'-','color',[0.8 0.2 0.2],'linewidth',1)
hold on
plot([(2002+skipper*episode.dt):episode.dt:(2004-episode.dt)],episode.rdef,'-','color',[0.0 0.1 1.0],'linewidth',2)
title('default premia','FontSize',14,'interpreter','latex')

% inflation premia in the data is the difference between the yield of the Brazil bond in reais and the yield of the Brazin bond in dollars
% inflation premia in the model is the difference between r of the nominal bond and r of the real bond
subplot(236)
plot([2002:episode.dt:(2004-episode.dt)],obs.rinf,'-','color',[0.8 0.2 0.2],'linewidth',1)
hold on
plot([(2002+skipper*episode.dt):episode.dt:(2004-episode.dt)],episode.rinf,'-','color',[0.0 0.1 1.0],'linewidth',2)
title('inflation premia','FontSize',14,'interpreter','latex')

print -dpdf     g61_episode_sim
savefig(myfig1,'g61_episode_sim.fig');


% plot the simulated episode on top of the pi surface

mypath=nan(size(results.pi));

for it1=13:size(episode.z,1)
    episode.zposD = floor((episode.z(it1)-parameters.zmin)/results.dz)+1;
    episode.zposU =  ceil((episode.z(it1)-parameters.zmin)/results.dz)+1;
    episode.aposD = floor((episode.a(it1)-parameters.amin)/results.da)+1;
    episode.aposU =  ceil((episode.a(it1)-parameters.amin)/results.da)+1;
    mypath(episode.aposD:episode.aposU,episode.zposD:episode.zposU)=1;
end

myfig2=figure;
mesh(results.z,results.a,results.pi)
hold on
surf(results.z,results.a,results.pi.*mypath)
title('pi surface, and simulation path','FontSize',10,'interpreter','latex')
view([20 30 10])

print -dpdf     g62_episode_pisurf_path_full
savefig(myfig2,'g62_episode_pisurf_path_full.fig');
zlim([0 0.25])
print -dpdf     g63_episode_pisurf_path
savefig(myfig2,'g63_episode_pisurf_path.fig');


myfig3=figure;
set(myfig3,'Position',[100 100 800 800])
mesh(results.z,results.a,results.d-1)
view([0,0,90])
hold on
plot(episode.z,episode.a,'color',[1.0 0.6 0.6],'linewidth',2)
plot(episode.z,episode.a,'color',[1.0 0.0 0.0],'linewidth',2)
plot(episode.z(1),episode.a(1),' ok','linewidth',2)
print -dpdf     g64_episode_dplot_path
savefig(myfig3,'g64_episode_dplot_path.fig');
