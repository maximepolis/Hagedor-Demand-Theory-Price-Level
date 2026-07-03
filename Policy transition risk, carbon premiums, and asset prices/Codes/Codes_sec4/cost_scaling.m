function cost_scaling=cost_scaling(breakthrough_counter,S)

if breakthrough_counter==1
    cost_scaling=1;
else
    cost_scaling=1;
end

% 30% law
%a=0.2141/0.6268;
%b=-0.5146;

% 20% law
a=0.5107;
b=-0.3219;

cost_scaling=cost_scaling.*a*(1-S).^b;

end