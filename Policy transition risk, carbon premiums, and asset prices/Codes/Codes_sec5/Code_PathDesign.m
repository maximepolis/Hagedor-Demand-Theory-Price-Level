
%% Monte-Carlo Simulation
for temp_index_t=2:time.number
    if strcmp(Business_as_usual,'on')==1
        load([save_data_at, 'Solution_bau\Z1_solution_', num2str(temp_index_t)]);
        V=Vbau;pi_energy_s1=pi_energy_s1bau;pi_s1=pi_s1bau;mu1_s1=mu1_s1bau;mu2_s1=mu2_s1bau;ep1_s1=ep1_s1bau;ep2_s1=ep2_s1bau;pdr1_s1=pdr1_s1bau;pdr2_s1=pdr2_s1bau;rf_s1=rf_s1bau;r_s1=r_s1bau;i1_s1=i1_s1bau;i2_s1=i2_s1bau;g1_s1=g1_s1bau;g2_s1=g2_s1bau;f1_s1=f1_s1bau;f2_s1=f2_s1bau;c_s1=c_s1bau;tax_s1=tax_s1bau;Q1_s1=Q1_s1bau;Q2_s1=Q2_s1bau;
    else
        load([save_data_at, 'Solution_policy\Z1_solution_', num2str(temp_index_t)]);
    end
    
    for  temp_counter=4
        %% Emissions
        simulation.mac(temp_counter,temp_index_t-1) = (NET.a(1)*simulation.S(temp_counter,temp_index_t-1).^NET.a(2)  +NET.a(3)*NET.a(4)*simulation.S(temp_counter,temp_index_t-1).^NET.a(5)  .*exp(NET.a(3)*simulation.S(temp_counter,temp_index_t-1).^NET.a(6)*simulation.d(temp_counter,temp_index_t-1))).*(simulation.K1(temp_counter,temp_index_t-1)+simulation.K2(temp_counter,temp_index_t-1))*10^12;
        simulation.Emissions(temp_counter,temp_index_t-1) = temperature.p(temp_index_t-1).*(simulation.f1(temp_counter,temp_index_t-1)*(1-simulation.S(temp_counter,temp_index_t-1))+simulation.f2(temp_counter,temp_index_t-1)*simulation.S(temp_counter,temp_index_t-1));
        simulation.neg(temp_counter,temp_index_t-1) = simulation.d(temp_counter,temp_index_t-1);
        simulation.Cumulative_Emissions(temp_counter,temp_index_t)=simulation.Cumulative_Emissions(temp_counter,temp_index_t-1)+simulation.Emissions(temp_counter,temp_index_t-1)*time.delta;
        
        %% Temperature
        simulation.T(temp_counter,temp_index_t)=simulation.T(temp_counter,temp_index_t-1)...
            + temperature.tcre*tcre_scaling(simulation.X(temp_counter,temp_index_t-1)).*simulation.Emissions(temp_counter,temp_index_t-1)*time.delta ...
            - temperature.tcre*tcre_scaling(simulation.X(temp_counter,temp_index_t-1)).*simulation.neg(temp_counter,temp_index_t-1)*time.delta ...
            + simulation.T(temp_counter,temp_index_t-1) * temperature.sigma * dWtau(temp_counter,temp_index_t-1);

        simulation.T(temp_counter,temp_index_t)=max(0.01,simulation.T(temp_counter,temp_index_t));

        %% Disaster Risk
        jump_temp=-1/intensity.lambda*log(U(temp_counter,temp_index_t-1));
        if jump_temp<=time.delta
            simulation.jump(temp_counter,temp_index_t-1)=Z(temp_counter,temp_index_t-1);
        else
            simulation.jump(temp_counter,temp_index_t-1)=0;
        end
        %% Climate Disaster Risk
        jump_climate_temp=-1/(climate.lambda1*simulation.T(temp_counter,temp_index_t-1))*log(Uc(temp_counter,temp_index_t-1));
        if jump_climate_temp<=time.delta
            simulation.jump_c(temp_counter,temp_index_t-1)=Zc(temp_counter,temp_index_t-1);
        else
            simulation.jump_c(temp_counter,temp_index_t-1)=0;
        end
        %% Transition Risk
        
        if temp_index_t<=9
            simulation.Y(temp_counter,temp_index_t)=1;
        elseif temp_index_t<=24
            simulation.Y(temp_counter,temp_index_t)=3;
        elseif temp_index_t<=31
            simulation.Y(temp_counter,temp_index_t)=2;
        elseif temp_index_t<=42
            simulation.Y(temp_counter,temp_index_t)=1;
        elseif temp_index_t<=48
            simulation.Y(temp_counter,temp_index_t)=3;
        elseif temp_index_t<=56
            simulation.Y(temp_counter,temp_index_t)=2;   
        elseif temp_index_t<=73
            simulation.Y(temp_counter,temp_index_t)=3;   
        else 
            simulation.Y(temp_counter,temp_index_t)=2;  
        end

        if temp_index_t<=47
            simulation.B(temp_counter,temp_index_t)=1;
        else
            simulation.B(temp_counter,temp_index_t)=2;
        end

        if temp_index_t<=35
            simulation.X(temp_counter,temp_index_t)=1;
        elseif temp_index_t<=50
            simulation.X(temp_counter,temp_index_t)=2;
        else
            simulation.X(temp_counter,temp_index_t)=3;
        end

        %% Green capital
        simulation.K1(temp_counter,temp_index_t)=simulation.K1(temp_counter,temp_index_t-1)*exp(...
            (-production.delta(1)+simulation.i1(temp_counter,temp_index_t-1)-production.costs(simulation.i1(temp_counter,temp_index_t-1),1)+simulation.r(temp_counter,temp_index_t-1)-0.5*reallocation.kappa*simulation.r(temp_counter,temp_index_t-1)^2)*time.delta ...
            + production.sigma(1).*dW1(temp_counter,temp_index_t-1)...
            - simulation.jump(temp_counter,temp_index_t-1)...
            - simulation.jump_c(temp_counter,temp_index_t-1));
        
        %% Brown capital
        simulation.K2(temp_counter,temp_index_t)=simulation.K2(temp_counter,temp_index_t-1)*exp(...
            + (-production.delta(2)+simulation.i2(temp_counter,temp_index_t-1)-production.costs(simulation.i2(temp_counter,temp_index_t-1),2)-simulation.r(temp_counter,temp_index_t-1).*(1-simulation.S(temp_counter,temp_index_t-1))/simulation.S(temp_counter,temp_index_t-1))*time.delta ...
            + production.sigma(2).*(production.rho12*dW1(temp_counter,temp_index_t-1)+sqrt(1-production.rho12^2)*dW2(temp_counter,temp_index_t-1))...
            - simulation.jump(temp_counter,temp_index_t-1)...
            - simulation.jump_c(temp_counter,temp_index_t-1));

 

        %% State
        simulation.S(temp_counter,temp_index_t)=max(0.01,simulation.K2(temp_counter,temp_index_t)/(simulation.K1(temp_counter,temp_index_t)+simulation.K2(temp_counter,temp_index_t)));
        
        %% Investment Strategy
        temp_index_state    = find(simulation.S(temp_counter,temp_index_t)-state.vector <0 ,1);
        temp_index_temperature     = find(simulation.T(temp_counter,temp_index_t)-temperature.vector <0 ,1);
        
        if simulation.S(temp_counter,temp_index_t)<state.vector(1)
            temp_dif_state=0;
        else
            temp_dif_state=(simulation.S(temp_counter,temp_index_t)-state.vector(temp_index_state-1))/state.delta;
            temp_dif_temperature=(simulation.T(temp_counter,temp_index_t)-temperature.vector(temp_index_temperature-1))/temperature.delta;
        end
        if simulation.T(temp_counter,temp_index_t)>temperature.max
            temp_index_temperature= temperature.number+1;
            temp_dif_temperature=0;
        end
        if simulation.T(temp_counter,temp_index_t)<temperature.min
            temp_index_temperature= 1;
            temp_dif_temperature=0;
        end
        if simulation.S(temp_counter,temp_index_t)>state.max
            temp_index_state= state.number+1;
            temp_dif_state=0;
        end
        if simulation.S(temp_counter,temp_index_t)<state.min
            temp_index_state= 1;
            temp_dif_state=0;
        end
        simulation.d(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*d_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*d_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*d_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*d_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.i1(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*i1_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*i1_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*i1_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*i1_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.i2(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*i2_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*i2_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*i2_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*i2_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.r(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*r_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*r_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*r_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*r_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.f1(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*f1_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*f1_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*f1_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*f1_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.f2(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*f2_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*f2_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*f2_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*f2_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.g1(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*g1_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*g1_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*g1_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*g1_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.g2(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*g2_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*g2_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*g2_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*g2_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.tax(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*tax_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*tax_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*tax_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*tax_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.tax(temp_counter,temp_index_t)     =simulation.tax(temp_counter,temp_index_t)*(simulation.K1(temp_counter,temp_index_t)+simulation.K2(temp_counter,temp_index_t))*10^12;
        
        simulation.q1(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*Q1_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*Q1_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*Q1_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*Q1_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.q2(temp_counter,temp_index_t)     = temp_dif_state.*temp_dif_temperature.*Q2_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*Q2_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*Q2_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*Q2_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.rf(temp_counter,temp_index_t) = temp_dif_state.*temp_dif_temperature.*rf_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*rf_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*rf_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*rf_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.pdr1(temp_counter,temp_index_t) =         (temp_dif_state.*temp_dif_temperature.*pdr1_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*pdr1_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*pdr1_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*pdr1_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t)))^(-1);
        
        simulation.pdr2(temp_counter,temp_index_t) =         (temp_dif_state.*temp_dif_temperature.*pdr2_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*pdr2_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*pdr2_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*pdr2_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t)))^(-1);
        
        simulation.ep1(temp_counter,temp_index_t) =         temp_dif_state.*temp_dif_temperature.*ep1_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*ep1_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*ep1_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*ep1_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.ep2(temp_counter,temp_index_t) =         temp_dif_state.*temp_dif_temperature.*ep2_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*ep2_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*ep2_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*ep2_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        simulation.pi(temp_counter,temp_index_t) =         temp_dif_state.*temp_dif_temperature.*pi_s1(temp_index_state,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*pi_s1(temp_index_state-1,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +(1-temp_dif_state).*temp_dif_temperature.*pi_s1(temp_index_state-1,temp_index_temperature,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t))...
            +temp_dif_state.*(1-temp_dif_temperature).*pi_s1(temp_index_state,temp_index_temperature-1,simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t),simulation.B(temp_counter,temp_index_t));
        
        % Dividends
simulation.D1mu(temp_counter,temp_index_t)=temp_dif_state.*temp_dif_temperature.*D1.mu(temp_index_state,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*D1.mu(temp_index_state-1,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*temp_dif_temperature.*D1.mu(temp_index_state-1,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +temp_dif_state.*(1-temp_dif_temperature).*D1.mu(temp_index_state,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1));
simulation.D2mu(temp_counter,temp_index_t)=temp_dif_state.*temp_dif_temperature.*D2.mu(temp_index_state,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*D2.mu(temp_index_state-1,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*temp_dif_temperature.*D2.mu(temp_index_state-1,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +temp_dif_state.*(1-temp_dif_temperature).*D2.mu(temp_index_state,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1));

simulation.D1sigma1(temp_counter,temp_index_t)=temp_dif_state.*temp_dif_temperature.*D1.sigma1(temp_index_state,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*D1.sigma1(temp_index_state-1,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*temp_dif_temperature.*D1.sigma1(temp_index_state-1,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +temp_dif_state.*(1-temp_dif_temperature).*D1.sigma1(temp_index_state,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1));
simulation.D1sigma2(temp_counter,temp_index_t)=temp_dif_state.*temp_dif_temperature.*D1.sigma2(temp_index_state,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*D1.sigma2(temp_index_state-1,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*temp_dif_temperature.*D1.sigma2(temp_index_state-1,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +temp_dif_state.*(1-temp_dif_temperature).*D1.sigma2(temp_index_state,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1));
simulation.D1sigma3(temp_counter,temp_index_t)=temp_dif_state.*temp_dif_temperature.*D1.sigma3(temp_index_state,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*D1.sigma3(temp_index_state-1,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*temp_dif_temperature.*D1.sigma3(temp_index_state-1,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +temp_dif_state.*(1-temp_dif_temperature).*D1.sigma3(temp_index_state,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1));

simulation.D2sigma1(temp_counter,temp_index_t)=temp_dif_state.*temp_dif_temperature.*D2.sigma1(temp_index_state,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*D2.sigma1(temp_index_state-1,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*temp_dif_temperature.*D2.sigma1(temp_index_state-1,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +temp_dif_state.*(1-temp_dif_temperature).*D2.sigma1(temp_index_state,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1));
simulation.D2sigma2(temp_counter,temp_index_t)=temp_dif_state.*temp_dif_temperature.*D2.sigma2(temp_index_state,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*D2.sigma2(temp_index_state-1,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*temp_dif_temperature.*D2.sigma2(temp_index_state-1,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +temp_dif_state.*(1-temp_dif_temperature).*D2.sigma2(temp_index_state,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1));
simulation.D2sigma3(temp_counter,temp_index_t)=temp_dif_state.*temp_dif_temperature.*D2.sigma3(temp_index_state,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*(1-temp_dif_temperature).*D2.sigma3(temp_index_state-1,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +(1-temp_dif_state).*temp_dif_temperature.*D2.sigma3(temp_index_state-1,temp_index_temperature,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1))...
            +temp_dif_state.*(1-temp_dif_temperature).*D2.sigma3(temp_index_state,temp_index_temperature-1,simulation.Y(1,1),simulation.X(1,1),simulation.B(1,1));

% absolute quantities
        simulation.E1(temp_counter,temp_index_t)=(pref.kappa(1,1).*(simulation.g1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t)).^pref.rho(1)+pref.kappa(2,1).*(simulation.f1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t)).^pref.rho(1)).^(1/pref.rho(1));
        simulation.E2(temp_counter,temp_index_t)=(pref.kappa(1,2).*(simulation.g2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t)).^pref.rho(2)+pref.kappa(2,2).*(simulation.f2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t)).^pref.rho(2)).^(1/pref.rho(2));
        simulation.Y1(temp_counter,temp_index_t)=production.A(1).*simulation.K1(temp_counter,temp_index_t).^(1-production.eta(1)).*simulation.E1(temp_counter,temp_index_t).^production.eta(1).*D(simulation.T(temp_counter,temp_index_t),simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t));
        simulation.Y2(temp_counter,temp_index_t)=production.A(2).*simulation.K2(temp_counter,temp_index_t).^(1-production.eta(2)).*simulation.E2(temp_counter,temp_index_t).^production.eta(2).*D(simulation.T(temp_counter,temp_index_t),simulation.Y(temp_counter,temp_index_t),simulation.X(temp_counter,temp_index_t));
        simulation.D1(temp_counter,temp_index_t)=simulation.Y1(temp_counter,temp_index_t)-simulation.i1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t)-production.b(1,temp_index_t).*simulation.g1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t)-production.b(2,temp_index_t).*simulation.f1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t);
        simulation.D2(temp_counter,temp_index_t)=simulation.Y2(temp_counter,temp_index_t)-simulation.i2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t)-production.b(1,temp_index_t).*simulation.g2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t)-production.b(2,temp_index_t).*simulation.f2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t);
        simulation.Output(temp_counter,temp_index_t) =simulation.Y1(temp_counter,temp_index_t)+simulation.Y2(temp_counter,temp_index_t);
        simulation.C(temp_counter,temp_index_t)=simulation.D1(temp_counter,temp_index_t)+simulation.D2(temp_counter,temp_index_t);
        simulation.pi_energy(temp_counter,temp_index_t) =  (simulation.g1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t) + simulation.g2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t))/(simulation.g1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t) + simulation.g2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t) + simulation.f1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t) + simulation.f2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t));
        simulation.Cg(temp_counter,temp_index_t)=(simulation.g1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t) + simulation.g2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t)).*production.b(1,temp_index_t)*cost_scaling(1,simulation.S(temp_counter,temp_index_t));
        simulation.Cf(temp_counter,temp_index_t)=(simulation.f1(temp_counter,temp_index_t).*simulation.K1(temp_counter,temp_index_t) + simulation.f2(temp_counter,temp_index_t).*simulation.K2(temp_counter,temp_index_t)).*production.b(2);
        simulation.Ctot(temp_counter,temp_index_t)=simulation.Cg(temp_counter,temp_index_t)+simulation.Cf(temp_counter,temp_index_t);
        simulation.Cratio(temp_counter,temp_index_t)=simulation.Ctot(temp_counter,temp_index_t)./simulation.Output(temp_counter,temp_index_t);
        % relative quantities
        simulation.g(temp_counter,temp_index_t-1)=log(simulation.Output(temp_counter,temp_index_t)./simulation.Output(temp_counter,temp_index_t-1));
        %simulation.g(temp_counter,temp_index_t-1)=log(simulation.C(temp_counter,temp_index_t)./simulation.C(temp_counter,temp_index_t-1));
        simulation.nu(temp_counter,temp_index_t)=temperature.p(temp_index_t).*simulation.S(temp_counter,temp_index_t)./(simulation.K1(temp_counter,temp_index_t)+simulation.K2(temp_counter,temp_index_t));
        simulation.C_Y(temp_counter,temp_index_t)=simulation.C(temp_counter,temp_index_t)./simulation.Output(temp_counter,temp_index_t);
        simulation.cp(temp_counter,temp_index_t)=simulation.ep2(temp_counter,temp_index_t)-simulation.ep1(temp_counter,temp_index_t);
    end
end

%% Testing by temperature in 2100
temperature_state1=simulation.T(:,81);
temperature_state1(temperature_state1<=2.5)=NaN;
temperature_state1(temperature_state1>2.5)=1;
no_1=nansum(temperature_state1);
bau_percent=no_1/simulation.number;

temperature_state2=simulation.T(:,81);
temperature_state2(temperature_state2>2.5)=NaN;
temperature_state2(temperature_state2<=1.8)=NaN;
temperature_state2(isnan(temperature_state2)==0)=1;
no_2=nansum(temperature_state2);
opt_percent=no_2/simulation.number;

temperature_state3=simulation.T(:,81);
temperature_state3(temperature_state3>1.8)=NaN;
temperature_state3(temperature_state3<=1.8)=1;
no_3=nansum(temperature_state3);
lim_percent=no_3/simulation.number;
disp([lim_percent opt_percent bau_percent]);


Code_PathDesign;
