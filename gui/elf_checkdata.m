function [status, para, datasets, dominantext] = elf_checkdata(para, verbose)

%% Set upper limit to datasets (for preallocation; will be trimmed at the end)
datalim = 2000;

%% Set up paths and file names; read info, infosum and para
if nargin < 2, verbose = 1; end
if nargin < 1
    para = elf_para; %without parameters, just returns basic parameters (call again later with dataset)
end

% parse verbose input
if verbose == 0
    verbose = false;
    listoutput = false;
elseif verbose ==0.5
    verbose = false;
    listoutput = true;
else
    verbose = true;
    listoutput = false;
end
    

imext_preforder = {'.dng', '.tif', '.jpg', '.tiff'};    % These are image formats that can be worked with (could include more)
imext_rawexts   = {'.nef', '.cr2'};                     % If these are the only images in a folder, the file light will turn orange (could include more raw files that can be transformed into dngs)

%% if no datasets exist, create an error
if ~exist(para.fh.Paths.root, 'file')
    warning('Root folder does not exist. Please enter the correct root folder!'); % in <a href="matlab: opentoline(''elf_para.m'',10)">elf_para.m</a>!');
    rootdir = elf_io_localpaths('loadroot', 1);
    para.fh.Paths.root = rootdir;
end

if verbose
    fprintf('Scanning root folder %s\n', para.fh.Paths.root);
end

%% Step 1: Find all folders in the data path (subfolders will be added later)
folders  = elf_io_dir(para.fh.Paths.root); % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
folders  = folders([folders.isdir]);    % only keep folders
datasets = {folders.name};

while isempty(datasets) 
    warning('Root folder is empty. Please enter the correct root folder in elf_para.m');
    rootdir = elf_io_localpaths('loadroot', 1);
    para.fh.Paths.root = rootdir;
    folders  = elf_io_dir(para.fh.Paths.root); % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
    folders  = folders([folders.isdir]); % only keep folders
    datasets = {folders.name};
end

% prealloc
foldertype      = cell(datalim, 1);
imfinfo         = cell(datalim, 1);
sceneFileNames  = cell(datalim, 1);
sceneFileValid  = cell(datalim, 1);
sceneFileDates  = cell(datalim, 1);
sceneFileStatus = repmat({""}, [datalim, 1]);
resFileNames    = cell(datalim, 1);
resFileValid    = cell(datalim, 1);
resFileDates    = cell(datalim, 1);
resFileStatus   = repmat({""}, [datalim, 1]);
modFileStatus   = repmat({""}, [datalim, length(para.modules)]);
modFileNames    = cell(datalim, length(para.modules));
modFileValid    = cell(datalim, length(para.modules));
modFileDates    = cell(datalim, length(para.modules));
sumstatus       = cell(datalim, 1);
meanstatus      = cell(datalim, 1);
dominantext     = cell(datalim, 1);
status.Colour   = StatusColour.prealloc([datalim, 2+length(para.modules)]);
status.Text     = repmat({""}, [datalim, 2+length(para.modules)]);

%% Step 2: Extract file and subfolder information
i = 1;
% while there are folders left
while i <= length(datasets)
    % Check if there are images in it (test dngs, then tifs/jpgs, then others)
    thisfolder  = fullfile(para.fh.Paths.root, datasets{i});
    content     = elf_io_dir(thisfolder);       % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
    folders     = content([content.isdir]);     % only keep folders
    folders     = {folders.name};
    files       = content(~[content.isdir]);    % only keep files
    files       = {files.name};
    
    % find all extensions / unique extensions, and count how many files of each there are
    [~, ~, allexts] = cellfun(@(x) fileparts(x), files, 'UniformOutput', false);
    uniqueexts    = unique(lower(allexts));
    extcount      = zeros(size(uniqueexts));
    for j = 1:length(uniqueexts)
        extcount(j) = nnz(strcmpi(allexts, uniqueexts{j}));
    end

    % verbose output
    if verbose
        fprintf('Folder ''%s'' contains %d folders and %d files.\n', datasets{i}, length(folders), length(files));
        for j = 1:length(uniqueexts)
            fprintf('\t%d %s-files\n', extcount(j), uniqueexts{j});
        end
    end
    
