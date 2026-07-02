function fh = plot_real_tax_rule(res_unique, res_multi, params)
% PLOT_REAL_TAX_RULE  Figure 3 replication: asset-market equilibrium under a
% REAL tax rule, where inflation (hence the real rate) depends on the price
% level. Shows one case with a UNIQUE equilibrium and one with MULTIPLE /
% non-unique equilibria.
%
% For a real tax rule the equilibrium price level solves
%       F(P) = S( r(P) ) - B/P = 0,   1+pi(P) = 1 + i^ss - (P/B) tau^*.
% We plot F(P) against P; each zero crossing is an equilibrium price level.
%
% INPUTS (each a struct with fields .Pgrid, .resid, .roots)
%   res_unique : the unique-root case.
%   res_multi  : the multi-root (or non-unique) case.
%   params     : setup_params struct.
%
% OUTPUT
%   fh : figure handle (saved as Figure3_real_tax_rule.{fig,png,pdf}).
%
% PAPER SECTION: Figure 3.

    fh = figure('Name','Figure 3: Real tax rule', ...
                'Color','w','Position',[100 100 1000 420]);

    panels = {res_unique, res_multi};
    titles = {'(a) Unique equilibrium', '(b) Possible multiplicity'};
    colr   = {[0.10 0.30 0.75], [0.60 0.20 0.55]};

    for pnl = 1:2
        res = panels{pnl};
        subplot(1,2,pnl); hold on; box on;
        plot(res.Pgrid, res.resid, '-', 'LineWidth',2, 'Color',colr{pnl});
        plot([min(res.Pgrid) max(res.Pgrid)], [0 0], 'k--', 'LineWidth',1);
        rts = getfield_default(res, 'roots', []);
        for k = 1:numel(rts)
            plot(rts(k), 0, 'o', 'MarkerFaceColor',[0.85 0.20 0.15], ...
                 'MarkerEdgeColor','k','MarkerSize',8);
            text(rts(k), 0, sprintf('  P*=%.3f', rts(k)), 'FontSize',9);
        end
        xlabel('price level  P'); ylabel('residual  F(P)=S(r(P)) - B/P');
        title(sprintf('%s (%d root(s))', titles{pnl}, numel(rts)));
    end

    save_all_figs(fh, 'Figure3_real_tax_rule', params);
end

% -------------------------------------------------------------------------
function v = getfield_default(s, f, d)
    if isfield(s, f), v = s.(f); else, v = d; end
end
