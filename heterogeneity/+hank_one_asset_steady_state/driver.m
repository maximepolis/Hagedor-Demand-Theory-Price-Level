%
% Status : main Dynare file
%
% Warning : this file is generated automatically by Dynare
%           from model file (.mod)

clearvars -global
clear_persistent_variables(fileparts(which('dynare')), false)
tic0 = tic;
% Define global variables.
global M_ options_ oo_ estim_params_ dataset_ dataset_info estimation_info
options_ = [];
M_.fname = 'hank_one_asset_steady_state';
M_.dynare_version = '8-unstable-2026-05-19-1735-01136995';
oo_.dynare_version = '8-unstable-2026-05-19-1735-01136995';
options_.dynare_version = '8-unstable-2026-05-19-1735-01136995';
%
% Some global variables initialization
%
global_initialization;
M_.exo_names = cell(3,1);
M_.exo_names_tex = cell(3,1);
M_.exo_names_long = cell(3,1);
M_.exo_names(1) = {'G'};
M_.exo_names_tex(1) = {'G'};
M_.exo_names_long(1) = {'G'};
M_.exo_names(2) = {'markup'};
M_.exo_names_tex(2) = {'markup'};
M_.exo_names_long(2) = {'markup'};
M_.exo_names(3) = {'rstar'};
M_.exo_names_tex(3) = {'rstar'};
M_.exo_names_long(3) = {'rstar'};
M_.endo_names = cell(10,1);
M_.endo_names_tex = cell(10,1);
M_.endo_names_long = cell(10,1);
M_.endo_names(1) = {'Y'};
M_.endo_names_tex(1) = {'Y'};
M_.endo_names_long(1) = {'Aggregate output'};
M_.endo_names(2) = {'L'};
M_.endo_names_tex(2) = {'L'};
M_.endo_names_long(2) = {'Aggregate labor'};
M_.endo_names(3) = {'w'};
M_.endo_names_tex(3) = {'w'};
M_.endo_names_long(3) = {'Real wage'};
M_.endo_names(4) = {'pi'};
M_.endo_names_tex(4) = {'pi'};
M_.endo_names_long(4) = {'Inflation'};
M_.endo_names(5) = {'Div'};
M_.endo_names_tex(5) = {'Div'};
M_.endo_names_long(5) = {'Dividends'};
M_.endo_names(6) = {'Tax'};
M_.endo_names_tex(6) = {'Tax'};
M_.endo_names_long(6) = {'Taxes'};
M_.endo_names(7) = {'r'};
M_.endo_names_tex(7) = {'r'};
M_.endo_names_long(7) = {'Real interest rate'};
M_.endo_names(8) = {'SUM_a'};
M_.endo_names_tex(8) = {'SUM\_a'};
M_.endo_names_long(8) = {'SUM_a'};
M_.endo_names(9) = {'SUM_ns'};
M_.endo_names_tex(9) = {'SUM\_ns'};
M_.endo_names_long(9) = {'SUM_ns'};
M_.endo_names(10) = {'AUX_EXO_LAG_14_0'};
M_.endo_names_tex(10) = {'AUX\_EXO\_LAG\_14\_0'};
M_.endo_names_long(10) = {'AUX_EXO_LAG_14_0'};
M_.endo_partitions = struct();
M_.param_names = cell(10,1);
M_.param_names_tex = cell(10,1);
M_.param_names_long = cell(10,1);
M_.param_names(1) = {'beta'};
M_.param_names_tex(1) = {'beta'};
M_.param_names_long(1) = {'beta'};
M_.param_names(2) = {'vphi'};
M_.param_names_tex(2) = {'vphi'};
M_.param_names_long(2) = {'vphi'};
M_.param_names(3) = {'eis'};
M_.param_names_tex(3) = {'eis'};
M_.param_names_long(3) = {'eis'};
M_.param_names(4) = {'frisch'};
M_.param_names_tex(4) = {'frisch'};
M_.param_names_long(4) = {'frisch'};
M_.param_names(5) = {'mu'};
M_.param_names_tex(5) = {'mu'};
M_.param_names_long(5) = {'mu'};
M_.param_names(6) = {'kappa'};
M_.param_names_tex(6) = {'kappa'};
M_.param_names_long(6) = {'kappa'};
M_.param_names(7) = {'phi'};
M_.param_names_tex(7) = {'phi'};
M_.param_names_long(7) = {'phi'};
M_.param_names(8) = {'Z'};
M_.param_names_tex(8) = {'Z'};
M_.param_names_long(8) = {'Z'};
M_.param_names(9) = {'B'};
M_.param_names_tex(9) = {'B'};
M_.param_names_long(9) = {'B'};
M_.param_names(10) = {'r_ss'};
M_.param_names_tex(10) = {'r\_ss'};
M_.param_names_long(10) = {'r_ss'};
M_.param_partitions = struct();
M_.epilogue_names = {};
M_.exo_det_nbr = 0;
M_.exo_nbr = 3;
M_.endo_nbr = 10;
M_.param_nbr = 10;
M_.epilogue_nbr = 0;
M_.orig_endo_nbr = 7;
M_.aux_vars(1).endo_index = 8;
M_.aux_vars(1).type = 14;
M_.aux_vars(1).orig_expr = 'sum(a)';
M_.aux_vars(2).endo_index = 9;
M_.aux_vars(2).type = 14;
M_.aux_vars(2).orig_expr = 'sum(ns)';
M_.aux_vars(3).endo_index = 10;
M_.aux_vars(3).type = 3;
M_.aux_vars(3).orig_index = 3;
M_.aux_vars(3).orig_lead_lag = 0;
M_.aux_vars(3).orig_expr = 'rstar';
M_.heterogeneity(1).endo_nbr = 6;
M_.heterogeneity(1).endo_names = {'c'; 'n'; 'ns'; 'a'; 'AUX_HET_ENDO_LEAD_18'; 'MULT_L_a'};
M_.heterogeneity(1).endo_names_tex = {'c'; 'n'; 'ns'; 'a'; 'AUX\_HET\_ENDO\_LEAD\_18'; 'MULT\_L\_a'};
M_.heterogeneity(1).endo_names_long = {'consumption'; 'labor supply'; 'effective labor supply'; 'assets'; 'AUX_HET_ENDO_LEAD_18'; 'MULT_L_a'};
M_.heterogeneity(1).orig_endo_nbr = 4;
M_.heterogeneity(1).exo_nbr = 1;
M_.heterogeneity(1).exo_names = {'e'};
M_.heterogeneity(1).exo_names_tex = {'e'};
M_.heterogeneity(1).exo_names_long = {'idiosyncratic efficiency'};
M_.heterogeneity(1).param_nbr = 0;
M_.heterogeneity(1).param_names = {};
M_.heterogeneity(1).param_names_tex = {};
M_.heterogeneity(1).param_names_long = {};
M_.heterogeneity(1).aux_vars(1).endo_index = 5;
M_.heterogeneity(1).aux_vars(1).type = 16;
M_.heterogeneity(1).aux_vars(1).eq_nbr = 1;
M_.heterogeneity(1).aux_vars(2).endo_index = 6;
M_.heterogeneity(1).aux_vars(2).type = 15;
M_.heterogeneity(1).aux_vars(2).eq_nbr = 1;
M_.heterogeneity(1).dimension_name = 'households';
M_.heterogeneity_aggregates = {
'sum', 1, 4;
'sum', 1, 3;
};
M_.database = {};
M_.Sigma_e = zeros(3, 3);
M_.Correlation_matrix = eye(3, 3);
M_.Skew_e = zeros(0, 4);
M_.heterogeneity(1).Sigma_e = zeros(1, 1);
M_.H = 0;
M_.Correlation_matrix_ME = 1;
M_.sigma_e_is_diagonal = true;
M_.det_shocks = struct([]);
M_.surprise_shocks = struct([]);
M_.learnt_shocks = struct([]);
M_.learnt_endval = struct([]);
M_.shock_paths = struct([]);
M_.heteroskedastic_shocks.Qvalue_orig = struct([]);
M_.heteroskedastic_shocks.Qscale_orig = struct([]);
M_.heteroskedastic_shocks.Hvalue_orig = struct([]);
M_.heteroskedastic_shocks.Hscale_orig = struct([]);
M_.matched_irfs = {};
M_.matched_irfs_weights = {};
M_.perfect_foresight_controlled_paths = struct([]);
M_.filter_tunes = struct([]);
options_.linear = false;
options_.block = false;
options_.bytecode = false;
options_.use_dll = false;
options_.ramsey_policy = false;
options_.discretionary_policy = false;
M_.nonzero_hessian_eqs = [2 3 5];
M_.hessian_eq_zero = isempty(M_.nonzero_hessian_eqs);
M_.eq_nbr = 10;
M_.ramsey_orig_eq_nbr = 0;
M_.ramsey_orig_endo_nbr = 0;
M_.set_auxiliary_variables = exist(['./+' M_.fname '/set_auxiliary_variables.m'], 'file') == 2;
M_.epilogue_var_list_ = {};
M_.orig_maximum_endo_lag = 1;
M_.orig_maximum_endo_lead = 1;
M_.orig_maximum_exo_lag = 1;
M_.orig_maximum_exo_lead = 0;
M_.orig_maximum_exo_det_lag = 0;
M_.orig_maximum_exo_det_lead = 0;
M_.orig_maximum_lag = 1;
M_.orig_maximum_lead = 1;
M_.orig_maximum_lag_with_diffs_expanded = 1;
M_.lead_lag_incidence = [
 0 3 13;
 0 4 0;
 0 5 0;
 1 6 14;
 0 7 0;
 0 8 0;
 0 9 15;
 0 10 0;
 0 11 0;
 2 12 0;]';
