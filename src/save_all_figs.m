function save_all_figs(fh, name, params)
% SAVE_ALL_FIGS  Save a figure to .fig, .png and .pdf in params.figdir.
%
% INPUTS
%   fh     : figure handle.
%   name   : base filename WITHOUT extension (e.g. 'Figure1_asset_market').
%   params : struct from setup_params (uses params.figdir).
%
% Robust to older/newer MATLAB: prefers exportgraphics (R2020a+) for png/pdf,
% falls back to print/saveas. Never fatal on the .fig save.

    figdir = params.figdir;
    if ~isfolder(figdir)
        mkdir(figdir);
    end
    png = fullfile(figdir, [name '.png']);
    pdf = fullfile(figdir, [name '.pdf']);
    figf = fullfile(figdir, [name '.fig']);

    % PNG + PDF
    if exist('exportgraphics', 'file') == 2
        try
            exportgraphics(fh, png, 'Resolution', 200);
            exportgraphics(fh, pdf, 'ContentType', 'vector');
        catch
            print(fh, png, '-dpng', '-r200');
            try, print(fh, pdf, '-dpdf', '-bestfit'); catch, end
        end
    else
        print(fh, png, '-dpng', '-r200');
        try
            set(fh, 'PaperPositionMode', 'auto');
            print(fh, pdf, '-dpdf', '-bestfit');
        catch
        end
    end

    % editable .fig (optional)
    try
        savefig(fh, figf);
    catch
    end
end
