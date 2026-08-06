% MAIN_TIMING_FRONTIER  Locate the phase-in speed at which the impact price
% response changes sign, SEPARATELY for the pure-timing experiment and the
% joint experiment the manuscript currently reports.
%
% WHY THIS EXISTS. main_deficit_decomposition established, at a single
% phase-in speed, that delaying the tax reverses the sign of the impact
% response even when terminal debt is held at the contemporaneous benchmark:
%
%     C1 (contemporaneous)                  dlnP_1 = -0.0396
%     C2 (delayed, CONSOLIDATED to C1)      dlnP_1 = +0.0221
%     C4 (delayed, no recovery)             dlnP_1 = +0.1421
%
% So a tax-timing claim is licensed in KIND. But the manuscript does not
% report a single speed -- it reports a CRITICAL SPEED, a frontier, quoted as
% a tax half-life. That frontier was located on the C4 experiment, which
% carries the terminal-debt ratchet as well as the delay, so it is a JOINT
% frontier. This driver locates the frontier of each experiment so the two can
% be quoted apart:
%
%     rho*_timing   where C2's impact response crosses zero  (pure timing)
%     rho*_joint    where C4's impact response crosses zero  (what is reported)
%
% WHAT TO EXPECT, so the result is not over-read either way. Consolidation
% removes a positive contribution, so C2 < C4 at every speed and the timing
% frontier must sit at a LONGER half-life than the joint one: you have to
% delay the tax MORE to flip the sign when you also pay the revenue back. The
% gap between the two frontiers is the object worth reporting.
%
% C1 IS SOLVED ONCE, NOT PER SPEED. Under the contemporaneous rule phi_t = 1
% at every date, so C1 does not depend on rho at all. Re-solving it inside the
% sweep would be a fifth of the run spent recomputing one number, and worse,
% would invite a reader to think the benchmark moves with the experiment.
%
% COST, MEASURED. Each speed needs one C4 transition plus a C2 consolidation
% bisection. With the bisection stopping on eta against the ratchet rather
% than on an unattainable kappa_tol, the pilot took 4529 s for C1 plus two
% speeds at T = 80 -- so roughly half an hour per speed, not the hour this
% comment first budgeted. The run CHECKPOINTS after
% every speed, keyed BY SPEED rather than by the grid, so a small pilot grid
% seeds a larger production grid and only the new speeds are paid for.
%
% FAST DOES NOT SOLVE THIS. At the shakeout horizon the transition paths for
% this fiscal spec are known not to converge -- main_deficit_decomposition
% established that and stops on the same precondition. FAST here validates
% the plumbing up to the C1 solve and then stops, by design and with the
% reason printed. The cheap real check is a two-point grid at BENCHMARK
% settings, which the by-speed checkpoint then feeds into the full run.
%
% USAGE   >> clear; RHOGRID = [0.65 0.90]; main_timing_frontier   (pilot)
%         >> clear; main_timing_frontier                  (benchmark, full)
%         >> clear; FAST = true; main_timing_frontier     (plumbing only)
% OUTPUT  output/tables/timing_frontier.txt
%         output/timing_frontier.mat
%         output/timing_frontier_checkpoint.mat

