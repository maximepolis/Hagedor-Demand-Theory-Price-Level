% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022, based on codes from GALO NUNO AND BENJAMIN MOLL

clear
clc

diary off;
delete('_log.txt');
diary('_log.txt');

parameters.inflation = 0; % 0 no inflation, 1 optimal inflation
parameters.plot      = 0;

b0_parameters

%%

% during calibration, for every set of parameters (rho, d0, d1, psi, zeta),
% we have to iteratively find the lambda that makes the moment match the data
% but that only happens in the version with inflation, for noi we take the
% value that we found in inf

lambda_last=parameters.lambda;
it_num = 3;

% for the calibration process: ratio of change of the calibration parameters (1 to keep them steady)
rho_step  =1;
d0_step   =1;
d1_step   =1;
psi_step  =1;
zeta_step =1;

if parameters.inflation==0
    it_start=it_num;
else
    it_start=1;
end

for it_search = it_start:it_num
    
    % prepare progress subfolder, set parameters

    tic
    foldername = ['iter_' num2str(1000+it_search)];
    status=mkdir(foldername);

    parameters.rho =parameters.rho *rho_step;
    parameters.d0  =parameters.d0  *d0_step;
    parameters.d1  =parameters.d1  *d1_step;
    parameters.psi =parameters.psi *psi_step;
    parameters.zeta=parameters.zeta*zeta_step;
    
    if parameters.inflation==0
        eval(['load ../a_inf/' foldername '/guess lambda V d'])
        parameters.lambda=lambda;
        V_inf=V;
        d_inf=d;
        clear lambda V d
    else
        lambda_step = (lambda_last/parameters.lambda)^0.5;
        disp(['lambda_step = ' num2str(lambda_step*100-100)]);
        lambda_step = max([0.99 lambda_step]);
        lambda_step = min([1.01 lambda_step]);
        parameters.lambda = parameters.lambda * lambda_step;
    end

    disp(' ');    disp(' ');    disp(' ');    disp(' ');    disp(' ');    disp(' ');
    disp(' ');    disp(' ');    disp(' ');    disp(' ');    disp(' ');    disp(' ');

    disp(['PARAM (iter rho d0 d1 psi zeta lambda): ' num2str(it_search) '   ' num2str(parameters.rho) '   ' num2str(parameters.d0) '   ' num2str(parameters.d1) '   ' num2str(parameters.psi) '   ' num2str(parameters.zeta) '   ' num2str(parameters.lambda) ])

    % solve model
    
    results=f0_solve(parameters);
    
    % plot diagnostics

    close all

    myfig = figure;            
    set(myfig, 'Position', [50 50 800 800])
    subplot(2,1,1)
    plot(results.dist1)
    hold on
    plot(results.dist2)
    plot(results.dist3)
    plot(results.dist4)
    ylim([0,0.25])
    legend({'dist V','dist Q','dist V-def','dist Q-def'},'Location','best', 'interpreter','latex','FontSize',10)
    title(['iter ' num2str(it_search)]);

    subplot(2,1,2)
    plot(results.dist1)
    hold on
    plot(results.dist2)
    plot(results.dist3)
    plot(results.dist4)
    ylim([0,0.01])
    drawnow;
    eval(['savefig(myfig,''g00_convergence_' num2str(1000+it_search) '.fig'');'])
    close all

    % save current solution to be used as guess for future iterations
    V     = results.V;
    V_def = results.V_def;
    Q     = results.Q;
    Q_def = results.Q_def;
    d     = results.d;
    lambda= parameters.lambda;
    if parameters.inflation==0
        V_eff=V.*(1-d)+V_def.*d;
        V_improvement=V_inf-V_eff-100*d_inf;
        save 'guess.mat' V V_def Q Q_def d lambda V_improvement -mat -v7.3
    else
        save 'guess.mat' V V_def Q Q_def d lambda -mat -v7.3
    end
    clear V V_def Q Q_def d lambda;

    % report obs vs sim

    disp(' ');    disp(' ');    disp(' ');
    disp(['obs vs sim for aY_mean:   ' num2str(round(obs.aY_mean,3))   ' vs ' num2str(round(results.moments.aY_mean,3))       ]);
    disp(['obs vs sim for pi_mean:   ' num2str(round(obs.pi_mean,3))   ' vs ' num2str(round(results.moments.pi_mean,3))       ]);
    disp(['obs vs sim for rdif_mean: ' num2str(round(obs.rdif_mean,3)) ' vs ' num2str(round(results.moments.rdif_mean,3))     ]);
    disp(['obs vs sim for rdef_mean: ' num2str(round(obs.rdef_mean,3)) ' vs ' num2str(round(results.moments.rdef_mean,3))     ]);
    disp(['obs vs sim for rinf_mean: ' num2str(round(obs.rinf_mean,3)) ' vs ' num2str(round(results.moments.rinf_mean,3))     ]);
    disp(' ');
    disp(['obs vs sim for aY_m:      ' num2str(round(obs.aY_m,3))      ' vs ' num2str(round(results.moments.aY_m,3))          ]);
    disp(['obs vs sim for pi_m:      ' num2str(round(obs.pi_m,3))      ' vs ' num2str(round(results.moments.pi_m,3))          ]);
    disp(['obs vs sim for r_m:       ' num2str(round(obs.rdif_m,3))    ' vs ' num2str(round(results.moments.rdif_m,3))        ]);
    disp(['obs vs sim for rdef_m:    ' num2str(round(obs.rdef_m,3))    ' vs ' num2str(round(results.moments.rdef_m,3))        ]);
    disp(['obs vs sim for rinf_m:    ' num2str(round(obs.rinf_m,3))    ' vs ' num2str(round(results.moments.rinf_m,3))        ]);
    disp(' ');
    disp(['obs vs sim for aY_M:      ' num2str(round(obs.aY_M,3))      ' vs ' num2str(round(results.moments.aY_M,3))          ]);
    disp(['obs vs sim for pi_M:      ' num2str(round(obs.pi_M,3))      ' vs ' num2str(round(results.moments.pi_M,3))          ]);
    disp(['obs vs sim for r_M:       ' num2str(round(obs.rdif_M,3))    ' vs ' num2str(round(results.moments.rdif_M,3))        ]);
    disp(['obs vs sim for rdef_M:    ' num2str(round(obs.rdef_M,3))    ' vs ' num2str(round(results.moments.rdef_M,3))        ]);
    disp(['obs vs sim for rinf_M:    ' num2str(round(obs.rinf_M,3))    ' vs ' num2str(round(results.moments.rinf_M,3))        ]);
    disp(' ');
    disp(['obs vs sim for aY_std:    ' num2str(round(obs.aY_std,3))    ' vs ' num2str(round(results.moments.aY_std,3))        ]);
    disp(['obs vs sim for pi_std:    ' num2str(round(obs.pi_std,3))    ' vs ' num2str(round(results.moments.pi_std,3))        ]);
    disp(['obs vs sim for rdif_std:  ' num2str(round(obs.rdif_std,3))  ' vs ' num2str(round(results.moments.rdif_std,3))      ]);
    disp(['obs vs sim for rdef_std:  ' num2str(round(obs.rdef_std,3))  ' vs ' num2str(round(results.moments.rdef_std,3))      ]);
    disp(['obs vs sim for rinf_std:  ' num2str(round(obs.rinf_std,3))  ' vs ' num2str(round(results.moments.rinf_std,3))      ]);
    disp(' ');
    disp(['default in simulated episode? (0/1):    ' num2str(round(results.moments.d_episode,3))                              ]);
    disp(' ');
    if parameters.inflation==0
        V_improvement_max = max(max(V_improvement));
        V_improvement_max_ceq = exp(parameters.rho*V_improvement_max)*100-100;
        disp(['maximum improvement in V (inf-noi) (c eq, %):    ' num2str(round(V_improvement_max_ceq,6))   ]);
        disp(' ');    disp(' ');    disp(' ');
    end

    % plot more diagnostics

    myfig = figure;            
    imshow(results.d)
    set(myfig, 'Position', [50 50 800 800])
    print -dpdf     g00_d
    close all

    b6_episode
    close all

    moments=results.moments;
    g=results.g;
    g_def=results.g_def;
    save 'iter_data.mat' parameters moments results g g_def -mat -v7.3
    status=copyfile('guess.mat',foldername);
    status=copyfile('iter_data.mat',foldername);
    status=copyfile('g00_d.pdf',foldername);
    status=copyfile('g61_episode_sim.pdf',foldername);

    disp(' ');
    disp(' ');
    disp(' ');
    disp(' ');
    tocc=toc;
    disp(['Elapsed time: ' num2str(tocc/60/60) ' hours'])
    disp(['Current time: ' datestr(now,'dd-mmm HH:MM')])

    lambda_last   = 1/(28/12) - (results.moments.rdif_mean+0.04); % update lambda

end

b4_plot
b5_sim
b6_episode

diary off;
close all

save z_finalworkspace