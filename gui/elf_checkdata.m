function [status, para, datasets, dominantext] = elf_checkdata(para, verbose)

%% Set upper limit to datasets
datalim = 2000;

%% Set up paths and file names; read info, infosum and para
if nargin < 2, verbose = 1; end
if nargin < 1
    para            = elf_para; %without parameters, just returns basic parameters (call again later with dataset)
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
if ~exist(para.paths.root, 'file')
    warning('Root folder does not exist. Please enter the correct root folder!'); % in <a href="matlab: opentoline(''elf_para.m'',10)">elf_para.m</a>!');
    rootdir = elf_io_localpaths('loadroot', 1);
    para.paths.root = rootdir;
end

if verbose
    fprintf('Scanning root folder %s\n', para.paths.root);
end

%% Step 1: Find all folders in the data path (subfolders will be added later)
folders  = elf_io_dir(para.paths.root); % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
folders  = folders([folders.isdir]);    % only keep folders
datasets = {folders.name};

while isempty(datasets) 
    warning('Root folder is empty. Please enter the correct root folder in elf_para.m');
    rootdir = elf_io_localpaths('loadroot', 1);
    para.paths.root = rootdir;
    folders  = elf_io_dir(para.paths.root); % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
    folders  = folders([folders.isdir]); % only keep folders
    datasets = {folders.name};
end

% prealloc
foldertype      = cell(datalim, 1);
imfinfo         = cell(datalim, 1);
sceneinfo       = cell(datalim, 1);
scenepres       = cell(datalim, 1);
scenestatus     = cell(datalim, 1);
scenevalid      = cell(datalim, 1);
sceneinfo_valid = cell(datalim, 1);
resinfo         = cell(datalim, 1);
respres         = cell(datalim, 1);
resstatus       = cell(datalim, 1);
resvalid        = cell(datalim, 1);
resinfo_valid   = cell(datalim, 1);
sumstatus       = cell(datalim, 1);
meanstatus      = cell(datalim, 1);
dominantext     = cell(datalim, 1);

%% Step 2: Extract file and subfolder information
i = 1;
% while there are folders left
while i <= length(datasets)
    % Check if there are images in it (test dngs, then jpgs, then others)
    thisfolder  = fullfile(para.paths.root, datasets{i});
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
    
    % verbose output
    if verbose
        switch foldertype{i}
            case 'data'
                fprintf('\t%s-files will be used.\n', dominantext{i});
            case 'rawdata'
                fprintf('\t%s-files can be used, but must be converted to .dng first.\n', imext_rawexts{min(posraw(israw))});
            case 'parent'
                fprintf('\tNo usable image files found.\n');
                fprintf('\tSub-folders will be searched.\n');
            case 'unknown'
                fprintf('\tNo usable image files found.\n');
                fprintf('\tFolder will be ignored.\n');
        end
    end
    
