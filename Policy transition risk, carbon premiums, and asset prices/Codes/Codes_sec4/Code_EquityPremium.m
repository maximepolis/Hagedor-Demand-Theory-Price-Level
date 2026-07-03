%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% APPENDIX C.1 %%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Dividends D_i = (chi_i*K_i)^phi
Code_ChiParameters;

%% Jump terms
% Policy Tipping %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Policy,'on')==1
    if policy_counter==1
        % Backward Jump
        j_chi1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,2,tipping_counter,breakthrough_counter)./chi1_s1(:,:,1,tipping_counter,breakthrough_counter);
        j_chi2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,2,tipping_counter,breakthrough_counter)./chi2_s1(:,:,1,tipping_counter,breakthrough_counter);
        j_D1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        % Forward Jump
        j_chi1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,3,tipping_counter,breakthrough_counter)./chi1_s1(:,:,1,tipping_counter,breakthrough_counter);
        j_chi2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,3,tipping_counter,breakthrough_counter)./chi2_s1(:,:,1,tipping_counter,breakthrough_counter);
        j_D1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
  
        D1.z12=j_D1z2;
        D1.z13=j_D1z3;
        D2.z12=j_D2z2;
        D2.z13=j_D2z3;
    elseif policy_counter==3
        j_chi1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,2,tipping_counter,breakthrough_counter)./chi1_s1(:,:,3,tipping_counter,breakthrough_counter);
        j_chi2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,2,tipping_counter,breakthrough_counter)./chi2_s1(:,:,3,tipping_counter,breakthrough_counter);
        j_D1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        % Backward Jump
        j_chi1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,1,tipping_counter,breakthrough_counter)./chi1_s1(:,:,3,tipping_counter,breakthrough_counter);
        j_chi2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,1,tipping_counter,breakthrough_counter)./chi2_s1(:,:,3,tipping_counter,breakthrough_counter);
        j_D1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
   
        D1.z31=j_D1z1;
        D1.z32=j_D1z2;
        D2.z31=j_D2z1;
        D2.z32=j_D2z2;

      
    elseif policy_counter==2
        % Backward Jump
        j_chi1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,1,tipping_counter,breakthrough_counter)./chi1_s1(:,:,2,tipping_counter,breakthrough_counter);
        j_chi2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,1,tipping_counter,breakthrough_counter)./chi2_s1(:,:,2,tipping_counter,breakthrough_counter);
        j_D1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        % Forward Jump
        j_chi1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,3,tipping_counter,breakthrough_counter)./chi1_s1(:,:,2,tipping_counter,breakthrough_counter);
        j_chi2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,3,tipping_counter,breakthrough_counter)./chi2_s1(:,:,2,tipping_counter,breakthrough_counter);
        j_D1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
   
        D1.z21=j_D1z1;
        D1.z23=j_D1z3;
        D2.z21=j_D2z1;
        D2.z23=j_D2z3;
    end
