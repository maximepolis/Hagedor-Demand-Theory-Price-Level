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
% The KVJ log-elasticity slot is filled automatically from
% calibrate_convenience_kvj's own transcription when that .mat carries it;
% see the model-side note in section C. Left here so the field always exists.
DATA.convenience_logel    = NaN;
% Real returns, annual, matched to the model's frequency. Cite the series.
DATA.real_safe_rate       = NaN;
DATA.equity_premium       = NaN;

BAND = struct('liquid_wealth_inc', 0.25, 'total_wealth_inc', 1.00, ...
              'top10_share', 0.10, 'direct_debt_share', 0.10, ...
              'adjust_spell_years', 2.00, 'htm_share', 0.10, ...
              'whtm_share', 0.07, 'convenience_pp', 0.75, ...
              'real_safe_rate', 0.01, 'equity_premium', 0.02);

% INTERVALS BEAT SYMMETRIC BANDS WHEN THE SOURCE REPORTS ONE. A band is a
% half-width around a point estimate and so is symmetric by construction; a
% published range usually is not. The KVJ log-elasticity range maps to
% roughly [-2.05, -0.55] around a point estimate of -1.03, which is not its
% midpoint. Grading the model against half that range's WIDTH reported FLAG
% for a value sitting comfortably inside the range itself -- a rejection
% manufactured by the approximation rather than by the evidence. Any key
% present here is graded against the interval and the band is ignored.
IVAL = struct();

% =====================================================================
% Load the shipped calibrations. Nothing is solved here.
% =====================================================================
f_cal = fullfile(projdir, 'output', 'calibrated_results.mat');
f_kv  = fullfile(projdir, 'output', 'twoasset_ownership_kv.mat');
f_fit = fullfile(projdir, 'output', 'wealth_fit_results.mat');
f_kvj = fullfile(projdir, 'output', 'convenience_kvj.mat');

pg = setup_params_green();
CAL = []; KV = []; FITW = []; KVJ = [];
if exist(f_cal, 'file') == 2, CAL  = load(f_cal);  end
if exist(f_kv,  'file') == 2, KV   = load(f_kv);   end
if exist(f_fit, 'file') == 2, FITW = load(f_fit);  end
if exist(f_kvj, 'file') == 2, KVJ  = load(f_kvj);  end

% A FILE THAT LOADS IS NOT THE SAME AS A FILE THAT IS CURRENT. Every driver
% here writes to a fixed path, so an .mat produced before a variable was added
% still loads cleanly and simply lacks that variable. The verdict that needs it
% then prints "NOT YET MEASURED", which reads like a finding about the economy
% when it is a finding about the extract. The fourth column below lists the
% variables a downstream verdict dereferences; a loaded file that is short of
% any of them is reported STALE in the header, next to the driver that fixes
% it, instead of only in the prose four hundred lines down.
srcspec = { 'one-asset calibration',  f_cal, 'main_project_calibrated', {'RCAL'}; ...
            'two-asset ownership+KV', f_kv,  'main_twoasset_ownership_kv', {'p','eq0','ss'}; ...
            'superstar wealth fit',   f_fit, 'wealth_concentration_fit', {'TOP1_TARGET','IDENT'}; ...
            'convenience curvature',  f_kvj, 'calibrate_convenience_kvj', {'kvj_logel'} };
loaded = {CAL, KV, FITW, KVJ};
SRC = struct('name', {}, 'file', {}, 'driver', {}, 'found', {}, 'stamp', {}, ...
             'short', {});
for i = 1:size(srcspec, 1)
    fn = srcspec{i, 2};
    ok = exist(fn, 'file') == 2;
    if ok
        dd = dir(fn); st = datestr(dd.datenum, 'yyyy-mm-dd HH:MM');
    else
        st = 'MISSING';
    end
    want = srcspec{i, 4};
    S    = loaded{i};
    shrt = {};
    if ok && ~isempty(S)
        for j = 1:numel(want)
            if ~isfield(S, want{j}), shrt{end+1} = want{j}; end %#ok<SAGROW>
        end
    end
    SRC(end+1) = struct('name', srcspec{i,1}, 'file', fn, ...
                        'driver', srcspec{i,3}, 'found', ok, 'stamp', st, ...
                        'short', {shrt}); %#ok<SAGROW>
