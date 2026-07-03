%% load results

load('../a_noi/z_finalworkspace.mat','results');
load('../a_noi/z_finalworkspace.mat','episode');
load('../a_noi/z_finalworkspace.mat','irf_p');
load('../a_noi/z_finalworkspace.mat','irf_n');
load('../a_noi/z_finalworkspace.mat','sss');
results_noi    = results;
episode_noi    = episode;
irf_p_noi      = irf_p;
irf_n_noi      = irf_n;
sss_noi        = sss;

load('../a_inf/z_finalworkspace.mat','results');
load('../a_inf/z_finalworkspace.mat','episode');
load('../a_inf/z_finalworkspace.mat','irf_p');
load('../a_inf/z_finalworkspace.mat','irf_n');
load('../a_inf/z_finalworkspace.mat','sss');
results_inf    = results;
episode_inf    = episode;
irf_p_inf      = irf_p;
irf_n_inf      = irf_n;
sss_inf        = sss;

clear results episode parameters obs irf_p irf_n sss;

load('../a_inf/z_finalworkspace.mat','parameters');
load('../a_inf/z_finalworkspace.mat','obs');

results_inf.V_eff =(1-results_inf.d).*results_inf.V + results_inf.d.*results_inf.V_def;
results_inf.Q_eff =(1-results_inf.d).*results_inf.Q + results_inf.d.*results_inf.Q_def;
results_inf.c_eff =(1-results_inf.d).*results_inf.c + results_inf.d.*results_inf.c_def;
results_inf.s_eff =(1-results_inf.d).*results_inf.s + results_inf.d.*results_inf.s_def;
results_inf.r_eff =(1-results_inf.d).*results_inf.r + results_inf.d.*results_inf.r_def;
results_inf.pi_eff=(1-results_inf.d).*results_inf.pi+ results_inf.d.*results_inf.pi_def;
results_inf.r_real_eff =results_inf.r_real;                                                 % no tengo el _def, habrá que calcularlo
results_inf.gt =results_inf.g+results_inf.g_def;

results_noi.V_eff =(1-results_noi.d).*results_noi.V + results_noi.d.*results_noi.V_def;
results_noi.Q_eff =(1-results_noi.d).*results_noi.Q + results_noi.d.*results_noi.Q_def;
results_noi.c_eff =(1-results_noi.d).*results_noi.c + results_noi.d.*results_noi.c_def;
results_noi.s_eff =(1-results_noi.d).*results_noi.s + results_noi.d.*results_noi.s_def;
results_noi.r_eff =(1-results_noi.d).*results_noi.r + results_noi.d.*results_noi.r_def;
results_noi.pi_eff=(1-results_noi.d).*results_noi.pi+ results_noi.d.*results_noi.pi_def;
results_noi.r_real_eff =results_noi.r_eff;
results_noi.gt =results_noi.g+results_noi.g_def;


%% Calibration moments

disp(' ');disp(' ');    disp('CALIBRATION MOMENTS (BASELINE)');    disp(' ');
    disp(' ');    disp(' ');    disp(' ');
    disp(['obs vs sim for aY_mean:   ' num2str(round(obs.aY_mean,3))   ' vs ' num2str(round(results_inf.moments.aY_mean,3))       ]);
    disp(['obs vs sim for pi_mean:   ' num2str(round(obs.pi_mean,3))   ' vs ' num2str(round(results_inf.moments.pi_mean,3))       ]);
    disp(['obs vs sim for rdif_mean: ' num2str(round(obs.rdif_mean,3)) ' vs ' num2str(round(results_inf.moments.rdif_mean,3))     ]);
    disp(['obs vs sim for rdef_mean: ' num2str(round(obs.rdef_mean,3)) ' vs ' num2str(round(results_inf.moments.rdef_mean,3))     ]);
    disp(['obs vs sim for rinf_mean: ' num2str(round(obs.rinf_mean,3)) ' vs ' num2str(round(results_inf.moments.rinf_mean,3))     ]);
    disp(' ');
    disp(['obs vs sim for aY_m:      ' num2str(round(obs.aY_m,3))      ' vs ' num2str(round(results_inf.moments.aY_m,3))          ]);
    disp(['obs vs sim for pi_m:      ' num2str(round(obs.pi_m,3))      ' vs ' num2str(round(results_inf.moments.pi_m,3))          ]);
    disp(['obs vs sim for r_m:       ' num2str(round(obs.rdif_m,3))    ' vs ' num2str(round(results_inf.moments.rdif_m,3))        ]);
    disp(['obs vs sim for rdef_m:    ' num2str(round(obs.rdef_m,3))    ' vs ' num2str(round(results_inf.moments.rdef_m,3))        ]);
    disp(['obs vs sim for rinf_m:    ' num2str(round(obs.rinf_m,3))    ' vs ' num2str(round(results_inf.moments.rinf_m,3))        ]);
    disp(' ');
    disp(['obs vs sim for aY_M:      ' num2str(round(obs.aY_M,3))      ' vs ' num2str(round(results_inf.moments.aY_M,3))          ]);
    disp(['obs vs sim for pi_M:      ' num2str(round(obs.pi_M,3))      ' vs ' num2str(round(results_inf.moments.pi_M,3))          ]);
    disp(['obs vs sim for r_M:       ' num2str(round(obs.rdif_M,3))    ' vs ' num2str(round(results_inf.moments.rdif_M,3))        ]);
    disp(['obs vs sim for rdef_M:    ' num2str(round(obs.rdef_M,3))    ' vs ' num2str(round(results_inf.moments.rdef_M,3))        ]);
    disp(['obs vs sim for rinf_M:    ' num2str(round(obs.rinf_M,3))    ' vs ' num2str(round(results_inf.moments.rinf_M,3))        ]);
    disp(' ');
    disp(['obs vs sim for aY_std:    ' num2str(round(obs.aY_std,3))    ' vs ' num2str(round(results_inf.moments.aY_std,3))        ]);
    disp(['obs vs sim for pi_std:    ' num2str(round(obs.pi_std,3))    ' vs ' num2str(round(results_inf.moments.pi_std,3))        ]);
    disp(['obs vs sim for rdif_std:  ' num2str(round(obs.rdif_std,3))  ' vs ' num2str(round(results_inf.moments.rdif_std,3))      ]);
    disp(['obs vs sim for rdef_std:  ' num2str(round(obs.rdef_std,3))  ' vs ' num2str(round(results_inf.moments.rdef_std,3))      ]);
    disp(['obs vs sim for rinf_std:  ' num2str(round(obs.rinf_std,3))  ' vs ' num2str(round(results_inf.moments.rinf_std,3))      ]);
    disp(' ');
    disp(['default in simulated episode? (0/1):    ' num2str(round(results_inf.moments.d_episode,3))                              ]);
    disp(' ');

disp(' ');disp(' ');    disp('CALIBRATION MOMENTS (NO INFLATION)');    disp(' ');
    disp(' ');    disp(' ');    disp(' ');
    disp(['obs vs sim for aY_mean:   ' num2str(round(obs.aY_mean,3))   ' vs ' num2str(round(results_noi.moments.aY_mean,3))       ]);
    disp(['obs vs sim for pi_mean:   ' num2str(round(obs.pi_mean,3))   ' vs ' num2str(round(results_noi.moments.pi_mean,3))       ]);
    disp(['obs vs sim for rdif_mean: ' num2str(round(obs.rdif_mean,3)) ' vs ' num2str(round(results_noi.moments.rdif_mean,3))     ]);
    disp(['obs vs sim for rdef_mean: ' num2str(round(obs.rdef_mean,3)) ' vs ' num2str(round(results_noi.moments.rdef_mean,3))     ]);
    disp(['obs vs sim for rinf_mean: ' num2str(round(obs.rinf_mean,3)) ' vs ' num2str(round(results_noi.moments.rinf_mean,3))     ]);
    disp(' ');
    disp(['obs vs sim for aY_m:      ' num2str(round(obs.aY_m,3))      ' vs ' num2str(round(results_noi.moments.aY_m,3))          ]);
    disp(['obs vs sim for pi_m:      ' num2str(round(obs.pi_m,3))      ' vs ' num2str(round(results_noi.moments.pi_m,3))          ]);
    disp(['obs vs sim for r_m:       ' num2str(round(obs.rdif_m,3))    ' vs ' num2str(round(results_noi.moments.rdif_m,3))        ]);
    disp(['obs vs sim for rdef_m:    ' num2str(round(obs.rdef_m,3))    ' vs ' num2str(round(results_noi.moments.rdef_m,3))        ]);
    disp(['obs vs sim for rinf_m:    ' num2str(round(obs.rinf_m,3))    ' vs ' num2str(round(results_noi.moments.rinf_m,3))        ]);
    disp(' ');
    disp(['obs vs sim for aY_M:      ' num2str(round(obs.aY_M,3))      ' vs ' num2str(round(results_noi.moments.aY_M,3))          ]);
    disp(['obs vs sim for pi_M:      ' num2str(round(obs.pi_M,3))      ' vs ' num2str(round(results_noi.moments.pi_M,3))          ]);
    disp(['obs vs sim for r_M:       ' num2str(round(obs.rdif_M,3))    ' vs ' num2str(round(results_noi.moments.rdif_M,3))        ]);
    disp(['obs vs sim for rdef_M:    ' num2str(round(obs.rdef_M,3))    ' vs ' num2str(round(results_noi.moments.rdef_M,3))        ]);
    disp(['obs vs sim for rinf_M:    ' num2str(round(obs.rinf_M,3))    ' vs ' num2str(round(results_noi.moments.rinf_M,3))        ]);
    disp(' ');
    disp(['obs vs sim for aY_std:    ' num2str(round(obs.aY_std,3))    ' vs ' num2str(round(results_noi.moments.aY_std,3))        ]);
    disp(['obs vs sim for pi_std:    ' num2str(round(obs.pi_std,3))    ' vs ' num2str(round(results_noi.moments.pi_std,3))        ]);
    disp(['obs vs sim for rdif_std:  ' num2str(round(obs.rdif_std,3))  ' vs ' num2str(round(results_noi.moments.rdif_std,3))      ]);
    disp(['obs vs sim for rdef_std:  ' num2str(round(obs.rdef_std,3))  ' vs ' num2str(round(results_noi.moments.rdef_std,3))      ]);
    disp(['obs vs sim for rinf_std:  ' num2str(round(obs.rinf_std,3))  ' vs ' num2str(round(results_noi.moments.rinf_std,3))      ]);
    disp(' ');
    disp(['default in simulated episode? (0/1):    ' num2str(round(results_noi.moments.d_episode,3))                              ]);
    disp(' ');

    V_improvement_max = max(max(results_inf.V_eff-results_noi.V_eff -100*results_inf.d));
    V_improvement_max_ceq = exp(parameters.rho*V_improvement_max)*100-100;
    disp(['maximum improvement in V (inf-noi) (c eq, %):    ' num2str(round(V_improvement_max_ceq,6))   ]);
    disp(' ');    disp(' ');    disp(' ');
    


