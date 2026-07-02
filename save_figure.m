function save_figure(fh, name, figdir)
% SAVE_FIGURE  Save a figure to <figdir>/<name>.png (and .fig), creating the
% directory if it does not yet exist.
%
%   fh     : figure handle
%   name   : base file name WITHOUT extension (e.g. 'Figure1')
%   figdir : target directory (e.g. par.figdir = 'figures')

    if nargin < 3 || isempty(figdir), figdir = '.'; end

    % --- Ensure the output directory exists (print/saveas will NOT create it) -
    if ~isempty(figdir) && ~isfolder(figdir)
        [ok, msg] = mkdir(figdir);
        if ~ok
            error('save_figure:mkdir', ...
                  'Could not create figure directory "%s": %s', figdir, msg);
        end
    end

    png = fullfile(figdir, [name '.png']);
    fig = fullfile(figdir, [name '.fig']);

    % --- Save PNG (prefer high-res print, fall back to saveas) ----------------
    try
        print(fh, png, '-dpng', '-r200');
    catch
        try
            print(fh, png, '-dpng', '-r200');
        catch
            saveas(fh, png);
        end
    end

    % --- Also save editable .fig (best effort; never fatal) -------------------
    try
        savefig(fh, fig);
    catch
        % ignore: .fig is optional
    end
end