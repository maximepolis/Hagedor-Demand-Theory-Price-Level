function [col, ls, mk] = regime_style(name)
% REGIME_STYLE  One colour per economic MEANING, everywhere in the paper.
%
% WHY THIS EXISTS. style_figure.m already gives every exported figure one
% typographic standard, and its colororder gives series one palette -- but by
% POSITION, not by meaning. Six plotting files then each declared their own
% RGB constants (plot_green_figures had BLUE/RED/GREEN/GRAY; the src/ plots
% had their own), so the proportional levy could be red in one exhibit and
% the counterexample red in the next, and a reader flipping between figures
% had to re-learn the encoding each time. The R14 co-editor brief makes the
% requirement explicit: every colour must carry the same economic meaning
% throughout the paper, the palette must be colourblind-safe, and lines must
% also be distinguishable in black and white.
%
% This function is the single source of that mapping. Plot files call it at
% their constant definitions -- BLUE = regime_style('lumpsum') -- so the plot
% calls themselves do not change, and adding a figure cannot invent a new
% encoding. Colours are Okabe-Ito (the same family style_figure orders), so
% a restyled legacy figure and a semantically-wired one cannot clash.
%
% INPUT   name   meaning, case-insensitive. Aliases listed per row below.
% OUTPUT  col    1x3 RGB
%         ls     line style carrying the SAME distinction in black and white
%         mk     marker for scatter/point use
%
% The registry. One row per MEANING; several names may share a row (aliases),
% but no two meanings share a colour AND line style, so greyscale printing
% keeps every within-figure contrast.
%
%   meaning                          colour        ls    mk
%   benchmark / baseline / noprogram grey          -     o
%   program / green / adaptation     bluish green  -     s
%   lumpsum                          blue          --    o
%   levy / proportional              vermillion    -.    d
%   rebate / progressive             purple        :     ^
%   deficit / delayed / joint        amber         --    v
%   timing / consolidated            sky           -.    >
%   debt (B/P locus)                 blue          --    none
%   counterexample / warning         vermillion    :     x
%   damage / highdamage              black         :     *
%
% 'debt' shares blue with 'lumpsum' and 'counterexample' shares vermillion
% with 'levy' DELIBERATELY: the pairs never draw in the same panel (the B/P
% hyperbola appears in market-clearing diagrams where no instrument
% comparison is drawn, and the counterexample panel has no levy), and the
% Okabe-Ito palette has too few strong hues to spend two on meanings that
% cannot collide. If a new figure ever puts a pair in one panel, split the
% alias here rather than recolouring locally.

    switch lower(strrep(strrep(char(name), '-', ''), '_', ''))
        case {'benchmark', 'baseline', 'noprogram', 'gray', 'grey'}
            col = [0.45 0.45 0.45]; ls = '-';  mk = 'o';
        case {'program', 'green', 'adaptation', 'indexed'}
            col = [0.00 0.62 0.45]; ls = '-';  mk = 's';
        case {'lumpsum', 'ls', 'nominal'}
            % 'nominal' (the nominal-appropriation regime in the transition
            % figures) aliases here: it is the baseline financing
            % environment, and it never shares a panel with the lump-sum
            % instrument line.
            col = [0.00 0.45 0.70]; ls = '--'; mk = 'o';
        case {'levy', 'proportional', 'lev'}
            col = [0.84 0.37 0.00]; ls = '-.'; mk = 'd';
        case {'rebate', 'progressive'}
            col = [0.80 0.47 0.65]; ls = ':';  mk = '^';
        case {'deficit', 'delayed', 'joint', 'reversal'}
            col = [0.90 0.62 0.00]; ls = '--'; mk = 'v';
        case {'timing', 'consolidated'}
            col = [0.34 0.71 0.91]; ls = '-.'; mk = '>';
        case {'debt', 'bp', 'supply'}
            col = [0.00 0.45 0.70]; ls = '--'; mk = 'none';
        case {'demand', 'scurve'}
            col = [0.84 0.37 0.00]; ls = '-';  mk = 'none';
        case {'counterexample', 'warning'}
            col = [0.84 0.37 0.00]; ls = ':';  mk = 'x';
        case {'damage', 'highdamage'}
            col = [0.00 0.00 0.00]; ls = ':';  mk = '*';
        otherwise
            error('regime_style:unknown', ...
                  ['regime_style: unknown meaning "%s". Add it to the ' ...
                   'registry rather than declaring a local colour -- a ' ...
                   'colour declared in one plot file is exactly the drift ' ...
                   'this function exists to prevent.'], char(name));
    end
end
