function sets = elf_hdr_brackets(rawinfo, verbose)
% ELF_HDR_BRACKETS detects the bracketing sets in the input images.
% The function assumes that bracketing sets are CONSECUTIVE images (not necessarily consecutively NUMBERED images) 
% with a pattern of exposure bias values that repeats throughout the set. If a brackets.info file exists in the
% main data folder, the bracketing information in that file is used instead.
%
% Inputs:
%   info - 1 x n info structure, containing the exif information of the raw image files (created by elf_info_collect)
% Outputs:
%   sets - m x 2 double, containing the numbers of the first and last image of each bracket
% 
% Call sequence: elf -> elf_main3_summary -> elf_hdr_brackets
%
% See also: elf_main3_summary, elf_info_collect

if nargin<2, verbose = true; end

%% Step 0: If brackets.info exist in the folder, read it and use that information
bracketfile = fullfile(fileparts(rawinfo(1).Filename), 'brackets.info');
if exist(bracketfile, 'file')
    sets = dlmread(bracketfile);
    return;
end

%% Step 1: extract all exposure bias values
try
    ev = arrayfun(@(x) x.DigitalCamera.ExposureBiasValue, rawinfo);
catch me
    warning('ELF:hdr:BracketingFailed', 'Exposure bracketing could not be detected due to missing or corrupt exif information. Images will be assumed to be independent (i.e. no bracketing). Original internal error message: %s', me.message);
    sets = [(1:length(rawinfo))' (1:length(rawinfo))'];
    return;
end
    
%% Step 2: Find the shortest repeating pattern (max 11)
putative_rep = 1; % putative length of the bracketing segments
bracketing_rep = NaN;
while putative_rep <= 11 && isnan(bracketing_rep)
    if mod(length(ev), putative_rep) == 0 % only check this length if it is a divider of the length of the dataset
        pattern = ev(1:putative_rep);     % the first N elements of ev determine the putative pattern
        locations = strfind(ev, pattern); % find all repetitions of the pattern
        if length(locations) == length(ev)/putative_rep && all(locations == 1:putative_rep:length(ev))
            % if the right number of repetitions have been found, and they
            % are in the right spots, use this bracketing
            bracketing_rep = putative_rep;
        end
    end
    putative_rep = putative_rep + 1;
end

if bracketing_rep == 1 && length(ev)>1 % if there is no ev-variation, and more than 1 image, warn
    if verbose
        [~, setName] = fileparts(fileparts(rawinfo(1).Filename));
        warning('ELF:hdr:NoBrackets', 'No exposure brackets were detected for environment %s. If the brackets were set manually, you need a brackets.info file!!!', setName);
    end
end

if isnan(bracketing_rep)
    if verbose
        warning('No consistent exposure pattern could be found. Images will be assumed to be independent (i.e. no bracketing).');
    end
    sets = [(1:length(rawinfo))' (1:length(rawinfo))'];
else
    sets = [locations' [locations(2:end)' - 1; length(rawinfo)]];
end
