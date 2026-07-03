%% Relevant drift terms
capital.drift=(1-state.mesh).*(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),1)-production.delta(1)+r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-0.5*reallocation.kappa.*r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2)...
    +state.mesh.*(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),2)-production.delta(2)-r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)./state.mesh);
state.drift=(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),2)-production.delta(2)-r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)./state.mesh)...
    -(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),1)-production.delta(1)+r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-0.5*reallocation.kappa.*r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2)...
    -capital.covariation;
temperature.drift=temperature.p(temp_counter_T).*temperature.tcre.*tcre_scaling(tipping_counter).*(f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)+f1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh);

%% Pricing Kernel (2nd-order approximation)
% 2nd-order fit of chi
[xData, yData, zData] = prepareSurfaceData(state.vector, temperature.vector, c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)');
ft = fittype('poly22');
[fitresult, gof_c] = fit([xData, yData], zData, ft);

% Dynamics of c
c.p=[fitresult.p00 fitresult.p10 fitresult.p01 fitresult.p20 fitresult.p02 fitresult.p11];
c.mesh=c.p(1)+c.p(2).*state.mesh+c.p(3)*temperature.mesh+c.p(4).*state.mesh.^2+c.p(5).*temperature.mesh.^2+c.p(6).*state.mesh.*temperature.mesh;
c.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)=(c.p(2)+2.*c.p(4).*state.mesh+c.p(6).*temperature.mesh).*state.mesh.*(1-state.mesh).*state.drift./c.mesh+...
    +c.p(4).*state.variation./c.mesh...
    +(c.p(3)+2.*c.p(5).*temperature.mesh+c.p(6).*state.mesh).*temperature.drift./c.mesh...
    +c.p(5).*temperature.variation./c.mesh;
c.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(c.p(2)+2.*c.p(4).*state.mesh+c.p(6).*temperature.mesh).*state.mesh.*(1-state.mesh).*(-production.sigma(1)+production.sigma(2).*production.rho12)./c.mesh;
c.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(c.p(2)+2.*c.p(4).*state.mesh+c.p(6).*temperature.mesh).*state.mesh.*(1-state.mesh).*production.sigma(2).*sqrt(1-production.rho12^2)./c.mesh;
c.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(c.p(3)+2.*c.p(5).*temperature.mesh+c.p(6).*state.mesh).*sqrt(temperature.variation)./c.mesh;

% Relevant risk terms
state.sigma1(:,:)=state.mesh.*(1-state.mesh).*(-production.sigma(1)+production.sigma(2).*production.rho12);
state.sigma2(:,:)=state.mesh.*(1-state.mesh).*production.sigma(2).*sqrt(1-production.rho12^2);
state.sigma3(:,:)=state.mesh.*0;
G.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)=Vs(:,:,policy_counter,tipping_counter,breakthrough_counter)./V(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.sigma1(:,:);
G.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)=Vs(:,:,policy_counter,tipping_counter,breakthrough_counter)./V(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.sigma2(:,:);
G.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)=Vtau(:,:,policy_counter,tipping_counter,breakthrough_counter)./V(:,:,policy_counter,tipping_counter,breakthrough_counter).*sqrt(temperature.variation);
capital.sigma1(:,:)=(1-state.mesh).*production.sigma(1)+state.mesh.*production.sigma(2).*production.rho12;
capital.sigma2(:,:)=state.mesh.*production.sigma(2).*sqrt(1-production.rho12^2);
capital.sigma3(:,:)=state.mesh.*0;

%% Risk-free rate
rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=pref.delta + capital.drift/pref.psi - 0.5*pref.gamma*(1+1/pref.psi).*capital.variation...
    - intensity.lambda.*intensity.rf_adjustment...
    - climate.lambda.*climate.rf_adjustment...
    + c.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)/pref.psi...
    - (1+pref.psi)/pref.psi.^2*(c.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+c.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+c.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).^2)...
    + (pref.theta-1)./(2*pref.theta^2)*(G.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+G.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+G.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).^2)...
    + 1/pref.psi*(pref.theta-1)./(pref.theta)*(c.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).*G.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)+c.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).*G.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)+c.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).*G.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter))...
    - pref.gamma/pref.psi * (capital.sigma1(:,:).*c.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)+capital.sigma2(:,:).*c.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)+capital.sigma3(:,:).*c.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter));

