function anaP = elf_analysisPara()

envPath = fullfile(fileparts(mfilename("fullpath")), '..', 'config');
d       = DotEnv(envPath, '');

anaParameters = ...
    {'RESOLUTION_BOOSTER',   'double'};

anaP = d.extractValues('ANALYSIS', anaParameters);
anaP.version = str2double(d.Env.VERSION);

if isempty(anaP.resolutionBooster) || anaP.resolutionBooster ~= round(anaP.resolutionBooster) || anaP.resolutionBooster<=0 || anaP.resolutionBooster>10
    error('Invalid value found for ANALYSIS_RESOLUTION_BOOSTER in %s', fullfile(envPath, '.env'));
end
