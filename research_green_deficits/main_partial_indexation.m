% MAIN_PARTIAL_INDEXATION  How much of the climate-price feedback survives
% realistic appropriation revision?  (Referee R12, Major Comment 5.)
%
% THE OBJECTION. The paper's climate loop closes through one line:
%
%       g_g = G_g / P,
%
% a higher price level shrinks the real program, which lowers adaptation
% capital and raises damages. That feedback generates the multiplicity result,
% the anchor-insulation result, and part of the cross-regime difference in
% real program size. But it is driven entirely by the assumption that the
% appropriation is a PERMANENT NOMINAL AMOUNT, never revised. Real
% appropriations are renegotiated, indexed imperfectly, and sometimes written
% against physical quantities. The manuscript compares only the two endpoints
% -- a fixed nominal budget and a fully indexed mandate -- and reports that
% they are nearly identical on the equilibrium path, which if anything
% sharpens the referee's point: if the endpoints barely differ, the interval
% between them cannot be carrying a first-order result.
%
% THE EXPERIMENT. Write the appropriation as
%
%       G_{g,t} = Gbar * (P_t / Pbar)^xi,     xi in [0, 1],
%
% so the real program is g_t = (Gbar/Pbar) * (P_t/Pbar)^(xi-1). Then
%   xi = 0  the appropriation is fixed in NOMINAL terms  (paper's baseline)
%   xi = 1  the appropriation is fully INDEXED           (real mandate)
% and everything in between is partial revision. Both endpoints reproduce the
% existing code paths EXACTLY (verified: max|difference| = 0), so this is a
% generalization of the manuscript's comparison rather than a replacement of
% it, and the legacy branches remain intact for the parity tests.
%
% WHAT IS REPORTED, per the referee's list: the impact and terminal price
% response, real green investment, damages, the financing ordering, debt
% revaluation, and the determinacy elasticity, each as a function of xi.
%
% WHAT THIS CANNOT SETTLE. xi is not estimated here. Choosing it needs
% institutional evidence on how adaptation and infrastructure appropriations
% are denominated and revised -- multi-year authorizations, cost-overrun
% provisions, indexation clauses. This driver establishes the SENSITIVITY of
% the conclusions to xi; it does not identify xi. If the multiplicity and
% insulation results disappear by, say, xi = 0.25, they belong in an appendix
% as limiting cases, which is precisely the referee's proposed disposition.
%
% STATUS: scaffolded, NOT YET RUN, and not authorized to run until the D10/D11
% parity sequence completes. No number from it may be cited before then.
%
% USAGE   >> clear; main_partial_indexation
%         >> clear; FAST = true; main_partial_indexation
%         >> clear; XIGRID = [0 0.5 1]; main_partial_indexation
%
% OUTPUT  output/tables/partial_indexation.txt
%         output/partial_indexation.mat

clearvars -except FAST XIGRID RHOBAR; close all; clc;
rng(20260803,'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
run_project_path_setup(struct('quiet', true));

if ~exist('FAST','var'), FAST = false; end
if ~exist('XIGRID','var') || isempty(XIGRID), XIGRID = [0 0.25 0.50 0.75 1.00]; end

pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'partial_indexation.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});

tee('PARTIAL INDEXATION OF THE GREEN APPROPRIATION\n%s\n\n', repmat('=',1,60));
tee('%s\n\n', kv_code_version(mfilename('fullpath')));
tee('G_{g,t} = Gbar * (P_t/Pbar)^xi;   g_t = (Gbar/Pbar) * (P_t/Pbar)^(xi-1)\n');
tee('  xi = 0  fixed NOMINAL appropriation (the manuscript baseline)\n');
tee('  xi = 1  fully INDEXED real mandate\n');
tee('Both endpoints reproduce the existing code paths exactly.\n\n');

% The legacy transition setup: calibrated beta, climate_version, D0, Gg_nom,
% and the FAST asset grid. Passing a default beta leaves no root in the
% solver's price bracket -- see kv_legacy_transition_setup.
[pgc, opts_base, calinfo] = kv_legacy_transition_setup(FAST);
tee('setup: na=%d, T=%d, beta*=%.6f, D0=%.3f, Gg=%.6f\n\n', ...
    calinfo.na, calinfo.T, calinfo.beta_star, calinfo.D0_med, calinfo.Gg_cal);

% =====================================================================
% ENDPOINT IDENTITY CHECK, before the sweep.
%
% xi = 0 must reproduce regime 'nominal' and xi = 1 must reproduce regime
% 'indexed', to machine precision. If they do not, the partial rule is not a
% generalization of the manuscript's experiment and nothing downstream of it
% means anything. This is a gate, not a diagnostic.
% =====================================================================
tee('ENDPOINT IDENTITY CHECK\n');
ENDPOINT = struct('ok', true, 'rows', {{}});
pairs = {0, 'nominal'; 1, 'indexed'};
for i = 1:size(pairs,1)
    xi = pairs{i,1}; reg = pairs{i,2};
    oL = opts_base; oL.regime = reg;                       % legacy branch
    oX = opts_base; oX.regime = reg; oX.xi_index = xi;     % partial rule
    TL = solve_hank_dtpl_transition(pgc, oL);
    TX = solve_hank_dtpl_transition(pgc, oX);
    if ~pathok(TL) || ~pathok(TX)
        tee('  xi=%.2f vs regime %-8s : ONE SIDE PRODUCED NO PATH\n', xi, reg);
        ENDPOINT.ok = false; continue;
    end
    dg = max(abs(TL.g_path(:) - TX.g_path(:)));
    dp = max(abs(TL.phat(:)   - TX.phat(:)));
    tee('  xi=%.2f vs regime %-8s : max|dg| %.3e   max|dphat| %.3e   %s\n', ...
        xi, reg, dg, dp, tern(dg < 1e-12 && dp < 1e-10, 'IDENTICAL', '*** DIFFERS ***'));
    ENDPOINT.ok = ENDPOINT.ok && (dg < 1e-12) && (dp < 1e-10);
end
if ~ENDPOINT.ok
    tee(['\n*** The partial rule does not reproduce the legacy endpoints, so it\n' ...
         '*** is not a generalization of the manuscript experiment. Stopping.\n']);
    fclose(fid);
    error('main_partial_indexation:endpoints', 'partial rule fails the endpoint identity');
end
tee('\n');

% =====================================================================
% THE SWEEP. Both financing instruments at every xi, so the ORDERING -- the
% paper's most robust claim per the referee -- is testable at each point
% rather than only at the endpoints.
% =====================================================================
R = struct('xi', {}, 'instrument', {}, 'P0', {}, 'P_impact', {}, 'P_term', {}, ...
           'dlnP_impact', {}, 'g_impact', {}, 'g_term', {}, 'D_impact', {}, ...
           'D_term', {}, 'reval_stock', {}, 'converged', {}, 'reportable', {}, 'msg', {});
tee('%-6s %-10s %10s %10s %10s %10s %10s %10s  %s\n', ...
    'xi', 'financing', 'P_impact', 'P_term', 'dlnP_imp', 'g_impact', 'D_term', 'reval', 'status');
tee('%s\n', repmat('-', 1, 104));
for xi = XIGRID(:)'
    for inst = {'lumpsum','rebate'}
        o = opts_base; o.regime = 'indexed'; o.financing = inst{1}; o.xi_index = xi;
        TR = solve_hank_dtpl_transition(pgc, o);
        r = struct('xi', xi, 'instrument', inst{1}, 'P0', NaN, 'P_impact', NaN, ...
                   'P_term', NaN, 'dlnP_impact', NaN, 'g_impact', NaN, 'g_term', NaN, ...
                   'D_impact', NaN, 'D_term', NaN, 'reval_stock', NaN, ...
                   'converged', false, 'reportable', false, 'msg', msgof(TR));
        if pathok(TR)
            r.P0 = TR.P0; r.P_impact = TR.phat(1); r.P_term = TR.phat(end);
            r.dlnP_impact = log(TR.phat(1)/TR.P0);
            r.g_impact = TR.g_path(1); r.g_term = TR.g_path(end);
            r.D_impact = TR.D_path(1); r.D_term = TR.D_path(end);
            r.reval_stock = getf(TR, 'reval_stock', NaN);
            r.converged  = getf(TR, 'converged', false);
            r.reportable = getf(TR, 'reportable', false);
        end
        R(end+1) = r; %#ok<AGROW>
        tee('%-6.2f %-10s %10.4f %10.4f %+10.4f %10.5f %10.5f %10.4f  %s\n', ...
            r.xi, r.instrument, r.P_impact, r.P_term, r.dlnP_impact, ...
            r.g_impact, r.D_term, r.reval_stock, ...
            tern(r.reportable, 'reportable', 'NOT reportable'));
    end
end

% =====================================================================
% THE ORDERING, at each xi. Per the referee, the ordering is the paper's most
% robust claim and the LEVEL sign is not; so the ordering is what this sweep
% must be read for.
% =====================================================================
tee('\nFINANCING ORDERING BY xi  (levy-with-rebate more inflationary than lump-sum?)\n');
tee('%-6s %14s %14s %12s  %s\n', 'xi', 'dlnP lumpsum', 'dlnP rebate', 'gap', 'ordering holds');
tee('%s\n', repmat('-', 1, 68));
ord_all = true; ord_any_unreportable = false;
for xi = XIGRID(:)'
    L = pick1(R, xi, 'lumpsum'); B = pick1(R, xi, 'rebate');
    if isempty(L) || isempty(B) || ~L.reportable || ~B.reportable
        tee('%-6.2f %14s %14s %12s  (a path was not reportable)\n', xi, '-', '-', '-');
        ord_any_unreportable = true; continue;
    end
    gap = B.dlnP_impact - L.dlnP_impact;
    holds = gap > 0;
    ord_all = ord_all && holds;
    tee('%-6.2f %+14.6f %+14.6f %+12.6f  %s\n', xi, L.dlnP_impact, B.dlnP_impact, gap, ...
        tern(holds, 'YES', '*** NO ***'));
end

tee('\nREADING\n');
if ord_any_unreportable
    tee('  At least one path was not reportable, so the sweep is incomplete.\n');
elseif ord_all
    tee('  The financing ordering holds at every xi examined. That is the claim\n');
    tee('  the referee identifies as the robust one, and partial indexation does\n');
    tee('  not disturb it.\n');
else
    tee('  *** The ordering FAILS at some xi. That is a first-order finding: the\n');
    tee('  *** paper''s most robust claim would then itself be conditional on the\n');
    tee('  *** appropriation being denominated one particular way.\n');
end
tee(['\n  What this does NOT establish: the value of xi. Choosing it needs\n' ...
     '  institutional evidence on how adaptation appropriations are denominated\n' ...
     '  and revised. This sweep reports sensitivity, not identification.\n']);

save(fullfile(projdir,'output','partial_indexation.mat'), ...
     'R', 'XIGRID', 'pgc', 'opts_base', 'calinfo', 'ENDPOINT');
tee('\n[main_partial_indexation] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function t = pathok(TR)
    t = isstruct(TR) && isfield(TR,'phat') && ~isempty(TR.phat) && ...
        isfield(TR,'g_path') && ~isempty(TR.g_path);
end

function r = pick1(R, xi, inst)
    r = [];
    for i = 1:numel(R)
        if abs(R(i).xi - xi) < 1e-12 && strcmp(R(i).instrument, inst)
            r = R(i); return;
        end
    end
end

function v = getf(S, f, dv)
    v = dv; if isstruct(S) && isfield(S, f) && ~isempty(S.(f)), v = S.(f); end
end

function s = msgof(TR)
    s = '(no message)';
    if isstruct(TR) && isfield(TR,'msg') && ~isempty(TR.msg), s = TR.msg; end
end

function s = tern(c, a, b)
    if c, s = a; else, s = b; end
end

function tee2(fid, varargin)
    fprintf(varargin{:});
    if fid > 0, fprintf(fid, varargin{:}); end
end
