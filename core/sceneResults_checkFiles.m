function [resultsFilesStatus, fileNames, fileValid, fileDates, statusText, statusColour] = sceneResults_checkFiles(thisFolder, para, fileNames_prev, fileValid_prev, fileDates_prev, verbose)
    % Test if there are valid results files for each scene

    resFolderName = fullfile(thisFolder, para.fh.Paths.matfolder);
    if ~exist(resFolderName, 'file')
        resultsFilesStatus = 'nofolder';
    else
        fileInfo  = elf_io_dir(fullfile(resFolderName, '*.mat'));  % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
        fileValid = zeros(size(fileValid_prev)); % pre-allocate; is 1/2 if this file has a corresponding older/younger file from previous step
        fileDates = zeros(size(fileValid_prev)); % pre-allocate
        fileNames = cell(size(fileValid_prev)); % pre-allocate
        for j = 1:length(fileNames_prev)
            if fileValid_prev(j) == 0
                continue;
            end

            % test if this results file exists and is older than its scene
            sceneName = fileNames_prev{j};
            sceneDate = fileDates_prev(j);
            resNameTemplate = [sceneName(1:end-4) '.mat'];
            [isRes, pos] = ismember(resNameTemplate, {fileInfo.name});
            if isRes
                fileNames{j} = resNameTemplate;
                fileDates(j) = fileInfo(pos).datenum;
                if fileDates(j) >= sceneDate
                    fileValid(j) = 2;
                else
                    fileValid(j) = 1;
                end
            end
        end
    
        % define status variable and display output
        if all(fileValid==0)
            resultsFilesStatus = 'none';
        elseif any(fileValid==0)
            resultsFilesStatus = 'some';
        elseif any(fileValid==1)
            resultsFilesStatus = 'allbutolder';
        elseif all(fileValid==2)
            resultsFilesStatus = 'all';
        else % shouldn't happen
            error('Unknown internal error.');
        end
    end
    
    % status text
    switch resultsFilesStatus
        case 'nofolder'
            statusText = 'No results folder found.';
            statusColour = StatusColour.Bad;
        case 'none'
            statusText = 'No results files found.';
            statusColour = StatusColour.Bad;
        case 'some'
            statusText = sprintf('%d results files found, but %d results files remain uncalculated.', nnz(fileValid>0), nnz(fileValid==0));
            statusColour = StatusColour.Incomplete;
        case 'allbutolder'
            statusText = sprintf('All results files have been calculated, but %d results files are older than their image files.', nnz(fileValid==1));
            statusColour = StatusColour.Problem;
        case 'all'
            statusText = 'All results files have been calculated.\n';
            statusColour = StatusColour.Good;
    end

    % verbose output
    if verbose
        fprintf("\t%s\n", statusText);
    end
end