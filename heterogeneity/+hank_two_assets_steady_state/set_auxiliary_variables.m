function y = set_auxiliary_variables(y, x, yagg, params)
%
% Computes auxiliary variables of the static model
%
y(19)=yagg(1);
y(20)=yagg(2);
y(21)=yagg(3);
y(22)=x(5);
end
