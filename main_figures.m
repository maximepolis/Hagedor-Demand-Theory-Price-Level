% MAIN_FIGURES  Generate Figures 1 and 2 (asset market; determinacy vs
% complete-markets indeterminacy). Requires the baseline steady state; if not
% present, computes it. Builds the asset-demand curve S(1+r) over a real-rate
% sweep and calls the plotting modules. Paper: Figures 1-2.

if ~exist('params','var') || isempty(params)
    addpath(genpath('src'));
    params = setup_params();
end
if ~exist('RES','var'), RES = struct(); end

fprintf('\n########## FIGURES 1-2 ##########\n');

% baseline steady state
if ~isfield(RES,'baseline')
    [ss, out] = solve_steady_state_DTPL(params, params.i_ss, params.pi_ss, params.Bnom);
    RES.baseline.ss = ss; RES.baseline.out = out;
else
    ss = RES.baseline.ss;
end

% asset-demand curve over a real-rate sweep
fprintf('Building asset-demand curve S(1+r) over %d real rates...\n', params.nr);
ad = asset_demand_interp(params);
RES.figures.ad = ad;

% local slope diagnostic (monotonicity is NOT required for determinacy)
if any(ad.converged)
    rc = ad.rgrid(ad.converged);
    slope = numerical_derivatives(ad.S_of_r, rc(2:end-1));
    fprintf('  dS/dr sign: %d of %d sampled points positive (monotone if all).\n', ...
        sum(slope > 0), numel(slope));
    RES.figures.slope = slope;
end

% complete-markets counterexample (for Fig 2b)
cm = solve_complete_markets_counterexample(params);
RES.figures.cm = cm;

% draw
fh1 = plot_asset_market(ad, ss, params);
fh2 = plot_price_level_determinacy(ad, ss, cm, params);
fprintf('  [saved] Figure1_asset_market.{fig,png,pdf}\n');
fprintf('  [saved] Figure2_determinacy.{fig,png,pdf}\n');
