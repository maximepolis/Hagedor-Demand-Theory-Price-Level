function dl = download_data(pg, force)
% DOWNLOAD_DATA  Download the cross-country panel for the empirical modules
% (E4) from the World Bank API using MATLAB's webread, and write
%   <repo root>/data/wb_panel.csv
% with columns: country, iso3, year, infl, govcons_nom, rgdp, debt_gdp, co2pc.
%
% INDICATORS (World Bank codes; annual, 1995-2024, all countries):
%   FP.CPI.TOTL.ZG      CPI inflation, %                     -> infl
%   NE.CON.GOVT.CN      gov. final consumption, current LCU  -> govcons_nom
%   NY.GDP.MKTP.KD      real GDP, constant 2015 USD          -> rgdp
%   GC.DOD.TOTL.GD.ZS   central gov. debt, % of GDP          -> debt_gdp
%   EN.ATM.CO2E.PC      CO2 emissions per capita             -> co2pc
%     (if the CO2 code returns empty -- the WB renamed the series in 2024 --
%      the fallback code EN.GHG.CO2.PC.CE.AR5 is tried automatically)
%
% HONESTY / NO-FABRICATION RULES
%   * If the API is unreachable or a series returns no data, the function
%     FAILS LOUDLY (dl.ok = false, with the failing URL); it never fills
%     gaps with synthetic values.
%   * govcons_nom is government CONSUMPTION, not the paper's full
%     expenditure concept (consumption + net capital formation - CFC); the
%     difference is documented in the paper's data appendix and the E4
%     results are labeled accordingly.
%
% USAGE (requires internet on the machine running MATLAB)
%   >> pg = setup_params_green(); dl = download_data(pg);
%   >> dl = download_data(pg, true);   % force re-download
%
% NOTE: this download cannot be run from the assistant's sandbox (the World
% Bank API is blocked there by network policy); it is designed to run on the
% user's machine.

    if nargin < 2, force = false; end
    projdir = fileparts(fileparts(mfilename('fullpath')));
    outcsv  = fullfile(fileparts(projdir), 'data', 'wb_panel.csv');
    dl = struct('ok', false, 'csv', outcsv, 'msg', '');

    if exist(outcsv, 'file') == 2 && ~force
        dl.ok = true;
        dl.msg = sprintf('Panel already present at %s (use force=true to refresh).', outcsv);
        fprintf('  %s\n', dl.msg);
        return;
    end

    codes = {'FP.CPI.TOTL.ZG','NE.CON.GOVT.CN','NY.GDP.MKTP.KD', ...
             'GC.DOD.TOTL.GD.ZS','EN.ATM.CO2E.PC'};
    names = {'infl','govcons_nom','rgdp','debt_gdp','co2pc'};
    co2_fallback = 'EN.GHG.CO2.PC.CE.AR5';

    base = 'https://api.worldbank.org/v2/country/all/indicator/%s?format=json&per_page=20000&date=1995:2024&page=%d';
    opts = weboptions('Timeout', 60, 'ContentType', 'json');

    store = containers.Map('KeyType','char','ValueType','any');  % key: iso3|year
    isoName = containers.Map('KeyType','char','ValueType','char');

    for c = 1:numel(codes)
        code = codes{c};
        got  = fetch_indicator(code);
        if isempty(got) && strcmp(names{c}, 'co2pc')
            fprintf('  [%s empty; trying fallback %s]\n', code, co2_fallback);
            got = fetch_indicator(co2_fallback);
        end
        if isempty(got)
            dl.msg = sprintf('Indicator %s returned no data -- aborting (no fabrication).', code);
            warning('download_data:empty', '%s', dl.msg);
            return;
        end
        for k = 1:numel(got)
            key = got(k).key;
            if ~isKey(store, key), store(key) = nan(1, numel(codes)); end
            v = store(key); v(c) = got(k).value; store(key) = v;
            isoName(got(k).iso3) = got(k).country;
        end
        fprintf('  [downloaded %s: %d observations]\n', names{c}, numel(got));
    end

    % ---- write CSV ----
    keys_ = store.keys;
    fid = fopen(outcsv, 'w');
    fprintf(fid, 'country,iso3,year,infl,govcons_nom,rgdp,debt_gdp,co2pc\n');
    nrows = 0;
    for k = 1:numel(keys_)
        parts = strsplit(keys_{k}, '|');
        iso3 = parts{1}; yr = parts{2};
        v = store(keys_{k});
        fprintf(fid, '"%s",%s,%s,%.6g,%.10g,%.10g,%.6g,%.6g\n', ...
                isoName(iso3), iso3, yr, v(1), v(2), v(3), v(4), v(5));
        nrows = nrows + 1;
    end
    fclose(fid);
    dl.ok = true;
    dl.msg = sprintf('Wrote %d country-year rows to %s.', nrows, outcsv);
    fprintf('  %s\n', dl.msg);

    % ------------------------------------------------------------------
    function out = fetch_indicator(code)
        out = [];
        page = 1; npages = 1;
        while page <= npages
            url = sprintf(base, code, page);
            try
                J = webread(url, opts);
            catch ME
                warning('download_data:web', 'webread failed for %s: %s', code, ME.message);
                out = []; return;
            end
            if ~iscell(J) || numel(J) < 2, out = []; return; end
            meta = J{1}; rows = J{2};
            if isfield(meta, 'pages'), npages = meta.pages; end
            if isstruct(rows)
                for rr = 1:numel(rows)
                    R = rows(rr);
                    if isempty(R.value) || ~isfield(R,'countryiso3code'), continue; end
                    iso3 = R.countryiso3code;
                    if isempty(iso3) || numel(iso3) ~= 3, continue; end  % skip aggregates
                    rec.key     = [iso3 '|' R.date];
                    rec.iso3    = iso3;
                    rec.country = R.country.value;
                    rec.value   = R.value;
                    out = [out; rec]; %#ok<AGROW>
                end
            end
            page = page + 1;
        end
    end
end
