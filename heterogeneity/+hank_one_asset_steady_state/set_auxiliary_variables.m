function y = set_auxiliary_variables(y, x, yagg, params)
%
% Computes auxiliary variables of the static model
%
y(8)=yagg(1);
y(9)=yagg(2);
y(10)=x(3);
end