%% Step 3: search for usable or raw image files; if no images found, add subfolders to end of list
    [isim, posim]   = ismember(uniqueexts, imext_preforder);    % determines for each extension whether it is a usable image extension and at what position in the preference list
    [israw, posraw] = ismember(uniqueexts, imext_rawexts);      % determines for each extension whether it is a raw image extension
    if any(isim)
        foldertype{i} = 'data';
        dominantext{i} = imext_preforder{min(posim(isim))};
    elseif any(israw)
        foldertype{i} = 'rawdata';
        dominantext{i} = NaN;
    else % no images and no raws
        if ~isempty(folders)
            for j = 1:length(folders)
                datasets{end+1} = fullfile(datasets{i}, folders{j}); %#ok<AGROW>
            end
            foldertype{i} = 'parent';
        else
            foldertype{i} = 'unknown';
        end
    end
    
    switch foldertype{i}
        case 'data'
            status.Colour(i, 1) = StatusColour.Good;
            status.Text{i, 1} = sprintf('%s-files were found in this folder (either DNGs or non-raw). Proceed to the next step.', dominantext{i});
        case 'rawdata'
            status.Colour(i, 1) = StatusColour.Incomplete;
            status.Text{i, 1} = 'Only raw image files were found in this folder. Please convert them into uncompressed DNG files with Adobe''s DNG-Converter (see ELF manual for instructions).';
        otherwise
            status.Text{i, 1} = "";
    end

    % verbose output
    if verbose
        fprintf("\t%s\n", status.Text{i, 1})
    end

    % collect dates
    if ~strcmp(foldertype{i}, 'data')
        if verbose, fprintf('\n'); end
        i = i + 1;
        continue; % if there are no usable images, continue to the next potential dataset
    else
        info = elf_io_dir(fullfile(thisfolder, ['*' dominantext{i}]));    % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
        step3_dates{i} = [info.datenum];
    end
    
%% Step 4: If there are images, find brackets and see if there are enough scene files
    [sceneFileStatus{i}, sceneFileNames{i}, sceneFileValid{i}, sceneFileDates{i}, sceneStatusText, sceneStatusColour] = scenes_checkFiles(thisfolder, dominantext{i}, para, step3_dates{i}, verbose);
   
%% Step 5: If there are scenes, test if there are also result-mats with a later date (these include the per-scene results for each module)
    switch sceneFileStatus{i}
        case {'nofolder', 'none', 'some'}
            resFileStatus{i} = 'na';
            status.Text{i, 2} = sceneStatusText;
            status.Colour(i, 2) = sceneStatusColour;
        case {'allbutolder', 'all'}
            [resFileStatus{i}, resFileNames{i}, resFileValid{i}, resFileDates{i}, resStatusText, resStatusColour] = sceneResults_checkFiles(thisfolder, para, sceneFileNames{i}, sceneFileValid{i}, sceneFileDates{i}, verbose);
            if sceneStatusColour.Prio >= resStatusColour.Prio
                status.Text{i, 2} = sceneStatusText;
                status.Colour(i, 2) = sceneStatusColour;
            else
                status.Text{i, 2} = resStatusText;
                status.Colour(i, 2) = resStatusColour;
            end
        otherwise
            error('Internal error: Unknown sceneFileStatus');
    end
    
%% Now, check for each module (This will happen in reverse module order, just as they are executed; e.g. core -> filter -> sky)
    lastFileNames = sceneFileNames{i};
    lastFileValid = sceneFileValid{i};
    lastFileDates = sceneFileDates{i};
    switch sceneFileStatus{i}
        case {'nofolder', 'none', 'some'}
            modFileStatus{i, :} = 'na';
            status.Text{i, 3+length(para.modules)-j} = "Prerequisite steps are unresolved";
        case {'allbutolder', 'all'}
            for j = length(para.modules):-1:1
                modCheckFilename = [para.modules{j} '_checkFiles'];
                if ~isempty(which(modCheckFilename))
                    [modFileStatus{i, j}, modFileNames{i, j}, modFileValid{i, j}, modFileDates{i, j}, status.Text{i, 3+length(para.modules)-j}, status.Colour(i, 3+length(para.modules)-j)] = feval(modCheckFilename, thisfolder, para, lastFileNames, lastFileValid, lastFileDates, verbose);
                    lastFileNames = modFileNames{i, j};
                    lastFileValid = modFileValid{i, j};
                    lastFileDates = modFileDates{i, j};
                else
                    modFileStatus{i, j} = 'na';
                    status.Text{i, 3+length(para.modules)-j} = "Internal error: this module has no function to check whether results have already been calculated.";
                end
            end
        otherwise
            error('Internal error: Unknown sceneFileStatus');
    end

