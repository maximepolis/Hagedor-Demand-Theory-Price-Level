%% Terminal Conditions for indirect utility and optimal controls
tempv1 = 1;
tempv2 = 1;
time_counter=time.number;

for breakthrough_counter=1:breakthrough.number+1
    for policy_counter=1:policy.number+1
        for tipping_counter=1:tipping.number+1
            utility_s1(:,:,policy_counter,tipping_counter,breakthrough_counter) = calib.v./D(temperature.mesh,policy_counter,tipping_counter);
        end
    end
end

V=utility_s1(:,:,:,:,:);
Vs(2:state.number,:,:,:,:)=abs(V(3:(state.number+1),:,:,:,:)-V(1:(state.number-1),:,:,:,:))./(2.*state.delta);
Vs(1,:,:,:,:)=abs(-3.*V(1,:,:,:,:)+4.*V(2,:,:,:,:)-V(3,:,:,:,:))./(2.*state.delta);
Vs(state.number+1,:,:,:,:)=abs(3.*V(state.number+1,:,:,:,:)-4.*V(state.number,:,:,:,:)+V(state.number-1,:,:,:,:))./(2.*state.delta);
Vtau(:,2:temperature.number,:,:,:)=abs(V(:,3:(temperature.number+1),:,:,:)-V(:,1:(temperature.number-1),:,:,:))./(2.*temperature.delta);
Vtau(:,1,:,:,:)=abs(-3.*V(:,1,:,:,:)+4.*V(:,2,:,:,:)-V(:,3,:,:,:))./(2.*temperature.delta);
Vtau(:,temperature.number+1,:,:,:)=abs(3.*V(:,temperature.number+1,:,:,:)-4.*V(:,temperature.number,:,:,:)+V(:,temperature.number-1,:,:,:))./(2.*temperature.delta);

thin.investment_green_s1=zeros(thin.state.number+1,thin.temperature.number+1, policy.number+1, tipping.number+1, breakthrough.number+1);
options = optimoptions('fsolve','Display','off');

%% Optimal Strategies
for breakthrough_counter=1:breakthrough.number+1
    for tipping_counter=1:tipping.number+1
        for policy_counter=1:policy.number+1
            Code_FOC
        end
    end
end

%% Terminal Condition for PDR
pdr1_s1(:,:,:,:,:) = 16.92;
pdr2_s1(:,:,:,:,:) = 16.92;
for breakthrough_counter=1:breakthrough.number+1
    for policy_counter=1:policy.number+1
        for tipping_counter=1:tipping.number+1
            delta_green_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(production.A(1).*(pref.kappa(1,1).*g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(1)+pref.kappa(2,1).*f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(1)).^(production.eta(1)/pref.rho(1)).*D(temperature.mesh,policy_counter,tipping_counter)-i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-(production.b(1,end)*cost_scaling(breakthrough_counter,state.mesh)).*g1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.b(2,end).*f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));
            delta_brown_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(production.A(2).*(pref.kappa(1,2).*g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(2)+pref.kappa(2,2).*f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^pref.rho(2)).^(production.eta(2)/pref.rho(2)).*D(temperature.mesh,policy_counter,tipping_counter)-i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-(production.b(1,end)*cost_scaling(breakthrough_counter,state.mesh)).*g2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.b(2,end).*f2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));
        end
    end
end
%% Update old and now Indirectutiltiy
thin.investment_green_s1old = thin.investment_green_s1;
utility_s1Old = utility_s1;
utility_s1prev = utility_s1;
optresult = utility_s1;
pdr1_s1Old = pdr1_s1;
pdr2_s1Old = pdr2_s1;
chi1_s1Old = chi1_s1;
chi2_s1Old = chi2_s1;
delta_green_s1Old=delta_green_s1;
delta_brown_s1Old=delta_brown_s1;