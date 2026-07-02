function D = load_oecd_data(par)
% LOAD_OECD_DATA  Data for Figure 5 of Hagedorn (2026), fetched from the INTERNET.
%
% Reproduces the empirical object of Figure 5: average annual CPI inflation vs.
% average annual growth of (nominal government expenditure / real GDP), for the
% 34 OECD countries in the paper's endnote 33.
%
% DATA SOURCE (web): World Bank World Development Indicators (WDI) REST API
%   https://api.worldbank.org/v2/country/<ISO3;...>/indicator/<CODE>?format=json
%   - Inflation, consumer prices (annual %)            : FP.CPI.TOTL.ZG
%   - General gov. final consumption expenditure (LCU) : NE.CON.GOVT.CN  (nominal)
%   - GDP (constant LCU)                               : NY.GDP.MKTP.KN  (real)
%   ratio_t   = NomGovExp_t / RealGDP_t
%   growth_t  = ratio_t/ratio_{t-1} - 1   (averaged per country, in percent)
%
% IMPORTANT FIDELITY CAVEAT: the paper uses NIPA Table 3.1 lines (21,39,41,42),
% i.e. final consumption (GP3P) + gross capital formation & net acquisitions of
% nonproduced assets (GP5_K2P) - consumption of fixed capital (GK1R). The WDI
% government measure (final consumption only) is a PROXY and will differ from the
% paper's exact construction. This is flagged in D.is_proxy / D.source.
%
% Resolution order:
%   1. Download fresh from World Bank API (if par.use_web_data == true).
%   2. Else / on failure: read cached local CSV  data/oecd_inflation_govexp.csv.
%   3. Else: generate a clearly-labelled ILLUSTRATIVE PLACEHOLDER (NOT real data).
%
% Returns struct D with fields:
%   country (cellstr ISO3), infl, govexp (percent), is_real, is_proxy, source.

    if ~exist(par.datadir,'dir'), mkdir(par.datadir); end
    cache = fullfile(par.datadir, 'oecd_inflation_govexp.csv');

    iso = {'AUS','AUT','BEL','CAN','CZE','DNK','EST','FIN','FRA','DEU', ...
           'GRC','HUN','ISL','IRL','ISR','ITA','JPN','KOR','LVA','LUX', ...
           'MEX','NLD','NZL','NOR','POL','PRT','SVK','SVN','ESP','SWE', ...
           'CHE','TUR','GBR','USA'};   % 34 OECD countries (paper endnote 33)

    %% ---------- 1. Try direct download from the internet -------------------
    if isfield(par,'use_web_data') && par.use_web_data
        try
            D = fetch_from_worldbank(iso, par);
            % cache for reproducibility / offline reruns
            try
                T = table(D.country(:), D.infl(:), D.govexp(:), ...
                          'VariableNames', {'country','infl','govexp_growth'});
                writetable(T, cache);
                fprintf('load_oecd_data: cached web data to %s\n', cache);
            catch ME
                warning('load_oecd_data: could not cache CSV (%s).', ME.message);
            end
            return;
        catch ME
            warning(['load_oecd_data: web download failed (%s). ', ...
                     'Falling back to cache/placeholder.'], ME.message);
        end
    end

    %% ---------- 2. Fall back to a local cached CSV -------------------------
    if exist(cache, 'file')
        T = readtable(cache);
        D.country  = cellstr(string(T.country));
        D.infl     = T.infl;
        D.govexp   = T.govexp_growth;
        D.is_real  = true;
        D.is_proxy = true;     % cache came from the WDI proxy (or a user CSV)
        D.source   = ['local cache: ' cache ' (web/WDI proxy or user-supplied)'];
        fprintf('load_oecd_data: loaded cached data from %s\n', cache);
        return;
    end

    %% ---------- 3. Last resort: clearly-labelled placeholder --------------
    warning(['load_oecd_data: no web data and no cache. Generating an ', ...
             'ILLUSTRATIVE PLACEHOLDER (NOT the paper''s data).']);
    rng(20260224,'twister');                  % reproducible placeholder
    n = numel(iso);
    g = 3 + 2.0*randn(n,1); g = max(g, 0.1);  % synthetic gov.exp/GDP growth (%)
    D.country  = iso(:);
    D.govexp   = g;
    D.infl     = max(g + 0.6*randn(n,1), 0);  % ~45-degree, corr ~ 0.93 by design
    D.is_real  = false;
    D.is_proxy = true;
    D.source   = 'ILLUSTRATIVE PLACEHOLDER (synthetic, not real data)';
end

