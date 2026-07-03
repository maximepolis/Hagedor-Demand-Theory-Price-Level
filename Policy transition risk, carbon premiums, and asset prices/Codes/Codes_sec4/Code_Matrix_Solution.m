%% Create Coefficients
if strcmp(Policy,'off')==1
    matrix.policy = 0;
    lambda_pol_sum = 0;
else
    if policy_counter == 1
        matrix.policy = lambda_pol(temperature.mesh,state.mesh,1,2).*utility_s1(:,:,2,tipping_counter,breakthrough_counter)...
            + lambda_pol(temperature.mesh,state.mesh,1,3).*utility_s1(:,:,3,tipping_counter,breakthrough_counter);
        lambda_pol_sum = lambda_pol(temperature.mesh,state.mesh,1,2)+lambda_pol(temperature.mesh,state.mesh,1,3);
    elseif policy_counter == 2
        matrix.policy = lambda_pol(temperature.mesh,state.mesh,2,1).*utility_s1(:,:,1,tipping_counter,breakthrough_counter)...
            + lambda_pol(temperature.mesh,state.mesh,2,3).*utility_s1(:,:,3,tipping_counter,breakthrough_counter);
        lambda_pol_sum = lambda_pol(temperature.mesh,state.mesh,2,1) + lambda_pol(temperature.mesh,state.mesh,2,3);
    elseif policy_counter == 3
        matrix.policy = lambda_pol(temperature.mesh,state.mesh,3,2).*utility_s1(:,:,2,tipping_counter,breakthrough_counter)...
            + lambda_pol(temperature.mesh,state.mesh,3,1).*utility_s1(:,:,1,tipping_counter,breakthrough_counter);
        lambda_pol_sum = lambda_pol(temperature.mesh,state.mesh,3,2) + lambda_pol(temperature.mesh,state.mesh,3,1);
    end
end
if strcmp(Tipping,'on')==1
    if tipping_counter == 1
        matrix.tipping = lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*utility_s1(:,:,policy_counter,2,breakthrough_counter)...
                       + lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*utility_s1(:,:,policy_counter,3,breakthrough_counter);
        lambda_tipp_sum = 2 * lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter);
    elseif tipping_counter == 2
        matrix.tipping = lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter).*utility_s1(:,:,policy_counter,3,breakthrough_counter);
        lambda_tipp_sum = lambda_tipp(temperature.mesh,state.mesh,policy_counter,tipping_counter);
    else
        matrix.tipping = 0;
        lambda_tipp_sum = 0;
    end
else
    matrix.tipping = 0;
    lambda_tipp_sum = 0;
end

if breakthrough_counter < breakthrough.number+1
    matrix.breakthrough = lambda_breakthrough(temperature.mesh,state.mesh,policy_counter,tipping_counter,breakthrough_counter).*utility_s1(:,:,policy_counter,tipping_counter,breakthrough_counter+1);
else
    matrix.breakthrough = 0;
end

matrix.K_1 = matrix.policy + matrix.tipping + matrix.breakthrough;

matrix.K_2 = (1-pref.gamma).*capital.drift...
    - 0.5.*pref.gamma.*(1-pref.gamma).*capital.variation ...
    + intensity.lambda.*(intensity.expected_loss_power-1) ...
    + climate.lambda.*climate.indicator(policy_counter).*(climate.expected_loss_power-1) ...
    + pref.delta.*pref.theta.*optresult(:,:,policy_counter,tipping_counter,breakthrough_counter).^(-1/pref.theta).*c_s1(:,:,policy_counter,tipping_counter,breakthrough_counter).^(1-1/pref.psi) ...
    - pref.delta.*pref.theta...
    - lambda_pol_sum...
    - lambda_breakthrough(temperature.mesh,state.mesh,policy_counter,tipping_counter,breakthrough_counter)...
    - lambda_tipp_sum;

matrix.K_3 = state.drift.*state.mesh.*(1-state.mesh)-pref.gamma.*state.mesh.*(1-state.mesh).*capital.covariation;              

matrix.K_4 = 0.5.*state.variation.*state.mesh(:,:).^2.*(1-state.mesh).^2;                                                                 

matrix.K_5 = temperature.drift;   

matrix.K_6 = 0.5.*temperature.variation;                                                                                                   

matrix.K_7 = 0.*state.mesh(:,:);                                                                  
  
