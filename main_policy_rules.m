% MAIN_POLICY_RULES  Nominal and real tax rules.
%   * Nominal tax rule  T = w1 i B + w2 B  =>  1+pi = (1-w1) i + (1-w2).
%     Demonstrates the special cases w1=1, w1<1, w1>1.
%   * Real tax rule  tau = tau* + gamma(r b - tau*)  =>  1+pi = 1+i - (P/B) tau*.
%     Solves S(r(P)) = B/P for P; reports unique vs multiple roots (Figure 3).
% Paper: policy-rules section, Figure 3.

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
% Gross debt growth is 1+pi = (1-w1) i + (1-w2). To target ~2% baseline debt
% growth when w1=1 we need (1-w2)=1.02, i.e. a small NEGATIVE w2 (net transfer).
omega2 = -0.02;
cases_w1 = [1.0, 0.5, 1.5];
nomtab = cell(numel(cases_w1),1);
for c = 1:numel(cases_w1)
    w1 = cases_w1(c);
    [ssn, outn] = solve_nominal_tax_rule(params, w1, omega2, i_ss, Bnom);
    fprintf('  w1=%.2f: pi_ss=%+.4f r_ss=%.4f P*=%s  [%s]\n', ...
        w1, ssn.pi_ss, ssn.r_ss, num2str(ssn.Pstar,'%.4f'), outn.special_case);
    nomtab{c} = ssn;
end
RES.policy.nominal = nomtab;

% Comparative static: dP/di under different omega1 (illustrative)
fprintf('  (w1<1 raises inflation with i; w1>1 lowers it; w1=1 decouples.)\n');

% =====================================================================
% Real tax rule: unique vs multiple roots
% =====================================================================
fprintf('\n--- Real tax rule  tau = tau* + gamma(r b - tau*) ---\n');

% Case A: tau*=0 => inflation independent of P => unique root.
[rootsA, outA] = solve_real_tax_rule(params, 0.0, 0.5, i_ss, Bnom);
outA.roots = rootsA;
fprintf('  Case A (tau*=0.00): %s\n', outA.msg);

% Case B: tau*>0 => inflation depends on P => possible multiplicity.
tau_star_B = 0.02;
[rootsB, outB] = solve_real_tax_rule(params, tau_star_B, 0.5, i_ss, Bnom);
outB.roots = rootsB;
fprintf('  Case B (tau*=%.2f): %s\n', tau_star_B, outB.msg);

RES.policy.real_unique = outA;
RES.policy.real_multi  = outB;

% Figure 3
fh3 = plot_real_tax_rule(outA, outB, params);
fprintf('  [saved] Figure3_real_tax_rule.{fig,png,pdf}\n');
