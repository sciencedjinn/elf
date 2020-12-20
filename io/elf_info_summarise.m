function infosum = elf_info_summarise(info, verbose)
% infosum = elf_info_summarise(info, verbose)
% Summarises an image info structure created by elf_info_collect.
%
% Input:
% info - info structure containing exif data
% verbose - 0/1, indicates whether verbose output to the command line is requested
%
% Output:
% infosum - info summary structure
%
% Uses: vesp_info_printsummary

%% check inputs
if nargin < 2, verbose = false; end

%% parameters
numeric_fields_to_read = {'Width', 'Height', 'SamplesPerPixel', 'bpc'};
numeric_fields_to_read_onlyone = [1 1 1 1 1]; % 1 means there will be a warning if more than one unique value is found
matrix_fields_to_read = {'ColorMatrix2'};
matrix_fields_to_read_onlyone = 1;
char_fields_to_read = {'Format', 'Model', 'class'};
char_fields_to_read_onlyone = [1 1 1];

% and then there are several subfields of .DigitalCamera to read
numeric_fields_to_read_dc = {'FNumber', 'ExposureTime', 'ISOSpeedRatings', 'ExposureBiasValue', 'FocalLength'};
numeric_fields_to_read_dc_onlyone = [0 0 0 0 1];
char_fields_to_read_dc = {'ExposureProgram'};
char_fields_to_read_dc_onlyone = 0;

%% Read values and find uniques
for i = 1:length(numeric_fields_to_read)
    thisfield = numeric_fields_to_read{i};
    temp = unique([info.(thisfield)]);
    infosum.(thisfield) = temp;
    
    % these should be all the same, so return a warning if they are not
    if numeric_fields_to_read_onlyone(i) && length(temp)>1
        warning('Field ''%s'' has %d different values across data set: %s.', thisfield, length(temp), num2str(temp));
    end
end

for i = 1:length(matrix_fields_to_read)
    thisfield = matrix_fields_to_read{i};
    if isfield(info, thisfield)
        temp = unique(cat(1, info.(thisfield)), 'rows');
        infosum.(thisfield) = temp;
        if matrix_fields_to_read_onlyone(i) && size(temp, 1) > 1
            warning('Field ''%s'' has %d different values across data set: %s.', thisfield, size(temp, 1), num2str(temp));
        end
    else
        infosum.(thisfield) = [];
    end
end

for i = 1:length(char_fields_to_read)
    thisfield = char_fields_to_read{i};
    if isfield(info, thisfield)
        temp = unique({info.(thisfield)});
        infosum.(thisfield) = temp;
    else
        infosum.(thisfield) = {NaN};
    end
    
    % these should be all the same, so return a warning if they are not
    if char_fields_to_read_onlyone(i) && length(temp)>1
        warning('Field ''%s'' has %d different values across data set.', thisfield, length(temp));
        disp(temp)
    end
end

% Process Camera information
for i = 1:length(numeric_fields_to_read_dc)
    thisfield = numeric_fields_to_read_dc{i};
    if ~isfield(info(1), 'DigitalCamera') || ~isfield(info(1).DigitalCamera, thisfield)
        warning('Field ''DigitalCamera.%s'' does not exist for this camera.', thisfield);
        temp = [];
        infosum.(thisfield) = NaN;
    else
        tempall = arrayfun(@(x) x.DigitalCamera.(thisfield), info);
        temp = unique(tempall);
        infosum.(thisfield) = temp;
    end

    if numeric_fields_to_read_dc_onlyone(i) && length(temp)>1
        warning('Field ''DigitalCamera.%s'' has %d different values across data set: %s.', thisfield, length(temp), num2str(temp));
    end
end

for i = 1:length(char_fields_to_read_dc)
    thisfield = char_fields_to_read_dc{i};
    if isfield(info(1), 'DigitalCamera') && isfield(info(1).DigitalCamera, thisfield)
        tempall = arrayfun(@(x) {x.DigitalCamera.(thisfield)}, info);
        temp = unique(tempall);
        infosum.(thisfield) = temp;
    else
        infosum.(thisfield) = {NaN};
    end
    if char_fields_to_read_dc_onlyone(i) && length(temp)>1
        warning('Field ''DigitalCamera.%s'' has %d different values across data set.', thisfield, length(temp));
        disp(temp)
    end
end

%% Finally, check time information and convert to a Matlab datenum

timefield = 'DateTimeOriginal';
if isfield(info(1), 'DigitalCamera') && isfield(info(1).DigitalCamera, timefield)
    tempall = arrayfun(@(x) datenum(x.DigitalCamera.(timefield), 'yyyy:mm:dd HH:MM:SS'), info);
    infosum.(timefield) = tempall;
else
    infosum.(timefield) = [];
end

%% verbose output
if verbose
    elf_info_printsummary(infosum);
end