clearvars -except FAST RHOGRID TC HC RESUME; close all; clc;
rng(20260806,'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
run_project_path_setup(struct('quiet', true));

if ~exist('FAST','var'), FAST = false; end
if ~exist('TC','var') || isempty(TC), TC = 10; end
if ~exist('HC','var') || isempty(HC), HC = 10; end
if ~exist('RESUME','var') || isempty(RESUME), RESUME = true; end
% GRID CHOSEN FROM MEASUREMENT, NOT FROM GUESSWORK. The pilot run at
% rho = 0.65 and 0.90 located the timing crossing at rho* = 0.7476 and showed
% C4 still POSITIVE at 0.65 (+0.0066), so the joint crossing lies below 0.65 --
% consistent with the manuscript's 1.4-year half-life, rho = 0.61. The grid is
% therefore dense between 0.55 and 0.80, where both crossings are, and stops at
% 0.90: a point at 0.95 costs a full speed to add shape in a region where both
% responses are large and positive and neither frontier can be.
if ~exist('RHOGRID','var') || isempty(RHOGRID)
    RHOGRID = [0.55 0.60 0.65 0.70 0.80 0.90];
end
RHOGRID = sort(RHOGRID(:).');
EPS_KAPPA = 1e-8; ETA_TOL = 1e-3;

T = 80; if FAST, T = 60; end
pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'timing_frontier.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});

hl = @(r) log(2) ./ (-log(r));
tee('THE TIMING FRONTIER vs THE JOINT FRONTIER\n');
tee('%s\n\n', kv_code_version(mfilename('fullpath')));
tee('rho grid and implied tax half-lives:\n');
for r = RHOGRID, tee('  rho %.3f  ->  half-life %6.2f yr\n', r, hl(r)); end
tee('\nconsolidation start T_c = %d yr, half-life H_c = %d yr; T = %d\n\n', TC, HC, T);
tee('C1 is solved ONCE: under the contemporaneous rule phi_t = 1 at every\n');
tee('date, so it does not depend on rho.\n\n');

[pgc, opts, calinfo] = kv_legacy_transition_setup(FAST); %#ok<ASGLU>
opts.T = T; opts.verbose = false;
opts.regime = 'indexed';   % REQUIRED with opts.fiscal; see main_deficit_decomposition
d1 = @(TR) log(TR.phat(1)/TR.P0);

% ---- the checkpoint is keyed BY SPEED, not by the grid --------------------
% An earlier version put RHOGRID in the signature, so a two-point pilot run
% and the six-point production run had different signatures and the pilot's
% solved speeds were discarded. Each speed is an independent solve; nothing
% about rho = 0.65 depends on which other speeds are in the grid. The
% signature therefore covers the ECONOMY -- preferences, damages, program
% size, horizon, consolidation shape, regime -- and solved speeds are stored
% in a list and matched one at a time. A pilot now seeds the production run,
% and extending the grid costs only the new speeds.
sig = struct('beta',pgc.beta,'D0',pgc.D0,'Gg',opts.Gg_nom,'T',T,'TC',TC, ...
             'HC',HC,'regime',opts.regime);
ckf = fullfile(projdir,'output','timing_frontier_checkpoint.mat');
% A CELL, not a struct array. A struct array demands identical fields in
% identical order, so a checkpoint written before a diagnostic field was added
% would throw on the first append -- killing a run at hour six to complain
% about a field name. A cell holds whatever each entry has.
SPD = {};                         % every speed ever solved under this sig
C1CK = [];                        % cached C1, which no speed depends on
if RESUME && exist(ckf,'file')==2
    CK = load(ckf);
    if isfield(CK,'sig') && isequaln(CK.sig, sig)
        if isfield(CK,'SPD') && iscell(CK.SPD), SPD = CK.SPD; end
        if isfield(CK,'C1CK'), C1CK = CK.C1CK; end
        tee('RESUMED: %d speed(s) already solved under this signature.\n\n', numel(SPD));
    else
        tee('checkpoint signature does not match the economy; starting clean.\n\n');
    end
end

% ---- C1, once ------------------------------------------------------------
% rho is FIXED at 0.90 here and is not read from the grid. Under C1 phi_t = 1
% at every date, so the path does not depend on rho at all; taking it from
% RHOGRID(1) would have made the cached C1 depend on the grid it was solved
% under, which is exactly the coupling the checkpoint above removes.
if ~isempty(C1CK)
    dP_C1 = C1CK.dP; k_C1 = C1CK.kappa;
    tee('C1  (cached)  kappa_inf=%.10f  dlnP1=%+0.6f\n\n', k_C1, dP_C1);
else
    s1 = struct('T',T,'rho_bar',0.90,'consolidation_start',TC, ...
                'consolidation_half_life',HC,'kappa_tol',EPS_KAPPA,'kappa_target',1);
    o1 = opts; o1.fiscal = kv_fiscal_spec('C1', s1);
    TR1 = solve_hank_dtpl_transition(pgc, o1);

    % CONVERGENCE IS A PRECONDITION, NOT AN ASSERT. This used to be a bare
    % assert, which reports a solver outcome as though it were a bug in the
    % driver -- and at FAST it is neither: main_deficit_decomposition already
    % established that these transition paths are KNOWN not to converge at the
    % shakeout horizon, and stops with that named as the expected cause. The
    % same is true here, so say so, write the file, and return.
    if ~TR1.converged
        tee('\n*** STOPPING: C1 did not converge.\n');
        tee('*** Every speed below needs C1: it supplies the consolidation\n');
        tee('*** target for C2 and the benchmark both frontiers are measured\n');
        tee('*** against. A frontier located off an unsolved C1 would report\n');
        tee('*** the solver''s stopping rule, not a critical tax speed.\n');
        if FAST
            tee('*** This is the EXPECTED outcome under FAST (T=%d). The\n', T);
            tee('*** shakeout horizon does not converge for this fiscal spec --\n');
            tee('*** main_deficit_decomposition stops the same way, for the same\n');
            tee('*** reason. FAST validates the plumbing only, and the plumbing\n');
            tee('*** up to this line has just been validated.\n');
            tee('*** For a cheap REAL check, run a two-point grid at benchmark\n');
            tee('*** settings instead -- it is checkpointed per speed and seeds\n');
            tee('*** the full run:\n');
            tee('***     clear; RHOGRID = [0.65 0.90]; main_timing_frontier\n');
        else
            tee('*** This is NOT expected at the benchmark horizon. Check the\n');
            tee('*** residuals below against opts.tol before changing anything.\n');
        end
        if isfield(TR1,'resid_interior') && isfield(TR1,'resid_terminal')
            tee('*** interior residual %.3e   terminal residual %.3e\n', ...
                TR1.resid_interior, TR1.resid_terminal);
        end
        save(fullfile(projdir,'output','timing_frontier.mat'), ...
             'RHOGRID','sig','T','TC','HC','calinfo');
        tee('\n[main_timing_frontier] stopped at the C1 precondition (%.1f s)\n', toc(t0));
        fclose(fid); return;
    end
    dP_C1 = d1(TR1); k_C1 = TR1.kappa_inf;
    C1CK = struct('dP', dP_C1, 'kappa', k_C1);
    tee('C1  converged=%d  kappa_inf=%.10f  dlnP1=%+0.6f\n\n', ...
        TR1.converged, k_C1, dP_C1);
    % Checkpoint C1 before the first speed. An interrupt during speed one
    % would otherwise throw away the benchmark solve that every speed needs.
    try
        tmp = [ckf '.tmp']; save(tmp,'SPD','sig','C1CK','-v7.3');
        movefile(tmp, ckf, 'f');
    catch, end
end

% Match each requested speed against what the checkpoint already holds.
R = cell(1, numel(RHOGRID));
for i = 1:numel(RHOGRID)
    j = local_find_rho(SPD, RHOGRID(i));
    if j > 0, R{i} = SPD{j}; end
end

tee('%7s %9s %11s %11s %11s %9s %8s\n', 'rho', 'half-life', ...
    'dlnP1 C2', 'dlnP1 C4', 'a_xi', 'eta', 'status');
for i = 1:numel(RHOGRID)
    if ~isempty(R{i})
        tee('%7.3f %9.2f %11.6f %11.6f %11.6f %9.2e %8s  (cached)\n', ...
            R{i}.rho, R{i}.hl, R{i}.dP_C2, R{i}.dP_C4, R{i}.a_xi, R{i}.eta, R{i}.status);
        continue;
    end
    rho = RHOGRID(i);
    so = struct('T',T,'rho_bar',rho,'consolidation_start',TC, ...
                'consolidation_half_life',HC,'kappa_tol',EPS_KAPPA,'kappa_target',1);
    % C4: delayed, no recovery. One transition, no bisection.
    o4 = opts; o4.fiscal = kv_fiscal_spec('C4', so);
    TR4 = solve_hank_dtpl_transition(pgc, o4);
    % C2: delayed, consolidated back to C1's REALIZED terminal debt.
    %
    % STOP THE BISECTION ON THE STATISTIC THAT GRADES IT. The acceptance test
    % three lines below is eta, the residual dilution as a fraction of the
    % ratchet the delay opened -- not kappa_tol, which at 1e-8 is below the
    % transition solver's own fixed point and so is never reached. Handing the
    % ratchet to the solver makes its internal stopping rule the same one, so
    % each speed costs roughly a dozen transitions instead of the full sixty
    % it would burn chasing an unattainable target. The ratchet is available
    % because C4 is solved first, which is also the reason C4 comes first.
    %
    % A NON-CONVERGED C4 IS A REASON NOT TO START. a_xi = 0 IS C4, so the
    % bisection's first evaluation is the path that just failed and
    % kv_solve_consolidation will correctly refuse to bracket through it --
    % after paying for the solve. Skip it and record the real cause.
    so2 = so;
    so2.kappa_ratchet = abs(TR4.kappa_inf - k_C1);
    so2.eta_tol       = ETA_TOL;
    if TR4.converged
        RC = kv_solve_consolidation(pgc, opts, so2, k_C1, @(varargin) []);
    else
        RC = struct('a_xi',NaN,'kappa_inf',NaN,'gap',NaN,'hit',false,'TR',[], ...
                    'iters',0,'status','C4_NOT_CONVERGED');
    end
    okC2 = ~isempty(RC.TR) && isstruct(RC.TR) && isfield(RC.TR,'converged') ...
           && RC.TR.converged;
    eta = NaN; dP_C2 = NaN; a_xi = NaN;
    if okC2
        ratchet = so2.kappa_ratchet;
        eta   = abs(RC.kappa_inf - k_C1) / max(ratchet, eps);
        dP_C2 = d1(RC.TR); a_xi = RC.a_xi;
    end
    st = 'ok';
    if ~TR4.converged,           st = 'C4NOCONV';
    elseif ~okC2,                st = 'C2FAIL';
    elseif ~(eta < ETA_TOL),     st = 'ETAFAIL';
    end
    R{i} = struct('rho',rho,'hl',hl(rho),'dP_C2',dP_C2,'dP_C4',d1(TR4), ...
                  'a_xi',a_xi,'eta',eta,'status',st, ...
                  'kappa_C4',TR4.kappa_inf,'conv_C4',TR4.converged, ...
                  'c2_status',RC.status,'c2_iters',RC.iters,'c2_gap',RC.gap);
    tee('%7.3f %9.2f %11.6f %11.6f %11.6f %9.2e %8s\n', ...
        rho, hl(rho), R{i}.dP_C2, R{i}.dP_C4, a_xi, eta, st);
    if ~strcmp(st, 'ok')
        % A silent tee was passed to the consolidation solver so the sweep
        % table stays readable; when a speed fails, its diagnosis has to
        % surface somewhere or the row is a dead end.
        tee('        consolidation returned %s after %d transitions (gap %.2e)\n', ...
            RC.status, RC.iters, RC.gap);
    end
    % Accumulate into the by-speed store, replacing any earlier entry for the
    % same rho rather than appending a duplicate the matcher would then have
    % to choose between.
    j = local_find_rho(SPD, rho);
    if j > 0, SPD{j} = R{i}; else, SPD{end+1} = R{i}; end %#ok<SAGROW>
    try
        tmp = [ckf '.tmp']; save(tmp,'SPD','sig','C1CK','-v7.3');
        movefile(tmp, ckf, 'f');
    catch, end
end

% ---- locate the crossings ------------------------------------------------
tee('\nFRONTIERS (linear interpolation in rho between the bracketing speeds)\n');
ok = ~cellfun(@isempty, R);
rr  = cellfun(@(x) x.rho,   R(ok));
c2  = cellfun(@(x) x.dP_C2, R(ok));
c4  = cellfun(@(x) x.dP_C4, R(ok));
good2 = cellfun(@(x) strcmp(x.status,'ok'), R(ok));
[r2, ok2, why2] = kv_zero_cross(rr(good2), c2(good2));
[r4, ok4, why4] = kv_zero_cross(rr, c4);
if ok4
    tee('  JOINT  frontier (C4): rho* = %.4f  ->  tax half-life %.2f yr\n', r4, hl(r4));
else
    tee('  JOINT  frontier (C4): NOT BRACKETED by this grid\n');
end
tee('      %s\n', why4);
if ok2
    tee('  TIMING frontier (C2): rho* = %.4f  ->  tax half-life %.2f yr\n', r2, hl(r2));
else
    tee('  TIMING frontier (C2): NOT BRACKETED by this grid\n');
end
tee('      %s\n', why2);
% ---- cross-check against the decomposition -------------------------------
% This sweep and main_deficit_decomposition solve the SAME three experiments
% at rho = 0.90, by different routes: the decomposition's consolidation
% bisection chased kappa_tol = 1e-8 and stopped on its iteration cap, while
% this one stops on eta against the ratchet. If the two agree, the cheaper
% stopping rule is validated on a case that was already certified; if they
% do not, one of them is wrong and the frontier is not reportable. Free --
% the decomposition's answer is already on disk.
dcf = fullfile(projdir, 'output', 'deficit_decomposition.mat');
i90 = find(abs(RHOGRID - 0.90) < 1e-12, 1, 'first');
if exist(dcf, 'file') == 2 && ~isempty(i90) && ~isempty(R{i90})
    DC = load(dcf);
    if isfield(DC,'SOL') && isfield(DC,'RHOBAR') && abs(DC.RHOBAR - 0.90) < 1e-12 ...
            && all(isfield(DC.SOL, {'C1','C2','C4'}))
        dd = @(S) log(S.phat(1)/S.P0);
        ref = [dd(DC.SOL.C1), dd(DC.SOL.C2), dd(DC.SOL.C4)];
        got = [dP_C1,         R{i90}.dP_C2,  R{i90}.dP_C4];
        tee('\nCROSS-CHECK against main_deficit_decomposition at rho = 0.90\n');
        tee('%6s %13s %13s %11s\n', 'case', 'this sweep', 'decomposition', 'difference');
        nm = {'C1','C2','C4'};
        for i = 1:3
            tee('%6s %13.6f %13.6f %11.2e\n', nm{i}, got(i), ref(i), got(i)-ref(i));
        end
        dmax = max(abs(got - ref));
        if dmax < 1e-3
            tee(['  Agreement to %.1e. The ratchet-normalized stopping rule\n' ...
                 '  reproduces the certified run, so the speeds solved here on\n' ...
                 '  that rule can be read as the same experiment.\n'], dmax);
        else
            tee(['  *** DISAGREEMENT of %.2e. These are meant to be the same\n' ...
                 '  *** three numbers. Do not report a frontier until this is\n' ...
                 '  *** explained: one of the two runs is not solving what it\n' ...
                 '  *** says it is.\n'], dmax);
        end
    end
end

if ok2 && ok4
    tee('\n  The timing frontier sits at a %.2f-year half-life against %.2f for\n', ...
        hl(r2), hl(r4));
    tee('  the joint experiment: delaying the tax must be %.1fx slower to flip\n', ...
        hl(r2)/max(hl(r4),eps));
    tee('  the sign once the revenue is actually paid back. The manuscript\n');
    tee('  quotes the JOINT number, so any timing claim must quote %.2f yr.\n', hl(r2));
end

save(fullfile(projdir,'output','timing_frontier.mat'), ...
     'R','SPD','RHOGRID','dP_C1','k_C1','sig','T','TC','HC','calinfo');
tee('\n[main_timing_frontier] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =========================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function j = local_find_rho(SPD, rho)
% Index of the stored speed equal to rho, 0 if absent. Exact comparison on a
% grid value the caller supplied, with a tolerance only against round-trip
% error through the .mat -- these are the same literals, not two computations
% that ought to agree.
    j = 0;
    for i = 1:numel(SPD)
        if isstruct(SPD{i}) && isfield(SPD{i},'rho') ...
                && abs(SPD{i}.rho - rho) < 1e-12
            j = i; return;
        end
    end
end
