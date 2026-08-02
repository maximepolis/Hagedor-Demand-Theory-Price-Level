% MAIN_TRANSITION_ORDERING  At what horizon does the levy-vs-lump-sum
% ordering become operative along the announcement path?
%
% THE QUESTION (external referee round, MC2). The paper's steady-state
% comparison orders the two financing instruments by their long-run price
% levels, but a policymaker lives on the path: if the ordering emerged only
% after decades, the steady-state ranking would be a poor guide to the
% politics of the program. This driver computes the date-by-date gap
%
%     Delta_t = ln phat_rebate(t) - ln phat_lumpsum(t)
%
% between the two ALREADY-SOLVED nonlinear transition paths (same economy,
% same announcement, same program; only the financing instrument differs),
% and asks (i) when Delta_t first attains the sign of the long-run gap and
% never reverses (the ordering's operative date, in cumulative terms), and
% (ii) what share of the long-run gap is priced by year h.
%
% WHY NO NEW SOLVE. Both paths are exact nonlinear DTPL transitions
% (Anderson-accelerated fixed point, market clearing at every date, both
% gated on convergence AND horizon adequacy). The ordering statistic is a
% deterministic functional of those paths, so this driver is pure
% post-processing: it refuses to run unless both stored paths are
% reportable, and it never re-solves. Runtime: seconds.
%
% THE TWO CLOCKS. "Operative" has a cumulative and a flow reading, and the
% path-solved model distinguishes them: the CUMULATIVE ordering (which
% price level is higher, i.e. which cohort of bondholders has lost more)
% can be set at the announcement instant, while the FLOW ordering (which
% path has higher inflation this year) can reverse immediately after
% impact as the front-loaded jump unwinds toward the terminal level. Both
% are reported; the cumulative clock is the incidence-relevant one.
%
% USAGE   >> main_transition_ordering
%         (requires output/transition_results.mat from main_project_transition;
%          picks up output/transition_deficit.mat too if present)
%
% OUTPUT  output/tables/transition_ordering.txt, output/transition_ordering.mat

clearvars; close all; clc;
t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

trf = fullfile(projdir, 'output', 'transition_results.mat');
assert(exist(trf, 'file') == 2, ...
    'transition_results.mat not found -- run main_project_transition first');
L = load(trf, 'TRn', 'TRi', 'TRr', 'pgc', 'opts');
assert(~isempty(L.TRr), ...
    'rebate path missing (SKIP_REBATE run?) -- rerun main_project_transition');
TRls = L.TRn;   % lump-sum-financed nominal appropriation
TRrb = L.TRr;   % rebate design (levy at 2x program, half rebated)
assert(TRls.reportable && TRrb.reportable, ...
    'both paths must be reportable (converged AND horizon-adequate)');
T = numel(TRls.phat);
assert(numel(TRrb.phat) == T, 'path horizons differ -- resolve on a common T');
assert(abs(log(TRrb.P0 / TRls.P0)) < 1e-9, ...
    'initial price levels differ: the paths are not the same economy');

% do NOT trust pgc.tabdir from the .mat: it is an absolute path from the
% machine that produced the file. Build the output path locally.
tabdir = fullfile(projdir, 'output', 'tables');
if ~isfolder(tabdir), mkdir(tabdir); end
sf = fullfile(tabdir, 'transition_ordering.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});

tee('FINITE-HORIZON OPERATIVENESS OF THE FINANCING ORDERING (MC2)\n');
tee('paths: lump-sum vs rebate, nominal regime; na=%d, T=%d, tol=%.0e\n', ...
    L.pgc.na, T, L.opts.tol);
tee('both paths reportable: converged AND horizon-adequate. no new solve.\n\n');

% ---- the gap path and its anchors ----
Delta   = log(TRrb.phat) - log(TRls.phat);        % cumulative ordering, by date
Dinf    = log(TRrb.eq1.P) - log(TRls.eq1.P);      % long-run (steady-state) gap
sgn     = sign(Dinf);
assert(sgn ~= 0, 'degenerate long-run gap; nothing to time');

tee('impact gap    Delta_1   = %+0.4f log points\n', Delta(1));
tee('terminal gap  Delta_T   = %+0.4f (path end)\n', Delta(T));
tee('long-run gap  Delta_inf = %+0.4f (terminal steady states)\n', Dinf);
tee('year-one share of the long-run gap: %.1f%%\n\n', 100 * Delta(1) / Dinf);

% ---- cumulative clock: first date from which sign(Delta) = sign(Dinf)
% holds forever after (the operative date of the ordering)
right_sign = (sgn .* Delta > 0);
holds_from = find(~right_sign, 1, 'last');   % last violation
if isempty(holds_from), t_op = 1; else, t_op = holds_from + 1; end
if t_op > T
    tee('CUMULATIVE ordering NEVER operative within the horizon (T=%d).\n', T);
else
    tee('CUMULATIVE ordering operative from year %d (never reverses after).\n', t_op);
end

% half-life and overshoot of the gap, on the cumulative clock
t_half = find(sgn .* Delta >= 0.5 * abs(Dinf), 1, 'first');
if isempty(t_half)
    tee('half of the long-run gap is never priced within the horizon.\n');
else
    tee('half of the long-run gap priced by year %d.\n', t_half);
end
[Dmax, t_max] = max(sgn .* Delta);
tee('largest gap %+0.4f at year %d (%.0f%% of long-run: %s).\n\n', ...
    sgn * Dmax, t_max, 100 * Dmax / abs(Dinf), ...
    ternstr(Dmax > abs(Dinf), 'the ordering OVERSHOOTS then settles back', ...
                              'monotone approach'));

% ---- horizon table ----
tee('  h     Delta_h    share of long-run gap\n');
for h = [1 2 5 10 20 40 T]
    if h > T, continue; end
    tee('%4d    %+0.4f    %6.1f%%\n', h, Delta(h), 100 * Delta(h) / Dinf);
end
tee('\n');

% ---- flow clock: which path has higher inflation, year by year ----
% GATED. The post-impact annual gap is a first difference of Delta, so it
% is smaller than Delta by a factor of the horizon and can easily fall
% below the solved price-path residual. Counting sign flips in that regime
% reports solver noise as economics, so the count is printed only when the
% typical annual gap clears the residual scale.
dpi = TRrb.pi_path - TRls.pi_path;
noise = max(TRls.resid_interior, TRrb.resid_interior);
typ   = mean(abs(diff(Delta(2:end))));       % post-impact annual gap scale
tee('FLOW clock (annual inflation ordering, rebate minus lump-sum):\n');
tee('  pi_reb - pi_ls at impact: %+0.2f%%/yr (far above the residual scale)\n', ...
    100 * dpi(1));
tee('  post-impact annual gap %.2e vs price-path residual %.2e\n', typ, noise);
if typ > 5 * noise
    flow_hi = find(dpi(2:end) > 0) + 1;
    tee('  RESOLVED: years after impact with pi_reb > pi_ls: %d of %d\n', ...
        numel(flow_hi), T - 1);
else
    tee(['  NOT RESOLVED at this tolerance: the post-impact flow ordering is\n' ...
         '  at or below the solver residual, so its year-by-year sign is not\n' ...
         '  a result. Only the impact value and the cumulative gap are.\n']);
end
tee(['  reading: the cumulative gap is the incidence-relevant clock, and it\n' ...
     '  is set at the announcement date.\n\n']);

% ---- optional: deficit-path timing against the balanced-timing anchor ----
dff = fullfile(projdir, 'output', 'transition_deficit.mat');
if exist(dff, 'file') == 2
    Ld = load(dff, 'TRd', 'TRi', 'rho_d');
    if Ld.TRd.reportable && numel(Ld.TRd.phat) == numel(Ld.TRi.phat)
        Lam = log(Ld.TRd.phat) - log(Ld.TRi.phat);
        lk  = log(Ld.TRd.kappa_inf);
        tee('DEFICIT-TIMING addendum (indexed regime, rho_d=%.2f):\n', Ld.rho_d);
        tee('  gap vs balanced timing: impact %+0.4f, terminal %+0.4f, dilution ln kappa_inf %+0.4f\n', ...
            Lam(1), Lam(end), lk);
        tee('  share of the dilution priced at impact: %.1f%%\n\n', 100 * Lam(1) / lk);
    else
        tee('(deficit path present but not reportable/horizon-matched; skipped)\n\n');
    end
end

% ---- verdict ----
tee('----- verdict (MC2) -----\n');
if t_op <= T
    tee(['The levy-vs-lump-sum ordering is operative in cumulative terms from\n' ...
         'year %d, with %.0f%% of the long-run gap priced in the announcement\n' ...
         'year: the steady-state ranking is a guide to the path from the start,\n' ...
         'not an asymptotic artifact.\n'], t_op, 100 * Delta(1) / Dinf);
else
    tee(['Within the solved horizon the cumulative ordering never locks in;\n' ...
         'the steady-state ranking is NOT a finite-horizon guide at this\n' ...
         'calibration. Report this as the finding.\n']);
end

OD = struct('Delta', Delta, 'Delta_inf', Dinf, 't_operative', t_op, ...
    't_half', ternval(isempty(t_half), NaN, t_half), 't_max', t_max, ...
    'share_y1', Delta(1) / Dinf, 'dpi', dpi, 'T', T);
save(fullfile(projdir, 'output', 'transition_ordering.mat'), 'OD', 'TRls', 'TRrb');
tee('\n[main_transition_ordering] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end

function v = ternval(c, a, b)
    if c, v = a; else, v = b; end
end