% =========================================================================
function D = fetch_from_worldbank(iso, par)
% Download CPI inflation, nominal gov. consumption and real GDP from WDI, then
% build the Figure-5 variables per country (averages over each country's sample).

    ds = par.wb_date_start;  de = par.wb_date_end;

    fprintf('load_oecd_data: downloading World Bank WDI (%d-%d) for %d countries...\n', ...
            ds, de, numel(iso));

    cpi = fetch_wb_indicator('FP.CPI.TOTL.ZG', iso, ds, de, par); % inflation %
    gov = fetch_wb_indicator('NE.CON.GOVT.CN', iso, ds, de, par); % nominal gov (LCU)
    gdp = fetch_wb_indicator('NY.GDP.MKTP.KN', iso, ds, de, par); % real GDP (const LCU)

    country = {}; infl = []; govexp = [];
    for k = 1:numel(iso)
        c = iso{k};
        if ~isKey(cpi,c) || ~isKey(gov,c) || ~isKey(gdp,c), continue; end

        % --- average CPI inflation over available years ---
        ci = cpi(c);
        mi = isfinite(ci.val);
        if ~any(mi), continue; end
        avg_infl = mean(ci.val(mi));

        % --- ratio = nominal gov exp / real GDP, then average annual growth ---
        gv = gov(c);  gd = gdp(c);
        [yr, ig, id] = intersect(gv.yr, gd.yr);
        gval = gv.val(ig);  dval = gd.val(id);
        good = isfinite(gval) & isfinite(dval) & (dval ~= 0) & (gval > 0);
        yr = yr(good);  ratio = gval(good) ./ dval(good);
        if numel(ratio) < 3, continue; end
        [yr, srt] = sort(yr);  ratio = ratio(srt);
        gth = ratio(2:end) ./ ratio(1:end-1) - 1;     % annual growth of the ratio
        avg_g = 100 * mean(gth);                      % percent

        country{end+1,1} = c;       %#ok<AGROW>
        infl(end+1,1)    = avg_infl; %#ok<AGROW>
        govexp(end+1,1)  = avg_g;    %#ok<AGROW>
    end

    if isempty(country)
        error('fetch_from_worldbank: no usable country series returned.');
    end

    D.country  = country;
    D.infl     = infl;
    D.govexp   = govexp;
    D.is_real  = true;
    D.is_proxy = true;   % WDI gov-consumption proxy differs from paper's NIPA def
    D.source   = sprintf(['World Bank WDI API (FP.CPI.TOTL.ZG, NE.CON.GOVT.CN, ', ...
                          'NY.GDP.MKTP.KN), %d-%d; PROXY for paper NIPA definition'], ds, de);
    fprintf('load_oecd_data: built Figure-5 variables for %d/%d countries from WDI.\n', ...
            numel(country), numel(iso));
end

% =========================================================================
function M = fetch_wb_indicator(code, iso, ds, de, par)
% Fetch one WDI indicator for a list of ISO3 countries in a single API call.
% Returns containers.Map: ISO3 -> struct('yr',[],'val',[]) sorted ascending.

    opts = weboptions('ContentType','json','Timeout',par.web_timeout, ...
                      'HeaderFields',{'Accept','application/json'});
    base = 'https://api.worldbank.org/v2/country/';
    url  = [base, strjoin(iso,';'), '/indicator/', code, ...
            sprintf('?format=json&per_page=20000&date=%d:%d', ds, de)];

    resp = webread(url, opts);

    % WB JSON top level is [pageInfo, observationsArray] -> MATLAB 1x2 cell.
    if iscell(resp) && numel(resp) >= 2
        obs = resp{2};
    elseif isstruct(resp)
        obs = resp;     % some MATLAB versions return the struct array directly
    else
        error('fetch_wb_indicator: unexpected JSON structure for %s.', code);
    end
    if isempty(obs)
        error('fetch_wb_indicator: empty response for %s.', code);
    end

    % robustly extract iso3, year, value across struct-array shapes
    n = numel(obs);
    isoc = cell(n,1); yr = nan(n,1); val = nan(n,1);
    for k = 1:n
        o = obs(k);
        if isfield(o,'countryiso3code'), isoc{k} = char(o.countryiso3code);
        elseif isfield(o,'country') && isfield(o.country,'id'), isoc{k} = char(o.country.id);
        else, isoc{k} = ''; end
        if isfield(o,'date'), yr(k) = str2double(o.date); end
        if isfield(o,'value') && ~isempty(o.value) && isnumeric(o.value)
            val(k) = double(o.value);
        end
    end

    M = containers.Map('KeyType','char','ValueType','any');
    for k = 1:numel(iso)
        c = iso{k};
        sel = strcmpi(isoc, c) & isfinite(yr);
        if ~any(sel), continue; end
        yk = yr(sel); vk = val(sel);
        [yk, srt] = sort(yk); vk = vk(srt);
        M(c) = struct('yr', yk, 'val', vk);
    end
end