function [mods, anap, plotp] = elf_modules_addWithDependencies(mods)
    % ELF_MODULES_ADDWITHDEPENDENCIES loads the desired modules (if installed) and their dependencies
    %   If a field is present in more than one .env file, the modules that are listed first in "mods" are prioritised.
    %   The "core" module is always added as a last dependency.
    %
    % Inputs:
    %   mods  - cell array of module names
    %
    % Outputs:
    %   mods  - cell array of module names with new dependencies added
    %   anaP  - analysis parameter structure, combined for all modules
    %   plotP - plotting parameter structure, combined for all modules

    % Step 1: Collect all modules, their dependencies, and their .env files
    i = 1;
    d = {};
    while i<=length(mods)
        [mods, d{i}] = loadEnvAndAddDependencies(mods, i);
        i = i + 1;
    end
    if ~ismember('core', mods)
        mods = [mods, {'core'}];
        [mods, d{end+1}] = loadEnvAndAddDependencies(mods, length(mods));    
    end

    % Step 2: Combine .env files, with earlier modules having higher priority
    d_comb = DotEnv.combineDotEnvs(d);

    % Step 3: Extract parameters using each module's read-functions (if they exist)
    anap = [];
    plotp = [];
    for i = 1:length(mods)
        [anap, plotp] = evaluateEnv(anap, plotp, mods{i}, d_comb);
    end
end

function [mods, d] = loadEnvAndAddDependencies(mods, i)
    % Loads the .env file for the "i"'th module in cell array "mods", and adds the dependencies to the end of "mods"
    %
    % Inputs:
    %   mods - cell array of module names
    %   i - index of the module to load
    %
    % Outputs:
    %   mods - cell array of module names with new dependencies added
    %   d    - DotEnv object for the information loaded from the .env file

    d = loadDotEnv(mods{i});
    deps = d.get('DEPENDENCIES', 'charvector');
    for j = 1:length(deps)
        if ~ismember(deps{j}, mods) % only load NEW dependencies
            mods = [mods, deps(j)]; %#ok<AGROW>
        end
    end
end

function d = loadDotEnv(modName)
    % Loads the .env file for a module from its default location
    % File location example for the module TEST
    %   TEST.env should be in elf/config/
    %   TEST_defaults.env should be in elf/modules/TEST/
    %
    % Inputs:
    %   modName - string with the module name
    %
    % Outputs:
    %   d - DotEnv object for the information loaded from the .env file

    if modName == "core"
        envFilename = '';
    else
        envFilename = modName;
    end
    envPath     = fullfile(fileparts(mfilename("fullpath")), '..', 'config');
    defFilename = [modName '_defaults'];
    defPath     = fullfile(fileparts(mfilename("fullpath")), modName);
    try
        d = DotEnv.fromFiles(envPath, envFilename, defPath, defFilename);
    catch me
        error("Module ""%s"" could not be found or is corrupted (%s)", modName, me.message);
    end
end

function [anaP, plotP] = evaluateEnv(anaP, plotP, modName, d)
    % Evaluates the DotEnv object using a module's _plottingPara and _analysisPara functions (if present)
    %
    % Inputs:
    %   mods - cell array of module names
    %   i - index of the module to load
    %
    % Outputs:
    %   anaP  - analysis parameter structure, combined for all modules
    %   plotP - plotting parameter structure, combined for all modules

    modPlotFilename = [modName '_plottingPara'];
    if ~isempty(which(modPlotFilename))
        modPlotP = feval(modPlotFilename, d);
        if ~isempty(modPlotP)
            plotP = compStruct(plotP, modPlotP, '', false);
        end
    end

    modAnaFilename = [modName '_analysisPara'];
    if ~isempty(which(modAnaFilename))
        modAnaP = feval(modAnaFilename, d);
        if ~isempty(modAnaP)
            anaP = compStruct(anaP, modAnaP, '', false);
        end
    end
end