% MAIN_EXTENSIONS_MONEY_CAPITAL_G  Model extensions:
%   * Capital:  K^* pinned by F_K+1-delta=1+r; P* = B/(S - K^*).
%   * Money:    money in utility; M endogenous when CB sets i; asset market
%               (not money market) pins P.
%   * Nominal G: nominal government expenditure determines P (Figure 4).
% Paper: extensions section, Figure 4.

if ~exist('params','var') || isempty(params)
    addpath(genpath('src'));
    params = setup_params();
end
if ~exist('RES','var'), RES = struct(); end

fprintf('\n########## EXTENSIONS: capital / money / nominal-G ##########\n');

% ---- capital ----
fprintf('\n--- Capital extension ---\n');
capout = solve_capital_extension(params);
fprintf('  %s\n', capout.msg);
RES.ext.capital = capout;

% ---- money ----
fprintf('\n--- Money extension ---\n');
monout = solve_money_extension(params);
RES.ext.money = monout;

% ---- nominal government expenditure ----
fprintf('\n--- Nominal government expenditure extension ---\n');
gout = solve_nominal_G_extension(params);
RES.ext.nominalG = gout;

% Figure 4
fh4 = plot_nominal_G(gout, params);
fprintf('  [saved] Figure4_nominal_G.{fig,png,pdf}\n');
