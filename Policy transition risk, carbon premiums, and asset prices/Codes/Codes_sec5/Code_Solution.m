%% Start iteration
error=NaN*policy.vector;
disp([datestr(now), ': Start Calculation']);
%% Time Iteration
for temp_counter_T=time.number:-1:1
    time_counter=temp_counter_T;
    % Error Iteration: Finish if iter.error is below threshold
    for breakthrough_counter=breakthrough.number+1:-1:1
        for tipping_counter=tipping.number+1:-1:1
            help.flag       = 0 ;
            iter.error      = 100 ;         % Initialize Iteration Error
            iter.threshold  = 0.0000001;    % Treshold for convergence
            iter.counter    = 1;           % Counts iterations
            while iter.counter<=15 && iter.error >= iter.threshold
                % For loop for the non-directed Markov Chain
                for policy_counter=policy.number+1:-1:1
                    % Update Drift terms
                    capital.drift=(1-state.mesh).*(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),1)-production.delta(1)-production.xi(1).*temperature.mesh+r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-0.5*reallocation.kappa.*r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2)...
                        +state.mesh.*(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),2)-production.delta(2)-production.xi(2).*temperature.mesh-r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)./state.mesh);
                    state.drift=(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),2)-production.delta(2)-production.xi(2).*temperature.mesh-r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)./state.mesh)...
                        -(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),1)-production.delta(1)-production.xi(1).*temperature.mesh+r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-0.5*reallocation.kappa.*r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2)...
                        -capital.covariation;
                    mu_s=state.drift;
                    temperature.drift=temperature.p(temp_counter_T).*temperature.tcre.*tcre_scaling(tipping_counter).*(f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)+f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh)-temperature.depreciation.*temperature.mesh...
                        -temperature.tcre.*tcre_scaling(tipping_counter).*d_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
                    
                    % Create Sparse Matrix and RHS solution vector
                    Code_Matrix_Solution;
        
                    optresult_v = Matrix_LHS \ Vector_RHS;
                    
                    if min(optresult_v)<0 
                        disp(iter.counter)
                        disp('Error: Indirect Utility is negative!')
                    end
                    if  isreal(optresult_v)==0
                        disp(iter.counter)
                        disp('Error: Indirect Utility is complex!')
                    end

                    optresult(:,:,policy_counter,tipping_counter,breakthrough_counter) = (reshape(optresult_v(:),temperature.number+1,state.number+1)');
                    
                    % Error Calculation and Counter
                    error(policy_counter)=norm(utility_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)./optresult(:,:,policy_counter,tipping_counter,breakthrough_counter)-1);
                    utility_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=optresult(:,:,policy_counter,tipping_counter,breakthrough_counter);
                    
                    % Derivatives
                    V(:,:,policy_counter,tipping_counter,breakthrough_counter)=utility_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
                    Vt(:,:,policy_counter,tipping_counter,breakthrough_counter)=(utility_s1Old(:,:,policy_counter,tipping_counter,breakthrough_counter)-utility_s1(:,:,policy_counter,tipping_counter,breakthrough_counter))./time.delta;
                    Vs(2:state.number,:,policy_counter,tipping_counter,breakthrough_counter)=(V(3:(state.number+1),:,policy_counter,tipping_counter,breakthrough_counter)-V(1:(state.number-1),:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
                    Vs(1,:,policy_counter,tipping_counter,breakthrough_counter)=(-3.*V(1,:,policy_counter,tipping_counter,breakthrough_counter)+4.*V(2,:,policy_counter,tipping_counter,breakthrough_counter)-V(3,:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
                    Vs(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)=(3.*V(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)-4.*V(state.number,:,policy_counter,tipping_counter,breakthrough_counter)+V(state.number-1,:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
                    Vtau(:,2:temperature.number,policy_counter,tipping_counter,breakthrough_counter)=abs(V(:,3:(temperature.number+1),policy_counter,tipping_counter,breakthrough_counter)-V(:,1:(temperature.number-1),policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);
                    Vtau(:,1,policy_counter,tipping_counter,breakthrough_counter)=abs(-3.*V(:,1,policy_counter,tipping_counter,breakthrough_counter)+4.*V(:,2,policy_counter,tipping_counter,breakthrough_counter)-V(:,3,policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);
                    Vtau(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)=abs(3.*V(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)-4.*V(:,temperature.number,policy_counter,tipping_counter,breakthrough_counter)+V(:,temperature.number-1,policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);
                    
                    % Optimal Strategies
                    Code_FOC
                    
                    % SCC and Tobin's Q's
                    if strcmp(Business_as_usual,'on')==1 || (strcmp(Policy,'on')==1 && policy_counter==1)
                        tax_fossil_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=0.*Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter);
                        tax_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=0.*Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter);
                    else
                        tax_fossil_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=-temperature.p(temp_counter_T).*temperature.tcre.*tcre_scaling(tipping_counter)*Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter)./(pref.delta.*(1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter).^(1-1/pref.theta)).*c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^(1/pref.psi)/(10^9);
                        tax_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=tax_fossil_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)./temperature.p(temp_counter_T);
                    end
                    
                    scc_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=-temperature.tcre.*tcre_scaling(tipping_counter)*Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter)./(pref.delta.*(1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter).^(1-1/pref.theta)).*c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^(1/pref.psi)/(10^9);
                    Q1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=((1-pref.gamma)*V(:,:,policy_counter,tipping_counter,breakthrough_counter)-Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh)./(pref.delta.*(1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter).^(1-1/pref.theta).*c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^(-1/pref.psi));
                    Q2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=((1-pref.gamma)*V(:,:,policy_counter,tipping_counter,breakthrough_counter)+Vs(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh))./(pref.delta.*(1-pref.gamma).*V(:,:,policy_counter,tipping_counter,breakthrough_counter).^(1-1/pref.theta).*c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^(-1/pref.psi));
                    pi_energy_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)+f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh)./((g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)+f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1-state.mesh)+(g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)+f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)).*state.mesh);
                    
                    % Calculate the pricing kernel
                    Code_PricingKernel
                    
                    % Calculate the equity premium
                    Code_EquityPremium
                                        
                    % Testing
                    if ~isreal(pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)) || ~isreal(pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter))
                        disp('Error: Price-dividend ratio is complex')
                    end
                    if ~isreal(thin.investment_green_s1(:,:,policy_counter,tipping_counter,breakthrough_counter))
                        disp('Error: Investment Strategy is complex')
                    end
                end
                
                iter.counter=iter.counter+1;
                iter.error=sum(error);
            end
        end
    end
    % Statusanzeige
    if mod(temp_counter_T-1,time.number/(time.max-time.min))==0
        actualelapsed = toc ;
        disp([datestr(now) ': Period ', num2str(floor((temp_counter_T-1)/(time.number/(time.max-time.min)))), ...
            ' finished after ', num2str(actualelapsed/60), ' minutes']);
    end
    
    % Save results
    if strcmp(Business_as_usual,'on')==1
        scc_s1bau=scc_s1;d_s1bau=d_s1;Vbau=V;pi_energy_s1bau=pi_energy_s1;pi_s1bau=pi_s1;mu1_s1bau=mu1_s1;mu2_s1bau=mu2_s1;ep1_s1bau=ep1_s1;ep2_s1bau=ep2_s1;pdr1_s1bau=pdr1_s1;pdr2_s1bau=pdr2_s1;rf_s1bau=rf_s1;r_s1bau=r_s1;i1_s1bau=i1_s1;i2_s1bau=i2_s1;g1_s1bau=g1_s1;g2_s1bau=g2_s1;f1_s1bau=f1_s1;f2_s1bau=f2_s1;c_s1bau=c_s1;tax_s1bau=tax_s1;Q1_s1bau=Q1_s1;Q2_s1bau=Q2_s1;
        save([save_data_at, 'Solution_bau\Z1_solution_', num2str(temp_counter_T)], 'Vbau','pi_energy_s1bau','scc_s1bau','d_s1bau', 'pi_s1bau','mu1_s1bau','mu2_s1bau','ep1_s1bau','ep2_s1bau', 'pdr1_s1bau', 'pdr2_s1bau', 'rf_s1bau', 'r_s1bau', 'i1_s1bau', 'i2_s1bau','g1_s1bau','g2_s1bau','f1_s1bau','f2_s1bau', 'c_s1bau', 'tax_s1bau', 'Q1_s1bau', 'Q2_s1bau','-v6');
    else
        if strcmp(Policy,'on')==1
            save([save_data_at, 'Solution_policy\Z1_solution_', num2str(temp_counter_T)], 'V','pi_energy_s1','scc_s1','d_s1','pi_s1','mu1_s1','mu2_s1','ep1_s1','ep2_s1', 'pdr1_s1', 'pdr2_s1', 'rf_s1', 'r_s1', 'i1_s1', 'i2_s1','g1_s1','g2_s1','f1_s1','f2_s1', 'c_s1', 'tax_s1', 'Q1_s1', 'Q2_s1','D1', 'D2','-v6');
        else
            save([save_data_at, 'Solution_bau\Z1_solution_', num2str(temp_counter_T)], 'V','pi_energy_s1','scc_s1','d_s1','pi_s1','mu1_s1','mu2_s1','ep1_s1','ep2_s1', 'pdr1_s1', 'pdr2_s1', 'rf_s1', 'r_s1', 'i1_s1', 'i2_s1','g1_s1','g2_s1','f1_s1','f2_s1', 'c_s1', 'tax_s1', 'Q1_s1', 'Q2_s1','-v6');
        end
    end
    % Update old and now Indirectutiltiy
    thin.investment_green_s1old = thin.investment_green_s1;
    utility_s1Old = utility_s1;
    pdr1_s1Old = pdr1_s1;
    pdr2_s1Old = pdr2_s1;
    chi1_s1Old = chi1_s1;
    chi2_s1Old = chi2_s1;
    delta_green_s1Old=delta_green_s1;
    delta_brown_s1Old=delta_brown_s1;
end

disp([datestr(now), ': Finished Calculations']);