else
    j_chi1z(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    j_chi2z(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    j_D1z(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
    j_D2z(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
    j_hat_D1z(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1z(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
    j_hat_D2z(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2z(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vz(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cz(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;

    D1.z=j_D1z;
    D2.z=j_D2z;
end

% Physical Tipping %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Tipping,'on')==1
    if tipping_counter==1
        % Backward Jump
        j_chi1x2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,policy_counter,2,breakthrough_counter)./chi1_s1(:,:,policy_counter,1,breakthrough_counter);
        j_chi2x2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,policy_counter,2,breakthrough_counter)./chi2_s1(:,:,policy_counter,1,breakthrough_counter);
        j_D1x2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2x2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1x2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2x2(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        % Forward Jump
        j_chi1x3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,policy_counter,2,breakthrough_counter)./chi1_s1(:,:,policy_counter,1,breakthrough_counter);
        j_chi2x3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,policy_counter,2,breakthrough_counter)./chi2_s1(:,:,policy_counter,1,breakthrough_counter);
        j_D1x3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2x3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1x3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2x3(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx3(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
     elseif tipping_counter==2
        j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,policy_counter,tipping_counter+1,breakthrough_counter)./chi1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
        j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,policy_counter,tipping_counter+1,breakthrough_counter)./chi2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
        j_D1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_D2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
        j_hat_D1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
        j_hat_D2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
    elseif tipping_counter==3
       j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)= 0 * temperature.mesh;
       j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)= 0 * temperature.mesh;
       j_D1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
       j_D2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
       j_hat_D1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
       j_hat_D2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
    end
else
    j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)= 0 * temperature.mesh;
    j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)= 0 * temperature.mesh;
    j_D1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
    j_D2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
    j_hat_D1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
    j_hat_D2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2x(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cx(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
end

% Technology %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if breakthrough_counter < breakthrough.number+1
    j_chi1b(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter+1)./chi1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
    j_chi2b(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-chi2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter+1)./chi2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
else 
    j_chi1b(:,:,policy_counter,tipping_counter,breakthrough_counter)=0 * temperature.mesh;
    j_chi2b(:,:,policy_counter,tipping_counter,breakthrough_counter)=0 * temperature.mesh;
end
j_D1b(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1b(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
j_D2b(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2b(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi-1;
j_hat_D1b(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi1b(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vb(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cb(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;
j_hat_D2b(:,:,policy_counter,tipping_counter,breakthrough_counter)=(1-j_chi2b(:,:,policy_counter,tipping_counter,breakthrough_counter)).^leverage.phi.*(1-j_vb(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(1-1./pref.theta).*(1-j_cb(:,:,policy_counter,tipping_counter,breakthrough_counter)).^(-1/pref.psi)-1;

%% Dividend Dynamics
D1.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)=...
    (chi1.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    +chi1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)*production.sigma(1)...
    +i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),1)-production.delta(1)+r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-0.5*reallocation.kappa.*r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2) ...
    +0.5*leverage.phi*(leverage.phi-1)*((production.sigma(1)+chi1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^2+chi1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+chi1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).^2);
D1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)=leverage.phi*(production.sigma(1)+chi1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter));
D1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)=leverage.phi*chi1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter);
D1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)=leverage.phi*chi1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter);

D2.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)=...
    (chi2.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    +chi2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)*production.sigma(2)*production.rho12+chi2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)*production.sigma(2)*sqrt(1-production.rho12^2))...
    +i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)-production.costs(i2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter),2)-production.delta(2)-r_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)./state.mesh ...
    +0.5*leverage.phi*(leverage.phi-1)*((production.sigma(1)*production.rho12+chi2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)).^2+(production.sigma(2)*sqrt(1-production.rho12^2)+chi2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)).^2+chi2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).^2);
D2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)=leverage.phi*(production.sigma(1)*production.rho12+chi2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter));
D2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)=leverage.phi*(production.sigma(2)*sqrt(1-production.rho12^2)+chi2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter));
D2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)=leverage.phi*chi2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter);

%% Discounted Dividends
Hat_D1.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)=D1.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    +sdf.drift(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    +D1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).*sdf.mpr1(:,:,policy_counter,tipping_counter,breakthrough_counter)+D1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).*sdf.mpr2(:,:,policy_counter,tipping_counter,breakthrough_counter)+D1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).*sdf.mpr3(:,:,policy_counter,tipping_counter,breakthrough_counter);
Hat_D1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)=D1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)+sdf.mpr1(:,:,policy_counter,tipping_counter,breakthrough_counter);
Hat_D1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)=D1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)+sdf.mpr2(:,:,policy_counter,tipping_counter,breakthrough_counter);
Hat_D1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)=D1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)+sdf.mpr3(:,:,policy_counter,tipping_counter,breakthrough_counter);

Hat_D2.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)=D2.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    +sdf.drift(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    +D2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).*sdf.mpr1(:,:,policy_counter,tipping_counter,breakthrough_counter)+D2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).*sdf.mpr2(:,:,policy_counter,tipping_counter,breakthrough_counter)+D2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).*sdf.mpr3(:,:,policy_counter,tipping_counter,breakthrough_counter);
Hat_D2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)=D2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)+sdf.mpr1(:,:,policy_counter,tipping_counter,breakthrough_counter);
Hat_D2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)=D2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)+sdf.mpr2(:,:,policy_counter,tipping_counter,breakthrough_counter);
Hat_D2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)=D2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)+sdf.mpr3(:,:,policy_counter,tipping_counter,breakthrough_counter);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% APPENDIX C.2 %%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PDE lösen im Zeitpunkt t
Code_Matrix_Solution_PDR1
temp.result = Matrix_LHS \ Vector_RHS;
pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter) = reshape(temp.result(:),temperature.number+1,state.number+1)';
pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=max(0,pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));