end

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf  = fullfile(pg.tabdir, 'identification_ledger.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});

tee('PARAMETER-IDENTIFICATION LEDGER (referee R12, Major 2, items 1-3)\n');
tee('%s\n', kv_code_version(thisfile));
tee('read-only over stored calibrations; nothing is solved here.\n\n');
tee('%-24s %-9s %-18s %s\n', 'source', 'state', 'file stamp', 'written by');
n_stale = 0;
for i = 1:numel(SRC)
    if ~SRC(i).found
        st = 'MISSING';
    elseif ~isempty(SRC(i).short)
        st = 'STALE'; n_stale = n_stale + 1;
    else
        st = 'loaded';
    end
    tee('%-24s %-9s %-18s %s\n', SRC(i).name, st, SRC(i).stamp, SRC(i).driver);
    if strcmp(st, 'STALE')
        tee('%-24s %-9s missing: %s\n', '', '', strjoin(SRC(i).short, ', '));
    end
end
if any(~[SRC.found])
    tee('\n*** at least one calibration is MISSING. Rows that depend on it\n');
    tee('*** print as "-" rather than as a number; run the named driver.\n');
end
if n_stale > 0
    tee('\n*** %d calibration(s) STALE: the file loads but predates a variable\n', n_stale);
    tee('*** a verdict below needs. Those verdicts report NOT YET MEASURED,\n');
    tee('*** which is a statement about the extract and not about the model.\n');
    tee('*** Re-run the driver named on the row, then re-run this ledger:\n');
    for i = 1:numel(SRC)
        if SRC(i).found && ~isempty(SRC(i).short)
            tee('***     clear; %s\n', SRC(i).driver);
        end
    end
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
    tee('This is the A-PRIORI count. Section D asks, per block, whether the\n');
    tee('slack is real: V1 measures it for the superstar pair, V6 for the\n');
    tee('(beta, chi) pair. A count can overstate the slack; it cannot\n');
    tee('understate it, so a failing count still has to be answered.\n');
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
% CONVENIENCE-YIELD ELASTICITY. An earlier version of this file put
% KVJ.kvj_logel in the MODEL column. That variable is the KVJ *target*
% (-0.75/0.73, transcribed in calibrate_convenience_kvj), so the row was
% reporting a data quantity as a model quantity and would have compared it
% against itself the moment the data slot was filled. The model counterpart
% is the demand-curve log-elasticity implied by the liquid FOC,
%   dln(spread)/dln(b) = -zeta * b/(b + bbar),
% evaluated at the calibrated liquid position -- which is the object the KVJ
% regression coefficient is comparable to, and the one verdict V3 is about.
% The GE ratio dspr/dlnS_b computed by calibrate_convenience_kvj is NOT
% comparable; that driver says so itself and the reason is recorded there.
logel_model = NaN;
zb = local_get(kvp, 'zeta_b'); bb = local_get(kvp, 'bbar_liq');
if isfinite(zb) && isfinite(bb) && isfinite(Sb) && (Sb + bb) > 0
    logel_model = -zb * Sb / (Sb + bb);
end
% The KVJ figure is transcribed in this repository already, so it is read
% from that .mat rather than restated here. Absent (an older .mat), the slot
% stays empty like every other data slot.
kvj_data = NaN; kvj_lo = NaN; kvj_hi = NaN;
if ~isempty(KVJ)
    if isfield(KVJ, 'kvj_logel'),  kvj_data = KVJ.kvj_logel;  end
    if isfield(KVJ, 'kvj_log_lo'), kvj_lo   = KVJ.kvj_log_lo; end
    if isfield(KVJ, 'kvj_log_hi'), kvj_hi   = KVJ.kvj_log_hi; end
end
if isfinite(kvj_data), DATA.convenience_logel = kvj_data; end
if ~isfield(DATA, 'convenience_logel'), DATA.convenience_logel = NaN; end
% The same .mat that transcribes the point estimate transcribes the range.
% Use the range when it is there; fall back on the symmetric half-width only
% when it is not, and say which rule was applied.
if isfinite(kvj_lo) && isfinite(kvj_hi)
    IVAL.convenience_logel = sort([kvj_lo, kvj_hi]);
else
    BAND.convenience_logel = 0.75;   % half the KVJ log-elasticity range
end

% ONE NUMBER, NOT TWO ROWS. An earlier version of this table carried both a
% "convenience yield (pp)" row, 100*((q+d)/q - (1+r_b)), and a "tree yield
% d/q minus r_b" row keyed as the equity premium. Those are the same number:
% (q+d)/q - (1+r_b) = d/q - r_b identically. The table printed it twice under
% two names and invited the reader to grade it against two different
% literatures whose objects differ by an order of magnitude.
%
% That is not a bookkeeping slip in the ledger; it is a property of the model,
% and the manuscript states it -- the liquid FOC
%   chi_b v'(b') = u'(c) [1 - (1+r_b) q/(q+d)]
% makes the convenience yield and the tree-bond excess return the SAME object,
% because the tree is the only alternative asset and its return gap over bonds
% is entirely the liquidity wedge. So the row is collapsed to one and the
% tension is promoted to a structural verdict, V7, where it belongs. Both data
% slots are kept: the single model number is graded against each in turn, and
% the point of V7 is that it cannot satisfy both.
%
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
 'convenience_pp',      'tree-bond spread (pp)',           spr, ...
   'IS the convenience yield AND the equity premium at once; see V7'; ...
 'convenience_logel',   'demand-curve log-elasticity',     logel_model, ...
   '-zeta*b/(b+bbar) at the calibrated position; KVJ-comparable'; ...
 'real_safe_rate',      'real safe rate',                  r_b, ...
   'implied by the Fisher identity at i and mu; not free' };

