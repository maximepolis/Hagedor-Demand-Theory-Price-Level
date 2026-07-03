function [lb, ub] = dynamic_het1_complementarity_conditions(params)
ub = inf(6,1);
lb = -ub;
lb(4)=0;
end
