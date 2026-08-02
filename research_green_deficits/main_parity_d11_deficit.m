% MAIN_PARITY_D11_DEFICIT  Does the refactored transition solver reproduce the
% legacy deficit experiment when called with the legacy default specification?
%
% MUST BE RUN AND MUST PASS before any C1-C4 result is reported. Static checks
% establish nothing here: the refactor added a branch inside the path
% recursion, and only a run can show that the legacy branch still executes the
% same arithmetic.
%
% THE TEST. Solve the rho_d = 0.90 deficit path twice:
%   LEGACY  opts.financing='deficit', opts.rho_d=0.90, NO opts.fiscal
%   NEW     the same, plus opts.fiscal built by kv_fiscal_spec with
%           phi_path = 1 - 0.90^t and kappa_mode='free'
% The second supplies explicitly what the first derives internally, so the two
% must agree to machine precision. If they do not, the fiscal-specification
% path is not a faithful generalization of the legacy rule.
%
% USAGE   >> clear; main_parity_d11_deficit
%         >> clear; FAST = true; main_parity_d11_deficit
%
% OUTPUT  output/tables/parity_d11_deficit.txt
%         output/parity_d11_deficit.mat

clearvars -except FAST; close all; clc;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir,'src')));
addpath(genpath(fullfile(projdir,'src_project')));
if ~exist('FAST','var'), FAST = false; end

pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'parity_d11_deficit.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});
tee('D11 PARITY: legacy deficit rule vs an explicit fiscal specification\n\n');

TOL = struct('path', 1e-12, ...   % sup-norm on tau, b, P paths, relative
             'kappa', 1e-12, ...  % terminal dilution, relative
             'scalar', 1e-12);    % headline statistics, relative
RHO = 0.90;
tee('rho_d = %.4f (tax half-life %.4f yr)\n', RHO, log(2)/(-log(RHO)));
tee('tolerances: paths %.0e  kappa %.0e  headlines %.0e\n\n', ...
    TOL.path, TOL.kappa, TOL.scalar);

T = 80; if FAST, T = 40; end
opts = struct('T', T, 'regime', 'indexed', 'financing', 'deficit', ...
              'rho_d', RHO, 'verbose', false);
if FAST, opts.tol = 5e-3; opts.maxit = 30; end
pgc = pg;

tee('--- legacy: no opts.fiscal, rule derived inside the solver ---\n');
TRl = solve_hank_dtpl_transition(pgc, opts);
tee('  kappa_inf = %.12f\n', TRl.kappa_inf);

tee('--- new: identical rule supplied through opts.fiscal ---\n');
fs = kv_fiscal_spec('C4', struct('T', T, 'rho_bar', RHO, 'kappa_bar', 1));
fs.kappa_mode = 'free';               % legacy pin: floats, not targeted
fs.kappa_target = NaN;
o2 = opts; o2.fiscal = fs;
TRn = solve_hank_dtpl_transition(pgc, o2);
tee('  kappa_inf = %.12f\n\n', TRn.kappa_inf);

R = {}; pass = true;
R = cmpp(R, 'tax path tau_t',        TRl, TRn, 'tau_path',  TOL.path);
R = cmpp(R, 'real debt path b_t',    TRl, TRn, 'b_path',    TOL.path);
R = cmpp(R, 'price path Phat_t',     TRl, TRn, 'phat',      TOL.path);
R = cmpp(R, 'nominal stock kappa_t', TRl, TRn, 'kappa_path',TOL.path);
R = cmps(R, 'kappa_inf',             TRl.kappa_inf, TRn.kappa_inf, TOL.kappa);
R = cmps(R, 'tax half-life (yr)',    log(2)/(-log(TRl.rho_d)), ...
                                     log(2)/(-log(TRn.rho_d)), TOL.scalar);
for f = {'dlnP1','impact','front_share','reval_share'}
    if isfield(TRl, f{1}) && isfield(TRn, f{1})
        R = cmps(R, f{1}, TRl.(f{1}), TRn.(f{1}), TOL.scalar);
    end
end

tee('%-24s %18s %18s %12s  %s\n','quantity','legacy','new','discrepancy','verdict');
for i = 1:numel(R)
    r = R{i};
    tee('%-24s %18.10g %18.10g %12.3e  %s\n', r.name, r.a, r.b, r.d, ...
        ternstr(r.pass,'PASS','FAIL'));
    if ~r.pass, pass = false; end
end
tee('\nD11 PARITY: %s\n', ternstr(pass,'PASS','FAIL'));
if ~pass
    tee('The fiscal-specification path is not a faithful generalization of the\n');
    tee('legacy rule. No C1-C4 result may be reported until it is.\n');
end

save(fullfile(projdir,'output','parity_d11_deficit.mat'),'R','pass','TOL','RHO','T');
tee('\n[main_parity_d11_deficit] wrote %s\n', sf);
fclose(fid);

% =====================================================================
function R = cmpp(R, name, A, B, f, tol)
    if ~isfield(A,f) || ~isfield(B,f)
        R{end+1} = struct('name',[name ' (absent)'],'a',NaN,'b',NaN,'d',NaN,'pass',false);
        return;
    end
    a = A.(f)(:); b = B.(f)(:);
    if numel(a) ~= numel(b)
        R{end+1} = struct('name',[name ' (length differs)'],'a',numel(a),'b',numel(b),'d',Inf,'pass',false);
        return;
    end
    d = max(abs(a-b)) / max(max(abs(a)), eps);
    R{end+1} = struct('name',name,'a',norm(a,1),'b',norm(b,1),'d',d,'pass',isfinite(d) && d < tol);
end

function R = cmps(R, name, a, b, tol)
    d = abs(a-b)/max(abs(a), eps);
    R{end+1} = struct('name',name,'a',a,'b',b,'d',d,'pass',isfinite(d) && d < tol);
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
