classdef StatusColour
    % Enumeration class representing the status colours for the ELF GUI
    %
    % To see all valid values, use enumeration('StatusColour')

    properties
        Prio
        RGB
    end

    methods
        function c = StatusColour(prio, rgb)
            c.Prio = prio; c.RGB = rgb;
        end

        function sc = combine(sc1, sc2)
            if sc1.Prio>=sc2.Prio
                sc = sc1;
            else
                sc = sc2;
            end
        end
    end

    methods (Static)
        function sca = prealloc(sz, val)
            if nargin<2, val = StatusColour.Bad; end
            sca = repmat(val, sz);
        end
    end

    enumeration
        Good       (0, [0,  1, 0])
        Problem    (1, [1, .6, 0])
        Incomplete (2, [0, .5, 0])
        Bad        (3, [1,  0, 0])
    end
end