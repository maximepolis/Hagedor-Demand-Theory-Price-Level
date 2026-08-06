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
% COST. Each speed needs one C4 transition plus a full C2 consolidation
% bisection, and the bisection is roughly forty transitions. Budget about an
% hour per grid point at the benchmark horizon. The run CHECKPOINTS after
% every speed and resumes on a matching signature, so it survives being
% interrupted.
%
% USAGE   >> clear; main_timing_frontier                  (benchmark)
%         >> clear; RHOGRID = [0.6 0.8 0.9]; main_timing_frontier
%         >> clear; FAST = true; main_timing_frontier     (shakeout only)
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
% The manuscript's reported frontier is a 1.4-year half-life, i.e. rho = 0.61.
% The decomposition ran at rho = 0.90. The grid must bracket BOTH crossings,
% so it spans from well below the reported joint frontier to well above the
% speed at which C2 is already positive.
if ~exist('RHOGRID','var') || isempty(RHOGRID)
    RHOGRID = [0.55 0.65 0.75 0.85 0.90 0.95];
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

% ---- C1, once ------------------------------------------------------------
s1 = struct('T',T,'rho_bar',RHOGRID(1),'consolidation_start',TC, ...
            'consolidation_half_life',HC,'kappa_tol',EPS_KAPPA,'kappa_target',1);
o1 = opts; o1.fiscal = kv_fiscal_spec('C1', s1);
TR1 = solve_hank_dtpl_transition(pgc, o1);
assert(TR1.converged, 'C1 did not converge; nothing downstream is meaningful');
dP_C1 = d1(TR1); k_C1 = TR1.kappa_inf;
tee('C1  converged=%d  kappa_inf=%.10f  dlnP1=%+0.6f\n\n', ...
    TR1.converged, k_C1, dP_C1);

% ---- checkpoint ----------------------------------------------------------
sig = struct('beta',pgc.beta,'D0',pgc.D0,'Gg',opts.Gg_nom,'T',T,'TC',TC, ...
             'HC',HC,'rho',RHOGRID,'regime',opts.regime);
ckf = fullfile(projdir,'output','timing_frontier_checkpoint.mat');
R = cell(1, numel(RHOGRID));
if RESUME && exist(ckf,'file')==2
    CK = load(ckf);
    if isfield(CK,'sig') && isequaln(CK.sig, sig) && numel(CK.R)==numel(R)
        R = CK.R;
        tee('RESUMED: %d of %d speeds already solved.\n\n', ...
            sum(~cellfun(@isempty,R)), numel(R));
    else
        tee('checkpoint signature does not match; starting clean.\n\n');
    end
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
    so2 = so;
    so2.kappa_ratchet = abs(TR4.kappa_inf - k_C1);
    so2.eta_tol       = ETA_TOL;
    RC = kv_solve_consolidation(pgc, opts, so2, k_C1, @(varargin) []);
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
    try
        tmp = [ckf '.tmp']; save(tmp,'R','sig','dP_C1','k_C1','-v7.3');
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
[r2, ok2] = kv_zero_cross(rr(good2), c2(good2));
[r4, ok4] = kv_zero_cross(rr, c4);
if ok4
    tee('  JOINT  frontier (C4): rho* = %.4f  ->  tax half-life %.2f yr\n', r4, hl(r4));
else
    tee('  JOINT  frontier (C4): NOT BRACKETED by this grid\n');
end
if ok2
    tee('  TIMING frontier (C2): rho* = %.4f  ->  tax half-life %.2f yr\n', r2, hl(r2));
else
    tee('  TIMING frontier (C2): NOT BRACKETED by this grid\n');
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
     'R','RHOGRID','dP_C1','k_C1','sig','T','TC','HC','calinfo');
tee('\n[main_timing_frontier] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =========================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
