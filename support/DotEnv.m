classdef DotEnv
    % DotEnv reads and handles .env files in the format used by ScienceDjinn's programs (e.g. elf, cocpit)
    %
    % .env file parsing was inspired by MathWorks's implementation, https://github.com/mathworks/dotenv-for-MATLAB

    properties (SetAccess = immutable)
        Env
        EnvDef
    end

    %%%%%%%%%%%%%%%%%
    %% Constructor %%
    %%%%%%%%%%%%%%%%%

    methods
        function obj = DotEnv(envFolder, envFilename)
            % DotEnv reads and handles .env files in the format used by ScienceDjinn's programs (e.g. elf, cocpit)
            % obj = DotEnv(envFolder, envFilename)
            %
            % Inputs:
            %   envFolder - relative or absolute path to the environment file folder (default: current working directory)
            %   envFileName - filename (without extension) to read. '.env'-extension is automatically added (default: '')
            %
            % Examples: 
            %   e = DotEnv(fullfile(rootFolder, 'config'), '') loads '.env' from /rootfolder/config
            %   e = DotEnv('', 'devices') loads 'devices.env' from the current working directory
            

            if nargin<2, envFilename = ''; end
            if nargin<1, envFolder = pwd; end

            envFullFilename = fullfile(envFolder, [envFilename '.env']);
            defFullFilename = fullfile(envFolder, 'defaults', [envFilename '_defaults.env']);

            % load _example.env file
            if isfile(defFullFilename)
                obj.EnvDef = DotEnv.parseFile(defFullFilename);
            else
                error('.env example file was not found in expected path: %s', defFullFilename);
            end

            % load .env file
            if isfile(envFullFilename)
                obj.Env = DotEnv.parseFile(envFullFilename);
            else
                % if the env file does not exist, copy the example file
                [status, msg] = copyfile(defFullFilename, envFullFilename);
                if status == 0
                    % copying was unsuccessful
                    error('.env file was not found in expected path, and copying the example file was unsuccessful with error message: %s', msg)
                else
                    fprintf('.env file was not found in expected path. Example was used and copied.\n')
                end
                obj.Env = DotEnv.parseFile(envFullFilename);
            end

            % Check whether any fields are missing. If so, just copy them from the example file
            obj.Env = compStruct(obj.Env, obj.EnvDef);
        end
    end

    %%%%%%%%%%%%%%%%%%%%
    %% PUBLIC METHODS %%
    %%%%%%%%%%%%%%%%%%%%

    methods
        function val = get(obj, key, conversionType)
            % DotEnv.get returns the value of a key in the environment file after converting it to a desired type
            % val = get(obj, key, [conversionType])
            %
            % Inputs:
            %   key - string describing the key of the field
            %   conversionType - variable type to convert the value to
            %       List of valid conversionType values:
            %           ''              - return the key directly, as a string
            %           'char'          - convert to a char vector
            %           'double'        - convert to a double
            %           'doublevector'  - convert to a vector of doubles
            %           'charvector'    - convert to a cell array of char vectors
            %           'logical'       - convert to a logical
            %
            % Example:
            %   val = myEnvObject.get('DEVICE_ADDRESS', 'double');

            % defaults
            if nargin<3, conversionType = ''; end % return the value without conversion

            % get the value of the desired key, as a string
            if isfield(obj.Env, key)
                val = obj.Env.(key); 
            else
                val = "";
            end

            % now convert to desired type
            switch conversionType
                case {'', 'string'}
                    val = val;
                case {'char', 'c'}
                    val = char(val);
                case {'double', 'number', 'numeric'}
                    val = str2double(val);
                case {'doublevector', 'doublematrix', 'vector'}
                    temp = textscan(val, '%f');
                    val = temp{1};
                case {'charvector', 'charmatrix'}
                    temp = textscan(val, '%s');
                    val = temp{1};
                case {'logical', 'bool', 'boolean'}
                    val = logical(str2double(val));
                otherwise
                    error('Unknown conversionType: %s', conversionType);
            end
        end

        function p = extractValues(obj, prefix, extMat)
            % DotEnv.extractValues extracts several keys from the environment file after converting them to a desired type; returns a struct
            % p = extractValues(obj, prefix, extMat)
            %
            % Inputs:
            %   prefix - prefix string that leads every fieldname to be extracted, but is not included in the output struct field names
            %            Usually used to denote a module or device name.
            %   extMat - cell array of keys to extract; column 1 has key names, column 2 conversion types. Each key is saved in a field in p named as
            %            the key name in camel case; e.g. field "IP_ADDRESS_FOR_WEBSITE" is stored in p.ipAddressForWebsite
            %
            % Examples:
            %   p = extractValues(obj, '', {'MY_KEY_1', 'double'; 'MY_KEY_2, 'char'})
            %       stores 'MY_KEY_1' in p.myKey1 as a double, and 'MY_KEY_2' in p.myKey2 as a char vector
            %   p = extractValues(obj, 'MODULE_1', {'MY_KEY_1', 'double'; 'MY_KEY_2, 'char'})
            %       stores 'MODULE_1_MY_KEY_1' in p.myKey1 as a double, and 'MODULE_1_MY_KEY_2' in p.myKey2 as a char vector

            for i = 1:size(extMat, 1)
                fieldName = extMat{i, 1};
                conversionType = extMat{i, 2};

                if isempty(prefix)
                    fieldNameOld = fieldName;
                else
                    fieldNameOld = [upper(prefix) '_' fieldName];
                end
                fieldNameNew = obj.snake2camel(fieldName);
                try
                    p.(fieldNameNew) = obj.get(fieldNameOld, conversionType);
                catch me
                    fprintf('Error converting key %s\n', fieldNameOld);
                    rethrow(me)
                end
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%
    %% Static methods %%
    %%%%%%%%%%%%%%%%%%%%

    methods (Static)
        function env = parseFile(fname)
            % DotEnv.parseFile reads and parses an environment file and returns a structure with all key values
            % env = DotEnv.parseFile(fname)
            %
            % fname - absolute or relative path to the environment file
            
            % ensure we can open the file
            try
                fid = fopen(fname, 'r');
                assert(fid ~= -1);
            catch
                throw(MException('DOTENV:CannotOpenFile', "Cannot open file: " + fname + ". Code: " + fid));
            end
            fclose(fid);
            
            % load the .env file with name=value pairs into the 'env' struct
            lines = string(splitlines(fileread(fname)));

            % remove comments
            comments = startsWith(lines, '#');
            lines(comments) = [];
                   
            expr = "(?<key>.+?)=(?<value>.*)";
            kvpair = regexp(lines, expr, 'names');
            
            % Deal with single entry case where regexp does not return a cell array
            if iscell(kvpair)
                kvpair(cellfun(@isempty, kvpair)) = [];
                kvpair = cellfun(@(x) struct('key', x.key, 'value', x.value), kvpair);
            end
            
            env = cell2struct(strtrim({kvpair.value}), [kvpair.key], 2);
        end

        function c = snake2camel(s)
            % DotEnv.snake2camel turns a snake case variable name ('A_VARIABLE_NAME') into a camel case one ('aVariableName')
            
            % Replace every underscore with an extra CapitalLetter
            [c, rest] = strtok(lower(s), '_');
            while ~isempty(rest)
                [newC, rest] = strtok(rest, '_'); %#ok<STTOK> 
                if ~isempty(newC)
                    newC(1) = upper(newC(1));
                end
                c = [c newC]; %#ok<AGROW> 
            end
        end
    end

end