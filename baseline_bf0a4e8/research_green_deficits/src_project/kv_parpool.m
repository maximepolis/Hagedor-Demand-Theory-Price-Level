function nw = kv_parpool(want, nworkers, threads1, tee, addpaths)
% KV_PARPOOL  Bring up a parallel pool if one is wanted and available.
% Returns the worker count, or 0 for "run serially".
%
% MATLAB executes parfor as an ordinary for-loop when there is no pool, so
% every caller stays correct without a pool -- this only decides whether the
% work is spread, never what is computed.
%
% Worker compute threads default to 1. Without that, N workers each run
% multithreaded BLAS on the same cores and oversubscribe: the household
% solve is dense-linear-algebra heavy, so N processes x M threads on M cores
% can be slower than the serial run. One thread per worker keeps the
% arithmetic where the parallelism actually is, across independent nodes.
    if nargin < 3 || isempty(threads1), threads1 = true; end
    if nargin < 4 || isempty(tee), tee = @(varargin) fprintf(varargin{:}); end
    if nargin < 5, addpaths = {}; end
    nw = 0;
    if ~want, return; end
    if isempty(ver('parallel'))
        tee('  (no Parallel Computing Toolbox: running the scan serially)\n');
        return;
    end
    try
        pool = gcp('nocreate');
        if isempty(pool)
            if isempty(nworkers), pool = parpool('local');
            else,                 pool = parpool('local', nworkers);
            end
        end
        nw = pool.NumWorkers;
        % Do not rely on workers inheriting the client path. A worker that
        % cannot see src_project fails with "undefined function" halfway
        % through a long run, which is the most expensive way to discover a
        % path problem.
        for i = 1:numel(addpaths)
            try
                parfevalOnAll(@addpath, 0, genpath(addpaths{i}));
            catch
                tee('  (could not push %s to the workers)\n', addpaths{i});
            end
        end
        if threads1
            try
                parfevalOnAll(@maxNumCompThreads, 0, 1);
            catch
                tee('  (could not pin worker threads to 1; expect oversubscription)\n');
            end
        end
    catch ME
        tee('  (parpool failed: %s -- running serially)\n', ME.message);
        nw = 0;
    end
end
