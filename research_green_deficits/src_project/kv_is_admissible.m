function a = kv_is_admissible(code)
% KV_IS_ADMISSIBLE  One definition of which status codes may be used in a
% sign test, a bracket, an interpolation or a difference.
%
% Admissible means "this is a number the model produced", not "this is a good
% number". BOUNDARY_HIT and DIST_LOOSE are accuracy warnings on a real
% equilibrium; the rest are failures to produce one. Keeping the list here
% rather than repeating strcmp chains at every call site is deliberate: the
% one thing that must never drift in this project is what counts as a
% residual and what counts as a hole in the domain.
    if iscell(code)
        a = cellfun(@kv_is_admissible, code);
        return;
    end
    a = any(strcmp(code, {'OK', 'BOUNDARY_HIT', 'DIST_LOOSE'}));
end
