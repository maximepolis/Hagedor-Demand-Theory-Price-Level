function gd = load_green_budget_data(csvfile)
% LOAD_GREEN_BUDGET_DATA  Loader for Prediction E2 of the paper: the panel of
% government green/climate expenditure with an indexation classification.
% NO DATA ARE FABRICATED: if the file is absent or malformed the function
% returns .ok = false with an explanatory message and the empirical script
% skips E2.
%
% REQUIRED CSV SCHEMA (data appendix, Prediction E2):
%   country            ISO code or name
%   year               calendar year
%   cpi                consumer price index (level)
%   real_gdp           real GDP (level, constant prices)
%   green_exp_nominal  general-government climate/environmental expenditure,
%                      national currency (COFOG 05 + green gross capital
%                      formation); sources: IMF GFS / climate budgeting
%                      database, OECD COFOG, national budget documents
%   indexed_dummy      1 if green appropriations are indexed (real mandates /
%                      GDP-share commitments), 0 for nominal cash budgets
%                      (classification from budget-law texts)
%
% OUTPUT
%   gd : struct with .ok, .msg, and (when ok) .T (the table), .countries,
%        plus per-country averages: .infl_avg, .gexp_growth_avg (growth of
%        green_exp_nominal / real_gdp), .indexed (mode of dummy).

    gd = struct('ok', false, 'msg', '');

    if exist(csvfile, 'file') ~= 2
        gd.msg = sprintf(['No green-budget panel at "%s". Prediction E2 ' ...
            'requires it; see the data appendix for the schema and sources.'], ...
            csvfile);
        return;
    end

    try
        T = readtable(csvfile);
    catch ME
        gd.msg = sprintf('Could not read "%s": %s', csvfile, ME.message);
        return;
    end

    need = {'country','year','cpi','real_gdp','green_exp_nominal','indexed_dummy'};
    vn = lower(T.Properties.VariableNames);
    if ~all(ismember(need, vn))
        gd.msg = sprintf(['"%s" is missing required columns. Needed: %s.'], ...
            csvfile, strjoin(need, ', '));
        return;
    end
    getc = @(nm) T.(T.Properties.VariableNames{find(strcmp(vn, nm), 1)});

    country = cellstr(string(getc('country')));
    year    = double(getc('year'));
    cpi     = double(getc('cpi'));
    rgdp    = double(getc('real_gdp'));
    gexp    = double(getc('green_exp_nominal'));
    idx     = double(getc('indexed_dummy'));

    ratio = gexp ./ rgdp;
    uc = unique(country, 'stable');
    infl_avg = nan(numel(uc),1); gg_avg = nan(numel(uc),1); ind = nan(numel(uc),1);
    for k = 1:numel(uc)
        m  = strcmp(country, uc{k});
        yk = year(m); [~, o] = sort(yk);
        ck = cpi(m);   ck = ck(o);
        rk = ratio(m); rk = rk(o);
        ik = idx(m);
        infl_avg(k) = mean(100*(ck(2:end)./ck(1:end-1) - 1), 'omitnan');
        gg_avg(k)   = mean(100*(rk(2:end)./rk(1:end-1) - 1), 'omitnan');
        ind(k)      = round(mean(ik, 'omitnan'));
    end

    gd.ok = true;
    gd.T = T;
    gd.countries = uc;
    gd.infl_avg = infl_avg;
    gd.gexp_growth_avg = gg_avg;
    gd.indexed = ind;
    gd.msg = sprintf('Loaded green-budget panel: %d countries.', numel(uc));
end