M_.nstatic = 6;
M_.nfwrd   = 2;
M_.npred   = 1;
M_.nboth   = 1;
M_.nsfwrd   = 3;
M_.nspred   = 2;
M_.ndynamic   = 4;
M_.dynamic_tmp_nbr = [2; 2; 1; 0; ];
M_.equations_tags = {
  1 , 'name' , 'Labor demand' ;
  2 , 'name' , 'Dividends' ;
  3 , 'name' , 'Taylor rule' ;
  4 , 'name' , 'Government budget constraint' ;
  5 , 'name' , 'New Keynesian Phillips curve' ;
  6 , 'name' , 'Asset market clearing' ;
  7 , 'name' , 'Labor market clearing' ;
};
M_.mapping.Y.eqidx = [1 2 5 ];
M_.mapping.L.eqidx = [1 2 7 ];
M_.mapping.w.eqidx = [2 5 ];
M_.mapping.pi.eqidx = [2 3 5 ];
M_.mapping.Div.eqidx = [2 ];
M_.mapping.Tax.eqidx = [4 ];
M_.mapping.r.eqidx = [3 4 5 ];
M_.mapping.G.eqidx = [4 ];
M_.mapping.markup.eqidx = [5 ];
M_.mapping.rstar.eqidx = [3 ];
M_.static_and_dynamic_models_differ = false;
M_.has_external_function = false;
M_.maximum_lag = 1;
M_.maximum_lead = 1;
M_.maximum_endo_lag = 1;
M_.maximum_endo_lead = 1;
[~, ~, M_.state_var] = set_state_space(struct(), M_);
oo_.steady_state = zeros(10, 1);
M_.maximum_exo_lag = 0;
M_.maximum_exo_lead = 0;
oo_.exo_steady_state = zeros(3, 1);
M_.params = NaN(10, 1);
M_.endo_trends = struct('deflator', cell(10, 1), 'log_deflator', cell(10, 1), 'growth_factor', cell(10, 1), 'log_growth_factor', cell(10, 1));
M_.dynamic_g1_sparse_rowval = int32([3 3 1 2 5 1 2 7 2 5 2 3 5 2 4 3 4 6 8 7 9 10 5 5 5 4 5 10 ]);
M_.dynamic_g1_sparse_colval = int32([4 10 11 11 11 12 12 12 13 13 14 14 14 15 16 17 17 18 18 19 19 20 21 24 27 31 32 33 ]);
M_.dynamic_g1_sparse_colptr = int32([1 1 1 1 2 2 2 2 2 2 3 6 9 11 14 15 16 18 20 22 23 24 24 24 25 25 25 26 26 26 26 27 28 29 ]);
M_.dynamic_g2_sparse_indices = int32([2 11 14 ;
2 12 13 ;
2 14 14 ;
3 4 14 ;
3 14 14 ;
3 14 10 ;
5 11 11 ;
5 11 21 ;
5 11 24 ;
5 11 27 ;
5 21 24 ;
5 21 27 ;
5 14 14 ;
5 24 24 ;
5 24 27 ;
5 27 27 ;
]);
M_.lhs = {
'L-Y/Z'; 
'Div-(Y-L*w-Y*mu/(mu-1)/(2*kappa)*log(1+pi)^2)'; 
'(phi*pi(-1)+1+r_ss+AUX_EXO_LAG_14_0(-1))/(1+pi)-1-r'; 
'Tax-r*B-G'; 
'kappa*(w/Z-1/mu)+Y(1)/Y*log(1+pi(1))/(1+r(1))+markup-log(1+pi)'; 
'SUM_a-B'; 
'SUM_ns-L'; 
'SUM_a'; 
'SUM_ns'; 
'AUX_EXO_LAG_14_0'; 
};
M_.dynamic_mcp_equations_reordering = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; ];
M_.static_tmp_nbr = [2; 1; 0; 0; ];
M_.static_g1_sparse_rowval = int32([1 2 1 2 7 2 5 2 3 5 2 4 3 4 5 6 8 7 9 3 10 ]);
M_.static_g1_sparse_colval = int32([1 1 2 2 2 3 3 4 4 4 5 6 7 7 7 8 8 9 9 10 10 ]);
M_.static_g1_sparse_colptr = int32([1 3 6 8 11 12 13 16 18 20 22 ]);
M_.static_mcp_equations_reordering = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; ];
M_.heterogeneity(1).state_var = [4 ];
M_.heterogeneity(1).dynamic_tmp_nbr = [1; 1; 1; 0; ];
M_.heterogeneity(1).dynamic_g1_sparse_rowval = int32([2 1 2 3 5 2 3 4 4 2 6 5 1 6 1 2 3 4 2 3 2 2 2 1 ]);
M_.heterogeneity(1).dynamic_g1_sparse_colval = int32([4 7 7 7 7 8 8 8 9 10 10 11 12 12 17 19 19 19 32 32 34 35 36 46 ]);
M_.heterogeneity(1).dynamic_g1_sparse_colptr = int32([1 1 1 1 2 2 2 6 9 10 12 13 15 15 15 15 15 16 16 19 19 19 19 19 19 19 19 19 19 19 19 19 21 21 22 23 24 24 24 24 24 24 24 24 24 24 25 25 25 25 25 25 25 ]);
M_.heterogeneity(1).dynamic_g2_sparse_indices = int32([1 7 7 ;
1 46 17 ;
2 8 19 ;
2 8 32 ;
2 4 36 ;
2 19 32 ;
2 19 34 ;
2 19 35 ;
3 7 7 ;
3 7 19 ;
3 7 32 ;
3 8 8 ;
3 19 32 ;
4 8 19 ;
5 7 7 ;
6 10 12 ;
]);
M_.heterogeneity(1).dynamic_mcp_equations_reordering = [4; 2; 3; 1; 5; 6; ];
M_.heterogeneity(1).set_auxiliary_variables = exist(['./+' M_.fname '/dynamic_het1_set_auxiliary_variables.m'], 'file') == 2;
M_.heterogeneity(1).n_aux_levels = 2;
M_.heterogeneity(1).het_aux_levels = {[5], [6]};
M_.heterogeneity(1).equations_tags = {
  1 , 'name' , 'Euler equation with borrowing constraint' ;
  2 , 'name' , 'Budget constraint' ;
  3 , 'name' , 'Labor supply' ;
  4 , 'name' , 'Effective labor supply' ;
};
M_.params(9) = 5.6;
B = M_.params(9);
M_.params(8) = 1;
Z = M_.params(8);
M_.params(3) = 0.5;
eis = M_.params(3);
M_.params(4) = 0.5;
frisch = M_.params(4);
M_.params(6) = 0.1;
kappa = M_.params(6);
M_.params(5) = 1.2;
mu = M_.params(5);
M_.params(7) = 1.5;
phi = M_.params(7);
M_.params(10) = 0.005;
r_ss = M_.params(10);
w = 1/mu;
Div = 1-w;
Tax = r_ss*B;
initial_guess = struct;
initial_guess.agg.Y = 1;
initial_guess.agg.L = 1;
initial_guess.agg.w = w;
initial_guess.agg.pi = 0;
initial_guess.agg.Div = Div;
initial_guess.agg.Tax = Tax;
initial_guess.agg.r = r_ss;
rho_e = 0.966;
sig_e = 0.5;
[grid_e, ~, Pi_e] = rouwenhorst(rho_e, sig_e, 3, 1e-12, 1e5);
initial_guess.shocks.grids.e = grid_e;
initial_guess.shocks.Pi.e = Pi_e;
grid_a = logspace(log10(0.25), log10(200.25), 30)-0.25;
initial_guess.pol.grids.a = grid_a;
T = (Div-Tax)*grid_e;
fininc = (1+r_ss)*grid_a+T;
coh = (1+r_ss)*grid_a+w*grid_e+T;
c = 0.1*coh;
a = coh-c;
n = ones(size(a));
ns = n .* grid_e;
initial_guess.pol.values.c = c;
initial_guess.pol.values.a = a;
initial_guess.pol.values.n = n;
initial_guess.pol.values.ns = ns;
initial_guess.free_parameters.beta.initial_guess = 0.98;
initial_guess.free_parameters.beta.upper_bound = 0.999;
initial_guess.free_parameters.beta.lower_bound = 0;
initial_guess.free_parameters.vphi.initial_guess = 0.78;
initial_guess.free_parameters.vphi.lower_bound = 0.01;
initial_guess.pol.order = {'e', 'a'};
%
% SHOCKS instructions
%
M_.Sigma_e(1, 1) = (0.01)^2;
M_.Sigma_e(2, 2) = (0.01)^2;
M_.Sigma_e(3, 3) = (0.01)^2;
if ~isfield(options_,'heterogeneity')
    options_.heterogeneity = struct();
