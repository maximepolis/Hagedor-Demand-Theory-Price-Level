% MAIN_IDENTIFICATION_LEDGER  The parameter-identification ledger and the
% untargeted-moment validation table demanded by referee report R12,
% Major Comment 2, items 1-3:
%
%   (1) a table linking EVERY parameter of the preferred model to an
%       external target or to an explicit statement that it has none;
%   (2) a count of free parameters against targeted moments, so the order
%       condition of the calibration is visible rather than implied;
%   (3) untargeted validation moments for liquid wealth, illiquid wealth,
%       direct and indirect public-debt ownership, adjustment frequency,
%       convenience yields, asset returns, wealth mobility and the
%       wealthy-hand-to-mouth share.
%
% WHY THIS DRIVER SOLVES NOTHING. It is deliberately READ-ONLY over the
% stored outputs of the calibration drivers. A ledger that recomputed the
% economy would be reporting a fresh solve, not an audit of the calibration
% the paper actually uses; and the entire point of the exercise is to state
% what the SHIPPED calibration targets and what it leaves free. It therefore
% runs in seconds and can be re-run after any calibration pass to see what
% moved. Every number it prints is read from a .mat written by the driver
% named beside it, with that file's modification date stamped, so a stale
% input announces itself instead of quietly propagating.
%
% THE DATA COLUMN IS INTENTIONALLY EMPTY. Section C carries NaN slots with
% the source that must be transcribed into each one. This follows the rule
% established for main_validation_mobility: no number enters a validation
% table from memory. An empty slot is honest; a wrong decimal in a
% validation table is worse than no table at all. Fill DATA below, re-run,
% and the driver reports gaps and flags the ones outside their band.
%
% WHAT IT REPORTS WITHOUT DATA. Some verdicts do not need an external
% number because they are STRUCTURAL: a moment that is identically zero in
% the model fails against any positive data value, and a calibration whose
% count of internally solved parameters exceeds its count of targeted
% moments is under-identified whatever the moments turn out to be. Those
% are printed in section D as verdicts, not as slots.
%
% TWO-ASSET ROWS ARE STAMPED UNCERTIFIED. The two-asset block has not
% cleared Gate 11 (grid-induced uncertainty in the financing response,
% normalised by that response, below 0.10). Its moments are reported here
% because the identification question is separate from the discretization
% question -- a parameter with no external target has no external target at
% any grid resolution -- but no row from that block may be quoted as a
% validated model moment while the stamp says UNCERTIFIED.
%
% USAGE   >> clear; main_identification_ledger
% OUTPUT  output/tables/identification_ledger.txt
%         output/identification_ledger.mat

clearvars; close all; clc;
t0 = tic;

thisfile = mfilename('fullpath');
projdir = fileparts(thisfile);
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

% =====================================================================
% DATA SLOTS -- transcribe from the cited source, then re-run.
% Each field is the external counterpart of a model moment in section C.
% BAND is the absolute gap beyond which the driver flags the moment.
% =====================================================================
DATA = struct();
% [SCF] Survey of Consumer Finances, household balance sheets. Use a
%       financial-wealth (liquid) definition for the first and a total
%       net-worth definition for the second; record which vintage.
DATA.liquid_wealth_inc    = NaN;   % liquid assets / annual income
DATA.total_wealth_inc     = NaN;   % net worth / annual income
DATA.top10_share          = NaN;   % top-10 pct net-worth share
% [FA]  Financial Accounts of the United States, table L.210 (Treasury
%       securities) split by holder sector: households and nonprofits
%       directly, versus funds/insurance/pensions/foreign/central bank.
DATA.direct_debt_share    = NaN;   % household DIRECT share of public debt
% [KV]  Kaplan & Violante, "A Model of the Consumption Response to Fiscal
%       Stimulus Payments", ECMA 2014: illiquid-account adjustment
%       frequency. Report as the mean spell in years between adjustments.
DATA.adjust_spell_years   = NaN;
% [KVW] Kaplan, Violante & Weidner, "The Wealthy Hand-to-Mouth", BPEA
%       2014(1): population shares of hand-to-mouth and wealthy HtM.
DATA.htm_share            = NaN;
DATA.whtm_share           = NaN;
% [KVJ] Krishnamurthy & Vissing-Jorgensen, "The Aggregate Demand for
%       Treasury Debt", JPE 2012: convenience yield in percentage points,
%       and the supply elasticity d(spread)/d(log debt/GDP).
DATA.convenience_pp       = NaN;
DATA.convenience_elast_pp = NaN;
% Real returns, annual, matched to the model's frequency. Cite the series.
DATA.real_safe_rate       = NaN;
DATA.equity_premium       = NaN;

