function ds = dynamic_set_auxiliary_series(ds, yagg, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.SUM_u=yagg(1);
ds.SUM_a=yagg(2);
ds.SUM_b=yagg(3);
ds.AUX_EXO_LEAD_69=ds.Z;
end