Code_Matrix_Solution_PDR2
temp.result = Matrix_LHS \ Vector_RHS;
pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter) = reshape(temp.result(:),temperature.number+1,state.number+1)';
pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=max(0,pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));

%P1.z13=pdr1_s1(:,:,3,tipping_counter,breakthrough_counter)./pdr1_s1(:,:,1,tipping_counter,breakthrough_counter).*(1+j_D1z3(:,:,1,tipping_counter,breakthrough_counter))-1
%P2.z13=pdr2_s1(:,:,3,tipping_counter,breakthrough_counter)./pdr2_s1(:,:,1,tipping_counter,breakthrough_counter).*(1+j_D2z3(:,:,1,tipping_counter,breakthrough_counter))-1

%% Log price dividend ratio
lpdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=log(pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));
lpdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=log(pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));
lpdr1.d=1;%lpdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
lpdr2.d=1;%lpdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
lpdr1.dt(:,:,policy_counter,tipping_counter,breakthrough_counter)=(log(pdr1_s1Old(:,:,policy_counter,tipping_counter,breakthrough_counter))-lpdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter))./time.delta;
lpdr2.dt(:,:,policy_counter,tipping_counter,breakthrough_counter)=(log(pdr2_s1Old(:,:,policy_counter,tipping_counter,breakthrough_counter))-lpdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter))./time.delta;
lpdr1.ds(2:state.number,:,policy_counter,tipping_counter,breakthrough_counter)=(lpdr1_s1(3:(state.number+1),:,policy_counter,tipping_counter,breakthrough_counter)-lpdr1_s1(1:(state.number-1),:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
lpdr2.ds(2:state.number,:,policy_counter,tipping_counter,breakthrough_counter)=(lpdr2_s1(3:(state.number+1),:,policy_counter,tipping_counter,breakthrough_counter)-lpdr2_s1(1:(state.number-1),:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
lpdr1.ds(1,:,policy_counter,tipping_counter,breakthrough_counter)=(-3.*lpdr1_s1(1,:,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr1_s1(2,:,policy_counter,tipping_counter,breakthrough_counter)-lpdr1_s1(3,:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
lpdr2.ds(1,:,policy_counter,tipping_counter,breakthrough_counter)=(-3.*lpdr2_s1(1,:,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr2_s1(2,:,policy_counter,tipping_counter,breakthrough_counter)-lpdr2_s1(3,:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
lpdr1.ds(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)=(3.*lpdr1_s1(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)-4.*lpdr1_s1(state.number,:,policy_counter,tipping_counter,breakthrough_counter)+lpdr1_s1(state.number-1,:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
lpdr2.ds(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)=(3.*lpdr2_s1(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)-4.*lpdr2_s1(state.number,:,policy_counter,tipping_counter,breakthrough_counter)+lpdr2_s1(state.number-1,:,policy_counter,tipping_counter,breakthrough_counter))./(2.*state.delta);
lpdr1.dtau(:,2:temperature.number,policy_counter,tipping_counter,breakthrough_counter)=(lpdr1_s1(:,3:(temperature.number+1),policy_counter,tipping_counter,breakthrough_counter)-lpdr1_s1(:,1:(temperature.number-1),policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);
lpdr1.dtau(:,1,policy_counter,tipping_counter,breakthrough_counter)=(-3.*lpdr1_s1(:,1,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr1_s1(:,2,policy_counter,tipping_counter,breakthrough_counter)-lpdr1_s1(:,3,policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);
lpdr1.dtau(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)=(3.*lpdr1_s1(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)-4.*lpdr1_s1(:,temperature.number,policy_counter,tipping_counter,breakthrough_counter)+lpdr1_s1(:,temperature.number-1,policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);
lpdr2.dtau(:,2:temperature.number,policy_counter,tipping_counter,breakthrough_counter)=(lpdr2_s1(:,3:(temperature.number+1),policy_counter,tipping_counter,breakthrough_counter)-lpdr2_s1(:,1:(temperature.number-1),policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);
lpdr2.dtau(:,1,policy_counter,tipping_counter,breakthrough_counter)=(-3.*lpdr2_s1(:,1,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr2_s1(:,2,policy_counter,tipping_counter,breakthrough_counter)-lpdr2_s1(:,3,policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);
lpdr2.dtau(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)=(3.*lpdr2_s1(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)-4.*lpdr2_s1(:,temperature.number,policy_counter,tipping_counter,breakthrough_counter)+lpdr2_s1(:,temperature.number-1,policy_counter,tipping_counter,breakthrough_counter))./(2.*temperature.delta);    
lpdr1.dss(2:state.number,:,policy_counter,tipping_counter,breakthrough_counter)=(lpdr1_s1(3:(state.number+1),:,policy_counter,tipping_counter,breakthrough_counter)-2*lpdr1_s1(2:state.number,:,policy_counter,tipping_counter,breakthrough_counter)+lpdr1_s1(1:(state.number-1),:,policy_counter,tipping_counter,breakthrough_counter))./state.delta^2;
lpdr1.dss(1,:,policy_counter,tipping_counter,breakthrough_counter) =(2.*lpdr1_s1(1,:,policy_counter,tipping_counter,breakthrough_counter)-5.*lpdr1_s1(2,:,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr1_s1(3,:,policy_counter,tipping_counter,breakthrough_counter)-lpdr1_s1(4,:,policy_counter,tipping_counter,breakthrough_counter))./state.delta^2;
lpdr1.dss(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)=(2.*lpdr1_s1(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)-5.*lpdr1_s1(state.number,:,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr1_s1(state.number-1,:,policy_counter,tipping_counter,breakthrough_counter)-lpdr1_s1(state.number-2,:,policy_counter,tipping_counter,breakthrough_counter))./state.delta^2;
lpdr2.dss(2:state.number,:,policy_counter,tipping_counter,breakthrough_counter)=(lpdr2_s1(3:(state.number+1),:,policy_counter,tipping_counter,breakthrough_counter)-2*lpdr2_s1(2:state.number,:,policy_counter,tipping_counter,breakthrough_counter)+lpdr2_s1(1:(state.number-1),:,policy_counter,tipping_counter,breakthrough_counter))./state.delta^2;
lpdr2.dss(1,:,policy_counter,tipping_counter,breakthrough_counter) =(2.*lpdr2_s1(1,:,policy_counter,tipping_counter,breakthrough_counter)-5.*lpdr2_s1(2,:,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr2_s1(3,:,policy_counter,tipping_counter,breakthrough_counter)-lpdr2_s1(4,:,policy_counter,tipping_counter,breakthrough_counter))./state.delta^2;
lpdr2.dss(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)=(2.*lpdr2_s1(state.number+1,:,policy_counter,tipping_counter,breakthrough_counter)-5.*lpdr2_s1(state.number,:,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr2_s1(state.number-1,:,policy_counter,tipping_counter,breakthrough_counter)-lpdr2_s1(state.number-2,:,policy_counter,tipping_counter,breakthrough_counter))./state.delta^2;
lpdr1.dtautau(:,2:temperature.number,policy_counter,tipping_counter,breakthrough_counter)=(lpdr1_s1(:,3:(temperature.number+1),policy_counter,tipping_counter,breakthrough_counter)-2*lpdr1_s1(:,2:temperature.number,policy_counter,tipping_counter,breakthrough_counter)+lpdr1_s1(:,1:(temperature.number-1),policy_counter,tipping_counter,breakthrough_counter))./temperature.delta^2;
lpdr1.dtautau(:,1,policy_counter,tipping_counter,breakthrough_counter) =(2.*lpdr1_s1(:,1,policy_counter,tipping_counter,breakthrough_counter)-5.*lpdr1_s1(:,2,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr1_s1(:,3,policy_counter,tipping_counter,breakthrough_counter)-lpdr1_s1(:,4,policy_counter,tipping_counter,breakthrough_counter))./temperature.delta^2;
lpdr1.dtautau(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)=(2.*lpdr1_s1(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)-5.*lpdr1_s1(:,temperature.number,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr1_s1(:,temperature.number-1,policy_counter,tipping_counter,breakthrough_counter)-lpdr1_s1(:,temperature.number-2,policy_counter,tipping_counter,breakthrough_counter))./temperature.delta^2;
lpdr2.dtautau(:,2:temperature.number,policy_counter,tipping_counter,breakthrough_counter)=(lpdr2_s1(:,3:(temperature.number+1),policy_counter,tipping_counter,breakthrough_counter)-2*lpdr2_s1(:,2:temperature.number,policy_counter,tipping_counter,breakthrough_counter)+lpdr2_s1(:,1:(temperature.number-1),policy_counter,tipping_counter,breakthrough_counter))./temperature.delta^2;
lpdr2.dtautau(:,1) =(2.*lpdr2_s1(:,1,policy_counter,tipping_counter,breakthrough_counter)-5.*lpdr2_s1(:,2,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr2_s1(:,3,policy_counter,tipping_counter,breakthrough_counter)-lpdr2_s1(:,4,policy_counter,tipping_counter,breakthrough_counter))./temperature.delta^2;
lpdr2.dtautau(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)=(2.*lpdr2_s1(:,temperature.number+1,policy_counter,tipping_counter,breakthrough_counter)-5.*lpdr2_s1(:,temperature.number,policy_counter,tipping_counter,breakthrough_counter)+4.*lpdr2_s1(:,temperature.number-1,policy_counter,tipping_counter,breakthrough_counter)-lpdr2_s1(:,temperature.number-2,policy_counter,tipping_counter,breakthrough_counter))./temperature.delta^2;

% Drifts
lpdr1.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)=(lpdr1.dt(:,:,policy_counter,tipping_counter,breakthrough_counter)+lpdr1.ds(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.drift.*state.mesh.*(1-state.mesh)+lpdr1.dtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*temperature.drift+0.5*lpdr1.dss(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.variation.*state.mesh.^2.*(1-state.mesh).^2+0.5*lpdr1.dtautau(:,:,policy_counter,tipping_counter,breakthrough_counter).*temperature.variation)./lpdr1.d;
lpdr2.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)=(lpdr2.dt(:,:,policy_counter,tipping_counter,breakthrough_counter)+lpdr2.ds(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.drift.*state.mesh.*(1-state.mesh)+lpdr2.dtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*temperature.drift+0.5*lpdr2.dss(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.variation.*state.mesh.^2.*(1-state.mesh).^2+0.5*lpdr2.dtautau(:,:,policy_counter,tipping_counter,breakthrough_counter).*temperature.variation)./lpdr2.d;

% Volatility Vectors
lpdr1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)=lpdr1.ds(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh.*(1-state.mesh).*(production.sigma(2).*production.rho12-production.sigma(1))./lpdr1.d;
lpdr1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)=lpdr1.ds(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh.*(1-state.mesh).*production.sigma(2).*sqrt(1-production.rho12^2)./lpdr1.d;
lpdr1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)=lpdr1.dtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*temperature.sigma.*temperature.mesh./lpdr1.d;
lpdr2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)=lpdr2.ds(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh.*(1-state.mesh).*(production.sigma(2).*production.rho12-production.sigma(1))./lpdr2.d;
lpdr2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)=lpdr2.ds(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh.*(1-state.mesh).*production.sigma(2).*sqrt(1-production.rho12^2)./lpdr2.d;
lpdr2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)=lpdr2.dtau(:,:,policy_counter,tipping_counter,breakthrough_counter).*temperature.sigma.*temperature.mesh./lpdr2.d;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% APPENDIX C.3 %%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Policy,'on')==1
    if policy_counter==1
        % Backward Jump
        j_Omega1z2(:,:,1,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,2,tipping_counter,breakthrough_counter)./pdr1_s1(:,:,1,tipping_counter,breakthrough_counter);
        j_Omega2z2(:,:,1,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,2,tipping_counter,breakthrough_counter)./pdr2_s1(:,:,1,tipping_counter,breakthrough_counter);
        % Forward Jump
        j_Omega1z3(:,:,1,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,3,tipping_counter,breakthrough_counter)./pdr1_s1(:,:,1,tipping_counter,breakthrough_counter);
        j_Omega2z3(:,:,1,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,3,tipping_counter,breakthrough_counter)./pdr2_s1(:,:,1,tipping_counter,breakthrough_counter);

        mu1_policy=lambda_pol(temperature.mesh,state.mesh,1,2).*((1-j_Omega1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1z2(:,:,policy_counter,tipping_counter,breakthrough_counter))-1)...
            +lambda_pol(temperature.mesh,state.mesh,1,3).*((1-j_Omega1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1z3(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
        mu2_policy=lambda_pol(temperature.mesh,state.mesh,1,2).*((1-j_Omega2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2z2(:,:,policy_counter,tipping_counter,breakthrough_counter))-1)...
            +lambda_pol(temperature.mesh,state.mesh,1,3).*((1-j_Omega2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2z3(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
    elseif policy_counter==3
        % Backward Jump
        j_Omega1z2(:,:,3,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,2,tipping_counter,breakthrough_counter)./pdr1_s1(:,:,3,tipping_counter,breakthrough_counter);
        j_Omega2z2(:,:,3,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,2,tipping_counter,breakthrough_counter)./pdr2_s1(:,:,3,tipping_counter,breakthrough_counter);
        % Forward Jump
        j_Omega1z1(:,:,3,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,1,tipping_counter,breakthrough_counter)./pdr1_s1(:,:,3,tipping_counter,breakthrough_counter);
        j_Omega2z1(:,:,3,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,1,tipping_counter,breakthrough_counter)./pdr2_s1(:,:,3,tipping_counter,breakthrough_counter);

        mu1_policy=lambda_pol(temperature.mesh,state.mesh,3,2).*((1-j_Omega1z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1z2(:,:,policy_counter,tipping_counter,breakthrough_counter))-1)...
            +lambda_pol(temperature.mesh,state.mesh,3,1).*((1-j_Omega1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1z1(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
        mu2_policy=lambda_pol(temperature.mesh,state.mesh,3,2).*((1-j_Omega2z2(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2z2(:,:,policy_counter,tipping_counter,breakthrough_counter))-1)...
            +lambda_pol(temperature.mesh,state.mesh,3,1).*((1-j_Omega2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2z1(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
    elseif policy_counter==2
        % Backward Jump
        j_Omega1z1(:,:,2,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,1,tipping_counter,breakthrough_counter)./pdr1_s1(:,:,2,tipping_counter,breakthrough_counter);
        j_Omega2z1(:,:,2,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,1,tipping_counter,breakthrough_counter)./pdr2_s1(:,:,2,tipping_counter,breakthrough_counter);
        % Forward Jump
        j_Omega1z3(:,:,2,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,3,tipping_counter,breakthrough_counter)./pdr1_s1(:,:,2,tipping_counter,breakthrough_counter);
        j_Omega2z3(:,:,2,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,3,tipping_counter,breakthrough_counter)./pdr2_s1(:,:,2,tipping_counter,breakthrough_counter);

        mu1_policy=lambda_pol(temperature.mesh,state.mesh,2,1).*((1-j_Omega1z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1z1(:,:,policy_counter,tipping_counter,breakthrough_counter))-1)...
            +lambda_pol(temperature.mesh,state.mesh,2,3).*((1-j_Omega1z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1z3(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
        mu2_policy=lambda_pol(temperature.mesh,state.mesh,2,1).*((1-j_Omega2z1(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2z1(:,:,policy_counter,tipping_counter,breakthrough_counter))-1)...
            +lambda_pol(temperature.mesh,state.mesh,2,3).*((1-j_Omega2z3(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2z3(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
    end
else
    j_Omega1z(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    j_Omega2z(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    mu1_policy=0;
    mu2_policy=0;
end



if strcmp(Tipping,'on')==1
    if tipping_counter==1
        % Backward Jump
        j_Omega1x2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,policy_counter,2,breakthrough_counter)./pdr1_s1(:,:,policy_counter,1,breakthrough_counter);
        j_Omega2x2(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,policy_counter,2,breakthrough_counter)./pdr2_s1(:,:,policy_counter,1,breakthrough_counter);
        % Forward Jump
        j_Omega1x3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,policy_counter,3,breakthrough_counter)./pdr1_s1(:,:,policy_counter,1,breakthrough_counter);
        j_Omega2x3(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,policy_counter,3,breakthrough_counter)./pdr2_s1(:,:,policy_counter,1,breakthrough_counter);

        mu1_tipping=lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*((1-j_Omega1x2(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1x2(:,:,policy_counter,tipping_counter,breakthrough_counter))-1)...
            +lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*((1-j_Omega1x3(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1x3(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
        mu2_tipping=lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*((1-j_Omega2x2(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2x2(:,:,policy_counter,tipping_counter,breakthrough_counter))-1)...
            +lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*((1-j_Omega2x3(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2x3(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
    elseif tipping_counter==3
        j_Omega1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
        j_Omega2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
        mu1_tipping=0;
        mu2_tipping=0;
    elseif tipping_counter==2
        % Backward Jump
        j_Omega1x1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,policy_counter,3,breakthrough_counter)./pdr1_s1(:,:,policy_counter,2,breakthrough_counter);
        j_Omega2x1(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,policy_counter,3,breakthrough_counter)./pdr2_s1(:,:,policy_counter,2,breakthrough_counter);
        mu1_tipping=lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*((1-j_Omega1x1(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1x(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
        mu2_tipping=lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*((1-j_Omega2x1(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2x(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);
    end
else
    j_Omega1x(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    j_Omega2x(:,:,policy_counter,tipping_counter,breakthrough_counter)=0;
    mu1_tipping=0;
    mu2_tipping=0;
end

if breakthrough_counter < breakthrough.number+1
    j_Omega1b(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter+1)./pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
    j_Omega2b(:,:,policy_counter,tipping_counter,breakthrough_counter)=1-pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter+1)./pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
else
    j_Omega1b(:,:,policy_counter,tipping_counter,breakthrough_counter)=0 * temperature.mesh;
    j_Omega2b(:,:,policy_counter,tipping_counter,breakthrough_counter)=0 * temperature.mesh;
end


%% Asset Price Drift
mu1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=lpdr1.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    + D1.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    + D1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).*lpdr1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)+D1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).*lpdr1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)+D1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).*lpdr1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    + 0.5*sqrt(lpdr1.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+lpdr1.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+lpdr1.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).^2)...
    - intensity.lambda.*jump.moment(leverage.phi)...
    - climate.lambda.*climate.moment(leverage.phi)...
    + mu1_policy...
    + mu1_tipping...
    + lambda_breakthrough(temperature.mesh,state.mesh,policy_counter,tipping_counter,breakthrough_counter).*((1-j_Omega1b(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D1b(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);    

mu2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=lpdr2.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    + D2.mu(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    + D2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).*lpdr2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter)+D2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).*lpdr2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter)+D2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).*lpdr2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter)...
    + 0.5*sqrt(lpdr2.sigma1(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+lpdr2.sigma2(:,:,policy_counter,tipping_counter,breakthrough_counter).^2+lpdr2.sigma3(:,:,policy_counter,tipping_counter,breakthrough_counter).^2)...
    - intensity.lambda.*jump.moment(leverage.phi)...
    - climate.lambda.*climate.moment(leverage.phi)...
    + mu2_policy...
    + mu2_tipping...
    + lambda_breakthrough(temperature.mesh,state.mesh,policy_counter,tipping_counter,breakthrough_counter).*((1-j_Omega2b(:,:,policy_counter,tipping_counter,breakthrough_counter)).*(1+j_hat_D2b(:,:,policy_counter,tipping_counter,breakthrough_counter))-1);    
    
%% Equity Premium
ep1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=mu1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)+pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^(-1)-rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);
ep2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=mu2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)+pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^(-1)-rf_s1(:,:,policy_counter,tipping_counter,breakthrough_counter);

%% Share of Dirty Assets
pi_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)=((chi2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh).^leverage.phi.*pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter))./((chi1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*(1-state.mesh)).^leverage.phi.*pdr1_s1(:,:,policy_counter,tipping_counter,breakthrough_counter)+(chi2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).*state.mesh).^leverage.phi.*pdr2_s1(:,:,policy_counter,tipping_counter,breakthrough_counter));

%% Plot Price-Dividend Ratios and Equity Premiums
%Code_SurfacePlots


