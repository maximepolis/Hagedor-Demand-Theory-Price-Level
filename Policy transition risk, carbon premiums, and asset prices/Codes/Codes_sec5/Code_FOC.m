if (strcmp(Policy,'on')==1 && policy_counter==1)
    load([save_data_at, 'Solution_bau\Z1_solution_', num2str(temp_counter_T)]);
    d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=d_s1bau(:,:,1,1,1);
    g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=g1_s1bau(:,:,1,1,1);
    g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=g2_s1bau(:,:,1,1,1);
    f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=f1_s1bau(:,:,1,1,1);
    f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=f2_s1bau(:,:,1,1,1);
    i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=i1_s1bau(:,:,1,1,1);
    i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=i2_s1bau(:,:,1,1,1);
    r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=r_s1bau(:,:,1,1,1);
    c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=c_s1bau(:,:,1,1,1);
    chi1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=production.A(1).*(pref.kappa(1,1).*g1_s1(:,:,1,1,1).^pref.rho(1)+pref.kappa(2,1).*f1_s1(:,:,1,1,1).^pref.rho(1)).^(production.eta(1)/pref.rho(1)).*D(temperature.mesh,1,1)-i1_s1(:,:,1,1,1)-(production.b(1,time_counter)*cost_scaling(1,state.mesh)).*g1_s1(:,:,1,1,1)-production.b(2,end).*f1_s1(:,:,1,1,1);
    chi2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=production.A(2).*(pref.kappa(1,2).*g2_s1(:,:,1,1,1).^pref.rho(2)+pref.kappa(2,2).*f2_s1(:,:,1,1,1).^pref.rho(2)).^(production.eta(2)/pref.rho(2)).*D(temperature.mesh,1,1)-i2_s1(:,:,1,1,1)-(production.b(1,time_counter)*cost_scaling(1,state.mesh)).*g2_s1(:,:,1,1,1)-production.b(2,end).*f2_s1(:,:,1,1,1);
