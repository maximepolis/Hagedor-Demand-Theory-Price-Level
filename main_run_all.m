function R = main_run_all()
% MAIN_RUN_ALL  Master script: full replication of Hagedorn (2026), "A Demand
% Theory of the Price Level" (IER). Runs from start to finish without manual input.
%
% Pipeline:
%   1. parameters         (parameters_baseline)
%   2. asset-demand curve S(1+r)               (Section 2.4, Eq.12; Fig.1)
%   3. baseline price level P*=B/S             (Section 3.1-3.3, Eq.22)
%   4. complete-markets indeterminacy          (Section 3.4, Fig.2b)
%   5. nominal & real tax rules                (Section 3.5, Fig.3)
%   6. DTPL vs FTPL                            (Section 3.5/App.B)
%   7. capital, money, nominal-G extensions    (Sections 3.6-3.8, Fig.4)
%   8. reproduce all figures                   (Fig.1-5)
%   9. validation report + status matrix
%  10. save output/results.mat

    t0 = tic;
    fprintf('==============================================================\n');
    fprintf(' Hagedorn (2026) "A Demand Theory of the Price Level" -- replication\n');
    fprintf('==============================================================\n');

    par = parameters_baseline();
    
    % --- Ensure all output directories exist before anything writes to them -----
    for d = {par.outdir, par.figdir, par.datadir}
        if ~isempty(d{1}) && ~isfolder(d{1}), mkdir(d{1}); end
    end
    if ~exist(par.outdir,'dir'), mkdir(par.outdir); end
    if ~exist(par.figdir,'dir'), mkdir(par.figdir); end
    if ~exist(par.datadir,'dir'), mkdir(par.datadir); end

    % --- core object: steady-state asset-demand curve ---
    ad = asset_demand_curve(par);

    % --- main results ---
    R.par = par;
    R.ad  = ad;
    R.baseline = compute_price_level_nominal_bonds(par, ad);
    R.cm       = complete_markets_comparison(par, ad);
    R.ntr      = nominal_tax_rules(par, ad);
    R.rtr      = real_tax_rules(par, ad);
    R.ftpl     = ftpl_comparison(par, ad);
    R.cap      = capital_extension(par);
    R.money    = money_demand_extension(par, ad);
    R.gov      = nominal_government_expenditure_extension(par, ad);

    % --- figures and validation ---
    reproduce_figures(par, ad, R);
    validation_report(par, ad, R);

    % --- save ---
    save(fullfile(par.outdir,'results.mat'), 'R', '-v7.3');

    fprintf('\nDONE in %.1f s. Outputs in %s/ and %s/.\n', toc(t0), par.outdir, par.figdir);
end