%% Step 6: If there are mats, see if a mean image and pdf are available in output_pdf
    switch resFileStatus{i}
        case {'na', 'nofolder', 'none', 'some'}
            meanstatus{i} = 'na';
        case {'allbutolder', 'all'}
            sumfolder         = para.fh.Paths.outputfolder_pub;
            [~, sumname, ext] = fileparts(datasets{i}); % important for sub-folder datasets
            sumnameTemplate   = [sumname ext '_mean_image.jpg'];
            
            % find maximum date
            latestdate        = max(resFileDates{i});
            ismean            = exist(fullfile(sumfolder, sumnameTemplate), 'file');
            if ismean
                temp          = elf_io_dir(fullfile(sumfolder, sumnameTemplate));
                sumdate       = temp.datenum;
                if sumdate >= latestdate
                    meanstatus{i} = 'good';
                else
                    meanstatus{i} = 'older';
                end
            else
                meanstatus{i} = 'none';
            end
            
            % verbose output
            if verbose
                switch meanstatus{i}
                    case 'none'
                        fprintf('\tNo mean image file found.\n');
                    case 'older'
                        fprintf('\tMean image file found, but it is older than the newest valid results file.\n');
                    case 'good'
                        fprintf('\tMean image file found.\n');
                        
                end
            end

        otherwise
            error('Internal error: Unknown resstatus');
            
    end
       
%% Step 7: Check if a combined res file is available
    switch resFileStatus{i}
        case {'na', 'nofolder', 'none', 'some'}
            sumstatus{i} = 'na';
        case {'allbutolder', 'all'}
            sumfolder         = para.fh.Paths.matfolder;
            [~, sumname, ext] = fileparts(datasets{i}); % important for sub-folder datasets
            sumnameTemplate   = [sumname ext '_meanres_int.mat'];
            
            % find maximum date
            latestdate = max(resFileDates{i});
            ismean = exist(fullfile(thisfolder, sumfolder, sumnameTemplate), 'file');
            if ismean
                temp = elf_io_dir(fullfile(thisfolder, sumfolder, sumnameTemplate));
                sumdate = temp.datenum;
                if sumdate >= latestdate
                    sumstatus{i} = 'good';
                else
                    sumstatus{i} = 'older';
                end
            else
                sumstatus{i} = 'none';
            end
            
            % verbose output
            if verbose
                switch sumstatus{i}
                    case 'none'
                        fprintf('\tNo summary file found.\n');
                    case 'older'
                        fprintf('\tSummary file found, but it is older than the newest valid results file.\n');
                    case 'good'
                        fprintf('\tSummary file found.\n');
                        
                end
            end

        otherwise
            error('Internal error: Unknown resstatus');
            
    end
    
%% Wrap up this loop iteration
    if verbose, fprintf('\n'); end
    i = i + 1;
end

%% trim away all the folders that are not datasets
sel1 = (1:datalim)'<i;
sel2 = strcmp('rawdata', foldertype) | strcmp('data', foldertype);
sel = sel1 & sel2; % If there is an error here, increase datalim at the top of the script
datasets    = datasets(sel2(sel1));
foldertype  = foldertype(sel);
imfinfo     = imfinfo(sel);

sceneFileStatus  = sceneFileStatus(sel);
resFileStatus   = resFileStatus(sel);
dominantext = dominantext(sel);
sumstatus   = sumstatus(sel);
meanstatus  = meanstatus(sel);

status.Colour = status.Colour(sel, :);
status.Text = status.Text(sel, :);

%% simplify status variables (0 - red ; 1 - dark green; 2 - orange ; 3 - green, 4 - orange)
%% TODO: Get rid of this
% status = zeros(length(foldertype), 4);
% % column 1: foldertype, can be data/rawdata/parent/unknown
% status(:, 1) = strcmp('rawdata', foldertype) + strcmp('data', foldertype)*3;
% % column 2: resstatus, can be na/nofolder/none/some/allbutolder/all
% status(:, 2) = strcmp('some', resFileStatus) + strcmp('allbutolder', resFileStatus)*2 + strcmp('all', resFileStatus)*3;
% % column 3: meanstatus,  can be none/older/good
% status(:, 3) = strcmp('older', meanstatus)*2 + strcmp('good', meanstatus)*3;
% % column 4: sumstatus,  can be none/older/good
% status(:, 4) = strcmp('older', sumstatus)*2 + strcmp('good', sumstatus)*3;

%% if verbose 0.5 was selected, just output a list of all datasets found (with numbers)
if listoutput
    fprintf('\n   Environments found in root folder %s\n', para.fh.Paths.root);
    for i = 1:length(datasets)
        fprintf('    %4d: %s\n', i, datasets{i});
    end
    fprintf('\n');
end