%% some more moments

disp(' ');disp(' ');disp(' ');
disp('Those moments up there were calculated with repayment spells only');
disp('From here onwards, we use the whole distribution, including default spells');
disp(' ');disp(' ');disp(' ');

disp(' ')
disp('Welfare improvement (exp(rho(V_inf-V_noi))) comparing the sss of each world')
disp(['exp(parameters.rho*(sss_inf.V-sss_noi.V))*100-100 = ' num2str(exp(parameters.rho*(sss_inf.V-sss_noi.V))*100-100)])

results_inf.moments.V_mean   =sum(sum(results_inf.gt .* results_inf.V_eff * results_inf.da * results_inf.dz)) / sum(sum(results_inf.gt * results_inf.da *results_inf.dz));
results_noi.moments.V_mean   =sum(sum(results_noi.gt .* results_noi.V_eff * results_noi.da * results_noi.dz)) / sum(sum(results_noi.gt * results_noi.da *results_noi.dz));
results_noi.moments.V_meaninf=sum(sum(results_inf.gt .* results_noi.V_eff * results_inf.da * results_inf.dz)) / sum(sum(results_inf.gt * results_inf.da *results_inf.dz));

disp(' ')
disp('Welfare improvement (V_inf-V_noi) evaluated using g_inf')
disp(['exp(parameters.rho*(results_inf.moments.V_mean-results_noi.moments.V_meaninf))*100-100 = ' num2str(exp(parameters.rho*(results_inf.moments.V_mean-results_noi.moments.V_meaninf))*100-100)])

disp(' ')
disp('Welfare improvement (V_inf-V_noi) evaluated using g_inf and g_noi')
disp(['exp(parameters.rho*(results_inf.moments.V_mean-results_noi.moments.V_mean))*100-100 = ' num2str(exp(parameters.rho*(results_inf.moments.V_mean-results_noi.moments.V_mean))*100-100)])


disp(' ')
disp('Consumption improvement (c_inf/c_noi) comparing the sss of each world')
disp(['sss_inf.c/sss_noi.c*100-100 = ' num2str(sss_inf.c/sss_noi.c*100-100)])

