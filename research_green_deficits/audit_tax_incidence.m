% AUDIT_TAX_INCIDENCE  Referee audit of the tax-incidence primitives (Blocks
% A-G). The measured negative direct covariance term (-0.07 per unit revenue,
% against a full stationary tilt response of +3.71) means the paper's positive
% tax semi-elasticity is a distributional-equilibrium object, not a direct
% saving response. This driver audits that finding before anything more is
% claimed:
%
%   A  step-size sweep of the tilt identity (central differences): the
%      additivity residual must fall with h for the identity to be local-exact;
%      the finite-change residual is reported as an interaction term, not error.
%   B  exact decomposition of the tilt response into policy-flow +
%      distribution-stock terms (identity: dS = int[b1'-b0']dOmega0 +
%      int b1'[dOmega1-dOmega0]); reconstruction residual ~ solver tolerance;
%      the covariance term of part (e) is the first-order approximation of the
%      policy-flow term, and their gap is reported.
%   C  dynamic partial-equilibrium path: unexpected permanent tilt from the
%      baseline stationary distribution, distribution iterated forward under
%      the new policy; horizons 0,1,2,5,10,30,inf. Tests dS_0 < 0 < dS_inf
%      (short-run/long-run sign reversal).
%   D  dense borrowing-limit map (13 points), BOTH fixed-beta and
%      recalibrated-beta, with constrained/near-constrained mass, min
%      consumption, finite-difference stability, equilibrium price, eps_S.
%   E  proportional-levy semi-elasticity across the same primitive sweeps as
%      the lump-sum map, plus the instrument difference.
%   F  sufficient-statistic validation: predicted d ln P = -eta_g/(1+eps_S)
%      vs the actually solved equilibrium price response, per instrument.
%   G  numerical audit: na in {250,500,1000} for the baseline semi-elasticity
%      and the covariance/distribution split; settings table.
%
% USAGE   >> audit_tax_incidence                 % full (hours at na=500)
%         >> FAST = true; audit_tax_incidence    % coarse grid, subset sweeps
%
% OUTPUT  output/audit_tax_incidence.mat, output/tables/audit_tax_incidence.txt
%
% STATUS: audit driver; no number is asserted in the paper until this has run.

clearvars -except FAST; close all; clc;
rng(20260720, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg0 = setup_params_green();
if FAST, pg0.na = pg0.fast.na; end
pg0 = rebuild_grid_local(pg0);
if ~isfolder(pg0.tabdir), mkdir(pg0.tabdir); end

% calibrated medium column (same conventions as decompose_tax_elasticity)
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
Gg_cal = 0.02 * (pg0.Bnom / 1.10);
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), pg0.beta = L.RCAL.beta_star; end
    if isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal'),   Gg_cal = L.RCAL.Gg_cal;       end
end
pg0.climate_version = 1;
pg0.D0 = 0.06;
r_cal  = (1 + pg0.i_ss)/(1 + pg0.mu) - 1;
P0n    = pg0.Bnom / 1.10;                 % no-program normalization price
tau0   = r_cal * pg0.Bnom / P0n;
g0     = Gg_cal / P0n;
D0     = pg0.D0;

AU = struct();  % results container
sf  = fullfile(pg0.tabdir, 'audit_tax_incidence.txt');
fid = fopen(sf, 'w');
assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee_local(fid, varargin{:});
tee('TAX-INCIDENCE AUDIT. na=%d, D0=%.2f, r=%.4f, beta=%.4f, FAST=%d\n\n', ...
    pg0.na, D0, r_cal, pg0.beta, FAST);

% =====================================================================
% BLOCK A -- step-size sweep of the tilt identity (central differences)
% =====================================================================
tee('===== BLOCK A: step-size and identity validation =====\n');
tee('%-9s %12s %12s %12s %14s %12s %12s\n', 'h', 'eps_ls', 'eps_levy', ...
    'eps_tilt', 'levy+tilt', 'abs_resid', 'rel_resid');
h_list = [1e-2 5e-3 1e-3 5e-4 1e-4 5e-5];
if FAST, h_list = [1e-2 1e-3 1e-4]; end
Acell = cell(numel(h_list), 1);
parfor ih = 1:numel(h_list)                          % independent h's
    h  = h_list(ih);
    R  = h*(1-D0);                                   % common revenue unit
    e_ls = (clnS(r_cal, tau0+R, D0, pg0, 0) - clnS(r_cal, tau0-R, D0, pg0, 0))/(2*R);
    e_lv = (clnS(r_cal, tau0, D0, pg0, +h) - clnS(r_cal, tau0, D0, pg0, -h))/(2*R);
    e_tl = (clnS(r_cal, tau0+R, D0, pg0, -h) - clnS(r_cal, tau0-R, D0, pg0, +h))/(2*R);
    resid = e_ls - (e_lv + e_tl);
    Acell{ih} = struct('h',h,'eps_ls',e_ls,'eps_levy',e_lv,'eps_tilt',e_tl, ...
                       'resid',resid,'rel',abs(resid)/max(abs(e_ls),eps));
end
A = [Acell{:}];
for ih = 1:numel(A)
    tee('%-9.1e %12.4f %12.4f %12.4f %14.4f %12.2e %12.2e\n', A(ih).h, ...
        A(ih).eps_ls, A(ih).eps_levy, A(ih).eps_tilt, ...
        A(ih).eps_levy+A(ih).eps_tilt, A(ih).resid, A(ih).rel);
end
AU.blockA = A;
tee(['Reading: if abs_resid falls with h, the identity is local-exact and\n' ...
     'the finite-change residual at h=1e-2 is a NONLINEAR INTERACTION term\n' ...
     '(Shapley-style), not numerical error. If it does not fall, the\n' ...
     'finite-difference step interacts with the grid; rerun at higher na.\n\n']);

% =====================================================================
% BLOCK B -- exact decomposition of the tilt response
% =====================================================================
tee('===== BLOCK B: exact decomposition (tilt experiment, dv=0.01) =====\n');
dv  = 0.01; rev = dv*(1-D0);
[S0, o0] = S_green_v(r_cal, tau0, D0, pg0, 0);
pgT = pg0; pgT.vartheta = -dv;
[S1, o1] = S_green(r_cal, tau0+rev, D0, pgT);
b0p = o0.polA; b1p = o1.polA;
w0  = o0.dist; w1  = o1.dist;
dS_pol  = sum(sum((b1p - b0p) .* w0));           % policy flow at fixed dist
dS_dist = sum(sum(b1p .* (w1 - w0)));            % distribution stock shift
dS_rec  = dS_pol + dS_dist;
dS_act  = S1 - S0;
% invariance check: stock vs aggregated chosen assets
inv0 = S0 - sum(sum(b0p .* w0));  inv1 = S1 - sum(sum(b1p .* w1));
% first-order covariance approximation of the policy term (part (e) object)
hh = 1e-3;
[~, obh] = S_green_v(r_cal, tau0 - hh, D0, pg0, 0);
mb   = (obh.polA - b0p)/hh;
yeff = o0.eGrid_eff(:); wy = sum(w0,1)'; ybar = wy'*yeff;
dynet = dv*(yeff - ybar);
dS_cov = sum((mb * diag(dynet)) .* w0, 'all');
tee('total equilibrium response        dS = %+.6f  (dlnS/rev = %+.4f)\n', dS_act, (log(S1)-log(S0))/rev);
tee('  direct policy-flow term            = %+.6f  (per rev %+.4f)\n', dS_pol, dS_pol/(S0*rev));
tee('  covariance (1st-order) approx      = %+.6f  (per rev %+.4f)\n', dS_cov, dS_cov/(S0*rev));
tee('  policy-vs-covariance gap           = %+.6f   [nonlinearity of b''(y)]\n', dS_pol - dS_cov);
tee('  stationary distribution term       = %+.6f  (per rev %+.4f)\n', dS_dist, dS_dist/(S0*rev));
tee('  price-level feedback               = 0 (r fixed; taxes exogenous in the experiment)\n');
tee('  return/tax feedback                = 0 (by design of the experiment)\n');
tee('reconstructed total                  = %+.6f\n', dS_rec);
tee('reconstruction residual              = %+.2e  (target < 1e-6 abs / 1e-4 rel)\n', dS_act - dS_rec);
tee('invariance residuals (S - int b'' dOmega): base %+.2e, tilt %+.2e\n\n', inv0, inv1);
AU.blockB = struct('dS_act',dS_act,'dS_pol',dS_pol,'dS_dist',dS_dist, ...
    'dS_cov',dS_cov,'recon_resid',dS_act-dS_rec,'inv0',inv0,'inv1',inv1, ...
    'per_rev', struct('total',(log(S1)-log(S0))/rev, 'pol',dS_pol/(S0*rev), ...
                      'cov',dS_cov/(S0*rev), 'dist',dS_dist/(S0*rev)));

% =====================================================================
% BLOCK C -- dynamic partial-equilibrium response to the permanent tilt
% =====================================================================
tee('===== BLOCK C: dynamic PE path (unexpected permanent tilt) =====\n');
tee(['(distribution iterated forward under the post-reform policy at fixed r;\n' ...
     ' the implied price is the static clearing counterfactual B/S_t, NOT the\n' ...
     ' perfect-foresight announcement path)\n']);
hor = [0 1 2 5 10 30];
tee('%-9s %12s %12s %12s %12s %12s %12s\n', 'horizon', 'total dS_t', ...
    'policy', 'dist-to-t', 'constr mass', 'leaving', 'P_t/P_0-1');
Om  = w0; Sser = nan(1, max(hor)+1);
% one-period outflow from the constraint under the new policy
leave0 = sum(w0(1,:) .* (b1p(1,:) > pg0.aGrid(1) + 1e-12));
C = struct('h',{},'dS',{},'pol',{},'dist',{},'cmass',{},'leave',{},'dP',{});
for t = 0:max(hor)
    St = sum(sum(b1p .* Om));                    % end-of-period-t chosen assets
    Sser(t+1) = St;
    if any(t == hor)
        dSt   = St - S0;
        dP    = (S0/St) - 1;                     % B/S_t vs B/S_0, fixed r
        distt = sum(sum(b1p .* (Om - w0)));
        cm    = sum(Om(1,:));
        lv    = sum(Om(1,:) .* (b1p(1,:) > pg0.aGrid(1) + 1e-12));
        C(end+1) = struct('h',t,'dS',dSt,'pol',dS_pol,'dist',distt, ...
                          'cmass',cm,'leave',lv,'dP',dP); %#ok<SAGROW>
        tee('%-9d %+12.6f %+12.6f %+12.6f %12.4f %12.4f %+12.4f\n', ...
            t, dSt, dS_pol, distt, cm, lv, dP);
    end
    Om = dist_forward_local(Om, b1p, o1.Pi_eff, pg0.aGrid);
end
dSinf = S1 - S0;
tee('%-9s %+12.6f %+12.6f %+12.6f %12.4f %12s %+12.4f\n', 'inf', ...
    dSinf, dS_pol, dS_dist, sum(w1(1,:)), '--', (S0/S1)-1);
tee('impact leaving-constraint mass (period 1 flow): %.4f\n', leave0);
if C(1).dS < 0 && dSinf > 0
    tee(['SIGN REVERSAL CONFIRMED: dS_0 < 0 < dS_inf. The financing\n' ...
         'instrument''s short-run and long-run effects on nominal-liability\n' ...
         'demand have OPPOSITE signs; the endogenous wealth distribution\n' ...
         'eventually dominates the direct household response.\n\n']);
elseif C(1).dS >= 0
    tee('No short-run sign reversal: impact dS_0 >= 0.\n\n');
end
AU.blockC = C; AU.blockC_Sser = Sser; AU.blockC_dSinf = dSinf;

% =====================================================================
% BLOCK D -- dense borrowing-limit map, fixed and recalibrated beta
% =====================================================================
tee('===== BLOCK D: dense borrowing-limit map =====\n');
abars = [0 0.1 0.25 0.5 0.75 0.9 1.0 1.1 1.25 1.5 1.75 2.0 2.25];
if FAST, abars = [0 0.5 0.9 1.0 1.1 1.5 2.0]; end
hD = 1e-3;
Dm = struct('abar',{},'mode',{},'beta',{},'S0',{},'cmass',{},'nearc',{}, ...
            'cmin',{},'eps_ls',{},'eps_levy',{},'fd_stab',{},'Peq',{}, ...
            'epsS',{},'onePlusEpsS',{},'resid',{},'status',{});
mname = {'fixed-beta','recal-beta'};
ncfg = 2*numel(abars);
Drows = cell(ncfg, 1);
parfor ic = 1:ncfg                                % independent (mode, abar)
    mode = 1 + (ic > numel(abars));
    k = ic - (mode-1)*numel(abars);
    pg = pg0; pg.abar = abars(k); pg = rebuild_grid_local(pg);
    status = 'ok'; row = [];
    if mode == 2
        try
            [bstar, cout] = calibrate_beta(pg, r_cal, 1.10, D0);
            pg.beta = bstar;
            if ~cout.converged, status = 'beta-edge'; end
        catch
            status = 'beta-fail';
        end
    end
    [Sb, ob] = S_green_v(r_cal, tau0, D0, pg, 0);
    if isfinite(Sb)
        wgt   = ob.dist;
        cmass = sum(wgt(1,:));
        arange = pg.aGrid(end) - pg.aGrid(1);
        nearc = sum(sum(wgt(pg.aGrid <= pg.aGrid(1) + 0.05*arange, :)));
        cmin  = min(ob.polC(1,:));
        e1  = ctau(r_cal, tau0, hD,   D0, pg);
        e2  = ctau(r_cal, tau0, hD/2, D0, pg);
        fdstab = abs(e1 - e2)/max(abs(e1), eps);
        elv = clevy(r_cal, tau0, 1e-3, D0, pg);
        try
            [Peq, epsS, rs] = solve_P_and_epsS(r_cal, D0, pg, 0);
        catch
            Peq = NaN; epsS = NaN; rs = NaN; status = [status '/P-fail'];
        end
        row = struct('abar',abars(k),'mode',mname{mode},'beta',pg.beta, ...
            'S0',Sb,'cmass',cmass,'nearc',nearc,'cmin',cmin,'eps_ls',e1, ...
            'eps_levy',elv,'fd_stab',fdstab,'Peq',Peq,'epsS',epsS, ...
            'onePlusEpsS',1+epsS,'resid',rs,'status',status);
    else
        row = struct('abar',abars(k),'mode',mname{mode},'beta',pg.beta, ...
            'S0',NaN,'cmass',NaN,'nearc',NaN,'cmin',NaN,'eps_ls',NaN, ...
            'eps_levy',NaN,'fd_stab',NaN,'Peq',NaN,'epsS',NaN, ...
            'onePlusEpsS',NaN,'resid',NaN,'status','infeasible');
    end
    Drows{ic} = row;
end
Dm = [Drows{:}];
for mode = 1:2
    tee('\n-- %s --\n', mname{mode});
    tee('%-6s %-8s %9s %8s %8s %9s %9s %9s %9s %8s %9s %9s %-8s\n', ...
        'abar','beta','S0','cmass','nearc','c_min','eps_ls','eps_levy', ...
        'fd_stab','P_eq','eps_S','1+eps_S','status');
    for k = 1:numel(abars)
        r = Drows{k + (mode-1)*numel(abars)};
        tee('%-6.2f %-8.4f %9.4f %8.4f %8.4f %9.4f %+9.3f %+9.3f %9.1e %8.4f %+9.3f %9.3f %-8s\n', ...
            r.abar, r.beta, r.S0, r.cmass, r.nearc, r.cmin, r.eps_ls, ...
            r.eps_levy, r.fd_stab, r.Peq, r.epsS, r.onePlusEpsS, r.status);
    end
end
AU.blockD = Dm;
tee(['\nReading: attribute the non-monotonicity to borrowing capacity ONLY if\n' ...
     'it appears in BOTH rows; in the fixed-beta row the debt target moves\n' ...
     'with abar, so that sweep confounds borrowing capacity with leverage.\n' ...
     'Flag any point with fd_stab > 1e-2 or |1+eps_S| < 0.1 (near-singular\n' ...
     'denominator) before quoting its elasticity.\n\n']);

% =====================================================================
% BLOCK E -- levy semi-elasticity across the same primitive sweeps
% =====================================================================
tee('===== BLOCK E: instrument map, lump-sum vs levy across primitives =====\n');
tee('%-28s %10s %12s %12s %12s\n', 'primitive', 'value', 'eps_ls', 'eps_levy', 'difference');
sw1 = struct('name','borrowing limit abar', 'vals', [0 0.5 1.0 2.0]);
sw2 = struct('name','income-risk sig_eps',  'vals', [0.15 0.20 0.25]);
sw3 = struct('name','CRRA sigma',           'vals', [1.5 2.0 3.0]);
sw4 = struct('name','discount beta',        'vals', pg0.beta*[0.97 1.00 1.03]);
% flatten sweep points into an independent work list
plist = {};
sw_defs = {sw1, sw2, sw3, sw4};
if FAST, sw_defs = {sw1}; end
for s = 1:numel(sw_defs)
    for k = 1:numel(sw_defs{s}.vals)
        plist{end+1} = struct('s',s,'name',sw_defs{s}.name,'val',sw_defs{s}.vals(k)); %#ok<SAGROW>
    end
end
Ecell = cell(numel(plist), 1);
parfor ip = 1:numel(plist)
    q = plist{ip}; v = q.val;
    pg = pg0;
    switch q.s
        case 1, pg.abar = v; pg = rebuild_grid_local(pg);
        case 2, pg.sig_eps = v; pg.sig_eps0 = v; pg.phi_D = 0;
                [eG,PiD,stD] = make_income_process(pg);
                pg.eGrid = eG; pg.Pi = PiD; pg.stationary_e = stD;
        case 3, pg.sigma = v;
        case 4, pg.beta = v;
    end
    e_ls = ctau(r_cal, tau0, 1e-3, D0, pg);
    e_lv = clevy(r_cal, tau0, 1e-3, D0, pg);
    Ecell{ip} = struct('sweep',q.name,'val',v,'eps_ls',e_ls, ...
                       'eps_levy',e_lv,'diff',e_ls - e_lv);
end
sweepE = Ecell;
for ip = 1:numel(sweepE)
    e = sweepE{ip};
    tee('%-28s %10.3f %+12.3f %+12.3f %+12.3f\n', e.sweep, e.val, ...
        e.eps_ls, e.eps_levy, e.diff);
end
AU.blockE = sweepE;
tee(['Reading: the paper''s claim is the instrument DIFFERENCE\n' ...
     'd lnS/d tau_ls - d lnS/d vartheta > 0, not the lump-sum sign alone;\n' ...
     'check whether the difference stays positive where eps_ls flips.\n\n']);

% =====================================================================
% BLOCK F -- sufficient-statistic validation per instrument
% =====================================================================
tee('===== BLOCK F: price-response formula vs solved equilibrium =====\n');
tee(['(fixed damages D0 on both sides of each comparison, so the test is\n' ...
     ' internally consistent; the regimes table additionally endogenizes\n' ...
     ' D(P) via the climate block, which this validation deliberately mutes)\n']);
tee('%-14s %9s %9s %9s %12s %12s %10s %9s\n', 'instrument', 'eta_g', ...
    'eps_S', '1+eps_S', 'pred dlnP', 'act dlnP', 'abs err', 'rel err');
% instrument maps (identical to main_project_regimes)
inst = {};
inst{1} = struct('name','lump-sum',   'tls', @(P,g) r_cal*pg0.Bnom./P + g, 'vth', @(P,g,D) 0*P);
inst{2} = struct('name','levy',       'tls', @(P,g) r_cal*pg0.Bnom./P,     'vth', @(P,g,D) g./(1-D));
inst{3} = struct('name','levy+rebate','tls', @(P,g) r_cal*pg0.Bnom./P - g, 'vth', @(P,g,D) 2*g./(1-D));
cases = {struct('tag','', 'pg', pg0)};
if ~FAST
    pgA = pg0; pgA.abar = 2.0; pgA = rebuild_grid_local(pgA);
    pgI = pg0; pgI.psi_inc = 1.0;
    cases{end+1} = struct('tag',' [abar=2]',    'pg', pgA);
    cases{end+1} = struct('tag',' [psi_inc=1]', 'pg', pgI);
end
% flatten (case, instrument) into an independent work list
wl = {};
for c = 1:numel(cases)
    for ii = 1:numel(inst)
        wl{end+1} = struct('pg',cases{c}.pg,'tag',cases{c}.tag,'inst',inst{ii}); %#ok<SAGROW>
    end
end
Fcell = cell(numel(wl), 1);
parfor iw = 1:numel(wl)
    w = wl{iw}; pg = w.pg;
    try
        [P0e, epsS0, ~] = solve_P_and_epsS(r_cal, D0, pg, 0);
        gP  = @(P) Gg_cal ./ P;
        tls = @(P) w.inst.tls(P, gP(P));
        vth = @(P) w.inst.vth(P, gP(P), D0);
        P1e = solve_P_instrument(r_cal, D0, pg, tls, vth, P0e);
        act = log(P1e/P0e);
        pgv = pg; pgv.vartheta = vth(P0e);
        S_on  = S_green(r_cal, tls(P0e), D0, pgv);
        S_off = S_green(r_cal, r_cal*pg0.Bnom/P0e, D0, pg);
        gg0   = gP(P0e);
        eta   = (log(S_on) - log(S_off)) / gg0;
        pred  = -eta*gg0 / (1 + epsS0);
        Fcell{iw} = struct('name',[w.inst.name w.tag],'eta',eta, ...
            'epsS',epsS0,'pred',pred,'act',act,'abserr',abs(pred-act), ...
            'relerr',abs(pred-act)/max(abs(act),eps),'err','');
    catch ME
        Fcell{iw} = struct('name',[w.inst.name w.tag],'eta',NaN,'epsS',NaN, ...
            'pred',NaN,'act',NaN,'abserr',NaN,'relerr',NaN,'err',ME.message);
    end
end
Fv = Fcell;
for iw = 1:numel(Fv)
    r = Fv{iw};
    if isempty(r.err)
        tee('%-14s %+9.3f %+9.3f %9.3f %+12.4f %+12.4f %10.2e %9.2e\n', ...
            r.name, r.eta, r.epsS, 1+r.epsS, r.pred, r.act, r.abserr, r.relerr);
    else
        tee('%-14s FAILED: %s\n', r.name, r.err);
    end
end
AU.blockF = Fv;
tee(['Reading: the formula is local; expect agreement to first order in the\n' ...
     'program scale. Large errors flag either a small/changing denominator\n' ...
     '(quote 1+eps_S) or strong nonlinearity over the program step.\n\n']);

% =====================================================================
% BLOCK G -- numerical audit across grids
% =====================================================================
tee('===== BLOCK G: grid audit =====\n');
nas = [250 500 1000];
if FAST, nas = [150 250]; end
tee('%-8s %12s %12s %12s %10s\n', 'na', 'eps_tau', 'cov/rev', 'dist/rev', 'runtime(s)');
Gcell = cell(numel(nas), 1);
parfor k = 1:numel(nas)                              % independent grids
    tg = tic;
    pg = pg0; pg.na = nas(k); pg = rebuild_grid_local(pg);
    et = ctau(r_cal, tau0, 1e-2, D0, pg);
    [Sg0, og0] = S_green_v(r_cal, tau0, D0, pg, 0);
    pgT2 = pg; pgT2.vartheta = -dv;
    [Sg1, og1] = S_green(r_cal, tau0+rev, D0, pgT2); %#ok<ASGLU>
    dpol  = sum(sum((og1.polA - og0.polA) .* og0.dist)) / (Sg0*rev);
    ddist = sum(sum(og1.polA .* (og1.dist - og0.dist))) / (Sg0*rev);
    Gcell{k} = struct('na',nas(k),'eps_tau',et,'cov',dpol,'dist',ddist,'rt',toc(tg));
end
Gv = [Gcell{:}];
for k = 1:numel(Gv)
    tee('%-8d %+12.4f %+12.4f %+12.4f %10.1f\n', Gv(k).na, Gv(k).eps_tau, ...
        Gv(k).cov, Gv(k).dist, Gv(k).rt);
end
if numel(Gv) >= 2
    rel = abs(Gv(end).eps_tau - Gv(end-1).eps_tau)/abs(Gv(end-1).eps_tau);
    tee('relative change of eps_tau between last two grids: %.2e (target < 1e-2)\n', rel);
end
tee('\nSETTINGS: na=%d, ne=%d, hh-solver tol=%g, dist tol=%g, elapsed %.1f s\n', ...
    pg0.na, numel(pg0.eGrid), pg0.tol_vfi, pg0.tol_dist, toc(t0));
AU.blockG = Gv;

save(fullfile(projdir,'output','audit_tax_incidence.mat'), 'AU');
fclose(fid);
fprintf('[audit_tax_incidence] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
% local functions
% =========================================================================
function pg = rebuild_grid_local(pg)
    u = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
end

function tee_local(fid, varargin)
    fprintf(varargin{:});
    fprintf(fid, varargin{:});
end

function [S, o] = S_green_v(r, tau, D, pg, vth)
    pg.vartheta = vth;
    [S, o] = S_green(r, tau, D, pg);
end

function v = clnS(r, tau, D, pg, vth)
    S = S_green_v(r, tau, D, pg, vth);
    v = log(S);
end

function e = ctau(r, tau0, h, D, pg)
% central per-revenue lump-sum semi-elasticity (revenue unit h*(1-D))
    R = h*(1-D);
    e = (clnS(r, tau0+R, D, pg, 0) - clnS(r, tau0-R, D, pg, 0)) / (2*R);
end

function e = clevy(r, tau0, h, D, pg)
% central per-revenue levy semi-elasticity
    R = h*(1-D);
    e = (clnS(r, tau0, D, pg, +h) - clnS(r, tau0, D, pg, -h)) / (2*R);
end

function Om = dist_forward_local(Om, polA, Pi, aGrid)
% one-period forward iteration of the (na x ne) distribution under policy
% polA (chosen a', grid values) and income transition Pi, Young lottery.
    [na, ne] = size(Om);
    Om2 = zeros(na, ne);
    for je = 1:ne
        col = Om(:, je);
        if ~any(col), continue; end
        ap = polA(:, je);
        % lottery weights onto the asset grid
        idx = discretize(ap, aGrid);            % lower node
        idx(~isfinite(idx)) = na - 1;
        idx = min(max(idx, 1), na - 1);
        whi = (ap - aGrid(idx)) ./ (aGrid(idx+1) - aGrid(idx));
        whi = min(max(whi, 0), 1);
        lot = zeros(na, 1);
        for ia = 1:na
            if col(ia) == 0, continue; end
            lot(idx(ia))   = lot(idx(ia))   + col(ia)*(1 - whi(ia));
            lot(idx(ia)+1) = lot(idx(ia)+1) + col(ia)*whi(ia);
        end
        Om2 = Om2 + lot * Pi(je, :);
    end
    Om = Om2;
end

function [Peq, epsS, resid] = solve_P_and_epsS(r, D, pg, gfix)
% no-program stationary equilibrium price: Phi(P) = S(r, r*B/P + gfix/P) - B/P
    B = pg.Bnom;
    Phi = @(P) S_green_v(r, r*B./P + gfix./P, D, pg, 0) - B./P;
    Peq = bisect_local(Phi, 0.5*B/1.10, 2.0*B/1.10);
    resid = Phi(Peq);
    dlp = 0.01;
    Sp = S_green_v(r, r*B/(Peq*(1+dlp)) + gfix/(Peq*(1+dlp)), D, pg, 0);
    Sm = S_green_v(r, r*B/(Peq*(1-dlp)) + gfix/(Peq*(1-dlp)), D, pg, 0);
    epsS = (log(Sp) - log(Sm)) / (2*dlp);
end

function Peq = solve_P_instrument(r, D, pg, tls, vth, Pguess)
% program equilibrium under instrument maps tau_ls(P), vartheta(P)
    Peq = bisect_local(@(P) phi_instrument(P, r, D, pg, tls, vth), ...
                       0.6*Pguess, 1.6*Pguess);
end

function phi = phi_instrument(P, r, D, pg, tls, vth)
    pgl = pg; pgl.vartheta = vth(P);
    S = S_green(r, tls(P), D, pgl);
    if isfinite(S), phi = S - pg.Bnom/P; else, phi = NaN; end
end

function x = bisect_local(f, lo, hi)
% robust bracketing bisection with coarse scan
    xs = linspace(lo, hi, 9);
    fs = arrayfun(f, xs);
    k = find(isfinite(fs(1:end-1)) & isfinite(fs(2:end)) & ...
             sign(fs(1:end-1)) ~= sign(fs(2:end)), 1, 'first');
    assert(~isempty(k), 'bisect_local: no sign change on [%g, %g]', lo, hi);
    a = xs(k); b = xs(k+1); fa = fs(k);
    for it = 1:60
        m = 0.5*(a+b); fm = f(m);
        if ~isfinite(fm) || abs(b-a) < 1e-10, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    x = 0.5*(a+b);
end
