function T = load_data_template(name, require_complete)
% LOAD_DATA_TEMPLATE  Read one of the calibration data templates and report
% how much of it is filled.
%
% The templates in data/templates are deliberately empty. Nothing may be
% guessed into them: a wrong decimal in a calibration or validation table is
% worse than an empty cell, because an empty cell is visible and a wrong one
% is not. This loader therefore refuses to hand back a PARTIALLY filled
% template to a caller that asked for a complete one, and always reports the
% fill rate so a run cannot quietly proceed on stubs.
%
% name : 'public_liability_balance_sheet' | 'intermediary_payout'
%        | 'wealth_mobility_targets'
% require_complete : if true, error unless every value cell and every source
%        cell is filled.
%
% OUTPUT T.rows (table), T.n_total, T.n_filled, T.complete, T.missing_sources

    if nargin < 2, require_complete = false; end
    here = fileparts(fileparts(mfilename('fullpath')));
    f = fullfile(here, 'data', 'templates', [name '.csv']);
    assert(exist(f,'file')==2, 'template not found: %s', f);

    % strip the leading comment block (lines beginning with #)
    raw = strsplit(fileread(f), newline);
    keep = ~startsWith(strtrim(raw), '#') & ~cellfun(@isempty, strtrim(raw));
    body = strjoin(raw(keep), newline);
    tmp = [tempname '.csv']; fid = fopen(tmp,'w');
    fprintf(fid, '%s', body); fclose(fid);
    rows = readtable(tmp, 'Delimiter', ',', 'TextType', 'string');
    delete(tmp);

    vcol = intersect({'value_ratio_to_income','value_data'}, rows.Properties.VariableNames);
    assert(~isempty(vcol), 'no value column in %s', name);
    v = rows.(vcol{1});
    if isstring(v) || iscellstr(v) %#ok<ISCLSTR>
        filled = ~ismissing(v) & strlength(strtrim(string(v))) > 0;
    else
        filled = ~isnan(v);
    end
    src = rows.source;
    has_src = ~ismissing(src) & strlength(strtrim(string(src))) > 0;

    T = struct('rows', rows, 'n_total', height(rows), ...
               'n_filled', sum(filled), 'complete', all(filled & has_src), ...
               'missing_sources', sum(filled & ~has_src), 'file', f);

    fprintf('[%s] %d/%d values filled', name, T.n_filled, T.n_total);
    if T.missing_sources > 0
        fprintf('; %d filled WITHOUT a source', T.missing_sources);
    end
    fprintf('\n');
    if T.missing_sources > 0
        warning('load_data_template:unsourced', ...
            ['%d filled cells in %s carry no source. Every value must be ' ...
             'traceable to a citable table before it enters a result.'], ...
            T.missing_sources, name);
    end
    if require_complete && ~T.complete
        error('load_data_template:incomplete', ...
            ['%s is %d/%d filled and is required complete here. Fill it ' ...
             'from the cited sources -- do not enter values from memory.'], ...
            name, T.n_filled, T.n_total);
    end
end