BAND = struct('liquid_wealth_inc', 0.25, 'total_wealth_inc', 1.00, ...
              'top10_share', 0.10, 'direct_debt_share', 0.10, ...
              'adjust_spell_years', 2.00, 'htm_share', 0.10, ...
              'whtm_share', 0.07, 'convenience_pp', 0.75, ...
              'convenience_elast_pp', 0.55, 'real_safe_rate', 0.01, ...
              'equity_premium', 0.02);

% =====================================================================
% Load the shipped calibrations. Nothing is solved here.
% =====================================================================
f_cal = fullfile(projdir, 'output', 'calibrated_results.mat');
f_kv  = fullfile(projdir, 'output', 'twoasset_ownership_kv.mat');
f_fit = fullfile(projdir, 'output', 'wealth_fit_results.mat');
f_kvj = fullfile(projdir, 'output', 'convenience_kvj.mat');

srcspec = { 'one-asset calibration',  f_cal, 'main_project_calibrated'; ...
            'two-asset ownership+KV', f_kv,  'main_twoasset_ownership_kv'; ...
            'superstar wealth fit',   f_fit, 'wealth_concentration_fit'; ...
            'convenience curvature',  f_kvj, 'calibrate_convenience_kvj' };
SRC = struct('name', {}, 'file', {}, 'driver', {}, 'found', {}, 'stamp', {});
for i = 1:size(srcspec, 1)
    fn = srcspec{i, 2};
    ok = exist(fn, 'file') == 2;
    if ok
        dd = dir(fn); st = datestr(dd.datenum, 'yyyy-mm-dd HH:MM');
    else
        st = 'MISSING';
    end
    SRC(end+1) = struct('name', srcspec{i,1}, 'file', fn, ...
                        'driver', srcspec{i,3}, 'found', ok, 'stamp', st); %#ok<SAGROW>
end