%% Step 4: If there are images, find brackets and see if there are enough scene files
%%test for each image if there is a _filt.mat in the filt folder, and how old it is
    if ~strcmp(foldertype{i}, 'data')
        if verbose, fprintf('\n'); end
        i = i + 1;
        continue; % if there are no usable images, continue to the next potential dataset
    else
        info        = elf_info_collect(thisfolder, dominantext{i});   % this contains EXIF information and filenames, verbose==1 means there will be output during system check
        brackets    = elf_hdr_brackets(info);
        
        scenefolder = fullfile(thisfolder, para.paths.scenefolder);
        
        if ~exist(scenefolder, 'file')
            scenestatus{i} = 'nofolder';
        else % check for each of the brackets whether a scene exists that is older than all of the images
            imfinfo{i}      = elf_io_dir(fullfile(thisfolder, ['*' dominantext{i}]));    % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
            sceneinfo{i}    = elf_io_dir(fullfile(scenefolder, '*.mat'));                % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
            scenevalid{i}    = zeros(size(sceneinfo)); % pre-alloc, will be 1 or 2 if this filter file has a corresponding older/younger image file
            for j = 1:size(brackets, 1)
                % find the oldest image file in this bracket
                imdates = [imfinfo{i}(brackets(j, 1):brackets(j, 2)).datenum];
                                            
                % test if this bracket has a scene equivalent
                filtnametemplate = sprintf('scene%03d.mat', j);
                [isscene, pos]   = ismember(filtnametemplate, {sceneinfo{i}.name});
                if isscene
                    scenedate = sceneinfo{i}(pos).datenum;
                    if scenedate >= max(imdates)
                        scenepres{i}(j) = 2; % 2 means all is good
                        scenevalid{i}(pos) = 2;
                    else
                        scenepres{i}(j) = 1; % 1 means filtered file present but older than image file (very weird)
                        scenevalid{i}(pos) = 1;
                    end
                else
                    scenepres{i}(j) = 0; % 0 means no filtered file found
                end
            end
            
            % define status variable and display output
            if all(scenepres{i}==0)
                scenestatus{i} = 'none';
            elseif any(scenepres{i}==0)
                scenestatus{i} = 'some';
            elseif any(scenepres{i}==1)
                scenestatus{i} = 'allbutolder';
            elseif all(scenepres{i}==2)
                scenestatus{i} = 'all';
            else %shouldn't happen
                error('Unknown internal error.');
            end
        end
        
        % verbose output
        if verbose
            switch scenestatus{i}
                case 'nofolder'
                    fprintf('\tNo scene folder found.\n');
                case 'none'
                    fprintf('\tNo scene files found.\n');
                case 'some'
                    fprintf('\t%d scene files found, but %d scenes remain to be done.\n', nnz(scenepres{i}>0), nnz(scenepres{i}==0));
                case 'allbutolder'
                    fprintf('\tAll files have been combined to scenes, but %d scene files are older than their image files.\n', nnz(scenepres{i}==1));
                case 'all'
                    fprintf('\tAll files have been combined to scenes.\n');
            end
        end
    end
    
%% Step 5: If there are scenes, test if there are also result-mats with a later date
    switch scenestatus{i}
        case {'nofolder', 'none', 'some'}
            resstatus{i} = 'na';
        case {'allbutolder', 'all'}
            sceneinfo_valid{i} = sceneinfo{i}(scenevalid{i} > 0);
            resfolder = fullfile(thisfolder, para.paths.matfolder);
            if ~exist(resfolder, 'file')
                resstatus{i} = 'nofolder';
            else
                resinfo{i}  = elf_io_dir(fullfile(resfolder, '*.mat'));  % read folder content and exclude invalid names (e.g. '$RECYCLE.BIN' and anything starting with .)
                resvalid{i} = zeros(size(resinfo)); % is 1 or 2 if this filter file has a corresponding older/younger image file
                for j = 1:length(sceneinfo_valid{i})
                    % test if this file has a results equivalent
                    scenename = sceneinfo_valid{i}(j).name;
                    scenedate = sceneinfo_valid{i}(j).datenum;
                    resnametemplate = [scenename(1:end-4) '.mat'];
                    [isres, pos] = ismember(resnametemplate, {resinfo{i}.name});
                    if isres
                        resdate = resinfo{i}(pos).datenum;
                        if resdate >= scenedate
                            respres{i}(j) = 2; % 2 means all is good
                            resvalid{i}(pos) = 2;
                        else
                            respres{i}(j) = 1; % 1 means res file present but older than filt file
                            resvalid{i}(pos) = 1;
                        end
                    else
                        respres{i}(j) = 0; % 0 means no res file found
                    end
                end

                % define status variable and display output
                if all(respres{i}==0)
                    resstatus{i} = 'none';
                elseif any(respres{i}==0)
                    resstatus{i} = 'some';
                elseif any(scenepres{i}==1)
                    resstatus{i} = 'allbutolder';
                elseif all(scenepres{i}==2)
                    resstatus{i} = 'all';
                else %shouldn't happen
                    error('Unknown internal error.');
                end
            end
            
            % verbose output
            if verbose
                switch resstatus{i}
                    case 'nofolder'
                        fprintf('\tNo results files found.\n');
                    case 'none'
                        fprintf('\tNo results files found.\n');
                    case 'some'
                        fprintf('\t%d results files found, but %d results files remain uncalculated.\n', nnz(scenepres{i}>0), nnz(scenepres{i}==0));
                    case 'allbutolder'
                        fprintf('\tAll results files have been calculated, but %d results files are older than their filtered files.\n', nnz(scenepres{i}==1));
                    case 'all'
                        fprintf('\tAll results files have been calculated.\n');
                end
            end
        otherwise
            error('Internal error: Unknown filtstatus');
    end
    
