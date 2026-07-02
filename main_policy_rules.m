% MAIN_POLICY_RULES  Nominal and real tax rules.
%   * Nominal tax rule  T = w1 i B + w2 B  =>  1+pi = (1-w1) i + (1-w2)
%     (paper Eq. 31-33). Demonstrates the special cases w1=1, w1<1, w1>1.
%   * Real tax rule  tau = tau* + gamma(r b - tau*)  (paper Eq. 34) =>
%     1+pi = 1+i - (P/B) tau* (Eq. 38). Solves S(r(P)) = B/P for P.
%     Panel (a): tau*>0 => unique equilibrium; panel (b): tau*<0 => the
%     transformed demand curve is decreasing in P and multiplicity is possible
%     (paper Figure 3).
% Paper: Section 3.5, Figure 3.

if ~exist('params','var') || isempty(params)
    addpath(genpath('src'));
    params = setup_params();
end
if ~exist('RES','var'), RES = struct(); end

fprintf('\n########## POLICY RULES ##########\n');

% =====================================================================
% Nominal tax rule: special cases in omega1
% =====================================================================
fprintf('\n--- Nominal tax rule  T = w1 i B + w2 B ---\n');
i_ss = params.i_ss; Bnom = params.Bnom;
% Gross debt growth is 1+pi = (1-w1) i + (1-w2); a small NEGATIVE w2 (net
% transfer) yields ~3%% baseline debt growth at w1=1. The w1>1 case uses 1.25
% (not larger) so the implied real rate stays below the range where asset
% demand diverges; pushing w1 higher at this i_ss correctly returns "no
% steady state exists", which is informative but not a good figure.
omega2 = -0.03;
cases_w1 = [1.0, 0.5, 1.25];
nomtab = cell(numel(cases_w1),1);
for c = 1:numel(cases_w1)
    w1 = cases_w1(c);
    [ssn, outn] = solve_nominal_tax_rule(params, w1, omega2, i_ss, Bnom);
    fprintf('  w1=%.2f: pi_ss=%+.4f r_ss=%+.4f P*=%s  [%s]\n', ...
        w1, ssn.pi_ss, ssn.r_ss, num2str(ssn.Pstar,'%.4f'), outn.special_case);
    nomtab{c} = ssn;
end
RES.policy.nominal = nomtab;
fprintf('  (w1<1 raises inflation with i; w1>1 lowers it; w1=1 decouples.)\n');

% =====================================================================
% Real tax rule: unique (tau*>0) vs possible multiplicity (tau*<0)
% =====================================================================
fprintf('\n--- Real tax rule  tau = tau* + gamma(r b - tau*) ---\n');

% One extended-range S(1+r) interpolant shared by both cases (tau*<0 pushes
% the real rate far below the baseline sweep range as P rises).
fprintf('Building extended-range S(1+r) interpolant for real tax rules...\n');
ad_rt = asset_demand_interp(params, linspace(-0.30, params.r_max, 45));
params.ad_cache = ad_rt;

% Case A: tau* > 0 => S(r(P)) increasing in P, B/P decreasing => unique root.
tau_star_A = 0.02;
[rootsA, outA] = solve_real_tax_rule(params, tau_star_A, 0.5, i_ss, Bnom);
outA.roots = rootsA;
fprintf('  Case A (tau*=%+.2f): %s\n', tau_star_A, outA.msg);

% Case B: tau* < 0 => S(r(P)) ALSO decreasing in P => two intersections with
% B/P are possible (paper Figure 3, panel b).
tau_star_B = -0.05;
[rootsB, outB] = solve_real_tax_rule(params, tau_star_B, 0.5, i_ss, Bnom);
outB.roots = rootsB;
fprintf('  Case B (tau*=%+.2f): %s\n', tau_star_B, outB.msg);

params = rmfield(params, 'ad_cache');
RES.policy.real_unique = outA;
RES.policy.real_multi  = outB;
RES.policy.ad_rt       = ad_rt;

% Figure 3
fh3 = plot_real_tax_rule(outA, outB, params);
fprintf('  [saved] Figure3_real_tax_rule.{fig,png,pdf}\n');
