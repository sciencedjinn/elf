function [sceneFilesStatus, fileNames, fileValid, fileDates, statusText, statusColour] = scenes_checkFiles(thisFolder, ext, para, fileDates_prev, verbose)
% Test if there are valid scenes files for each scene

info     = elf_info_collect(thisFolder, ext);   % this contains EXIF information and filenames, verbose==1 means there will be output during system check
brackets = elf_hdr_brackets(info, verbose);
scenesFolderName = fullfile(thisFolder, para.fh.Paths.scenefolder);

if ~exist(scenesFolderName, 'file')
    sceneFilesStatus = 'nofolder';
else
    fileInfo  = elf_io_dir(fullfile(scenesFolderName, 'scene*.mat'));  % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
    foundFileDates = [fileInfo.datenum];
    foundFileNames = {fileInfo.name};
    fileValid = zeros(length(brackets), 1); % pre-allocate; is 1/2 if this file has a corresponding older/younger file from previous step
    fileDates = zeros(length(brackets), 1); % pre-allocate
    fileNames = cell(length(brackets), 1); % pre-allocate

    for j = 1:length(brackets)
        % find the oldest image file in this bracket
        imDates = fileDates_prev(brackets(j, 1):brackets(j, 2));

        % test if this bracket has a scene equivalent
        fileNames{j} = sprintf('scene%03d.mat', j);
        [isScene, pos] = ismember(fileNames{j}, foundFileNames);
       
        if isScene
            fileDates(j) = foundFileDates(pos);
            if fileDates(j) >= max(imDates)
                fileValid(j) = 2; % 2 means all is good
            else
                fileValid(j) = 1; % 1 means scene file present but older than image file (very weird)
            end
        else
            fileValid(j) = 0;  % 0 means no scene file found
        end
    end

    % define status variable and display output
    if all(fileValid==0)
        sceneFilesStatus = 'none';
    elseif any(fileValid==0)
        sceneFilesStatus = 'some';
    elseif any(fileValid==1)
        sceneFilesStatus = 'allbutolder';
    elseif all(fileValid==2)
        sceneFilesStatus = 'all';
    else % shouldn't happen
        error('Unknown internal error.');
    end
end

% status text
switch sceneFilesStatus
    case 'nofolder'
        statusText = 'No scene folder found.';
        statusColour = StatusColour.Bad;
    case 'none'
        statusText = 'No scene files found.';
        statusColour = StatusColour.Bad;
    case 'some'
        statusText = sprintf('%d scene files found, but %d scene files remain uncalculated.', nnz(fileValid>0), nnz(fileValid==0));
        statusColour = StatusColour.Incomplete;
    case 'allbutolder'
        statusText = sprintf('All scene files have been calculated, but %d scene files are older than their image files.', nnz(fileValid==1));
        statusColour = StatusColour.Problem;
    case 'all'
        statusText = 'All scene files have been calculated.';
        statusColour = StatusColour.Good;
end

% verbose output
if verbose
    fprintf("\t%s\n", statusText);
end
end