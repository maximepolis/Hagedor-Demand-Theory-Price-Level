function dec = self_financing_decomposition(pg, ad2)
% SELF_FINANCING_DECOMPOSITION  Proposition 2: does the green deficit finance
% itself? Compares the no-program steady state (Gg = 0, damages D0) with the
% program steady state (Gg = pg.Gg_nom) under the nominal budget regime, and
% computes the exact decomposition of Definition 2:
%
%   nu = nu_reval + nu_damage,
%   nu_reval  = r*B*(1/P0 - 1/P1) / g_g1      (price-level revaluation),
%   nu_damage = (D0 - D1) / g_g1              (damage dividend),
%
% together with the identity check tau1 - tau0 = g_g1 - r*B*(1/P0 - 1/P1),
% the one-time bondholder levy L = B/P0 - B/P1, and the sweep nu(theta_g).
%
% INPUTS
%   pg  : project params.
%   ad2 : S(tau,D) interpolant at the baseline real rate (reused for every
%         theta_g, since it covers the whole (tau,D) plane).
%
% OUTPUT
%   dec : struct with .base (no-program equilibrium), .prog (program
%         equilibrium), .nu .nu_reval .nu_damage .levy .identity_resid
%         .dtau .dW (welfare change) .sweep (theta_g, nu, components, n_roots).

    r_ss = ad2.r;
    B    = pg.Bnom;

    pol0 = struct('regime','nominal','i_ss',pg.i_ss,'mu',pg.mu, ...
                  'Bnom',B,'Gg_nom',0.0);
    pol1 = struct('regime','nominal','i_ss',pg.i_ss,'mu',pg.mu, ...
                  'Bnom',B,'Gg_nom',pg.Gg_nom);

    % ---- no-program steady state (Gg=0 => D = D_noabatement) ----
    [eq0, out0] = solve_green_steady_state(pg, pol0, ad2);
    if isempty(eq0)
        warning('self_financing_decomposition:base', ...
            'No baseline equilibrium: %s -- decomposition skipped.', out0.msg);
        dec = empty_dec(pg); dec.out_base = out0; return;
    end
    base = eq0(1);      % baseline is unique in the benchmark (checked by caller)

    % ---- program steady state at the benchmark theta_g ----
    [eq1, out1] = solve_green_steady_state(pg, pol1, ad2);
    if isempty(eq1)
        warning('self_financing_decomposition:prog', ...
            'No program equilibrium: %s -- decomposition skipped.', out1.msg);
        dec = empty_dec(pg); dec.out_base = out0; dec.out_prog = out1; return;
    end
    % if multiple, use the LOWEST-P (green boom) equilibrium and flag it
    prog = eq1(1);
    multi_flag = numel(eq1) > 1;

    P0 = base.P;  P1 = prog.P;
    g_g1 = prog.g_real;

    nu_reval  = r_ss * B * (1/P0 - 1/P1) / g_g1;
    nu_damage = (base.D - prog.D) / g_g1;
    nu        = nu_reval + nu_damage;

    dtau  = prog.tau - base.tau;
    ident = dtau - (g_g1 - r_ss*B*(1/P0 - 1/P1));   % should be ~0 (Def. 2)
    levy  = B/P0 - B/P1;                            % one-time bondholder levy
    dW    = prog.W - base.W;

    dec = struct();
    dec.ok = true;
    dec.base = base;  dec.out_base = out0;
    dec.prog = prog;  dec.out_prog = out1;
    dec.multi_program_equilibria = multi_flag;
    dec.nu = nu; dec.nu_reval = nu_reval; dec.nu_damage = nu_damage;
    dec.levy = levy; dec.dtau = dtau; dec.identity_resid = ident;
    dec.dW = dW;

    fprintf('\n[self-financing, Proposition 2]\n');
    fprintf('  baseline: P0=%.4f, D0=%.4f, tau0=%.4f, W0=%.4f\n', ...
            P0, base.D, base.tau, base.W);
    fprintf('  program : P1=%.4f, D1=%.4f, tau1=%.4f, g_g=%.4f, W1=%.4f%s\n', ...
            P1, prog.D, prog.tau, g_g1, prog.W, ...
            ternary(multi_flag, '  [MULTIPLE eq., using green boom]', ''));
    fprintf('  nu = %.3f  (revaluation %.3f + damage dividend %.3f)%s\n', ...
            nu, nu_reval, nu_damage, ternary(nu>=1, '  => FULLY self-financing', ...
            '  => partially self-financing'));
    fprintf('  one-time bondholder levy L = %.4f;  identity resid = %.2e\n', ...
            levy, ident);

    % ---- sweep nu(theta_g): the interpolant is reused, so this is cheap ----
    ths = pg.theta_sweep;
    sw = struct('theta_g', ths, 'nu', nan(size(ths)), ...
                'nu_reval', nan(size(ths)), 'nu_damage', nan(size(ths)), ...
                'n_roots', zeros(size(ths)), 'P1', nan(size(ths)));
    for k = 1:numel(ths)
        polk = pol1; polk.theta_g = ths(k);
        [eqk, outk] = solve_green_steady_state(pg, polk, ad2);
        sw.n_roots(k) = outk.n_roots;
        if ~isempty(eqk)
            pk = eqk(1);
            sw.P1(k)        = pk.P;
            sw.nu_reval(k)  = r_ss*B*(1/P0 - 1/pk.P) / pk.g_real;
            sw.nu_damage(k) = (base.D - pk.D) / pk.g_real;
            sw.nu(k)        = sw.nu_reval(k) + sw.nu_damage(k);
        end
        fprintf('  sweep theta_g=%.2f: n_roots=%d, nu=%.3f\n', ...
                ths(k), sw.n_roots(k), sw.nu(k));
    end
    dec.sweep = sw;
end

% -------------------------------------------------------------------------
function s = ternary(cond, a, b)
    if cond, s = a; else, s = b; end
end

% -------------------------------------------------------------------------
function dec = empty_dec(pg)
% Graceful no-equilibrium return: all fields present, values NaN, ok=false,
% so downstream printing/plotting never crashes.
    ths = pg.theta_sweep;
    dec = struct();
    dec.ok = false;
    dec.base = []; dec.prog = [];
    dec.out_base = []; dec.out_prog = [];
    dec.multi_program_equilibria = false;
    dec.nu = NaN; dec.nu_reval = NaN; dec.nu_damage = NaN;
    dec.levy = NaN; dec.dtau = NaN; dec.identity_resid = NaN; dec.dW = NaN;
    dec.sweep = struct('theta_g', ths, 'nu', nan(size(ths)), ...
                       'nu_reval', nan(size(ths)), 'nu_damage', nan(size(ths)), ...
                       'n_roots', zeros(size(ths)), 'P1', nan(size(ths)));
end
