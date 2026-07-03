function [lb, ub] = dynamic_het1_complementarity_conditions(params)
ub = inf(8,1);
lb = -ub;
lb(1)=0;
lb(2)=0;
end