results_inf.moments.c_mean   =sum(sum(results_inf.gt .* results_inf.c_eff * results_inf.da * results_inf.dz)) / sum(sum(results_inf.gt * results_inf.da *results_inf.dz));
results_noi.moments.c_mean   =sum(sum(results_noi.gt .* results_noi.c_eff * results_noi.da * results_noi.dz)) / sum(sum(results_noi.gt * results_noi.da *results_noi.dz));
results_noi.moments.c_meaninf=sum(sum(results_inf.gt .* results_noi.c_eff * results_inf.da * results_inf.dz)) / sum(sum(results_inf.gt * results_inf.da *results_inf.dz));

results_inf.moments.c_mean_nd   =sum(sum(results_inf.g     .* results_inf.c_eff * results_inf.da * results_inf.dz)) / sum(sum(results_inf.g     * results_inf.da *results_inf.dz));
results_noi.moments.c_mean_nd   =sum(sum(results_noi.g     .* results_noi.c_eff * results_noi.da * results_noi.dz)) / sum(sum(results_noi.g     * results_noi.da *results_noi.dz));
results_noi.moments.c_meaninf_nd=sum(sum(results_inf.g     .* results_noi.c_eff * results_inf.da * results_inf.dz)) / sum(sum(results_inf.g     * results_inf.da *results_inf.dz));

results_inf.moments.c_mean_d    =sum(sum(results_inf.g_def .* results_inf.c_eff * results_inf.da * results_inf.dz)) / sum(sum(results_inf.g_def * results_inf.da *results_inf.dz));
results_noi.moments.c_mean_d    =sum(sum(results_noi.g_def .* results_noi.c_eff * results_noi.da * results_noi.dz)) / sum(sum(results_noi.g_def * results_noi.da *results_noi.dz));
results_noi.moments.c_meaninf_d =sum(sum(results_inf.g_def .* results_noi.c_eff * results_inf.da * results_inf.dz)) / sum(sum(results_inf.g_def * results_inf.da *results_inf.dz));

disp(' ')
disp('Consumption improvement (c_inf/c_noi) evaluated using g_inf')
disp(['results_inf.moments.c_mean/results_noi.moments.c_meaninf*100-100 = ' num2str(results_inf.moments.c_mean/results_noi.moments.c_meaninf*100-100)])

disp(' ')
disp('Consumption improvement (c_inf/c_noi) evaluated using g_inf and g_noi')
disp(['results_inf.moments.c_mean/results_noi.moments.c_mean*100-100 = ' num2str(results_inf.moments.c_mean/results_noi.moments.c_mean*100-100)])

disp(' ')
disp('Average consumption in these three worlds:')
disp(['c_inf    = ' num2str(results_inf.moments.c_mean)])
disp(['c_noi    = ' num2str(results_noi.moments.c_mean)])
disp(['c_noiinf = ' num2str(results_noi.moments.c_meaninf)])

disp(' ')
disp('Average consumption in these three worlds, only repayment:')
disp(['c_inf    = ' num2str(results_inf.moments.c_mean_nd)])
disp(['c_noi    = ' num2str(results_noi.moments.c_mean_nd)])
disp(['c_noiinf = ' num2str(results_noi.moments.c_meaninf_nd)])

disp(' ')
disp('Average consumption in these three worlds, only default:')
disp(['c_inf    = ' num2str(results_inf.moments.c_mean_d)])
disp(['c_noi    = ' num2str(results_noi.moments.c_mean_d)])
disp(['c_noiinf = ' num2str(results_noi.moments.c_meaninf_d)])

results_inf.moments.c_std   =(sum(sum(results_inf.gt .* (results_inf.c_eff.^2) * results_inf.da * results_inf.dz)) / sum(sum(results_inf.gt * results_inf.da *results_inf.dz)) - results_inf.moments.c_mean.^2)^0.5;
results_noi.moments.c_std   =(sum(sum(results_noi.gt .* (results_noi.c_eff.^2) * results_noi.da * results_noi.dz)) / sum(sum(results_noi.gt * results_noi.da *results_noi.dz)) - results_noi.moments.c_mean.^2)^0.5;

results_inf.moments.c_std_nd  =(sum(sum(results_inf.g     .* (results_inf.c_eff.^2) * results_inf.da * results_inf.dz)) / sum(sum(results_inf.g     * results_inf.da *results_inf.dz)) - results_inf.moments.c_mean_nd.^2)^0.5;
results_noi.moments.c_std_nd  =(sum(sum(results_noi.g     .* (results_noi.c_eff.^2) * results_noi.da * results_noi.dz)) / sum(sum(results_noi.g     * results_noi.da *results_noi.dz)) - results_noi.moments.c_mean_nd.^2)^0.5;