%% Step 6: If there are mats, see if a mean image and pdf are available in output_pdf
    switch resstatus{i}
        case {'na', 'nofolder', 'none', 'some'}
            meanstatus{i} = 'na';
        case {'allbutolder', 'all'}
            sumfolder         = para.paths.outputfolder_pub;
            [~, sumname, ext] = fileparts(datasets{i}); % important for sub-folder datasets
            sumname           = [sumname ext];
            sumnametemplate   = [sumname '_mean_image.jpg'];
            resinfo_valid{i}  = resinfo{i}(resvalid{i} > 0);
            
            % find maximum date
            latestdate        = max([resinfo_valid{i}.datenum]);
            ismean            = exist(fullfile(sumfolder, sumnametemplate), 'file');
            if ismean
                temp          = elf_io_dir(fullfile(sumfolder, sumnametemplate));
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
    switch resstatus{i}
        case {'na', 'nofolder', 'none', 'some'}
            sumstatus{i} = 'na';
        case {'allbutolder', 'all'}
            sumfolder         = para.paths.matfolder;
            [~, sumname, ext] = fileparts(datasets{i}); % important for sub-folder datasets
            sumname           = [sumname ext];
            sumnametemplate   = [sumname '_meanres_int.mat'];
            resinfo_valid{i}  = resinfo{i}(resvalid{i} > 0);
            
            % find maximum date
            latestdate = max([resinfo_valid{i}.datenum]);
            ismean = exist(fullfile(thisfolder, sumfolder, sumnametemplate), 'file');
            if ismean
                temp = elf_io_dir(fullfile(thisfolder, sumfolder, sumnametemplate));
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

%% chop out all the ones that are not datasets
sel1 = (1:datalim)'<i;
sel2 = strcmp('rawdata', foldertype) | strcmp('data', foldertype);
sel = sel1 & sel2; % If there is an error here, increase datalim at the top of the script
datasets    = datasets(sel2(sel1));
foldertype  = foldertype(sel);
imfinfo     = imfinfo(sel);
sceneinfo    = sceneinfo(sel);
scenepres    = scenepres(sel);
scenestatus  = scenestatus(sel);
scenevalid   = scenevalid(sel);
sceneinfo_valid = sceneinfo_valid(sel);
resinfo     = resinfo(sel);
respres     = respres(sel);
resstatus   = resstatus(sel);
resvalid    = resvalid(sel);
resinfo_valid = resinfo_valid(sel);
dominantext = dominantext(sel);
sumstatus   = sumstatus(sel);
meanstatus  = meanstatus(sel);

%% simplify status variables (0 - res ; 1 - orange ; 2 - green)
status = zeros(length(foldertype), 4);
% column 1: foldertype, can be data/rawdata/parent/unknown
status(:, 1) = strcmp('rawdata', foldertype) + strcmp('data', foldertype)*3;
% column 2: resstatus, can be nofolder/none/some/allbutolder/all
status(:, 2) = strcmp('some', resstatus) + strcmp('allbutolder', resstatus)*2 + strcmp('all', resstatus)*3;
% column 3: meanstatus,  can be none/older/good
status(:, 3) = strcmp('older', meanstatus)*2 + strcmp('good', meanstatus)*3;
% column 4: sumstatus,  can be none/older/good
status(:, 4) = strcmp('older', sumstatus)*2 + strcmp('good', sumstatus)*3;

%% if verbose 0.5 was selected, just output a list of all datasets found (with numbers)
if listoutput
    fprintf('\n   Environments found in root folder %s\n', para.paths.root);
    for i = 1:length(datasets)
        fprintf('    %4d: %s\n', i, datasets{i});
    end
    fprintf('\n');
end