end
options_.heterogeneity.calibration.target_equations = {'Asset market clearing', 'Labor market clearing'};
options_.heterogeneity.steady_state_variable_name = 'initial_guess';
options_.heterogeneity.time_iteration.solver_stop_on_error = true;
oo_.heterogeneity = struct;
[oo_.heterogeneity, M_.params] = heterogeneity.compute_steady_state(M_, options_.heterogeneity, oo_.heterogeneity);
if ~isfield(options_.heterogeneity,'solve')
    options_.heterogeneity.solve = struct();
end
options_.heterogeneity.solve.truncation_horizon = 300;
oo_.heterogeneity.dr = heterogeneity.solve(M_, options_.heterogeneity.solve, oo_.heterogeneity);
options_.periods = 1000;
var_list_ = {};
[oo_, options_] = heterogeneity.simulate(M_, options_, oo_, var_list_);


oo_.time = toc(tic0);
disp(['Total computing time : ' dynsec2hms(oo_.time) ]);
if ~exist([M_.dname filesep 'Output'],'dir')
    mkdir(M_.dname,'Output');
end
save([M_.dname filesep 'Output' filesep 'hank_one_asset_steady_state_results.mat'], 'oo_', 'M_', 'options_');
if exist('estim_params_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'hank_one_asset_steady_state_results.mat'], 'estim_params_', '-append');
end
if exist('dataset_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'hank_one_asset_steady_state_results.mat'], 'dataset_', '-append');
end
if exist('estimation_info', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'hank_one_asset_steady_state_results.mat'], 'estimation_info', '-append');
end
if exist('dataset_info', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'hank_one_asset_steady_state_results.mat'], 'dataset_info', '-append');
end
if exist('oo_recursive_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'hank_one_asset_steady_state_results.mat'], 'oo_recursive_', '-append');
end
if exist('options_mom_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'hank_one_asset_steady_state_results.mat'], 'options_mom_', '-append');
end
if ~isempty(lastwarn)
  disp('Note: warning(s) encountered in MATLAB/Octave code')
end