else
    for sparse_temp_s=1:thin.state.number+1
        for sparse_temp_tau=1:thin.temperature.number+1
            temp_s=1+(sparse_temp_s-1)*thin.divisor;
            temp_tau=1+(sparse_temp_tau-1)*thin.divisor;

            if strcmp(Policy,'on')==1
                % 3 Cases
                if policy_counter==1
                    % BAU
                    foc_i1_solve=@(i1) foc_i1BAU(V(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vs(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vtau(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),state.mesh(temp_s,temp_tau),temperature.mesh(temp_s,temp_tau),i1,time.number,policy_counter,tipping_counter,breakthrough_counter);
                elseif policy_counter==2 || policy_counter==3
                    % Optimal
                    foc_i1_solve=@(i1) foc_i1(V(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vs(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vtau(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),state.mesh(temp_s,temp_tau),temperature.mesh(temp_s,temp_tau),i1,time.number,policy_counter,tipping_counter,breakthrough_counter);
                end
            else
                if strcmp(Business_as_usual,'on')==1
                    % BAU
                    foc_i1_solve=@(i1) foc_i1BAU(V(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vs(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vtau(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),state.mesh(temp_s,temp_tau),temperature.mesh(temp_s,temp_tau),i1,time_counter,policy_counter,tipping_counter,breakthrough_counter);
                else
                    % Optimal
                    foc_i1_solve=@(i1) foc_i1(V(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vs(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vtau(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),state.mesh(temp_s,temp_tau),temperature.mesh(temp_s,temp_tau),i1,time_counter,policy_counter,tipping_counter,breakthrough_counter);
                end
            end
            thin.investment_green_s1(sparse_temp_s,sparse_temp_tau,policy_counter,tipping_counter,breakthrough_counter)=fsolve(foc_i1_solve,thin.investment_green_s1(sparse_temp_s,sparse_temp_tau,policy_counter,tipping_counter,breakthrough_counter),options);
        end
    end

    % Interpolation (T,S)-space
    i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=interp2(thin.temperature.mesh,thin.state.mesh,thin.investment_green_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),temperature.mesh,state.mesh,'makima');
    i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-((1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)-Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh)./(Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)+(1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1-production.phi(1).*i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)))./production.phi(2);
    if breakthrough_counter==1
       d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
       NET_costs=0;
    else
       d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=max(0,log(max(0,...
           (-Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*temperature.tcre*tcre_scaling(tipping_counter)./(((1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)-Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh).*(1-production.phi(1).*i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)))-NET.a(1).*max(NET.zeta,state.mesh).^NET.a(2))./(NET.a(3).*NET.a(4).*max(NET.zeta,state.mesh).^NET.a(5))))./(NET.a(3).*max(NET.zeta,state.mesh).^NET.a(6)));
       NET_costs=NET.a(1)*max(NET.zeta,state.mesh).^NET.a(2).*d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)+NET.a(4).*state.mesh.^(NET.a(5)-NET.a(6)).*exp(NET.a(3).*max(NET.zeta,state.mesh).^NET.a(6).*d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));
       NET_costs(d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)==0)=0;
       NET_MC(:,:,policy_counter,tipping_counter,breakthrough_counter)=NET.a(1)*max(NET.zeta,state.mesh).^NET.a(2)+NET.a(3)*NET.a(4).*max(NET.zeta,state.mesh).^NET.a(5).*exp(NET.a(3).*max(NET.zeta,state.mesh).^NET.a(6).*d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));
    end

    if strcmp(Policy,'on')==1
        if  policy_counter==2 || policy_counter==3
            z1=(pref.kappa(1,1)./pref.kappa(2,1)./(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))).^(1/(pref.rho(1)-1)).*(production.b(2,end)-(Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh).*temperature.p(time_counter)*temperature.tcre*tcre_scaling(tipping_counter))./(((1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)-Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh).*(1-production.phi(1).*i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)))).^(1/(pref.rho(1)-1));
            z2=(pref.kappa(1,2)./pref.kappa(2,2)./(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))).^(1/(pref.rho(2)-1)).*(production.b(2,end)-(Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh.*temperature.p(time_counter)*temperature.tcre*tcre_scaling(tipping_counter))./(((1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)-Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh).*(1-production.phi(1).*i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)))).^(1/(pref.rho(2)-1));
        elseif policy_counter==1
            z1=(pref.kappa(1,1).*production.b(2,time_counter)./pref.kappa(2,1)./(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))).^(1/(pref.rho(1)-1));
            z2=(pref.kappa(1,2).*production.b(2,time_counter)./pref.kappa(2,2)./(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))).^(1/(pref.rho(2)-1));
        end
    else
        if strcmp(Business_as_usual,'on')==1
            z1=(pref.kappa(1,1).*production.b(2,time_counter)./pref.kappa(2,1)./(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))).^(1/(pref.rho(1)-1));
            z2=(pref.kappa(1,2).*production.b(2,time_counter)./pref.kappa(2,2)./(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))).^(1/(pref.rho(2)-1));
        else
            z1=(pref.kappa(1,1)./pref.kappa(2,1)./(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))).^(1/(pref.rho(1)-1)).*(production.b(2,end)-(Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh).*temperature.p(time_counter)*temperature.tcre*tcre_scaling(tipping_counter))./(((1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)-Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh).*(1-production.phi(1).*i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)))).^(1/(pref.rho(1)-1));
            z2=(pref.kappa(1,2)./pref.kappa(2,2)./(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))).^(1/(pref.rho(2)-1)).*(production.b(2,end)-(Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh.*temperature.p(time_counter)*temperature.tcre*tcre_scaling(tipping_counter))./(((1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)-Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh).*(1-production.phi(1).*i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)))).^(1/(pref.rho(2)-1));
        end
    end
    g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=((production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))./(production.eta(1)*production.A(1).*(pref.kappa(1,1)+pref.kappa(2,1).*z1.^pref.rho(1)).^(production.eta(1)/pref.rho(1)-1).*D(temperature.mesh,policy_counter,tipping_counter).*pref.kappa(1,1))).^(1/(production.eta(1)-1));
    g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=((production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh))./(production.eta(2)*production.A(2).*(pref.kappa(1,2)+pref.kappa(2,2).*z2.^pref.rho(2)).^(production.eta(2)/pref.rho(2)-1).*D(temperature.mesh,policy_counter,tipping_counter).*pref.kappa(1,2))).^(1/(production.eta(2)-1));
    f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*z1;
    f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*z2;
    c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-state.mesh).*(production.A(1).*(pref.kappa(1,1).*g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(1)+pref.kappa(2,1).*f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(1)).^(production.eta(1)/pref.rho(1)).*D(temperature.mesh,policy_counter,tipping_counter)-i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh)).*g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.b(2,end).*f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter))...
        +state.mesh.*(production.A(2).*(pref.kappa(1,2).*g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(2)+pref.kappa(2,2).*f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(2)).^(production.eta(2)/pref.rho(2)).*D(temperature.mesh,policy_counter,tipping_counter)-i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh)).*g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.b(2,end).*f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter))...
        -NET_costs;
    chi1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=production.A(1).*(pref.kappa(1,1).*g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(1)+pref.kappa(2,1).*f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(1)).^(production.eta(1)/pref.rho(1)).*D(temperature.mesh,policy_counter,tipping_counter)-i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh)).*g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.b(2,end).*f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-NET_costs;
    chi2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=production.A(2).*(pref.kappa(1,2).*g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(2)+pref.kappa(2,2).*f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(2)).^(production.eta(2)/pref.rho(2)).*D(temperature.mesh,policy_counter,tipping_counter)-i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh)).*g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.b(2,end).*f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-NET_costs;
    % Reallocation Strategy
    r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1./reallocation.kappa.*(Vs(:,:,policy_counter,tipping_counter,breakthrough_counter)./((pref.gamma-1).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)+Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh));
    r_s2(:,:,policy_counter,tipping_counter,breakthrough_counter)=min(max(0,r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)./state.mesh),1);
    r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=r_s2(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh./(1-state.mesh);
   
    % Carbon Budget
    if (strcmp(Policy,'on')==1 && policy_counter==3) 
        foc_i1_solve=@(i1) foc_i1Budget(V(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vs(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),Vtau(temp_s,temp_tau,policy_counter,tipping_counter,breakthrough_counter),state.mesh(temp_s,temp_tau),temperature.mesh(temp_s,temp_tau),i1,time_counter,policy_counter,tipping_counter);
        i1_temp=interp2(thin.temperature.mesh,thin.state.mesh,thin.investment_green_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),temperature.mesh,state.mesh,'makima');
        if breakthrough_counter==1
            d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
            NET_costs=d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
        else
            d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=max(0,log(max(0,...
                (-Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*temperature.tcre*tcre_scaling(tipping_counter)./(((1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter)-Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh).*(1-production.phi(1).*i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)))-NET.a(1).*max(NET.zeta,state.mesh).^NET.a(2))./(NET.a(3).*NET.a(4).*max(NET.zeta,state.mesh).^NET.a(5))))./(NET.a(3).*max(NET.zeta,state.mesh).^NET.a(6)));
            NET_costs=NET.a(1)*max(NET.zeta,state.mesh).^NET.a(2).*d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)+NET.a(4).*state.mesh.^(NET.a(5)-NET.a(6)).*exp(NET.a(3).*max(NET.zeta,state.mesh).^NET.a(6).*d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));
            NET_costs(d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)==0)=0;
        end
        i1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=i1_temp(:,budget.k:end);
        f2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=0;
        f1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=0;
        g1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=((production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh(:,budget.k:end)))./(production.eta(1)*production.A(1).*pref.kappa(1,1).^(production.eta(1)/pref.rho(1)).*D(temperature.mesh(:,budget.k:end),policy_counter,tipping_counter))).^(1/(production.eta(1)-1));
        chi1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=production.A(1).*(pref.kappa(1,1).*g1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(1)).^(production.eta(1)/pref.rho(1)).*D(temperature.mesh(:,budget.k:end),policy_counter,tipping_counter)-i1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)-(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh(:,budget.k:end))).*g1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter);
        if pref.rho(2)<0
            g2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=0;
            i2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=0;
            chi2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=0;
            chi1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=chi1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)-NET_costs;
        else
            i2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=0;
            g2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=((production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh(:,budget.k:end)))./(production.eta(2)*production.A(2).*pref.kappa(1,2).^(production.eta(2)/pref.rho(2)-1).*D(temperature.mesh(:,budget.k:end),policy_counter,tipping_counter))).^(1/(production.eta(2)-1));
            chi2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=production.A(2).*(pref.kappa(1,2).*g2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(2)).^(production.eta(2)/pref.rho(2)).*D(temperature.mesh(:,budget.k:end),policy_counter,tipping_counter)-i2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)-(production.b(1,time_counter)*cost_scaling(breakthrough_counter,state.mesh(:,budget.k:end))).*g2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)-NET_costs(:,budget.k:end);
            chi1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=chi1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)-NET_costs(:,budget.k:end);
        end
        c_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)=max(0.001, (1-state.mesh(:,budget.k:end)).*chi1_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter)+state.mesh(:,budget.k:end).*chi2_s1(:,budget.k:end,policy_counter,tipping_counter,breakthrough_counter));
    end
end
