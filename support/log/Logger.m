classdef Logger < handle
    % LOGGER handles log messages for the COcPIT software
    
    properties (Constant)
        S = LogSettings
    end
    
    methods
        %% constructor
        function obj = Logger()
            
        end
    end
    
    %% public static methods    
    methods (Static)
        function setLevel(newLevel)
             h = Logger.S;
             h.Level = newLevel;
        end
        
        function setDest(newDest)
             h = Logger.S;
             h.Dest = newDest;
        end
        
        function log(level, str, varargin)
            %%

            % currently, this function directly uses fprintf. In the future, there
            % should be an option in para to save everything to a file instead.

            d = dbstack;
%             [~, callingName] = fileparts(d(2).file);    % fileparts(d(2).file) just gives the filename
            callingName = d(2).name;                    % d(2).name can give the method/function name 
            
            if level>=Logger.S.Level
                if strncmp(str, "\b", 1)
                    % if the string start with a backspace, don't print the header
                    s = str;
                else
                    s = sprintf('[%s] [ %5s ] %-35s: %s', datestr(now, 'HH:MM:SS.FFF'), char(level), callingName, str);
                end

                if isnumeric(Logger.S.Dest) && Logger.S.Dest==1
                    % sending to standard out
                    fprintf(Logger.S.Dest, s, varargin{:});
                elseif isnumeric(Logger.S.Dest)
                    % sending to file
                    try
                        fprintf(Logger.S.Dest, s, varargin{:});
                    catch me
                        % writing to file failed, write to standard out and change Dest
                        warning(me.identifier, 'Writing to file failed with error message: %s', me.message);
                        Logger.setDest(1);
                        fprintf(Logger.S.Dest, s, varargin{:});
                    end
                elseif isa(Logger.S.Dest, 'matlab.ui.control.TextArea')
                    s1 = sprintf(s, varargin{:});

                    ta = Logger.S.Dest;
                    currentText = ta.Value;
                    % shorten log every now and then to keep memory in check
                    if length(currentText)>150
                        currentText = currentText(end-100:end);
                    end
                    textToAdd = split([s1 s2], newline);
                    if isempty(textToAdd{end})
                        textToAdd = textToAdd(1:end-1);
                    end
                    ta.Value = [currentText;textToAdd];
                    scroll(ta, 'bottom')
                else
                    Logger.S.Dest
                end
            end
        end
    end
end

