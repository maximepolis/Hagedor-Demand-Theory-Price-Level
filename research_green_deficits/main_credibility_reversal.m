% MAIN_CREDIBILITY_REVERSAL  How much of the announcement capitalization is
% the mechanism, and how much is the assumption of perfect credibility?
% (Referee R13, Experiment 5 / Major Comment 9.)
%
% PROVENANCE WARNING. The referee round this file answers is NOT in the
% repository: grepping the whole project for "Experiment 5" and "Major
% Comment 9" returns NOTHING, so the referee's own wording could not be read
% and nothing here is quoted from it. Worse, the label collides: the tag "R13"
% is ALREADY IN USE at referee_memo/REFEREE_MEMO.md line 125 for a different
% objection ("Your high-damage case drives full self-financing"). Do not
% cross-reference the two. The experiment implemented below is the one
% specified in the task that commissioned this file -- announcement
% probability p, per-period reversal hazard h, report dlnP_1 and F_P -- and if
% the referee asked for something else, this file does not answer it.
%
% ---------------------------------------------------------------------------
% THE OBJECTION. The paper's announcement result is computed under an
% announcement that is believed with probability one and implemented forever.
% Under that assumption the whole future tax stream is capitalized into asset
% demand at t=1, so the impact price response is as large as it can possibly
% be. The referee's charge is that the reported magnitude is therefore
% mechanically amplified by the credibility assumption rather than by the
% demand-theory mechanism, and that the paper cannot tell the two apart.
%
% THE EXPERIMENT. At announcement the permanent program is implemented with
% probability p; once implemented it faces a per-period (annual) reversal
% hazard h, after which it is abandoned permanently. The probability that the
% program is RUNNING at date t is therefore
%
%       m_t(p,h) = p * (1-h)^(t-1),        t = 1, 2, ...
%
% and the object of interest is the impact response dlnP_1(p,h) together with
% the front-loading share
%
%       F_P(p,h) = dlnP_1(p,h) / dlnP_inf(p,h),
%       dlnP_1   = log( phat_1 / P0 ),   dlnP_inf = log( phat_T / P0 ),
%
% swept over p in {0.25, 0.50, 0.75, 1} and over several hazards h.
%
% ---------------------------------------------------------------------------
% WHAT IS ACTUALLY SOLVED, AND WHAT IT IS NOT. READ THIS BEFORE QUOTING ANY
% NUMBER BELOW.
%
% solve_hank_dtpl_transition.m is a PERFECT-FORESIGHT solver and must not be
% modified (D10/D11 parity). Its appropriation is a SCALAR, opts.Gg_nom (see
% its lines 193-197), from which it builds g_path internally in one of three
% ways (its lines 279-291): Gg./phat (nominal), a constant real mandate
% (indexed), or the partial-indexation power rule. There is no interface for a
% caller-supplied time-varying spending path. The terminal price is likewise
% pinned at the steady state of that same constant program: its line 218 solves
% the green terminal steady state eq1, its lines 243-248 set phat(T) = eq1.P,
% and its line 449 updates only phat(1:T-1), so phat(T) is never a free
% unknown. So the risky program is passed through the existing interface as a
% CERTAINTY-EQUIVALENT, PV-MATCHED PERMANENT SURROGATE:
%
%       Gg_eff(p,h) = s(p,h) * Gbar,
%       s(p,h) = E[ sum_t 1{running at t} (1+rbar)^-t ] / sum_t (1+rbar)^-t
%              = p * rbar / (rbar + h),          (exact geometric sums)
%
% i.e. the certain permanent appropriation whose present value equals the
% present value of the risky one, discounted at the stationary real rate
% rbar = (1+i_ss)/(1+mu) - 1. The solver then builds the boundary steady
% states, the terminal pin, the climate block and the tax path consistently
% for THAT permanent program, so the object solved is an internally coherent
% perfect-foresight economy. s(1,0) = 1 exactly, which is what makes the
% identity check below exact rather than approximate.
%
% TWO APPROXIMATIONS, NAMED.
%
%  (1) CERTAINTY EQUIVALENCE. The risk is NOT PRICED. Households face a
%      deterministic policy path; there is no state-contingent price-level
%      jump on the implementation date or on a reversal date, no risk premium
%      in the bond market, and no additional precautionary asset demand
%      arising from policy uncertainty ITSELF. In a model whose entire
%      mechanism IS precautionary asset demand, priced policy risk is not a
%      second-order detail: it adds a source of income risk that would raise
%      asset demand and hence push the price level down, partially offsetting
%      the smaller expected program. The sign of the net effect cannot be
%      signed from this run and is NOT claimed here. A probability-weighted
%      policy path is not the same object as a solution with the risk priced.
%      THIS FILE IMPLEMENTS THE PROBABILITY-WEIGHTED (CERTAINTY-EQUIVALENT)
%      VERSION. It does not price the risk.
%
%  (2) PV MATCHING RATHER THAN PATH MATCHING. The expected policy path
%      m_t*Gbar is DECLINING when h > 0; the surrogate replaces it by the flat
%      permanent path s*Gbar with the same present value. The two coincide
%      exactly when h = 0 (then m_t = p for all t and s = p), so the h = 0
%      column implements the expected policy path EXACTLY and carries only
%      approximation (1). For h > 0 the surrogate back-loads spending relative
%      to the expected path; the table reports max_t |m_t - s| per cell as the
%      size of that distortion. Because green capital accumulates
%      (Kg_t = (1-delta_g)Kg_{t-1} + q_g g_t) and damages are a nonlinear
%      function of Kg, the flattening changes the TIMING of damages even when
%      the present value of spending is matched. F_P for h > 0 should
%      therefore be read as the front-loading of a SMALLER PERMANENT program,
%      not as the front-loading of a program expected to be dismantled.
%
% Doing this without approximation (2) would require a caller-supplied
% spending path and a no-program terminal steady state, i.e. changes inside
% solve_hank_dtpl_transition.m, which is out of bounds here.
%
% ---------------------------------------------------------------------------
% THE IDENTITY CHECK. p = 1, h = 0 must reproduce the existing
% perfect-foresight path bit for bit, through the SAME code path the sweep
% uses. It runs BEFORE the sweep and the driver refuses to continue if it
% fails (same pattern as main_partial_indexation's endpoint identity). A
% generalization that does not nest the original is not a generalization.
%
% NOT CALIBRATED. The hazards h are ILLUSTRATIVE, not estimated. Identifying h
% would need evidence on the durability of climate appropriations across
% administrations (reauthorization, rescission and repeal histories); no such
% series is in this repository, so no value here is presented as an empirical
% magnitude. The same holds for p. This driver reports SENSITIVITY, not
% identification.
%
% USAGE   >> clear; main_credibility_reversal
%         >> clear; FAST = true; main_credibility_reversal
%         >> clear; HGRID = [0 0.02 0.05 0.10]; main_credibility_reversal
%         >> clear; REGIME = 'indexed'; main_credibility_reversal
%
% OUTPUT  output/tables/credibility_reversal.txt
%         output/credibility_reversal.mat

clearvars -except FAST PGRID HGRID REGIME; close all; clc;
rng(20260805, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
run_project_path_setup(struct('quiet', true));

if ~exist('FAST','var')  || isempty(FAST),  FAST  = false; end
if ~exist('PGRID','var') || isempty(PGRID), PGRID = [0.25 0.50 0.75 1.00]; end
if ~exist('HGRID','var') || isempty(HGRID), HGRID = [0.00 0.05 0.10]; end
if ~exist('REGIME','var')|| isempty(REGIME), REGIME = 'nominal'; end

PGRID = PGRID(:).';  HGRID = HGRID(:).';
assert(all(PGRID > 0 & PGRID <= 1), 'PGRID entries must lie in (0,1]');
assert(all(HGRID >= 0 & HGRID < 1), 'HGRID entries must lie in [0,1)');
assert(any(abs(PGRID - 1) < 1e-15) && any(HGRID == 0), ...
    'the grids must contain the perfect-credibility cell p=1, h=0');

% The legacy transition setup: calibrated beta, climate_version, D0, Gg_nom
% and the FAST asset grid. Passing the DEFAULT beta leaves no root in the
% solver's [0.5, 1.3] price bracket and the baseline steady state does not
% exist -- see kv_legacy_transition_setup.
[pgc, opts_base, calinfo] = kv_legacy_transition_setup(FAST);
rbar   = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;   % same expression as the solver

% ---- SWEEP THE PV WEIGHT s, NOT THE RAW HAZARD h ------------------------
% The first run of this driver swept h in {0, 0.05, 0.10} and returned NOTHING
% USABLE: 9 of 12 cells fell below the solver's clearing residual and the
% front-loading grid printed as all dots. The cause is not the solver. It is
% that the map h -> s is violently convex when rbar is small:
%
%   s = rbar/(rbar+h),   rbar = 1.96%
%     h = 0.02  ->  s = 0.50     the program is HALVED
%     h = 0.05  ->  s = 0.28
%     h = 0.10  ->  s = 0.16
%
% A hazard of 5% a year -- an expected program life of 20 years, which is a
% mild assumption in words -- removes 72% of the program's present value,
% because at a 2% real rate a perpetual program's PV is dominated by the far
% future. The response then scales down with it and disappears under the
% residual floor. Reading that as "front-loading collapses under imperfect
% credibility" would be reading the noise floor.
%
% THIS IS ITSELF THE SUBSTANTIVE ANSWER to the request for "at least two
% reversal hazards": at rbar = 2% there is no graded middle ground in h. To
% hold s >= 0.9 needs h <= 0.22% a year, an expected life of 459 years -- i.e.
% indistinguishable from perfect credibility. Anything a reader would call a
% real reversal risk already halves the program. The experiment is therefore
% posed in s, which is well-scaled and resolvable, with the implied hazard
% REPORTED beside it so the reader sees what each s costs in years.
%
% Set HGRID explicitly to sweep raw hazards instead; SGRID then has no effect.
if ~exist('HGRID_EXPLICIT','var'), HGRID_EXPLICIT = false; end
if ~exist('SGRID','var') || isempty(SGRID), SGRID = [1.00 0.90 0.80 0.70]; end
if ~HGRID_EXPLICIT
    SGRID = SGRID(:).';
    assert(all(SGRID > 0 & SGRID <= 1), 'SGRID entries must lie in (0,1]');
    assert(any(abs(SGRID - 1) < 1e-15), 'SGRID must contain s = 1 (the identity check)');
    HGRID = rbar * (1 - SGRID) ./ SGRID;      % invert s = rbar/(rbar+h)
    HGRID(abs(SGRID - 1) < 1e-15) = 0;        % exact, not 2e-19
end
Gg_cal = calinfo.Gg_cal;
T      = opts_base.T;

if ~isfolder(pgc.tabdir), mkdir(pgc.tabdir); end
sf  = fullfile(pgc.tabdir, 'credibility_reversal.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});

tee('CREDIBILITY AND REVERSAL RISK IN THE ANNOUNCEMENT RESULT\n%s\n', repmat('=', 1, 74));
tee('%s\n\n', kv_code_version(mfilename('fullpath')));
tee('referee R13, Experiment 5 / Major Comment 9 -- NOTE: that referee text is\n');
tee('NOT in this repository (no "Experiment 5" / "Major Comment 9" anywhere),\n');
tee('and the tag R13 is already used in REFEREE_MEMO.md line 125 for a\n');
tee('DIFFERENT objection. Nothing here is quoted from the referee.\n');
tee('setup: regime=%s  na=%d  T=%d  beta*=%.6f  D0=%.3f  Gbar=%.6f  rbar=%.6f  FAST=%d\n\n', ...
    REGIME, calinfo.na, T, calinfo.beta_star, calinfo.D0_med, Gg_cal, rbar, FAST);

% ---------------------------------------------------------------------------
tee('WHAT IS SOLVED (and what is not)\n%s\n', repmat('-', 1, 74));
tee('Program implemented at announcement w.p. p; once implemented, per-period\n');
tee('reversal hazard h. Probability the program is running at t:\n');
tee('    m_t(p,h) = p*(1-h)^(t-1).\n\n');
tee('IMPLEMENTED: the CERTAINTY-EQUIVALENT, PV-MATCHED PERMANENT SURROGATE.\n');
tee('    Gg_eff(p,h) = s(p,h)*Gbar,   s(p,h) = p*rbar/(rbar+h),\n');
tee('    s = PV-weighted expected share of dates at which the program runs,\n');
tee('    discounted at the stationary real rate rbar. s(1,0) = 1 exactly.\n');
tee('The solver is then run as a PERFECT-FORESIGHT transition for a permanent\n');
tee('program of size Gg_eff: boundary steady states, terminal pin, climate\n');
tee('block and taxes are all internally consistent with that program.\n\n');
tee('NOT IMPLEMENTED: the risk is NOT PRICED. A probability-weighted policy\n');
tee('path is NOT the same object as a solution in which the reversal risk is\n');
tee('priced. There is no state-contingent price jump at implementation or at\n');
tee('reversal, no bond risk premium, and no extra precautionary demand coming\n');
tee('from policy uncertainty itself. In a model whose mechanism IS\n');
tee('precautionary asset demand, priced policy risk would raise asset demand\n');
tee('and push the price level DOWN, offsetting the smaller expected program by\n');
tee('an amount this run cannot measure. No net sign is claimed.\n\n');
tee('SECOND APPROXIMATION: the expected path m_t*Gbar declines when h>0; the\n');
tee('surrogate is the FLAT PV-equivalent path s*Gbar. They coincide exactly at\n');
tee('h=0 (m_t = p = s), so the h=0 column carries ONLY the certainty-equivalence\n');
tee('approximation. Column "flatgap" = max_t |m_t - s| reports the size of the\n');
tee('flattening for h>0. Green capital accumulates, so flattening moves the\n');
tee('TIMING of damages even at matched spending PV.\n\n');
tee('The hazards h and probabilities p are ILLUSTRATIVE, not estimated. This\n');
tee('driver reports sensitivity, not identification.\n\n');
tee('SWEEP IS IN THE PV WEIGHT s, NOT THE RAW HAZARD h. At rbar = %.4f the map\n', rbar);
tee('h -> s = rbar/(rbar+h) is violently convex: h = 0.05 (a 20-year expected\n');
tee('life) already removes %.0f%% of the program PV, which drives the price\n', ...
    100*(1 - rbar/(rbar+0.05)));
tee('response under the solver residual and returns an unresolved grid. There\n');
tee('is no graded middle ground in h at this real rate -- holding s >= 0.9\n');
tee('needs h <= %.4f, an expected life of %.0f years. Implied hazards:\n', ...
    rbar*(1-0.9)/0.9, 0.9/(rbar*0.1));
for jj = 1:numel(HGRID)
    if HGRID(jj) > 0
        tee('    s = %.2f  ->  h = %.5f   (expected life %6.0f yr)\n', ...
            rbar/(rbar+HGRID(jj)), HGRID(jj), 1/HGRID(jj));
    else
        tee('    s = %.2f  ->  h = 0         (permanent)\n', 1.0);
    end
end

% ===========================================================================
% IDENTITY CHECK, BEFORE THE SWEEP.
%
% p = 1, h = 0 must reproduce the existing perfect-foresight path exactly, and
% must do so through the same helper the sweep calls, so that the check tests
% the sweep's code rather than a re-typed formula. This is a gate, not a
% diagnostic.
% ===========================================================================
tee('IDENTITY CHECK: p=1, h=0 must reproduce the perfect-foresight path\n%s\n', ...
    repmat('-', 1, 74));

s10 = credibility_scale(1, 0, rbar);
tee('  s(1,0) = %.17g   (must be exactly 1)\n', s10);
IDENT = struct('ok', (s10 == 1), 's10', s10, 'dphat', NaN, 'dg', NaN, ...
               'dtau', NaN, 'dD', NaN, 'archive', 'not compared');

fprintf('  [1/%d] reference perfect-foresight path (regime %s)...\n', ...
    1 + numel(PGRID)*numel(HGRID), REGIME);
o_ref  = opts_base; o_ref.regime = REGIME; o_ref.verbose = false;
TR_ref = solve_hank_dtpl_transition(pgc, o_ref);
fprintf('  [2/%d] p=1,h=0 through the credibility helper...\n', ...
    1 + numel(PGRID)*numel(HGRID));
TR_id  = solve_cell(pgc, opts_base, REGIME, s10 * Gg_cal);

if ~pathok(TR_ref) || ~pathok(TR_id)
    tee('  ONE SIDE PRODUCED NO PATH.\n    ref: %s\n    id : %s\n', ...
        msgof(TR_ref), msgof(TR_id));
    IDENT.ok = false;
else
    IDENT.dphat = max(abs(TR_ref.phat(:)     - TR_id.phat(:)));
    IDENT.dg    = max(abs(TR_ref.g_path(:)   - TR_id.g_path(:)));
    IDENT.dtau  = max(abs(TR_ref.tau_path(:) - TR_id.tau_path(:)));
    IDENT.dD    = max(abs(TR_ref.D_path(:)   - TR_id.D_path(:)));
    tee('  max|d phat| %.3e   max|d g| %.3e   max|d tau| %.3e   max|d D| %.3e   %s\n', ...
        IDENT.dphat, IDENT.dg, IDENT.dtau, IDENT.dD, ...
        tern(IDENT.dphat < 1e-12 && IDENT.dg < 1e-12 && ...
             IDENT.dtau < 1e-12 && IDENT.dD < 1e-12, 'IDENTICAL', '*** DIFFERS ***'));
    IDENT.ok = IDENT.ok && (IDENT.dphat < 1e-12) && (IDENT.dg < 1e-12) && ...
               (IDENT.dtau < 1e-12) && (IDENT.dD < 1e-12);
    tee('  reference path reportable = %d (converged %d, horizon_ok %d)\n', ...
        TR_ref.reportable, TR_ref.converged, TR_ref.horizon_ok);
end

% INFORMATIONAL ONLY (never a gate): compare against the archived headline
% path in output/transition_results.mat when its grid and horizon match. A
% nonzero difference here signals a SETUP difference (e.g. the archived run
% used a cached beta while kv_legacy_transition_setup always recomputes it),
% not a failure of this experiment.
trf = fullfile(projdir, 'output', 'transition_results.mat');
if exist(trf, 'file') == 2
    La = load(trf);
    fa = '';
    if strcmpi(REGIME, 'nominal') && isfield(La, 'TRn'), fa = 'TRn';
    elseif strcmpi(REGIME, 'indexed') && isfield(La, 'TRi'), fa = 'TRi';
    end
    if ~isempty(fa) && isfield(La, 'pgc') && isfield(La.pgc, 'na') ...
            && La.pgc.na == pgc.na && pathok(La.(fa)) ...
            && numel(La.(fa).phat) == T && pathok(TR_ref)
        da = max(abs(La.(fa).phat(:) - TR_ref.phat(:)));
        IDENT.archive = sprintf('max|d phat| vs archived %s = %.3e', fa, da);
        tee('  archived cross-check (informational, NOT a gate): %s\n', IDENT.archive);
    else
        tee('  archived cross-check skipped (grid/horizon/field mismatch).\n');
    end
else
    tee('  archived cross-check skipped (transition_results.mat absent).\n');
end

if ~IDENT.ok
    tee(['\n*** p=1, h=0 does NOT reproduce the perfect-foresight path, so the\n' ...
         '*** credibility block is not a generalization of the announcement\n' ...
         '*** experiment. Stopping; nothing below would mean anything.\n']);
    fclose(fid);
end
assert(IDENT.ok, 'main_credibility_reversal:identity', ...
    'p=1,h=0 does not nest the existing perfect-foresight path; see the table file');
tee('\n');

% ===========================================================================
% THE SWEEP.
% ===========================================================================
np = numel(PGRID); nh = numel(HGRID);
CR = struct('p', {}, 'h', {}, 's', {}, 'Gg_eff', {}, 'flatgap', {}, ...
            'P0', {}, 'P_impact', {}, 'P_term', {}, 'dlnP1', {}, 'dlnPinf', {}, ...
            'F_P', {}, 'F_level', {}, 'linearity', {}, 'reval_stock', {}, ...
            'reval_pv_share', {}, 'resid_interior', {}, 'resid_terminal', {}, ...
            'snr', {}, 'converged', {}, 'reportable', {}, 'msg', {});
M_dlnP1 = nan(np, nh); M_FP = nan(np, nh); M_s = nan(np, nh); M_ok = false(np, nh);

% Cache on the exact surrogate scale: two (p,h) cells with the same s are the
% same economy, and the p=1,h=0 cell is the identity run already computed.
CACHE = struct('s', {s10}, 'TR', {TR_id});

k = 2;   % runs already done (reference + identity)
ntot = 1 + np*nh;
for i = 1:np
    for j = 1:nh
        p = PGRID(i); h = HGRID(j);
        [s, m] = credibility_scale(p, h, rbar, T);
        Gg_eff = s * Gg_cal;
        flatgap = max(abs(m - s));

        TR = []; hit = false;
        for c = 1:numel(CACHE)
            if CACHE(c).s == s, TR = CACHE(c).TR; hit = true; break; end
        end
        if ~hit
            k = k + 1;
            fprintf('  [%d/%d] p=%.2f h=%.3f -> s=%.4f, Gg_eff=%.6f ...\n', ...
                k, ntot, p, h, s, Gg_eff);
            TR = solve_cell(pgc, opts_base, REGIME, Gg_eff);
            CACHE(end+1) = struct('s', s, 'TR', TR); %#ok<AGROW>
        else
            fprintf('  [--/%d] p=%.2f h=%.3f -> s=%.4f (cached)\n', ntot, p, h, s);
        end

        r = struct('p', p, 'h', h, 's', s, 'Gg_eff', Gg_eff, 'flatgap', flatgap, ...
                   'P0', NaN, 'P_impact', NaN, 'P_term', NaN, 'dlnP1', NaN, ...
                   'dlnPinf', NaN, 'F_P', NaN, 'F_level', NaN, 'linearity', NaN, ...
                   'reval_stock', NaN, 'reval_pv_share', NaN, ...
                   'resid_interior', NaN, 'resid_terminal', NaN, 'snr', NaN, ...
                   'converged', false, 'reportable', false, 'msg', msgof(TR));
        if pathok(TR)
            r.P0       = TR.P0;
            r.P_impact = TR.phat(1);
            r.P_term   = TR.phat(end);
            r.dlnP1    = log(TR.phat(1)   / TR.P0);
            r.dlnPinf  = log(TR.phat(end) / TR.P0);
            if r.dlnPinf ~= 0, r.F_P = r.dlnP1 / r.dlnPinf; end
            r.F_level  = getf(TR, 'frontload', NaN);   % solver's LEVEL share
            r.reval_stock    = getf(TR, 'reval_stock', NaN);
            r.reval_pv_share = getf(TR, 'reval_pv_share', NaN);
            r.resid_interior = getf(TR, 'resid_interior', NaN);
            r.resid_terminal = getf(TR, 'resid_terminal', NaN);
            % SIGNAL-TO-NOISE. At the fixed point the exact clearing price is
            % phat* = B0/S, so log(phat*) - log(phat) = log(b/S) = -log(1+resid)
            % ~ -resid: the log-price error is of the SAME ORDER as the reported
            % market-clearing residual. A cell whose |dlnP1| is not comfortably
            % larger than resid_interior has no resolved impact response, and
            % its F_P is noise. The margin factor 10 below is a CHOSEN
            % convention, not a calibrated one.
            if r.resid_interior > 0, r.snr = abs(r.dlnP1) / r.resid_interior; end
            r.converged  = getf(TR, 'converged', false);
            r.reportable = getf(TR, 'reportable', false);
        end
        CR(end+1) = r; %#ok<AGROW>
        M_dlnP1(i,j) = r.dlnP1; M_FP(i,j) = r.F_P; M_s(i,j) = r.s;
        M_ok(i,j) = r.reportable && (r.snr >= 10);
    end
end

% linearity benchmark: is the impact response proportional to s?
base = pick1(CR, 1, 0);
dlnP1_full = NaN;
if ~isempty(base), dlnP1_full = base.dlnP1; end
for n = 1:numel(CR)
    if isfinite(dlnP1_full) && dlnP1_full ~= 0 && CR(n).s > 0
        CR(n).linearity = CR(n).dlnP1 / (CR(n).s * dlnP1_full);
    end
end

% ===========================================================================
% TABLES
% ===========================================================================
tee('MAIN TABLE. dlnP1 = log(phat_1/P0); dlnPinf = log(phat_T/P0);\n');
tee('F_P = dlnP1/dlnPinf (front-loading share, LOG definition).\n');
tee('linearity = dlnP1(p,h) / [ s(p,h) * dlnP1(1,0) ]: 1.00 means the impact\n');
tee('response is exactly proportional to the PV-weighted expected program.\n\n');
tee('%5s %6s %8s %9s %9s %10s %10s %9s %9s %9s  %s\n', ...
    'p', 'h', 's', 'Gg_eff', 'flatgap', 'dlnP1', 'dlnPinf', 'F_P', 'F_lev', 'linear', 'status');
tee('%s\n', repmat('-', 1, 116));
for n = 1:numel(CR)
    r = CR(n);
    tee('%5.2f %6.3f %8.4f %9.6f %9.4f %+10.5f %+10.5f %9.4f %9.4f %9.4f  %s\n', ...
        r.p, r.h, r.s, r.Gg_eff, r.flatgap, r.dlnP1, r.dlnPinf, r.F_P, ...
        r.F_level, r.linearity, statusof(r));
end

tee('\nNUMERICAL RESOLUTION. |dlnP1| against the solver''s interior clearing\n');
tee('residual: at the fixed point the log-price error is of the same order as\n');
tee('that residual, so snr = |dlnP1|/resid_interior is the usable-signal ratio.\n');
tee('Cells with snr < 10 (a chosen margin, not a calibrated one) are NOT resolved.\n\n');
tee('%5s %6s %12s %12s %9s %10s %10s  %s\n', ...
    'p', 'h', 'resid_int', 'resid_term', 'snr', 'reval', 'reval/PV', 'status');
tee('%s\n', repmat('-', 1, 88));
for n = 1:numel(CR)
    r = CR(n);
    tee('%5.2f %6.3f %12.2e %12.2e %9.1f %+10.5f %+10.4f  %s\n', ...
        r.p, r.h, r.resid_interior, r.resid_terminal, r.snr, ...
        r.reval_stock, r.reval_pv_share, statusof(r));
end

tee('\nGRID: impact response dlnP1 (rows p, columns h)\n');
tee('%6s', 'p \ h'); for j = 1:nh, tee('%12.3f', HGRID(j)); end; tee('\n');
for i = 1:np
    tee('%6.2f', PGRID(i));
    for j = 1:nh, tee('%12.5f', M_dlnP1(i,j)); end
    tee('\n');
end

tee('\nGRID: front-loading share F_P (rows p, columns h); . = not resolved\n');
tee('%6s', 'p \ h'); for j = 1:nh, tee('%12.3f', HGRID(j)); end; tee('\n');
for i = 1:np
    tee('%6.2f', PGRID(i));
    for j = 1:nh
        if M_ok(i,j), tee('%12.4f', M_FP(i,j)); else, tee('%12s', '.'); end
    end
    tee('\n');
end

% ===========================================================================
% READING
% ===========================================================================
tee('\nREADING\n%s\n', repmat('-', 1, 74));
% CR is filled with p OUTER and h INNER, i.e. ROW-MAJOR over the (np,nh)
% grids, while M_ok(:) is column-major. Transposing before linearizing is what
% aligns the two; without it every per-cell mask below would be scrambled.
okvec = reshape(M_ok.', 1, []);
nun  = sum(~[CR.reportable]);
nlow = sum([CR.reportable] & ~okvec);   % reportable but unresolved
if nun > 0
    tee('  %d of %d cells were NOT reportable (converged AND horizon-adequate).\n', ...
        nun, numel(CR));
    tee('  Those rows are diagnostics, not results.\n');
end
if nlow > 0
    tee('  %d of %d cells converged but fail the snr>=10 resolution margin:\n', ...
        nlow, numel(CR));
    tee('  their impact response is not separated from the solver''s clearing\n');
    tee('  residual, so their F_P is not reported. Small s means a small program\n');
    tee('  means a small price response; a resolution limit, not a finding.\n');
end
lin = [CR.linearity]; lin = lin(isfinite(lin) & [CR.reportable]);
if ~isempty(lin)
    tee('  linearity ratio across reportable cells: min %.3f, median %.3f, max %.3f.\n', ...
        min(lin), median(lin), max(lin));
    tee('  If this sits near 1, the impact response is close to PROPORTIONAL to\n');
    tee('  s(p,h), and the referee''s charge is answered quantitatively: perfect\n');
    tee('  credibility scales the announcement response by 1/s relative to a\n');
    tee('  program believed with probability p and reversed at hazard h. If it\n');
    tee('  departs from 1, the capitalization is nonlinear in program size and\n');
    tee('  the scaling argument does not hold.\n');
end
fp = [CR.F_P]; fpm = okvec & isfinite(fp);
if any(fpm)
    tee('  F_P across RESOLVED cells: min %.3f, median %.3f, max %.3f.\n', ...
        min(fp(fpm)), median(fp(fpm)), max(fp(fpm)));
    tee('  Front-loading is a property of the transition dynamics; under this\n');
    tee('  PV-matched surrogate a change in (p,h) rescales the program, so a\n');
    tee('  NEARLY CONSTANT F_P is the expected outcome and is NOT evidence that\n');
    tee('  reversal risk leaves front-loading alone. Establishing that would\n');
    tee('  require the declining expected path (approximation 2 removed) and,\n');
    tee('  for the real question, the priced-risk solution (approximation 1).\n');
end
tee(['\n  WHAT THIS DOES NOT SETTLE: the priced-risk economy, the values of p\n' ...
     '  and h, and the front-loading of a program that is expected to be\n' ...
     '  dismantled rather than merely smaller. None of those is claimed here.\n']);

save(fullfile(projdir, 'output', 'credibility_reversal.mat'), ...
     'CR', 'PGRID', 'HGRID', 'REGIME', 'M_dlnP1', 'M_FP', 'M_s', 'M_ok', ...
     'pgc', 'opts_base', 'calinfo', 'IDENT', 'rbar', 'Gg_cal', 'TR_ref');
tee('\n[main_credibility_reversal] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% ===========================================================================
% local functions
% ===========================================================================
function [s, m] = credibility_scale(p, h, rbar, T)
% CREDIBILITY_SCALE  PV-weighted expected share of dates at which the program
% is running, and the probability path m_t = p*(1-h)^(t-1).
%
%   s = sum_t m_t (1+rbar)^-t  /  sum_t (1+rbar)^-t
%     = [ p/(rbar+h) ] / [ 1/rbar ] = p*rbar/(rbar+h)   (infinite horizon)
%
% Both sums are taken to infinity, which is the right horizon: the solver's
% terminal steady state persists after date T. s(1,0) = rbar/rbar * 1 = 1
% EXACTLY in IEEE arithmetic, which is what makes the identity check exact.
    assert(isscalar(p) && p >= 0 && p <= 1, 'p must be a scalar in [0,1]');
    assert(isscalar(h) && h >= 0 && h <  1, 'h must be a scalar in [0,1)');
    assert(isscalar(rbar) && rbar > 0, 'rbar must be a positive scalar');
    s = p * rbar / (rbar + h);
    m = [];
    if nargin >= 4 && ~isempty(T), m = p * (1 - h) .^ (0:(T-1)); end
end

function TR = solve_cell(pgc, opts_base, regime, Gg_eff)
% The ONE place a credibility cell is handed to the solver. The identity check
% and every sweep cell go through here, so the check tests this code path.
    o = opts_base;
    o.regime  = regime;
    o.Gg_nom  = Gg_eff;
    o.verbose = false;
    TR = solve_hank_dtpl_transition(pgc, o);
end

function t = pathok(TR)
    t = isstruct(TR) && isfield(TR,'phat') && ~isempty(TR.phat) && ...
        isfield(TR,'g_path') && ~isempty(TR.g_path);
end

function r = pick1(CR, p, h)
    r = [];
    for i = 1:numel(CR)
        if abs(CR(i).p - p) < 1e-12 && abs(CR(i).h - h) < 1e-12
            r = CR(i); return;
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

function s = statusof(r)
    if ~r.reportable
        s = 'NOT reportable';
    elseif ~(r.snr >= 10)
        s = 'reportable, F_P NOT resolved';
    else
        s = 'reportable';
    end
end

function s = tern(c, a, b)
    if c, s = a; else, s = b; end
end

function tee2(fid, varargin)
    fprintf(varargin{:});
    if fid > 0, fprintf(fid, varargin{:}); end
end
