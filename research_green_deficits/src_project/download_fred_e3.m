function dl = download_fred_e3(apikey, force)
% DOWNLOAD_FRED_E3  Download the daily financial-market series for the E3
% event study / local-projection test of the disinflation prediction, from
% the FRED API (St. Louis Fed) using MATLAB's webread, and write
%   <repo root>/data/fred_e3_daily.csv
% with one row per business day and the columns listed below.
%
% WHAT E3 TESTS. The paper predicts that a credible announcement of a
% permanent, deficit-financed green-investment program is DISINFLATIONARY on
% impact (it raises safe-asset demand and lowers the price level), whereas a
% sticky-price/New-Keynesian view predicts inflation or neutrality. The sign
% of the response of MARKET-IMPLIED EXPECTED INFLATION (breakeven inflation)
% in tight windows around major green-fiscal announcements is the test.
%
% SERIES (FRED codes; daily; from 2003 -- the start of the breakeven series):
%   OUTCOME (expected inflation)
%     T5YIE     5-year breakeven inflation rate            -> be5
%     T10YIE    10-year breakeven inflation rate           -> be10
%     T5YIFR    5-year, 5-year-forward inflation expect.   -> be5y5y  (cleanest
%               long-run expected-inflation measure, least contaminated by
%               near-term energy prices -- the paper's object is a permanent
%               program, so the forward measure is the primary outcome)
%   CONTROLS (to strip the obvious confounds -- Fed, oil, risk)
%     DFII5     5-year TIPS real yield                     -> real5
%     DFII10    10-year TIPS real yield                    -> real10
%     DGS2      2-year nominal Treasury yield              -> ny2
%     DGS10     10-year nominal Treasury yield             -> ny10
%     DCOILWTICO WTI crude oil spot price                  -> oil
%     VIXCLS    CBOE volatility index                      -> vix
%
% Decomposition used downstream: a nominal-yield move = real-yield move +
% breakeven move, so controlling for the SAME-DAY real-yield and oil changes
% isolates the part of the breakeven move that is NOT a repricing of the real
% rate or an energy shock -- the object the theory speaks to.
%
% HONESTY / NO-FABRICATION RULES (identical discipline to download_data.m)
%   * FRED returns "." for a missing daily value; these become NaN and are
%     NEVER interpolated or filled. Business days with no trading are simply
%     absent.
%   * If the API is unreachable or a REQUIRED series (a breakeven) returns no
%     data, the function FAILS LOUDLY (dl.ok=false) with the failing URL.
%   * The API key is NEVER written to disk or the CSV. Pass it as the first
%     argument, or set the environment variable FRED_API_KEY, or place it in
%     an untracked file <repo root>/data/.fred_key (git-ignored).
%
% USAGE (requires internet on the machine running MATLAB)
%   >> download_fred_e3('YOUR_FRED_API_KEY')
%   >> download_fred_e3('YOUR_FRED_API_KEY', true)   % force re-download
%   >> setenv('FRED_API_KEY','...'); download_fred_e3   % key from env
%
% Get a free key at https://fredaccount.stlouisfed.org/apikeys .
% This download cannot run from the assistant's sandbox (FRED is blocked by
% the network policy there); it is designed to run on the user's machine.

    if nargin < 2, force = false; end
    if nargin < 1, apikey = ''; end
    projdir = fileparts(fileparts(mfilename('fullpath')));   % research_green_deficits
    rootdir = fileparts(projdir);                            % repo root
    datadir = fullfile(rootdir, 'data');
    if ~isfolder(datadir), mkdir(datadir); end
    outcsv  = fullfile(datadir, 'fred_e3_daily.csv');
    dl = struct('ok', false, 'csv', outcsv, 'msg', '');

    % ---- resolve the API key (argument > env var > untracked file) ----
    if isempty(apikey), apikey = getenv('FRED_API_KEY'); end
    if isempty(apikey)
        kf = fullfile(datadir, '.fred_key');
        if exist(kf, 'file') == 2, apikey = strtrim(fileread(kf)); end
    end
    if isempty(apikey)
        dl.msg = ['No FRED API key. Pass it as the first argument, set ' ...
                  'FRED_API_KEY, or put it in data/.fred_key .'];
        error('download_fred_e3:nokey', '%s', dl.msg);
    end

    if exist(outcsv, 'file') == 2 && ~force
        dl.ok = true;
        dl.msg = sprintf('E3 data already present at %s (force=true to refresh).', outcsv);
        fprintf('  %s\n', dl.msg);
        return;
    end

    codes    = {'T5YIE','T10YIE','T5YIFR','DFII5','DFII10','DGS2','DGS10','DCOILWTICO','VIXCLS'};
    names    = {'be5','be10','be5y5y','real5','real10','ny2','ny10','oil','vix'};
    required = {'be5','be10','be5y5y'};       % must be non-empty
    start    = '2003-01-01';

    opts = weboptions('Timeout', 60, 'ContentType', 'json');
    base = ['https://api.stlouisfed.org/fred/series/observations' ...
            '?series_id=%s&api_key=%s&file_type=json&observation_start=%s'];

    % master date axis (string keys yyyy-mm-dd) and per-series value maps
    S = containers.Map('KeyType','char','ValueType','any');
    allDates = containers.Map('KeyType','char','ValueType','logical');
    for c = 1:numel(codes)
        url = sprintf(base, codes{c}, apikey, start);
        fprintf('  [FRED] %-10s (%s) ... ', codes{c}, names{c});
        try
            resp = webread(url, opts);
        catch ME
            if any(strcmp(names{c}, required))
                dl.msg = sprintf('required series %s failed: %s (%s)', ...
                    codes{c}, ME.message, url);
                error('download_fred_e3:fetch', '%s', dl.msg);
            end
            fprintf('FAILED (%s) -- optional control, skipped\n', ME.message);
            continue;
        end
        obs = resp.observations;
        if iscell(obs), obs = [obs{:}]; end          % normalize to struct array
        n = numel(obs);
        m = containers.Map('KeyType','char','ValueType','double');
        for k = 1:n
            d = obs(k).date;  v = obs(k).value;
            if ischar(v) || isstring(v)
                vv = str2double(v);                  % "." -> NaN, never filled
            else
                vv = double(v);
            end
            m(d) = vv;
            allDates(d) = true;
        end
        S(names{c}) = m;
        fprintf('%d obs\n', n);
        if any(strcmp(names{c}, required)) && n == 0
            dl.msg = sprintf('required series %s returned 0 observations (%s)', codes{c}, url);
            error('download_fred_e3:empty', '%s', dl.msg);
        end
    end

    % ---- assemble the wide daily table on the union of dates ----
    dts = sort(keys(allDates));
    nd  = numel(dts);
    have = names(ismember(names, keys(S)));
    M = nan(nd, numel(have));
    for j = 1:numel(have)
        m = S(have{j});
        for i = 1:nd
            if isKey(m, dts{i}), M(i,j) = m(dts{i}); end
        end
    end
    T = array2table(M, 'VariableNames', have);
    T = addvars(T, datetime(dts(:), 'InputFormat','yyyy-MM-dd'), ...
                'Before', 1, 'NewVariableNames', 'date');
    T = sortrows(T, 'date');
    writetable(T, outcsv);

    dl.ok = true;
    dl.nrows = height(T);
    dl.cols  = have;
    dl.first = char(T.date(1));  dl.last = char(T.date(end));
    dl.msg = sprintf(['wrote %d daily rows (%s .. %s), columns: %s'], ...
        height(T), dl.first, dl.last, strjoin(have, ', '));
    fprintf('  [saved] %s\n  %s\n', outcsv, dl.msg);
end