MOM = struct('key', mrows(:,1), 'label', mrows(:,2), 'model', mrows(:,3), ...
             'note', mrows(:,4));

tee('===== C. UNTARGETED VALIDATION MOMENTS =====\n');
tee('Every model value below comes from the two-asset block, which is\n');
tee('UNCERTIFIED. Data slots are NaN until transcribed from the cited\n');
tee('source; an empty slot reports PENDING and never a pass.\n\n');
tee('%-33s %10s %10s %10s %8s  %s\n', 'moment', 'model', 'data', 'gap', ...
    'verdict', 'note');
tee('%s\n', repmat('-', 1, 140));
nflag = 0; npend = 0; npass = 0; nomodel = 0; ivrows = {};
for i = 1:numel(MOM)
    k = MOM(i).key;
    dv = NaN; bd = NaN; iv = [];
    if isfield(DATA, k), dv = DATA.(k); end
    if isfield(BAND, k), bd = BAND.(k); end
    if isfield(IVAL, k), iv = IVAL.(k); end
    gap = MOM(i).model - dv;
    if ~isfinite(MOM(i).model)
        vd = 'NO MODEL'; nomodel = nomodel + 1;
    elseif ~isempty(iv) && all(isfinite(iv))
        % Graded against the published range, not against a half-width. The
        % data column still shows the point estimate and the gap column the
        % distance to it, because both are worth seeing; they just do not
        % decide the verdict.
        mv = MOM(i).model;
        if mv >= iv(1) && mv <= iv(2)
            vd = 'ok';   npass = npass + 1;
        else
            vd = 'FLAG'; nflag = nflag + 1;
        end
        ivrows{end+1} = sprintf(['  %s: model %s against the published range ' ...
            '[%s, %s] -> %s\n'], MOM(i).label, local_num(mv), ...
            local_num(iv(1)), local_num(iv(2)), vd); %#ok<SAGROW>
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
tee('\n%d ok, %d flagged, %d pending transcription, %d with no model value.\n', ...
    npass, nflag, npend, nomodel);
if ~isempty(ivrows)
    tee('\nrows graded against a published RANGE rather than a symmetric band:\n');
    for i = 1:numel(ivrows), tee('%s', ivrows{i}); end
end
tee('\n');
tee('Wealth-mobility moments are NOT duplicated here. main_validation_mobility\n');
tee('computes them with its own data slots and four definition-robust\n');
tee('stylized-fact gates; this ledger points at that table rather than\n');
tee('restating it, so there is exactly one place to fill in.\n\n');

% =====================================================================
% SECTION D -- structural verdicts that need no external number
% =====================================================================
tee('===== D. STRUCTURAL VERDICTS =====\n\n');

