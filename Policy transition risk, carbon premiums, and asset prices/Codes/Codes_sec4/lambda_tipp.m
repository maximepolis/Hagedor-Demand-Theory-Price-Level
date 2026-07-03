function lambda_tipp=lambda_tipp(T,S,policy_counter,tipping_counter)

global tipping

if tipping_counter==tipping.number+1
    lambda_tipp=0;
else
    if tipping_counter == 1
        lambda_tipp=0.012*max(T-1,0);
    else
        lambda_tipp=0.02;
    end
end
end