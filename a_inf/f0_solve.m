% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022, based on codes from GALO NUNO AND BENJAMIN MOLL

% The value function is found every round by solving the HJB equation through an upwind finite differences scheme
% The distribution is found by also solving using finite differences the Fokker-Planck (Kolmogorov forward) equation


function results = f0_solve(parameters)


%% Solution

obs=parameters.obs; % this will only contain the part we want to simulate with the model

if parameters.inflation==0
    results   = f1_HJB_NoInflation(parameters);
else
    results   = f2_HJB_Inflation(parameters);
end
results   = f3_KFE(parameters,results);




%% Find SSS

sim.dt = 1/12;
sim.total    = 100/sim.dt;        % total number of periods that will be simulated

sim.z0 = 0;      % value of z at the start of the simulation
sim.a0 = obs.a0; % value of a at the start of the simulation, this shouldn't matter as long as the simulation to find the SSS is long enough
sim.d0 = 0;

sim.e_shocks = zeros(sim.total,1); % no shocks, for finding SSS

sim = f5_sim(parameters,results,sim);

sss.a  = sim.a(end);
sss.z  = sim.z(end);
sss.s  = sim.s(end);
sss.c  = sim.c(end);
sss.pi = sim.pi(end);
sss.r  = sim.r(end);
sss.Q  = sim.Q(end);
sss.d  = sim.d_state(end);
sss.r_real= sim.r_real(end);
sss.rinf= sss.r-sss.r_real;



%% Simulate observed episode (Brasil 2001-2003)


sim.dt = 1/12;
sim.d0 = 0;

sim.z0       = obs.z0;  % value of z at the start of the simulation
sim.a0       = obs.a0;  % value of a at the start of the simulation
sim.e_shocks = obs.e_shocks;
sim.total    = size(sim.e_shocks,1);  % total number of periods that will be simulated


sim = f5_sim(parameters,results,sim);



%% Moments

% debt to GDP
moments.aY_mean = sum(sum(results.g .*  results.aa ./exp(results.zz)      * results.da * results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d)));
moments.aY_std  =(sum(sum(results.g .*((results.aa ./exp(results.zz)).^2) * results.da * results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d))) - moments.aY_mean^2)^0.5;
moments.aY_sss  = sss.a;

% inflation
moments.pi_mean = sum(sum(results.g .*  results.pi     * results.da *results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d)));
moments.pi_std  =(sum(sum(results.g .* (results.pi.^2) * results.da *results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d))) - moments.pi_mean.^2)^0.5;
moments.pi_sss  = sss.pi;

% spread
moments.rdif_mean = sum(sum(results.g .* (results.r - parameters.r_bar)     * results.da * results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d)));
moments.rdif_std  =(sum(sum(results.g .*((results.r - parameters.r_bar).^2) * results.da * results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d))) - moments.rdif_mean^2)^0.5;
moments.rdif_sss  = sss.r - parameters.r_bar;

% default premia
results.rdef=results.r-parameters.r_bar-results.rinf;
moments.rdef_mean = sum(sum(results.g .* results.rdef     * results.da * results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d)));
moments.rdef_std  =(sum(sum(results.g .*(results.rdef.^2) * results.da * results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d))) - moments.rdef_mean^2)^0.5;
moments.rdef_sss = sss.r_real-parameters.r_bar;

% inflation premia
moments.rinf_mean = sum(sum(results.g .* results.rinf     * results.da * results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d)));
moments.rinf_std  =(sum(sum(results.g .*(results.rinf.^2) * results.da * results.dz .*(1-results.d))) / sum(sum(results.g * results.da *results.dz .*(1-results.d))) - moments.rinf_mean^2)^0.5;
moments.rinf_sss = sss.r-sss.r_real;

% min, max and range in the simulated episode

moments.aY_m         =     sim.aY(end-12);
moments.rdif_m       = min(sim.rdif(1:end-12));
moments.rinf_m       = min(sim.rinf(1:end-12));
moments.rdef_m       = min(sim.rdef(1:end-12));
moments.pi_m         = min(sim.pi(1:end-12));

moments.aY_M         =     sim.aY(end);
moments.rdif_M       = max(sim.rdif(end-11:end));
moments.rinf_M       = max(sim.rinf(end-11:end));
moments.rdef_M       = max(sim.rdef(end-11:end));
moments.pi_M         = max(sim.pi(end-11:end));

moments.aY_up        = moments.aY_M   - moments.aY_m   ;
moments.rdif_up      = moments.rdif_M - moments.rdif_m ;
moments.rinf_up      = moments.rinf_M - moments.rinf_m ;
moments.rdef_up      = moments.rdef_M - moments.rdef_m ;
moments.pi_up        = moments.pi_M   - moments.pi_m   ;

moments.d_episode = max(sim.d_state);

% welfare
moments.welfare_mean = sum(sum(results.g .* results.V * results.da *results.dz .*(1-results.d)))/ sum(sum(results.g * results.da *results.dz .*(1-results.d)));



% echo counter: check if there are problems in d (sometimes it can generate echoes)

echo_counter=0;
for itd1=1:parameters.J
    echo_count=0;
    for itd2=1:parameters.I
        if results.d(parameters.I-itd2+1,itd1)==1
            echo_count=echo_count+1;
        else
            if echo_count>0
                echo_counter=echo_counter+1;
            end
        end
    end
end
        
moments.echo=echo_counter/parameters.I/parameters.J;


if parameters.plot==1

    myfig = figure;            
    set(myfig, 'Position', [50 50 700 1000])

    subplot(421)
    plot(sim.d_state)
    title('d','FontSize',10,'interpreter','latex')

    subplot(422)
    plot(-sim.a)
    title('a','FontSize',10,'interpreter','latex')
    
    subplot(423)
    plot(sim.z)
    hold on
    yyaxis right
    plot(obs.z)
    title('z','FontSize',10,'interpreter','latex')
    
    subplot(424)
    plot(-sim.aY)
    hold on
    yyaxis right
    plot(-obs.aY)
    title('a/Y','FontSize',10,'interpreter','latex')
    
    subplot(425)
    plot(sim.c)
    title('c','FontSize',10,'interpreter','latex')
    
    subplot(426)
    plot(sim.pi)
    hold on
    yyaxis right
    plot(obs.pi)
    title('pi','FontSize',10,'interpreter','latex')
    
    subplot(427)
    plot(sim.rdif)
    hold on
    yyaxis right
    plot(obs.rdif)
    title('rdif','FontSize',10,'interpreter','latex')
    
    subplot(428)
    plot(sim.Q)
    title('Q','FontSize',10,'interpreter','latex')
    
    print -dpdf    g0_simBrasil
    savefig(myfig,'g0_simBrasil.fig');
    
    close all

end


results.moments=moments;


