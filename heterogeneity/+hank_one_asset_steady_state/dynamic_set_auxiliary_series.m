function ds = dynamic_set_auxiliary_series(ds, yagg, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.SUM_a=yagg(1);
ds.SUM_ns=yagg(2);
ds.AUX_EXO_LAG_14_0=ds.rstar;
end