pg = setup_params_green();
CAL = []; KV = []; FITW = []; KVJ = [];
if exist(f_cal, 'file') == 2, CAL  = load(f_cal);  end
if exist(f_kv,  'file') == 2, KV   = load(f_kv);   end
if exist(f_fit, 'file') == 2, FITW = load(f_fit);  end
if exist(f_kvj, 'file') == 2, KVJ  = load(f_kvj);  end

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf  = fullfile(pg.tabdir, 'identification_ledger.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});

tee('PARAMETER-IDENTIFICATION LEDGER (referee R12, Major 2, items 1-3)\n');
tee('pipeline %s\n', kv_code_version(thisfile));
tee('read-only over stored calibrations; nothing is solved here.\n\n');
tee('%-24s %-9s %-18s %s\n', 'source', 'state', 'file stamp', 'written by');
for i = 1:numel(SRC)
    if SRC(i).found, st = 'loaded'; else, st = 'MISSING'; end
    tee('%-24s %-9s %-18s %s\n', SRC(i).name, st, SRC(i).stamp, SRC(i).driver);
end
if any(~[SRC.found])
    tee('\n*** at least one calibration is MISSING. Rows that depend on it\n');
    tee('*** print as "-" rather than as a number; run the named driver.\n');
end

% IS THE TWO-ASSET INPUT A FAST ARTIFACT? A FAST run of the ownership driver
% writes to the SAME output file as the benchmark, so a shakeout or a FAST
% parity run can leave a coarse-grid economy sitting where the benchmark
% should be. Nothing in the file says so; the grid sizes do. The production
% grid is nb=60, nk=34, nx=150 (main_twoasset_ownership_kv); FAST is
% 40 / 22 / 100. Report the sizes always and shout when they are short.
if ~isempty(KV) && isfield(KV, 'p')
    nb_in = local_len(KV.p, 'bGrid');
    nk_in = local_len(KV.p, 'kGrid');
    nx_in = local_len(KV.p, 'xGridA');
    tee('\ntwo-asset input grid: nb=%d nk=%d nx=%d', nb_in, nk_in, nx_in);
    if nb_in < 60 || nk_in < 34 || nx_in < 150
        tee('   *** BELOW PRODUCTION (60/34/150)\n');
        tee('*** The two-asset .mat looks like a FAST artifact. Every model\n');
        tee('*** value in section C is then a coarse-grid number and none of\n');
        tee('*** it may be quoted. Re-run main_twoasset_ownership_kv WITHOUT\n');
        tee('*** FAST, then re-run this ledger.\n');
    else
        tee('   (production sizes)\n');
    end
end
tee('\n');

% =====================================================================
% SECTION A -- the parameter ledger
% =====================================================================
% CLASS legend, and the reason the distinction is the whole exercise:
%   NORM  a normalization. Carries no economic content; a different value
%         rescales units and nothing else.
%   EXT   set from an external estimate or a convention with a citable
%         source. Not re-estimated here.
%   CAL   solved for internally so the model reproduces a stated target
%         moment. Consumes one degree of freedom AND one moment.
%   DECL  chosen by the authors with NO external target. This is the class
%         the referee is asking about. It is not a criticism to have such
%         parameters; it is a criticism to leave them unlabelled.
%   NUM   discretization or tolerance. Affects accuracy, not the economy --
%         which is precisely the claim Gate 11 exists to test, and which
%         the two-asset block has not yet established.

beta_one = NaN;
if ~isempty(CAL) && isfield(CAL, 'RCAL') && isfield(CAL.RCAL, 'beta_star')
    beta_one = CAL.RCAL.beta_star;
end
r_ss = (1 + pg.i_ss)/(1 + pg.mu) - 1;

kvp = []; kveq = []; kvH = []; iota_H = NaN; d_base = NaN; Kbar = 1.0;
if ~isempty(KV)
    if isfield(KV, 'p'),      kvp    = KV.p;      end
    if isfield(KV, 'eq0'),    kveq   = KV.eq0;    end
    if isfield(KV, 'H'),      kvH    = KV.H;      end
    if isfield(KV, 'iota_H'), iota_H = KV.iota_H; end
    if isfield(KV, 'd_base'), d_base = KV.d_base; end
end
ssm = NaN; ssi = NaN; sso = NaN; top1_targ = NaN;
if ~isempty(KV) && isfield(KV, 'ss')
    ssm = local_get(KV.ss, 'mult');
    ssi = local_get(KV.ss, 'p_in');
    sso = local_get(KV.ss, 'p_out');
end
if ~isempty(FITW) && isfield(FITW, 'TOP1_TARGET'), top1_targ = FITW.TOP1_TARGET; end

% block | parameter | value | class | target moment | source / note
rows = { ...
 'household', 'sigma (CRRA)',            pg.sigma,        'EXT',  '-', ...
   'conventional; not re-estimated here'; ...
 'household', 'beta (one-asset)',        beta_one,        'CAL',  'debt / income = 1.10', ...
   'calibrate_beta'; ...
 'household', 'abar (borrowing limit)',  pg.abar,         'NORM', '-', ...
   'zero-borrowing normalization'; ...
 'household', 'rho (income AR1)',        pg.rho,          'EXT',  '-', ...
   'standard annual persistence; replicator benchmark'; ...
 'household', 'sig_eps',                 pg.sig_eps,      'EXT',  '-', ...
   'standard annual innovation s.d.; replicator benchmark'; ...
 'household', 'ne (income states)',      pg.ne,           'NUM',  '-', ...
   'Rouwenhorst discretization'; ...
 'household', 'E[e]',                    1.0,             'NORM', '-', ...
   'mean endowment normalization'; ...
 'policy',    'Bnom',                    pg.Bnom,         'NORM', '-', ...
   'nominal debt normalization'; ...
 'policy',    'i_ss',                    pg.i_ss,         'EXT',  '-', ...
   'nominal rate; policy choice'; ...
 'policy',    'mu = pi_ss',              pg.mu,           'EXT',  '-', ...
   'nominal growth equals inflation'; ...
 'policy',    'r_ss (implied)',          r_ss,            'NORM', '-', ...
   'Fisher identity; not free'; ...
 'policy',    'Gg / income',             0.02,            'DECL', '-', ...
   'program size: an experiment scale, not an estimate'; ...
 'climate',   'D0 (damages)',            pg.D0,           'EXT',  '-', ...
   'swept 0.02 / 0.06 / 0.20 = DICE / DJO-BHM / Bilal-Kaenzig'; ...
 'climate',   'theta_g (abatement)',     pg.theta_g,      'DECL', '-', ...
   'ILLUSTRATIVE; no external target. Swept in theta_sweep'; ...
 'climate',   'delta_g',                 pg.delta_g,      'DECL', '-', ...
   'ILLUSTRATIVE green-capital depreciation'; ...
 'climate',   'phi_D (risk channel)',    pg.phi_D,        'DECL', '-', ...
   'ILLUSTRATIVE; 0 switches the channel off'; ...
 'climate',   'psi_inc (incidence)',     pg.psi_inc,      'DECL', '-', ...
   'default 0 = uniform damages; swept in the extended runs'; ...
 'climate',   'scale_floor',             pg.scale_floor,  'DECL', '-', ...
   'economic bound on the damage share; prevents an unbounded tail'; ...
 'two-asset', 'lambda_adj',              local_get(kvp, 'lambda_adj'), 'EXT', '-', ...
   'adjustment frequency; KV 2014 counterpart in section C'; ...
 'two-asset', 'zeta_b (conv. curvature)', local_get(kvp, 'zeta_b'), 'EXT', ...
   'KVJ demand-curve elasticity', 'dln(spr)/dln(b) ~ -zeta; see verdict V3'; ...
 'two-asset', 'chi_b (conv. level)',     local_get(kvp, 'chi_b'), 'CAL', ...
   'S_b = 0.30 in the FRICTIONLESS economy', 'transplanted; see verdict V6'; ...
 'two-asset', 'beta (two-asset)',        local_get(kvp, 'beta'), 'CAL', ...
   'S_b = 0.30 in the KV economy', 'calib_beta on the KV household'; ...
 'two-asset', 'bbar_liq (Stone-Geary)',  local_get(kvp, 'bbar_liq'), 'DECL', '-', ...
   'NO external target. Set so v-prime(0) is finite; see verdict V2'; ...
 'two-asset', 'div_payout phi',          local_get(kvp, 'div_payout'), 'DECL', '-', ...
   'NO external target. R12 names it quantitatively decisive'; ...
 'two-asset', 'iota_H',                  iota_H,          'NORM', '-', ...
   'algebraic: 0.30 / 1.10. NOT a free parameter, NOT a second moment'; ...
 'two-asset', 'd (tree dividend)',       d_base,          'NORM', '-', ...
   'tree normalization'; ...
 'two-asset', 'Kbar',                    Kbar,            'NORM', '-', ...
   'tree supply normalization'; ...
 'superstar', 'mult',                    ssm,             'CAL', ...
   'top-1 pct wealth share', 'grid search; see verdict V1'; ...
 'superstar', 'p_in',                    ssi,             'CAL', ...
   'top-1 pct wealth share', 'grid search over the SAME single moment'; ...
 'superstar', 'p_out',                   sso,             'DECL', '-', ...
   'HELD FIXED in the fit; no external target' };

LED = struct('block', rows(:,1), 'name', rows(:,2), 'value', rows(:,3), ...
             'class', rows(:,4), 'target', rows(:,5), 'source', rows(:,6));

tee('===== A. PARAMETER LEDGER =====\n');
tee('CLASS: NORM normalization | EXT external/cited | CAL calibrated to a\n');
tee('target | DECL declared, NO external target | NUM discretization\n\n');
tee('%-11s %-27s %11s  %-5s %-32s %s\n', ...
    'block', 'parameter', 'value', 'class', 'target moment', 'source / note');
tee('%s\n', repmat('-', 1, 140));
cur = '';
for i = 1:numel(LED)
    if ~strcmp(LED(i).block, cur)
        cur = LED(i).block;
        if strcmp(cur, 'two-asset')
            tee('%s\n', repmat('.', 1, 140));
            tee('  [UNCERTIFIED BLOCK -- has not cleared Gate 11; see section D]\n');
        end
    end
    tee('%-11s %-27s %11s  %-5s %-32s %s\n', LED(i).block, LED(i).name, ...
        local_num(LED(i).value), LED(i).class, LED(i).target, LED(i).source);
end
tee('\n');

% =====================================================================
% SECTION B -- counts and the order condition
% =====================================================================
cls    = {LED.class};
blk    = {LED.block};
is_two = strcmp(blk, 'two-asset') | strcmp(blk, 'superstar');

n_norm_one = sum(strcmp(cls, 'NORM') & ~is_two);
n_ext_one  = sum(strcmp(cls, 'EXT')  & ~is_two);
n_cal_one  = sum(strcmp(cls, 'CAL')  & ~is_two);
n_decl_one = sum(strcmp(cls, 'DECL') & ~is_two);
n_norm_two = sum(strcmp(cls, 'NORM') &  is_two);
n_ext_two  = sum(strcmp(cls, 'EXT')  &  is_two);
n_cal_two  = sum(strcmp(cls, 'CAL')  &  is_two);
n_decl_two = sum(strcmp(cls, 'DECL') &  is_two);

% Targeted moments, counted as DISTINCT moments rather than as instruments.
% Counting instruments would make every calibration look exactly identified
% by construction, which is the error the referee is guarding against.
% Note what is NOT on the two-asset list. iota_H is an algebraic consequence
% of 0.30 and 1.10 and adds no information; beta and chi are both aimed at
% S_b = 0.30, so that moment is counted ONCE even though two instruments
% chase it. Counting it twice would manufacture an exactly-identified
% calibration out of a redundancy.
mom_one = {'debt / income = 1.10'};
mom_two = {'direct liquid holding S_b = 0.30', 'top-1 pct wealth share'};

tee('===== B. COUNTS AND THE ORDER CONDITION =====\n\n');
tee('%-36s %10s %10s\n', '', 'one-asset', 'two-asset');
tee('%-36s %10d %10d\n', 'normalizations (NORM)',       n_norm_one, n_norm_two);
tee('%-36s %10d %10d\n', 'externally set (EXT)',        n_ext_one,  n_ext_two);
tee('%-36s %10d %10d\n', 'internally calibrated (CAL)', n_cal_one,  n_cal_two);
tee('%-36s %10d %10d\n', 'declared, NO target (DECL)',  n_decl_one, n_decl_two);
tee('%-36s %10d %10d\n', 'targeted moments', numel(mom_one), numel(mom_two));
tee('\n');
tee('The two-asset column counts only what that block ADDS: the household,\n');
tee('policy and climate blocks are shared, so the preferred-model totals are\n');
tee('the sums. CAL %d, DECL %d, targeted moments %d.\n\n', ...
    n_cal_one + n_cal_two, n_decl_one + n_decl_two, ...
    numel(mom_one) + numel(mom_two));
tee('targeted moments, one-asset:\n');
for i = 1:numel(mom_one), tee('  %s\n', mom_one{i}); end
tee('targeted moments added by the two-asset block:\n');
for i = 1:numel(mom_two), tee('  %s\n', mom_two{i}); end
tee('\n');

ncal_tot = n_cal_one + n_cal_two;
nmom_tot = numel(mom_one) + numel(mom_two);
if ncal_tot > nmom_tot
    tee('ORDER CONDITION: FAILS. %d internally solved parameters against %d\n', ...
        ncal_tot, nmom_tot);
    tee('targeted moments. The calibration is UNDER-IDENTIFIED: a family of\n');
    tee('parameter vectors reproduces the same targets, and which point on it\n');
    tee('the driver selects is a property of the search, not of the data.\n');
    tee('Verdict V1 names where the slack sits.\n');
elseif ncal_tot == nmom_tot
    tee('ORDER CONDITION: exactly identified (%d = %d). This is necessary,\n', ...
        ncal_tot, nmom_tot);
    tee('not sufficient: it says nothing about whether the mapping from\n');
    tee('parameters to moments is locally invertible.\n');
else
    tee('ORDER CONDITION: over-identified (%d parameters, %d moments). The\n', ...
        ncal_tot, nmom_tot);
    tee('surplus moments are a testable restriction and should be reported.\n');
end
tee('\n');

% =====================================================================
% SECTION C -- untargeted validation moments
% =====================================================================
% Every row here is a moment the calibration did NOT target, except the two
% marked TARGETED, which are listed so the table is a complete census of the
% moments the paper could be held to rather than a selection of them. A
% model that reproduces its own targets tells you the solver works; these
% tell you whether the economy resembles the one the paper is about.
Sb  = local_get(kveq, 'Sb');
qq  = local_get(kveq, 'q');
r_b = NaN; if ~isempty(KV) && isfield(KV, 'r_b'), r_b = KV.r_b; end
ill = NaN; W_tot = NaN; spr = NaN; tree_yield = NaN;
if isfinite(Sb) && isfinite(qq)
    ill   = qq * Kbar;
    W_tot = Sb + ill;
end
if isfinite(qq) && isfinite(d_base)
    tree_yield = d_base / qq;
    if isfinite(r_b)
        spr = 100 * ((qq + d_base)/qq - (1 + r_b));   % percentage points
    end
end
lam = local_get(kvp, 'lambda_adj');
adj_spell = NaN; if isfinite(lam) && lam > 0, adj_spell = 1/lam; end
kvj_el = NaN;
if ~isempty(KVJ) && isfield(KVJ, 'kvj_logel'), kvj_el = KVJ.kvj_logel; end

% key | label | model value | note
mrows = { ...
 'liquid_wealth_inc',   'liquid wealth / income',          Sb, ...
   'TARGETED (S_b = 0.30) -- census row, not a validation'; ...
 'total_wealth_inc',    'total wealth / income',           W_tot, ...
   'untargeted under the one-instrument calibration'; ...
 'illiquid_wealth_inc', 'illiquid wealth / income',        ill, ...
   'untargeted; equals q x Kbar'; ...
 'top10_share',         'top-10 pct wealth share',         local_get(kvH, 'top10'), ...
   'untargeted; only the top-1 pct share is targeted'; ...
 'top1_share',          'top-1 pct wealth share',          local_get(kvH, 'top1'), ...
   'TARGETED via the superstar fit -- census row'; ...
 'direct_debt_share',   'household DIRECT share of debt',  iota_H, ...
   'TARGETED by construction (0.30 / 1.10) -- census row'; ...
 'indirect_debt_share', 'INDIRECT share of debt',          1 - iota_H, ...
   'implied residual; the intermediated slice'; ...
 'adjust_spell_years',  'mean years between adjustments',  adj_spell, ...
   'SET, not calibrated: 1 / lambda_adj'; ...
 'htm_share',           'hand-to-mouth share',             local_get(kvH, 'htm'), ...
   'untargeted'; ...
 'whtm_share',          'WEALTHY hand-to-mouth share',     local_get(kvH, 'whtm'), ...
   'untargeted; see verdict V2'; ...
 'convenience_pp',      'convenience yield (pp)',          spr, ...
   'equity-bond spread (q+d)/q - (1+r_b); untargeted'; ...
 'convenience_elast_pp','convenience supply elasticity',   kvj_el, ...
   'from calibrate_convenience_kvj; read its GE-ratio caveat first'; ...
 'real_safe_rate',      'real safe rate',                  r_b, ...
   'implied by the Fisher identity at i and mu; not free'; ...
 'equity_premium',      'tree yield d/q minus r_b',        tree_yield - r_b, ...
   'untargeted' };

MOM = struct('key', mrows(:,1), 'label', mrows(:,2), 'model', mrows(:,3), ...
             'note', mrows(:,4));

tee('===== C. UNTARGETED VALIDATION MOMENTS =====\n');
tee('Every model value below comes from the two-asset block, which is\n');
tee('UNCERTIFIED. Data slots are NaN until transcribed from the cited\n');
tee('source; an empty slot reports PENDING and never a pass.\n\n');
tee('%-33s %10s %10s %10s %8s  %s\n', 'moment', 'model', 'data', 'gap', ...
    'verdict', 'note');
tee('%s\n', repmat('-', 1, 140));
nflag = 0; npend = 0; npass = 0; nomodel = 0;
for i = 1:numel(MOM)
    k = MOM(i).key;
    dv = NaN; bd = NaN;
    if isfield(DATA, k), dv = DATA.(k); end
    if isfield(BAND, k), bd = BAND.(k); end
    gap = MOM(i).model - dv;
    if ~isfinite(MOM(i).model)
        vd = 'NO MODEL'; nomodel = nomodel + 1;
    elseif ~isfinite(dv)
        vd = 'PENDING';  npend = npend + 1;
    elseif isfinite(bd) && abs(gap) <= bd
        vd = 'ok';       npass = npass + 1;
    else
        vd = 'FLAG';     nflag = nflag + 1;
    end
    tee('%-33s %10s %10s %10s %8s  %s\n', MOM(i).label, ...
        local_num(MOM(i).model), local_num(dv), local_num(gap), vd, MOM(i).note);
end
tee('\n%d ok, %d flagged, %d pending transcription, %d with no model value.\n\n', ...
    npass, nflag, npend, nomodel);
tee('Wealth-mobility moments are NOT duplicated here. main_validation_mobility\n');
tee('computes them with its own data slots and four definition-robust\n');
tee('stylized-fact gates; this ledger points at that table rather than\n');
tee('restating it, so there is exactly one place to fill in.\n\n');

% =====================================================================
% SECTION D -- structural verdicts that need no external number
% =====================================================================
tee('===== D. STRUCTURAL VERDICTS =====\n\n');

tee('V1  THE SUPERSTAR STATE IS UNDER-IDENTIFIED.\n');
tee('    wealth_concentration_fit searches (mult, p_in) over a 3 x 3 grid\n');
tee('    with p_out held fixed at %s and selects the cell whose top-1 pct\n', ...
    local_num(sso));
tee('    share is closest to a SINGLE target (%s). Two free parameters\n', ...
    local_num(top1_targ));
tee('    against one moment: a one-dimensional family of (mult, p_in)\n');
tee('    reproduces any given top-1 pct share, so the selected point is\n');
tee('    determined by the grid rather than by the data. A second\n');
tee('    concentration moment -- the top-10 pct share or the wealth Gini,\n');
tee('    both already computed by that driver -- would close the gap at no\n');
tee('    additional computational cost. That is the cheapest identification\n');
tee('    improvement available anywhere in this ledger.\n');
if ~isempty(FITW) && isfield(FITW, 'IDENT') && isstruct(FITW.IDENT)
    ID = FITW.IDENT;
    tee('    MEASURED, from that driver rather than argued here:\n');
    tee('      %d configs solved; %d tie on the top-1 pct target within %s.\n', ...
        ID.n_ok, ID.n_ties, local_num(ID.top1_band));
    if ID.n_ties >= 2
        tee('      among the ties, the top-10 pct share spans %s and the\n', ...
            local_num(ID.top10_spread));
        tee('      gini spans %s.\n', local_num(ID.gini_spread));
        if ID.underidentified
            tee('      => UNDER-IDENTIFIED as arithmetic, not as opinion.\n');
        else
            tee('      => the ties agree on the untargeted moments, so the\n');
            tee('         single moment is locally sufficient ON THIS GRID.\n');
        end
    end
    if isfield(ID, 'rule'), tee('      selection rule in force: %s\n', ID.rule); end
else
    tee('    The measured version of this verdict requires a re-run of\n');
    tee('    wealth_concentration_fit, which now emits the diagnostic.\n');
end
tee('\n');

whtm = local_get(kvH, 'whtm');
tee('V2  THE WEALTHY-HAND-TO-MOUTH SHARE IS A STRUCTURAL ZERO.\n');
tee('    Model value: %s.\n', local_num(whtm));
tee('    This does not need a data slot in order to fail. With phi = 1 the\n');
tee('    whole dividend d*k arrives as LIQUID income, so a household rich in\n');
tee('    the tree never runs its liquid buffer down, at any beta, lambda or\n');
tee('    bbar. The share is zero BY CONSTRUCTION rather than by calibration,\n');
tee('    and any positive external value therefore rejects it. The two\n');
tee('    parameters governing this margin -- phi and bbar_liq -- are exactly\n');
tee('    the two carrying the DECL class in the two-asset block. That is not\n');
tee('    a coincidence: the margin the model cannot reproduce is governed by\n');
tee('    the parameters nothing external pins down.\n\n');

tee('V3  ZETA IS DISCIPLINED AT THE EDGE OF ITS RANGE, NOT AT ITS CENTRE.\n');
tee('    The KVJ mapping dln(spr)/dln(b) ~ -zeta puts the point estimate\n');
tee('    near zeta = 1 and the range near [0.55, 2.05]. The benchmark uses\n');
tee('    zeta = %s: inside the range, at its steep edge. The paper should\n', ...
    local_num(local_get(kvp, 'zeta_b')));
tee('    therefore report the ZETA = 1.0 rerun alongside the benchmark, not\n');
tee('    instead of it, and say which it prefers and why.\n\n');

tee('V4  THE CLIMATE BLOCK IS ENTIRELY DECLARED.\n');
tee('    Only D0 is tied to an external source, and then only as a\n');
tee('    three-point sweep across damage literatures; theta_g, delta_g,\n');
tee('    phi_D, psi_inc and scale_floor have no external target at all.\n');
tee('    Every abatement-effectiveness statement is conditional on theta_g,\n');
tee('    which is why the damage-dividend term should be read as an\n');
tee('    elasticity with respect to a declared parameter rather than as a\n');
tee('    measured magnitude.\n\n');

tee('V5  IDENTIFICATION AND DISCRETIZATION ARE SEPARATE FAILURES.\n');
tee('    Section B measures the first; Gate 11 measures the second. Passing\n');
tee('    Gate 11 would not add a single external target, and a parameter\n');
tee('    with no external target has no external target at any resolution.\n');
tee('    Neither result can be used to excuse the other.\n\n');

tee('V6  CHI IS CALIBRATED IN A DIFFERENT ECONOMY FROM THE ONE IT IS USED IN.\n');
tee('    chi_b is fitted in main_twoasset_ownership -- the FRICTIONLESS\n');
tee('    companion, lambda = 1 -- to S_b = 0.30, and then transplanted into\n');
tee('    the infrequent-adjustment economy, where beta is refitted to the\n');
tee('    same moment. Two instruments therefore chase ONE target across two\n');
tee('    economies. The transplant is defensible -- the driver states the\n');
tee('    reason, that the friction roughly doubles precautionary wealth and\n');
tee('    puts the level out of chi''s reach -- but it is a modelling choice,\n');
tee('    not an identification, and section B counts the moment once.\n');
tee('    The WTARGET option adds total wealth as a second moment and makes\n');
tee('    the pair (beta, chi) genuinely two-instrument; it is not what the\n');
tee('    shipped benchmark runs, and the paper should say which it reports.\n\n');

R = struct('LED', LED, 'MOM', MOM, 'DATA', DATA, 'BAND', BAND, 'SRC', SRC, ...
           'n_cal', ncal_tot, 'n_mom', nmom_tot, 'n_flag', nflag, ...
           'n_pending', npend, 'n_ok', npass, 'n_nomodel', nomodel);
save(fullfile(projdir, 'output', 'identification_ledger.mat'), 'R');
fclose(fid);
fprintf('[main_identification_ledger] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function v = local_get(s, f)
% Read a field if the struct and the field both exist; NaN otherwise, so a
% missing input file degrades to an empty cell instead of an error. A ledger
% that refuses to print at all when one calibration is stale is a ledger
% nobody runs.
    v = NaN;
    if ~isempty(s) && isstruct(s) && isfield(s, f)
        x = s.(f);
        if isnumeric(x) && isscalar(x), v = double(x); end
    end
end

function n = local_len(s, f)
% Length of a grid field, 0 when absent, so the FAST guard degrades to a
% loud "below production" rather than to an error on an older .mat.
    n = 0;
    if ~isempty(s) && isstruct(s) && isfield(s, f) && isnumeric(s.(f))
        n = numel(s.(f));
    end
end

function s = local_num(v)
% One numeric format for the whole table, with NaN printed as a dash so an
% empty slot is visually distinct from a zero. A zero that reads as missing
% is precisely how the WHtM structural zero could be overlooked.
    if ~isnumeric(v) || ~isscalar(v) || ~isfinite(v)
        s = '-';
    elseif v ~= 0 && abs(v) < 1e-3
        s = sprintf('%.2e', v);
    else
        s = sprintf('%.4f', v);
    end
end
