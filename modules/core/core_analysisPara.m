function anaP = core_analysisPara(d)

anaParameters = ...
    {'RESOLUTION_BOOSTER', 'double';
     'TARGET_PROJECTION', 'string';
     'TARGET_AZI_RANGE', 'doublevector';
     'TARGET_ELE_RANGE', 'doublevector';
     'HDIVN_INT', 'double';
     'RANGE_PERC', 'double';
     'COLOUR_CALIB_TYPE', 'string';
     'INT_ANALYSIS_TYPE', 'string';
     'HDR_METHOD', 'string';};

anaP = d.extractValues('ANALYSIS', anaParameters);
anaP.version = str2double(d.Env.VERSION);

if isempty(anaP.resolutionBooster) || anaP.resolutionBooster ~= round(anaP.resolutionBooster) || anaP.resolutionBooster<=0 || anaP.resolutionBooster>10
    error('Invalid value found for ANALYSIS_RESOLUTION_BOOSTER in %s', fullfile(envPath, '.env'));
end