% V1 is stated as a QUESTION and answered by the measurement, not asserted
% and then decorated with one. An earlier version of this file asserted the
% superstar block was under-identified and appended the diagnostic
% underneath; the diagnostic came back the other way. A verdict that can
% only be confirmed by its own evidence is not a verdict.
tee('V1  IS THE SUPERSTAR STATE IDENTIFIED BY ITS SINGLE MOMENT?\n');
tee('    wealth_concentration_fit searches (mult, p_in) over a 3 x 3 grid\n');
tee('    with p_out held fixed at %s and selects the cell whose top-1 pct\n', ...
    local_num(sso));
tee('    share is closest to a SINGLE target (%s). Two free parameters\n', ...
    local_num(top1_targ));
tee('    against one moment is an a-priori count, and section B counts it\n');
tee('    that way. Whether the direction is actually FLAT is a different\n');
tee('    question, and it is measurable: beta is recalibrated to the debt\n');
tee('    target inside every config, which constrains the pair, so the\n');
tee('    counting argument alone does not settle it.\n');
if ~isempty(FITW) && isfield(FITW, 'IDENT') && isstruct(FITW.IDENT)
    ID = FITW.IDENT;
    tee('    MEASURED by that driver:\n');
    tee('      %d configs solved; %d tie on the top-1 pct target within %s.\n', ...
        ID.n_ok, ID.n_ties, local_num(ID.top1_band));
    if ID.n_ties >= 2
        tee('      among the ties, the top-10 pct share spans %s and the\n', ...
            local_num(ID.top10_spread));
        tee('      gini spans %s.\n', local_num(ID.gini_spread));
        if ID.underidentified
            tee('      => UNDER-IDENTIFIED as arithmetic, not as opinion. The\n');
            tee('         tied configs disagree about an untargeted moment by\n');
            tee('         more than the tie band, so the winner is chosen by\n');
            tee('         the search grid. Transcribe TOP10_TARGET.\n');
        else
            tee('      => NOT the binding problem. The tied configs agree on\n');
            tee('         the untargeted moments to within the tie band, so on\n');
            tee('         this grid the single moment is locally sufficient and\n');
            tee('         the a-priori count OVERSTATES the slack here.\n');
            tee('         Two limits, both real: a 3 x 3 grid is coarse enough\n');
            tee('         that ties are scarce, and local sufficiency at one\n');
            tee('         point is not global identification. It does mean the\n');
            tee('         slack in section B sits elsewhere -- see V6 and V2.\n');
        end
    end
    if isfield(ID, 'rule'), tee('      selection rule in force: %s\n', ID.rule); end
else
    tee('    NOT YET MEASURED. Re-run wealth_concentration_fit, which now\n');
    tee('    emits the diagnostic; until then this verdict is a count, not\n');
    tee('    a finding.\n');
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
tee('    zeta = %s. What matters is not zeta itself but the elasticity it\n', ...
    local_num(local_get(kvp, 'zeta_b')));
tee('    implies AT the calibrated liquid position, which is damped by the\n');
tee('    Stone-Geary shift: -zeta*b/(b+bbar) = %s.\n', local_num(logel_model));
if isfinite(kvj_data)
    tee('    KVJ counterpart, as transcribed in calibrate_convenience_kvj: %s.\n', ...
        local_num(kvj_data));
    if isfinite(logel_model)
        tee('    Model minus KVJ point estimate: %s.\n', ...
            local_num(logel_model - kvj_data));
    end
else
    tee('    The KVJ counterpart is not in the stored convenience .mat --\n');
    tee('    that file predates the variable. Re-run the driver.\n');