results_inf.moments.c_std_d   =(sum(sum(results_inf.g_def .* (results_inf.c_eff.^2) * results_inf.da * results_inf.dz)) / sum(sum(results_inf.g_def * results_inf.da *results_inf.dz)) - results_inf.moments.c_mean_d.^2)^0.5;
results_noi.moments.c_std_d   =(sum(sum(results_noi.g_def .* (results_noi.c_eff.^2) * results_noi.da * results_noi.dz)) / sum(sum(results_noi.g_def * results_noi.da *results_noi.dz)) - results_noi.moments.c_mean_d.^2)^0.5;

results_inf.moments.c_var_surf =(results_inf.c_eff.^2) - results_inf.moments.c_mean.^2;
results_noi.moments.c_var_surf =(results_noi.c_eff.^2) - results_noi.moments.c_mean.^2;

disp(' ')
disp(['std of consumption in the world with    inflation = ' num2str(results_inf.moments.c_std)])
disp(['std of consumption in the world without inflation = ' num2str(results_noi.moments.c_std)])

disp(' ')
disp(['std of consumption in the world with    inflation, only repayment = ' num2str(results_inf.moments.c_std_nd)])
disp(['std of consumption in the world without inflation, only repayment = ' num2str(results_noi.moments.c_std_nd)])

disp(' ')
disp(['std of consumption in the world with    inflation, only default = ' num2str(results_inf.moments.c_std_d)])
disp(['std of consumption in the world without inflation, only default = ' num2str(results_noi.moments.c_std_d)])

disp(' ')
disp(['percentage of time in default, with    inflation = ' num2str(sum(sum(results_inf.g_def * results_inf.da *results_inf.dz))*100)])
disp(['percentage of time in default, without inflation = ' num2str(sum(sum(results_noi.g_def * results_noi.da *results_noi.dz))*100)])


GDPfall=exp(obs.z(17))/exp(obs.z(11))-1;
disp(' ')
disp('EPISODE:                    data      model    noinf')
disp(' ')
disp(['max to through GDP    :   ' num2str(round(GDPfall,4))     '    ' num2str(round(GDPfall,4))                     '    ' num2str(round(GDPfall,4))])
disp(['through to max aY     :   ' num2str(round(-obs.aY_up,4))  '    ' num2str(round(-results_inf.moments.aY_up,4))  '    ' num2str(round(-results_noi.moments.aY_up,4))])
disp(['through to max pi     :   ' num2str(round(obs.pi_up,4))   '    ' num2str(round(results_inf.moments.pi_up,4))   '    ' num2str(0)])
disp(['through to max r      :   ' num2str(round(obs.rdif_up,4)) '    ' num2str(round(results_inf.moments.rdif_up,4)) '    ' num2str(round(results_noi.moments.rdif_up,4))])
disp(['through to max rdef   :   ' num2str(round(obs.rdef_up,4)) '    ' num2str(round(results_inf.moments.rdef_up,4)) '    ' num2str(round(results_noi.moments.rdif_up,4))])
disp(['through to max rinf   :   ' num2str(round(obs.rinf_up,4)) '    ' num2str(round(results_inf.moments.rinf_up,4)) '    ' num2str(0)])
disp(' ')
disp(['max aY                :   ' num2str(round(-obs.aY_M,4))  '    ' num2str(round(-results_inf.moments.aY_M,4))  '    ' num2str(round(-results_noi.moments.aY_M,4))])
disp(['max pi                :   ' num2str(round(obs.pi_M,4))   '    ' num2str(round(results_inf.moments.pi_M,4))   '    ' num2str(0)])
disp(['max r                 :   ' num2str(round(obs.rdif_M,4)) '    ' num2str(round(results_inf.moments.rdif_M,4)) '    ' num2str(round(results_noi.moments.rdif_M,4))])
disp(['max rdef              :   ' num2str(round(obs.rdef_M,4)) '    ' num2str(round(results_inf.moments.rdef_M,4)) '    ' num2str(round(results_noi.moments.rdif_M,4))])
disp(['max rinf              :   ' num2str(round(obs.rinf_M,4)) '    ' num2str(round(results_inf.moments.rinf_M,4)) '    ' num2str(0)])

 

%% Calculate Default frontier

z1=15;
z2=25;
z3=35;
disp(' ')
disp('values of y used in the graphs (low-mid-high):')
disp([exp(results_inf.z(z1)) exp(results_inf.z(z2)) exp(results_inf.z(z3))]);

a=-results_inf.a;
z= results_inf.z;




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




