function Phi_e = build_pol_phi_e(x, layout, oo_)
% build_pol_phi_e
% Rebuild the policy-grid expectation operator Phi_e given a policy x.
% Brackets the next-period state values x(state_var, :) on the policy grid for
% each state dimension, then assembles the sparse N_sp x N_sp expectation
% matrix via the Dynare MEX `compute_Phi_tilde_e`, which combines the asset
% lottery (Gray code over n_states dimensions) with the idiosyncratic shock
% transition Mu.
%
% At x = x_ss this returns exactly mat.pol.Phi_e (load_steady_state.m:144).
%
% Shared by reiter_residual.m and the sequence-space transition helpers
% (ha_coleman_residual.m / ha_backward_step.m): the household expectation
% E[g(x_{t+1})] is taken at the next-period state implied by the CURRENT asset
% choice x(state_var, :), so the lottery brackets must be rebuilt from the
% current policy rather than held at the steady-state lottery position.
%
% Inputs
% ------
% x      : H_.endo_nbr x N_sp policy on the policy grid.
% layout : output of build_state_layout(M_, oo_).
% oo_    : Dynare results struct carrying oo_.heterogeneity.
%
% Output
% ------
% Phi_e  : sparse N_sp x N_sp expectation operator.
%
% Author: Normann Rion (Dynare Team), workshop session 4 (Extensions).

    H_      = layout.H_;
    mat     = oo_.heterogeneity.mat;
    sizes   = oo_.heterogeneity.sizes;
    indices = oo_.heterogeneity.indices;
    ss      = oo_.heterogeneity.steady_state;

    n_a  = sizes.n_a;
    N_sp = sizes.N_sp;

    ind = zeros(N_sp, n_a, 'int32');
    w   = zeros(N_sp, n_a);
    for k = 1 : n_a
        state = indices.states{k};
        grid  = ss.pol.grids.(state);
        [ind_k, w_k] = find_bracket_linear_weight(grid, x(H_.state_var(k), :));
        ind(:, k) = ind_k;
        w(:, k)   = w_k;
    end

    [I_mex, J_mex, V_mex] = compute_Phi_tilde_e(ind, w, mat.pol.dims, mat.Mu);
    Phi_e = sparse(I_mex, J_mex, V_mex, N_sp, N_sp);
end
