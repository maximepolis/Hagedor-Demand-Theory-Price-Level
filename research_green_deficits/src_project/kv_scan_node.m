function rec = kv_scan_node(q, al, CTX, cachedir, gridkey, force)
% KV_SCAN_NODE  One independent node of the diagnostic residual scan.
%
% This is the unit of parallel work. It takes no state from any other node
% -- no warm start, no continuation -- so the result is a pure function of
% (alpha, q, grids, calibration), which is precisely the condition under
% which running the nodes concurrently is not an approximation but the same
% computation in a different order.
%
% Each node writes ONE file named by the hash of everything it depends on.
% Two consequences that matter more than the speed-up:
%   * a rerun after an unrelated edit is a cache hit, and a rerun after a
%     grid or calibration change is a miss, with no bookkeeping to get wrong;
%   * the file is written atomically (unique temp name, then rename), so a
%     killed run leaves either a complete result or nothing, never a
%     truncated .mat that a later run would silently trust.
%
% The distribution and the value function are NOT stored. Only the scalars
% the scan reports plus the adjuster's k-policy index map, as uint16 -- about
% 2 KB per node instead of several MB, and the index map is what the
% staircase diagnostic needs.
%
% OUTPUT rec .alpha .q .ok .Fk .Fb .P .dV .ddist .mass .ksat .bsat .kocc
%            .bocc .kidx .cached .key

    if nargin < 6, force = false; end
    key = kv_hash(gridkey, al, q);
    f = fullfile(cachedir, ['n_' key(1:24) '.mat']);
    if ~force && exist(f,'file') == 2
        try
            S = load(f, 'rec');
            rec = S.rec; rec.cached = true;
            return;
        catch
            % unreadable cache entry: fall through and recompute
        end
    end

    rec = struct('alpha',al,'q',q,'key',key,'ok',false,'cached',false, ...
                 'Fk',NaN,'Fb',NaN,'P',NaN,'dV',NaN,'ddist',NaN,'mass',NaN, ...
                 'ksat',NaN,'bsat',NaN,'kocc',NaN,'bocc',NaN,'kidx',uint16([]));

    st = kv_solve_bond_given_q(q, al, CTX, []);
    if st.ok
        rec.ok = true;
        rec.Fk = st.Sk - CTX.Kbar;
        rec.Fb = st.Sb - CTX.iota*CTX.Bnom/st.P;
        rec.P = st.P; rec.dV = st.dV; rec.ddist = st.ddist;
        rec.mass = abs(1 - sum(st.dist(:)));
        [rec.ksat, rec.bsat, rec.kocc, rec.bocc] = ...
            kv_boundary_mass(st.dist, CTX.p.kGrid, CTX.p.bGrid);
        kG = CTX.p.kGrid(:);
        idx = discretize(min(max(st.sol.polKa, kG(1)), kG(end)), kG);
        idx(isnan(idx)) = 1;
        rec.kidx = uint16(idx);
    end

    tmp = [tempname(cachedir) '.mat'];
    try
        save(tmp, 'rec', '-v7');
        movefile(tmp, f, 'f');
    catch
        if exist(tmp,'file')==2, delete(tmp); end
    end
end
