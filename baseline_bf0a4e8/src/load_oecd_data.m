function data = load_oecd_data(csvfile)
% LOAD_OECD_DATA  Load and prepare the OECD panel for Figure 5, supporting two
% CSV layouts. Returns country-average inflation and government-expenditure/real-
% GDP growth. Does NOT fabricate data: if the file is missing or unusable the
% caller must skip the figure.
%
% SUPPORTED LAYOUTS
%   (A) Pre-aggregated summary: columns  country, infl, govexp_growth
%       (percent per year, already averaged over the sample). Used as-is.
%   (B) Raw panel: columns  country, year, cpi, real_gdp, and government
%       expenditure either as a single column gov_exp_nominal OR as the paper's
%       components:
%         final_consumption + gross_capital_formation
%         + acquisitions_less_disposals - consumption_fixed_capital.
%       Annual inflation = 100*(cpi_t/cpi_{t-1} - 1);
%       gov-exp ratio     = gov_exp_nominal / real_gdp;
%       ratio growth      = 100*(ratio_t/ratio_{t-1} - 1);
%       country averages are then taken.
%
% INPUT
%   csvfile : path to the CSV.
%
% OUTPUT
%   data : struct with .ok (logical), .country (cellstr), .infl, .gexp
%          (country-average vectors), .layout, .msg.
%
% PAPER SECTION: Figure 5 (empirical, optional).

    data = struct('ok', false, 'country', {{}}, 'infl', [], 'gexp', [], ...
                  'layout', 'none', 'msg', '');

    if exist(csvfile, 'file') ~= 2
        data.msg = sprintf('No data file at "%s".', csvfile);
        return;
    end

    try
        T = readtable(csvfile);
    catch ME
        data.msg = sprintf('Could not read "%s": %s', csvfile, ME.message);
        return;
    end
    vn = lower(T.Properties.VariableNames);

    % ---------- Layout A: pre-aggregated ----------
    if all(ismember({'country','infl','govexp_growth'}, vn))
        data.country = cellstr(string(T.(T.Properties.VariableNames{find(strcmp(vn,'country'),1)})));
        data.infl    = T.(T.Properties.VariableNames{find(strcmp(vn,'infl'),1)});
        data.gexp    = T.(T.Properties.VariableNames{find(strcmp(vn,'govexp_growth'),1)});
        data.layout  = 'A (pre-aggregated averages)';
        data.ok      = true;
        data.msg     = sprintf('Loaded %d countries (layout A) from %s.', ...
                               numel(data.infl), csvfile);
        return;
    end

    % ---------- Layout B: raw panel ----------
    if all(ismember({'country','year','cpi','real_gdp'}, vn))
        getc = @(nm) T.(T.Properties.VariableNames{find(strcmp(vn,nm),1)});
        country = cellstr(string(getc('country')));
        year    = double(getc('year'));
        cpi     = double(getc('cpi'));
        rgdp    = double(getc('real_gdp'));

        if ismember('gov_exp_nominal', vn)
            gexp_nom = double(getc('gov_exp_nominal'));
        elseif all(ismember({'final_consumption','gross_capital_formation', ...
                'acquisitions_less_disposals','consumption_fixed_capital'}, vn))
            gexp_nom = double(getc('final_consumption')) ...
                     + double(getc('gross_capital_formation')) ...
                     + double(getc('acquisitions_less_disposals')) ...
                     - double(getc('consumption_fixed_capital'));
        else
            data.msg = ['Layout B needs gov_exp_nominal OR the four spending ' ...
                        'components (final_consumption, gross_capital_formation, ' ...
                        'acquisitions_less_disposals, consumption_fixed_capital).'];
            return;
        end

        ratio = gexp_nom ./ rgdp;    % nominal gov exp / real GDP

        uc = unique(country, 'stable');
        infl_avg = nan(numel(uc),1);
        gexp_avg = nan(numel(uc),1);
        for k = 1:numel(uc)
            idx = strcmp(country, uc{k});
            yk  = year(idx); [yk, o] = sort(yk);
            ck  = cpi(idx);   ck = ck(o);
            rk  = ratio(idx); rk = rk(o);
            infl_avg(k) = mean(100*(ck(2:end)./ck(1:end-1) - 1), 'omitnan');
            gexp_avg(k) = mean(100*(rk(2:end)./rk(1:end-1) - 1), 'omitnan');
        end
        data.country = uc;
        data.infl    = infl_avg;
        data.gexp    = gexp_avg;
        data.layout  = 'B (raw panel, computed averages)';
        data.ok      = true;
        data.msg     = sprintf('Loaded %d countries (layout B) from %s.', ...
                               numel(uc), csvfile);
        return;
    end

    data.msg = sprintf(['CSV "%s" columns not recognized. Provide layout A ' ...
        '(country,infl,govexp_growth) or layout B (country,year,cpi,real_gdp,' ...
        'gov_exp_nominal|components).'], csvfile);
end