end
% THE POINT ESTIMATE IS NOT THE EVIDENCE. KVJ report a range, and the range
% is not symmetric about the point estimate, so the distance printed above
% does not settle whether the model is consistent with the paper it cites.
% Say where the model sits in the interval and let the reader see it.
if isfinite(logel_model) && isfinite(kvj_lo) && isfinite(kvj_hi)
    iv = sort([kvj_lo, kvj_hi]);
    tee('    KVJ RANGE, from the same transcription: [%s, %s].\n', ...
        local_num(iv(1)), local_num(iv(2)));
    if logel_model >= iv(1) && logel_model <= iv(2)
        pos = (logel_model - iv(1)) / max(iv(2) - iv(1), eps);
        tee(['    The model elasticity is INSIDE that range, %.0f%% of the way\n' ...
             '    up from the elastic end. So the benchmark is not rejected by\n' ...
             '    the KVJ evidence; it is disciplined at the ELASTIC edge of it,\n' ...
             '    which is a claim about where in the range the paper sits and\n' ...
             '    not a claim that the paper is outside it. Note that the point\n' ...
             '    estimate alone, graded against half the range WIDTH, would\n' ...
             '    have called this a failure -- the range is asymmetric and the\n' ...
             '    symmetric approximation manufactures the rejection.\n'], 100*pos);
    else
        tee(['    The model elasticity is OUTSIDE that range. This is not a\n' ...
             '    matter of which summary statistic is used: no reading of the\n' ...
             '    cited evidence supports the benchmark curvature.\n']);
    end
end
tee('    Either way the paper should report the ZETA = 1.0 rerun alongside\n');
tee('    the benchmark, not instead of it, and say which it prefers and why:\n');
tee('    the sensitivity is what a reader needs, and it is cheap.\n\n');

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

% V7 is a structural verdict in the same sense as V2: it does not need an
% external number in order to bind. What it needs the numbers for is the
% MAGNITUDE of the tension, and those slots are empty by design, so the
% verdict states the identity and reports whichever comparison is available.
tee('V7  THE CONVENIENCE YIELD AND THE EQUITY PREMIUM ARE ONE NUMBER.\n');
tee('    The liquid FOC in this economy is\n');
tee('        chi_b v''(b'') = u''(c) [1 - (1+r_b) q/(q+d)],\n');
tee('    so the tree''s excess return over bonds IS the convenience yield:\n');
tee('    the tree is the only alternative asset, and nothing else can absorb\n');
tee('    a return gap. The manuscript says as much in the two-asset section.\n');
tee('    Model value: %s pp -- the same number under both names. The two\n', local_num(spr));
tee('    ways of writing it agree to the digit, which is the point:\n');
tee('      100*[(q+d)/q - (1+r_b)] = %s      (called a convenience yield)\n', local_num(spr));
tee('      100*[ d/q  -  r_b     ] = %s      (called an equity premium)\n', ...
    local_num(100*(tree_yield - r_b)));
tee('    The consequence is a restriction, not a calibration choice. The\n');
tee('    Treasury-premium literature and the equity-premium literature\n');
tee('    measure objects that differ by roughly an order of magnitude, and\n');
tee('    this model has ONE number to offer both. It cannot sit in both\n');
tee('    ranges, so a reader is entitled to know which one the paper is\n');
tee('    claiming to match and to see the other named as a cost.\n');
dpp = NaN; if isfield(DATA,'convenience_pp'), dpp = DATA.convenience_pp; end
dep = NaN; if isfield(DATA,'equity_premium'), dep = DATA.equity_premium; end
if isfinite(spr) && (isfinite(dpp) || isfinite(dep))
    tee('    Graded against each transcribed slot in turn:\n');
    if isfinite(dpp)
        tee('      vs the convenience-yield slot %s pp: gap %s pp\n', ...
            local_num(dpp), local_num(spr - dpp));
    end
    if isfinite(dep)
        tee('      vs the equity-premium slot %s pp: gap %s pp\n', ...
            local_num(100*dep), local_num(spr - 100*dep));
    end
    tee('    A model that passes one of these two is failing the other by\n');
    tee('    construction. Report both gaps; do not quote the smaller.\n');
else
    tee('    Neither data slot is transcribed yet, so the SIZE of the tension\n');
    tee('    is not measured here. The identity above holds regardless, and\n');
    tee('    it is the identity -- not the gap -- that the paper must own.\n');
    tee('    Transcribing DATA.convenience_pp and DATA.equity_premium turns\n');
    tee('    this verdict into a number; it will not turn it into a pass.\n');
end
tee('\n');

R = struct('LED', LED, 'MOM', MOM, 'DATA', DATA, 'BAND', BAND, 'IVAL', IVAL, ...
           'SRC', SRC, ...
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
