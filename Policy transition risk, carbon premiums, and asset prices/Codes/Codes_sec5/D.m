function D=D(T, policy_state, tipping)
    global MCsimulation damages 
    % Cai Lontzek specification
    % Drawback: SCC declines when the first tipping element kicks in
    
    if MCsimulation==0 && damages==0
        D=1;
    else
        D=(1-(tipping-1)*0.025)./(1+3.1*0.00236.*T.^2);
    end
end