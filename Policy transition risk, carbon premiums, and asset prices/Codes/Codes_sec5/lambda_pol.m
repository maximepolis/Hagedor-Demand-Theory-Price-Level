function lambda_pol=lambda_pol(T,S,policy_counter,policy_target)
global lambda12 lambda13 lambda23 lambda32 lambda31 lambda21 mu_plus mu_minus nu_plus nu_minus transition
%0.2840    0.4660    0.2400


%T=1.27;
%S=0.876;

lambda12 =0.1;
lambda13 =0.05;
lambda23 =0.05;
lambda32 =0.10;
lambda31 =0.06;
lambda21 =0.12;
mu_plus =0.75;
mu_minus =0.75;
nu_plus =0.75;
nu_minus=0.75;
if strcmp(transition,'off')==1
    lambda_pol=0;
else
    if policy_counter==1 && policy_target==2
        lambda_pol=lambda12.*exp(mu_plus*max(T-1.5,0)-nu_plus*S);
    elseif policy_counter==2 && policy_target==3
        lambda_pol=lambda23*exp(mu_plus*max(T-1.5,0)-nu_plus*S);
    elseif policy_counter==1 && policy_target==3
        lambda_pol=lambda13*exp(mu_plus*max(T-1.5,0)-nu_plus*S);
    elseif policy_counter==3 && policy_target==1
        lambda_pol=lambda31./exp(mu_minus*max(T-1.5,0)-nu_minus*S);
    elseif policy_counter==2 && policy_target==1
        lambda_pol=lambda21./exp(mu_minus*max(T-1.5,0)-nu_minus*S);
    elseif policy_counter==3 && policy_target==2
        lambda_pol=lambda32./exp(mu_minus*max(T-1.5,0)-nu_minus*S);
    else
        lambda_pol=0;
    end
end


end