%% Create Vector of RHS 
Vector_RHS = utility_s1Old(:,:,policy_counter,tipping_counter)./time.delta + matrix.K_1; 
Vector_RHS = reshape(Vector_RHS',[],1);             

%% Create Entries for Matrix
% Pre-Allocate Matrices
[temp.Jxh,temp.Jxph,temp.Jx2ph,temp.Jxmh,temp.Jx2mh,temp.Jxhp,temp.Jxh2p,temp.Jxhm,temp.Jxh2m,temp.Jxphp,temp.Jxmhm,temp.Jxphm,temp.Jxmhp ] = deal(zeros(state.number+1, temperature.number+1));  

%J(t,i,j)
temp.Jxh=-matrix.K_2+1./time.delta+2.*matrix.K_4./state.delta.^2+abs(matrix.K_3./state.delta)+2.*matrix.K_6./temperature.delta.^2+abs(matrix.K_5./temperature.delta)-matrix.K_7./(state.delta.*temperature.delta);
temp.Jxh(1,1)=1/time.delta-matrix.K_2(1,1)+matrix.K_3(1,1)./state.delta-matrix.K_4(1,1)./state.delta.^2+matrix.K_5(1,1)./temperature.delta-matrix.K_6(1,1)./(temperature.delta.^2)-matrix.K_7(1,1)./(state.delta.*temperature.delta);
temp.Jxh(1,2:temperature.number)=1/time.delta-matrix.K_2(1,2:temperature.number)+matrix.K_3(1,2:temperature.number)./state.delta-matrix.K_4(1,2:temperature.number)./state.delta.^2+abs(matrix.K_5(1,2:temperature.number)./temperature.delta)+2.*matrix.K_6(1,2:temperature.number)./temperature.delta.^2;
temp.Jxh(1,temperature.number+1)=1/time.delta-matrix.K_2(1,temperature.number+1)+matrix.K_3(1,temperature.number+1)./state.delta-matrix.K_4(1,temperature.number+1)./state.delta.^2-matrix.K_5(1,temperature.number+1)./temperature.delta-matrix.K_6(1,temperature.number+1)./temperature.delta.^2+matrix.K_7(1,temperature.number+1)./(state.delta.*temperature.delta);
temp.Jxh(2:state.number,temperature.number+1)=1/time.delta-matrix.K_2(2:state.number,temperature.number+1)+abs(matrix.K_3(2:state.number,temperature.number+1)./state.delta)+2.*matrix.K_4(2:state.number,temperature.number+1)./state.delta.^2-matrix.K_5(2:state.number,temperature.number+1)./temperature.delta-matrix.K_6(2:state.number,temperature.number+1)./temperature.delta.^2;
temp.Jxh(state.number+1,temperature.number+1)=1/time.delta-matrix.K_2(state.number+1,temperature.number+1)-matrix.K_3(state.number+1,temperature.number+1)./state.delta-matrix.K_5(state.number+1,temperature.number+1)./temperature.delta-matrix.K_4(state.number+1,temperature.number+1)./state.delta.^2-matrix.K_6(state.number+1,temperature.number+1)./temperature.delta.^2-matrix.K_7(state.number+1,temperature.number+1)./(state.delta.*temperature.delta);
temp.Jxh(state.number+1,2:temperature.number)=1/time.delta-matrix.K_2(state.number+1,2:temperature.number)-matrix.K_3(state.number+1,2:temperature.number)./state.delta+abs(matrix.K_5(state.number+1,2:temperature.number))./temperature.delta-matrix.K_4(state.number+1,2:temperature.number)./state.delta.^2+2.*matrix.K_6(state.number+1,2:temperature.number)./temperature.delta.^2;
temp.Jxh(state.number+1,1)=1/time.delta-matrix.K_2(state.number+1,1)-matrix.K_3(state.number+1,1)./state.delta-matrix.K_4(state.number+1,1)./state.delta.^2+matrix.K_5(state.number+1,1)./temperature.delta-matrix.K_6(state.number+1,1)./temperature.delta.^2+matrix.K_7(state.number+1,1)./(state.delta.*temperature.delta);
temp.Jxh(2:state.number,1)=1/time.delta-matrix.K_2(2:state.number,1)+abs(matrix.K_3(2:state.number,1)./state.delta)+matrix.K_5(2:state.number,1)./temperature.delta+2.*matrix.K_4(2:state.number,1)./state.delta.^2-matrix.K_6(2:state.number,1)./temperature.delta.^2;

%J(t,i+1,j)
temp.Jxph=-max(matrix.K_3./state.delta,0)-matrix.K_4./state.delta.^2+matrix.K_7./(2.*state.delta.*temperature.delta);
temp.Jxph(1,1)=-matrix.K_3(1,1)./state.delta+2.*matrix.K_4(1,1)./(state.delta.^2)+matrix.K_7(1,1)./(state.delta.*temperature.delta);
temp.Jxph(1,2:temperature.number)=-matrix.K_3(1,2:temperature.number)./state.delta+2.*matrix.K_4(1,2:temperature.number)./state.delta.^2;
temp.Jxph(1,temperature.number+1)=-matrix.K_3(1,temperature.number+1)./state.delta+2*matrix.K_4(1,temperature.number+1)./state.delta.^2-matrix.K_7(1,temperature.number+1)./(state.delta.*temperature.delta);
temp.Jxph(2:state.number,temperature.number+1)=-max(matrix.K_3(2:state.number,temperature.number+1)./state.delta,0)-matrix.K_4(2:state.number,temperature.number+1)./state.delta.^2-matrix.K_7(2:state.number,temperature.number+1)./(2.*state.delta.*temperature.delta);
temp.Jxph(state.number+1,:)=0;
temp.Jxph(2:state.number,1)=-max(matrix.K_3(2:state.number,1)./state.delta,0)-matrix.K_4(2:state.number,1)./state.delta.^2+matrix.K_7(2:state.number,1)./(2.*state.delta.*temperature.delta);

%J(t,i+2,j)
temp.Jx2ph(1,:)=-matrix.K_4(1,:)./state.delta^2;

%J(t,i-1,j)
temp.Jxmh=min(matrix.K_3./state.delta,0)-matrix.K_4./state.delta.^2+matrix.K_7./(2.*state.delta.*temperature.delta);
temp.Jxmh(1,:)=0;
temp.Jxmh(2:state.number,temperature.number+1)=min(matrix.K_3(2:state.number,temperature.number+1)./state.delta,0)-matrix.K_4(2:state.number,temperature.number+1)./state.delta.^2+matrix.K_7(2:state.number,temperature.number+1)./(2.*state.delta.*temperature.delta);
temp.Jxmh(state.number+1,temperature.number+1)=matrix.K_3(state.number+1,temperature.number+1)./state.delta+2.*matrix.K_4(state.number+1,temperature.number+1)./state.delta.^2+matrix.K_7(state.number+1,temperature.number+1)./(state.delta.*temperature.delta);
temp.Jxmh(state.number+1,2:temperature.number)=matrix.K_3(state.number+1,2:temperature.number)./state.delta+2.*matrix.K_4(state.number+1,2:temperature.number)./state.delta.^2;
temp.Jxmh(state.number+1,1)=matrix.K_3(state.number+1,1)./state.delta+2.*matrix.K_4(state.number+1,1)./state.delta.^2-matrix.K_7(state.number+1,1)./(state.delta.*temperature.delta);
temp.Jxmh(2:state.number,1)=min(matrix.K_3(2:state.number,1)./state.delta,0)-matrix.K_4(2:state.number,1)./state.delta.^2-matrix.K_7(2:state.number,1)./(2.*state.delta.*temperature.delta);

%J(t,i-2,j)
temp.Jx2mh(state.number+1,:)=-matrix.K_4(state.number+1,:)./state.delta.^2;

%J(t,i,j+1)
temp.Jxhp=-max(matrix.K_5./temperature.delta,0)-matrix.K_6./temperature.delta.^2+matrix.K_7./(2.*state.delta.*temperature.delta);
temp.Jxhp(1,1)=-matrix.K_5(1,1)./temperature.delta+2.*matrix.K_6(1,1)./temperature.delta.^2+matrix.K_7(1,1)./(state.delta.*temperature.delta);
temp.Jxhp(1,2:temperature.number)=-max(matrix.K_5(1,2:temperature.number)./temperature.delta,0)-matrix.K_6(1,2:temperature.number)./temperature.delta.^2+matrix.K_7(1,2:temperature.number)./(2.*state.delta.*temperature.delta);
temp.Jxhp(:,temperature.number+1)=0;
temp.Jxhp(state.number+1,2:temperature.number)=-max(matrix.K_5(state.number+1,2:temperature.number)./temperature.delta,0)-matrix.K_6(state.number+1,2:temperature.number)./temperature.delta.^2-matrix.K_7(state.number+1,2:temperature.number)./(2.*state.delta.*temperature.delta);
temp.Jxhp(state.number+1,1)=-matrix.K_5(state.number+1,1)./temperature.delta+2.*matrix.K_6(state.number+1,1)./temperature.delta.^2-matrix.K_7(state.number+1,1)./(state.delta.*temperature.delta);
temp.Jxhp(2:state.number,1)=-matrix.K_5(2:state.number,1)./temperature.delta+2.*matrix.K_6(2:state.number,1)./temperature.delta.^2;

%J(t,i,j+2)
temp.Jxh2p(:,1)=-matrix.K_6(:,1)./temperature.delta.^2;

%J(t,i,j-1)
temp.Jxhm=min(matrix.K_5./temperature.delta,0)-matrix.K_6./temperature.delta.^2+matrix.K_7./(2.*state.delta.*temperature.delta);
temp.Jxhm(1,2:temperature.number)=min(matrix.K_5(1,2:temperature.number)./temperature.delta,0)-matrix.K_6(1,2:temperature.number)./temperature.delta.^2-matrix.K_7(1,2:temperature.number)./(2.*state.delta.*temperature.delta);
temp.Jxhm(1,temperature.number+1)=matrix.K_5(1,temperature.number+1)./temperature.delta+2.*matrix.K_6(1,temperature.number+1)./temperature.delta.^2-matrix.K_7(1,temperature.number+1)./(state.delta.*temperature.delta);
temp.Jxhm(2:state.number,temperature.number+1)=matrix.K_5(2:state.number,temperature.number+1)./temperature.delta+2.*matrix.K_6(2:state.number,temperature.number+1)./temperature.delta.^2;
temp.Jxhm(state.number+1,temperature.number+1)=matrix.K_5(state.number+1,temperature.number+1)./temperature.delta+2.*matrix.K_6(state.number+1,temperature.number+1)./temperature.delta.^2+matrix.K_7(state.number+1,temperature.number+1)./(state.delta.*temperature.delta);
temp.Jxhm(state.number+1,2:temperature.number)=min(matrix.K_5(state.number+1,2:temperature.number)./temperature.delta,0)-matrix.K_6(state.number+1,2:temperature.number)./temperature.delta.^2+matrix.K_7(state.number+1,2:temperature.number)./(2.*state.delta.*temperature.delta);
temp.Jxhm(:,1)=0;

%J(t,i,j-2)
temp.Jxh2m(:,temperature.number+1)=-matrix.K_6(:,temperature.number+1)./temperature.delta.^2;

%J(t,i+1,j+1)
temp.Jxphp=-matrix.K_7./(2.*state.delta.*temperature.delta);
temp.Jxphp(1,1)=-matrix.K_7(1,1)./(state.delta.*temperature.delta);
temp.Jxphp(1,2:temperature.number)=-matrix.K_7(1,2:temperature.number)./(2.*state.delta.*temperature.delta);
temp.Jxphp(:,temperature.number+1)=0;
temp.Jxphp(state.number+1,:)=0;
temp.Jxphp(2:state.number,1)=-matrix.K_7(2:state.number,1)./(2.*state.delta.*temperature.delta);

%J(t,i-1,j-1)
temp.Jxmhm=-matrix.K_7./(2.*state.delta.*temperature.delta);
temp.Jxmhm(1,:)=0;
temp.Jxmhm(2:state.number,temperature.number+1)=-matrix.K_7(2:state.number,temperature.number+1)./(2.*state.delta.*temperature.delta);
temp.Jxmhm(state.number+1,temperature.number+1)=-matrix.K_7(state.number+1,temperature.number+1)./(state.delta.*temperature.delta);
temp.Jxmhm(state.number+1,2:temperature.number)=-matrix.K_7(state.number+1,2:temperature.number)./(2.*state.delta.*temperature.delta);
temp.Jxmhm(:,1)=0;

%J(t,i+1,j-1)
temp.Jxphm(1,2:temperature.number)=matrix.K_7(1,2:temperature.number)./(2.*state.delta.*temperature.delta);
temp.Jxphm(1,temperature.number+1)=matrix.K_7(1,temperature.number+1)./(state.delta.*temperature.delta);
temp.Jxphm(2:state.number,temperature.number+1)=matrix.K_7(2:state.number,temperature.number+1)./(2.*state.delta.*temperature.delta);

%J(t,i-1,j+1)
temp.Jxmhp(state.number+1,2:temperature.number)=matrix.K_7(state.number+1,2:temperature.number)./(2.*state.delta.*temperature.delta);
temp.Jxmhp(state.number+1,1)=matrix.K_7(state.number+1,1)./(state.delta.*temperature.delta);
temp.Jxmhp(2:state.number,1)=matrix.K_7(2:state.number,1)./(2.*state.delta.*temperature.delta);


%Reshape Coefficients
temp.Jxh=reshape(temp.Jxh',numel(temp.Jxh),1);
temp.Jxph=reshape(temp.Jxph',numel(temp.Jxph),1);
temp.Jx2ph=reshape(temp.Jx2ph',numel(temp.Jx2ph),1);
temp.Jxmh=reshape(temp.Jxmh',numel(temp.Jxmh),1);
temp.Jx2mh=reshape(temp.Jx2mh',numel(temp.Jx2mh),1);
temp.Jxhp=reshape(temp.Jxhp',numel(temp.Jxhp),1);
temp.Jxh2p=reshape(temp.Jxh2p',numel(temp.Jxh2p),1);
temp.Jxhm=reshape(temp.Jxhm',numel(temp.Jxhm),1);
temp.Jxh2m=reshape(temp.Jxh2m',numel(temp.Jxh2m),1);
temp.Jxphp=reshape(temp.Jxphp',numel(temp.Jxphp),1);
temp.Jxmhm=reshape(temp.Jxmhm',numel(temp.Jxmhm),1);
temp.Jxphm=reshape(temp.Jxphm',numel(temp.Jxphm),1);
temp.Jxmhp=reshape(temp.Jxmhp',numel(temp.Jxmhp),1);


%center Band
temp.Sij2p=sparse(1:((state.number+1)*(temperature.number+1)-2),3:(state.number+1)*(temperature.number+1),temp.Jxh2p(1:((state.number+1)*(temperature.number+1)-2)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Sijp=sparse(1:((state.number+1)*(temperature.number+1)-1),2:(state.number+1)*(temperature.number+1),temp.Jxhp(1:((state.number+1)*(temperature.number+1)-1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Sij=sparse(1:(state.number+1)*(temperature.number+1),1:(state.number+1)*(temperature.number+1),temp.Jxh,(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Sijm=sparse(2:(state.number+1)*(temperature.number+1),1:((state.number+1)*(temperature.number+1)-1),temp.Jxhm(2:(state.number+1)*(temperature.number+1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Sij2m=sparse(3:(state.number+1)*(temperature.number+1),1:((state.number+1)*(temperature.number+1)-2),temp.Jxh2m(3:(state.number+1)*(temperature.number+1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Scent=temp.Sij2p+temp.Sijp+temp.Sij+temp.Sijm+temp.Sij2m;

%right hand temp.Side band
temp.Sipjm=sparse(1:state.number*(temperature.number+1)+1,(temperature.number+1):(state.number+1)*(temperature.number+1),temp.Jxphm(1:state.number*(temperature.number+1)+1),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Sipj=sparse(1:state.number*(temperature.number+1),(temperature.number+2):(state.number+1)*(temperature.number+1),temp.Jxph(1:state.number*(temperature.number+1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Sipjp=sparse(1:(state.number*(temperature.number+1)-1),(temperature.number+3):(state.number+1)*(temperature.number+1),temp.Jxphp(1:(state.number*(temperature.number+1)-1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Srhs=temp.Sipjm+temp.Sipj+temp.Sipjp;

%second right hand temp.Side band
temp.Si2pj=sparse(1:(temperature.number+1)*(state.number-1),(2*temperature.number+3):(temperature.number+1)*(state.number+1),temp.Jx2ph(1:(temperature.number+1)*(state.number-1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));

%left hand temp.Side band
temp.Simjp=sparse((temperature.number+1):(state.number+1)*(temperature.number+1),1:state.number*(temperature.number+1)+1,temp.Jxmhp((temperature.number+1):(state.number+1)*(temperature.number+1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Simj=sparse((temperature.number+2):(state.number+1)*(temperature.number+1),1:state.number*(temperature.number+1),temp.Jxmh((temperature.number+2):(state.number+1)*(temperature.number+1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Simjm=sparse((temperature.number+3):(state.number+1)*(temperature.number+1),1:(state.number*(temperature.number+1)-1),temp.Jxmhm((temperature.number+3):(state.number+1)*(temperature.number+1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));
temp.Slhs=temp.Simjp+temp.Simj+temp.Simjm;

%second left hand temp.Side band
temp.Si2mj=sparse((2*temperature.number+3):(state.number+1)*(temperature.number+1),1:(state.number-1)*(temperature.number+1),temp.Jx2mh((2*temperature.number+3):(state.number+1)*(temperature.number+1)),(state.number+1)*(temperature.number+1),(state.number+1)*(temperature.number+1));

Matrix_LHS=temp.Scent+temp.Srhs+temp.Si2pj+temp.Slhs+temp.Si2mj; %Left Hand temp.Side Matrix