if strcmp(Policy,'on')==1
    if policy_counter==1
        % Backward Jump
        j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-V(:,:,2,tipping_counter,breakthrough_counter)./V(:,:,1,tipping_counter,breakthrough_counter);
        j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-c_s1(:,:,2,tipping_counter,breakthrough_counter)./c_s1(:,:,1,tipping_counter,breakthrough_counter);
        r_policy2=((1-j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,1,2)...
            +(pref.theta-1)./(pref.theta)*j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_pol(temperature.mesh,state.mesh,1,2);
        % Forward Jump
        j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-V(:,:,3,tipping_counter,breakthrough_counter)./V(:,:,1,tipping_counter,breakthrough_counter);
        j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-c_s1(:,:,3,tipping_counter,breakthrough_counter)./c_s1(:,:,1,tipping_counter,breakthrough_counter);
        r_policy3=((1-j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,1,3)...
            +(pref.theta-1)./(pref.theta)*j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_pol(temperature.mesh,state.mesh,1,3);
        % Total
        r_policy=r_policy2+r_policy3;
        sdf_policy=((1-j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,1,2)...
            +((1-j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,1,3);
     elseif policy_counter==3
        % Backward Jump
        j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-V(:,:,2,tipping_counter,breakthrough_counter)./V(:,:,3,tipping_counter,breakthrough_counter);
        j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-c_s1(:,:,2,tipping_counter,breakthrough_counter)./c_s1(:,:,3,tipping_counter,breakthrough_counter);
        r_policy2=((1-j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,3,2)...
            +(pref.theta-1)./(pref.theta)*j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_pol(temperature.mesh,state.mesh,3,2);
        % Forward Jump
        j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-V(:,:,1,tipping_counter,breakthrough_counter)./V(:,:,3,tipping_counter,breakthrough_counter);
        j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-c_s1(:,:,1,tipping_counter,breakthrough_counter)./c_s1(:,:,3,tipping_counter,breakthrough_counter);
        r_policy1=((1-j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,3,1)...
            +(pref.theta-1)./(pref.theta)*j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_pol(temperature.mesh,state.mesh,3,1);
        % Total
        r_policy=r_policy2+r_policy1;
        sdf_policy=((1-j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,3,1)...
            +((1-j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,3,2);
  elseif policy_counter==2
        % Backward Jump
        j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-V(:,:,1,tipping_counter,breakthrough_counter)./V(:,:,2,tipping_counter,breakthrough_counter);
        j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-c_s1(:,:,1,tipping_counter,breakthrough_counter)./c_s1(:,:,2,tipping_counter,breakthrough_counter);
        r_policy1=((1-j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,2,1)...
            +(pref.theta-1)./(pref.theta)*j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_pol(temperature.mesh,state.mesh,2,1);
        % Forward Jump
        j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-V(:,:,3,tipping_counter,breakthrough_counter)./V(:,:,2,tipping_counter,breakthrough_counter);
        j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-c_s1(:,:,3,tipping_counter,breakthrough_counter)./c_s1(:,:,2,tipping_counter,breakthrough_counter);
        r_policy3=((1-j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,2,3)...
            +(pref.theta-1)./(pref.theta)*j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_pol(temperature.mesh,state.mesh,2,3);
        % Total
        r_policy=r_policy1+r_policy3;
        sdf_policy=((1-j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,2,1)...
            +((1-j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_pol(temperature.mesh,state.mesh,2,3);
    end
else
    j_vz(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    j_cz(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    r_policy=0;
    sdf_policy=0;
end

% Update risk free rate
rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    + r_policy;
if strcmp(Tipping,'on')==1
    if tipping_counter==1
        j_vx3(:,:,policy_counter,1,breakthrough_counter)=1-V(:,:,policy_counter,3,breakthrough_counter)./V(:,:,policy_counter,1,breakthrough_counter);
        j_cx3(:,:,policy_counter,1,breakthrough_counter)=1-c_s1(:,:,policy_counter,3,breakthrough_counter)./c_s1(:,:,policy_counter,1,breakthrough_counter);
        j_vx2(:,:,policy_counter,1,breakthrough_counter)=1-V(:,:,policy_counter,2,breakthrough_counter)./V(:,:,policy_counter,1,breakthrough_counter);
        j_cx2(:,:,policy_counter,1,breakthrough_counter)=1-c_s1(:,:,policy_counter,2,breakthrough_counter)./c_s1(:,:,policy_counter,1,breakthrough_counter);
        
        % Update risk free rate
        rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)...
        - (pref.theta-1)./(pref.theta)*j_vx3(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter)...
        - (pref.theta-1)./(pref.theta)*j_vx2(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter)...
        - ((1-j_vx3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter)...
        - ((1-j_vx2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter);
        sdf_tipping=((1-j_vx2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter)...
                   +((1-j_vx3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter);
    elseif tipping_counter==2
        j_vx(:,:,policy_counter,2,breakthrough_counter)=1-V(:,:,policy_counter,3,breakthrough_counter)./V(:,:,policy_counter,2,breakthrough_counter);
        j_cx(:,:,policy_counter,2,breakthrough_counter)=1-c_s1(:,:,policy_counter,3,breakthrough_counter)./c_s1(:,:,policy_counter,2,breakthrough_counter);
        % Update risk free rate
        rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)...
        - (pref.theta-1)./(pref.theta)*j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter)...
        - ((1-j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter);
        sdf_tipping=((1-j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter);
    elseif tipping_counter==3
        sdf_tipping=0;
    end
else 
    sdf_tipping=0;
end

if breakthrough_counter < breakthrough.number+1
    j_vb(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-V(:,:,policy_counter,tipping_counter,breakthrough_counter+1)./V(:,:,policy_counter,tipping_counter,breakthrough_counter);
    j_cb(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter+1)./c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
    % Update risk free rate
    rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)...
        - (pref.theta-1)./(pref.theta)*j_vb(:,:,policy_counter,tipping_counter,breakthrough_counter).*lambda_breakthrough(temperature.mesh,state.mesh,policy_counter,tipping_counter,breakthrough_counter)...
        - ((1-j_vb(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cb(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_breakthrough(temperature.mesh,state.mesh,policy_counter,tipping_counter,breakthrough_counter);
    sdf_breakthrough=((1-j_vb(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cb(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1).*lambda_breakthrough(temperature.mesh,state.mesh,policy_counter,tipping_counter,breakthrough_counter);
else
    j_vb(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    j_cb(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    sdf_breakthrough=0;
end

%% SDF drift = -rf - compensators
sdf.drift(:,:,policy_counter,tipping_counter,breakthrough_counter)=-rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    - intensity.lambda.*(intensity.sdf_adjustment-1)...
    - climate.lambda.*(climate.sdf_adjustment-1)...
    - sdf_policy...
    - sdf_tipping...
    - sdf_breakthrough;

%% Market Prices of risk
sdf.mpr1(:,:,policy_counter,tipping_counter,breakthrough_counter)=-pref.gamma.*capital.sigma1(:,:)-c.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)/pref.psi+(pref.theta-1)/pref.theta*G.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter);
sdf.mpr2(:,:,policy_counter,tipping_counter,breakthrough_counter)=-pref.gamma.*capital.sigma2(:,:)-c.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)/pref.psi+(pref.theta-1)/pref.theta*G.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter);
sdf.mpr3(:,:,policy_counter,tipping_counter,breakthrough_counter)=-pref.gamma.*capital.sigma3(:,:)-c.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)/pref.psi+(pref.theta-1)/pref.theta*G.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter);