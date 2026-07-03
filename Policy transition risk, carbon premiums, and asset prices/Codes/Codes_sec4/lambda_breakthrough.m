function lambda_breakthrough=lambda_breakthrough(T,S,policy_counter,tipping_counter,breakthrough_counter)

global breakthrough

if breakthrough_counter==breakthrough.number+1
    lambda_breakthrough=0;
else
    if policy_counter==1
        lambda_breakthrough=0.0224;
    elseif policy_counter==2
        lambda_breakthrough=0.0224;
    else
        lambda_breakthrough=0.0224;
    end
end
end