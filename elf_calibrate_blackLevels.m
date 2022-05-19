function [blackLevel, srcs, warnings] = elf_calibrate_blackLevels(info, imgformat)
% ELF_CALIBRATE_BLACKLEVELS detects and loads dark images, if they are present
%
% Inputs:
%   info - 1 x n info structure, containing the exif information of the raw image files (created by elf_info_collect)
% Outputs:
%   sets - m x 2 double, containing the numbers of the first and last image of each bracket
% 
% Call sequence: elf -> elf_main3_summary -> elf_hdr_brackets
%
% See also: elf_main3_summary, elf_info_collect

                    elf_support_logmsg('      Calculating black levels / reading dark images ...\n');

    darkFolder = fullfile(fileparts(info(1).Filename), 'dark');
    exp        = arrayfun(@(x) x.DigitalCamera.ExposureTime, info);      % exposure time in seconds
    iso        = arrayfun(@(x) x.DigitalCamera.ISOSpeedRatings, info);   % ISO speed
    t          = arrayfun(@(x) datenum(x.DateTime, 'yyyy:mm:dd HH:MM:SS'), info); % date and time
    srcs       = nan(size(iso));
    camstring  = info(1).Model;
    
    switch lower(camstring)
        case 'nikon d810'
            para = elf_para;
            calibfilefolder = para.paths.calibfolder; % Where to find the finished calibration files
            load(fullfile(calibfilefolder, camstring, 'noise.mat'), 'rf_mean'); 

            blackLevel = 600 * ones(length(iso), 3);
    
            % 1 (ISO<=6400, EXP<=1): Dark level is within +-10 counts of 400, so accept these
            sel = iso<=6400 & exp<=1;
            srcs(sel) = 1; % 1: using calibration or default black level
            for c = 1:3
                XX = [ones(length(iso), 1) iso(:) exp(:) iso(:).*exp(:)];
                calibLevels = XX*rf_mean{c};
                blackLevel(sel, c) = calibLevels(sel); 
            end
    
        case 'nikon d850'        
            blackLevel = 400 * ones(length(iso), 3);
        
            % 1 (ISO<=1600, EXP<=1): Dark level is within +-10 counts of 400, so accept these
            srcs(iso<=1600 & exp<=1) = 1; % 1: iso<=1600 and exp<=1; here, calib shows that noise is low
    
        otherwise
            blackLevel = info.SubIFDs{1}.BlackLevel(1) * ones(length(iso), 3);   % black level saved by camera in exif file. This seems to very closely correspond to measured readout noise
            elf_support_logmsg('          No calibration exists for this camera.\n');
    end

    % 2 (dark images): Load all dark images and apply them
    dark = sub_loadDarkImages(darkFolder, imgformat);
    [blackLevel, srcs, warnings] = sub_applyDarkImages(blackLevel, srcs, dark, iso, exp, t);

    % 3: log messages/warnings
    elf_support_logmsg('          Dark correction finished:\n');
    elf_support_logmsg('            %d images were corrected using the default black level or calibration\n', nnz(srcs==1));
    elf_support_logmsg('            %d images were corrected using dark images\n', nnz(srcs==2 | srcs==3));
    elf_support_logmsg('            %d images were NOT PROPERLY dark corrected\n', nnz(isnan(srcs)));
    if isempty(warnings)
        elf_support_logmsg('          No warnings were encountered.\n');
    else
        elf_support_logmsg('          %d warnings were encountered:\n', length(warnings));
        for i = 1:length(warnings)
            elf_support_logmsg('            %s\n', warnings{i});
        end
    end
                    elf_support_logmsg('        done.\n');
end

%% Sub functions
function dark = sub_loadDarkImages(darkFolder, imgformat)
    % Load all dark images and calculate their mean and std

    if isfolder(darkFolder)
        infoDark        = elf_info_collect(darkFolder, imgformat);   % this contains EXIF information and filenames, verbose==1 means there will be output during system check
        dark.infosum    = elf_info_summarise(infoDark, false);         % summarise EXIF information for this dataset. This will be saved for later use below
        dark.exp        = arrayfun(@(x) x.DigitalCamera.ExposureTime, infoDark);
        dark.iso        = arrayfun(@(x) x.DigitalCamera.ISOSpeedRatings, infoDark);
        dark.t          = arrayfun(@(x) datenum(x.DateTime, 'yyyy:mm:dd HH:MM:SS'), infoDark); % date and time
        dark.camstring  = arrayfun(@(x) x.Model, infoDark, 'UniformOutput', false);

        for filenum = length(infoDark):-1:1 % for each image in the dark folder
            % Load image        
            fname   = infoDark(filenum).Filename;  % full path to input image file
            darkim  = double(elf_io_imread(fname)); % load the image (uint16)
            R       = darkim(:, :, 1);
            G       = darkim(:, :, 2);
            B       = darkim(:, :, 3);
            dark.std(filenum, 1)  = std(R(:));
            dark.std(filenum, 2)  = std(G(:));
            dark.std(filenum, 3)  = std(B(:));
            dark.mean(filenum, 1) = mean(R(:));
            dark.mean(filenum, 2) = mean(G(:));
            dark.mean(filenum, 3) = mean(B(:));
        end
    
    else
        dark = [];
        fprintf('There is no dark folder\n');
    end
end

function [blackLevel, srcs, warnings] = sub_applyDarkImages(blackLevel, srcs, dark, iso, exp, t)
    % apply the dark measurements
    warnings = {};

    if isempty(dark)
        elf_support_logmsg('          No dark images were found.\n');
    else
        elf_support_logmsg('          Applying dark images for all available conditions...\n');
        uExp = unique(dark.exp);
        for e = 1:length(uExp)
            thisExp = uExp(e);
            uIso = unique(dark.iso(dark.exp==thisExp));
            for i = 1:length(uIso)
                thisIso = uIso(i);
                selDark = dark.iso==thisIso & dark.exp==thisExp;
                selLight = iso==thisIso & exp==thisExp;
                if nnz(selDark)==0
                    error('Something is wrong with this loop')
                elseif nnz(selDark)>1
                    % this condition has more than one dark image, linearly interpolate
                    elf_support_logmsg('              For ISO %d & exposure %.3f s, %d dark images were found. Linearly interpolating over time.\n', thisIso, thisExp, nnz(selDark));
                    tLight = t(selLight);
                    tDark = t(selDark);
                    blackLevel(selLight, 1) = interp1(tDark, dark.mean(selDark, 1), tLight, 'linear', 'extrap');
                    blackLevel(selLight, 2) = interp1(tDark, dark.mean(selDark, 2), tLight, 'linear', 'extrap');
                    blackLevel(selLight, 3) = interp1(tDark, dark.mean(selDark, 3), tLight, 'linear', 'extrap');
                    srcs(selLight) = 3; % 2 means this black level comes from linearly interpolated dark image
    
                    %% Warn if some of the real images lie too far outside the range
                    if any(tLight>max(tDark)+0.2/24) || any(tLight<min(tDark)-0.2/24)
                        warnings{end+1} = 'Some images were taken >30 min outside the dark-image range.'; %#ok<AGROW> 
                    end
                else
                    % this condition has only one dark image
                    elf_support_logmsg('              For ISO %d & exposure %.3f s, 1 dark image was found.\n', thisIso, thisExp);
                    blackLevel(selLight, :) = dark.mean(selDark, :);
                    srcs(selLight) = 2; % 2 means this black level comes from a single dark image
    
                    %% Warn if some of the real images were taken much earlier or later
                    if any(abs(t(selLight)-t(selDark))>0.5/24)
                        warnings{end+1} = 'Some images were taken >30 min before/after their dark-image.\n'; %#ok<AGROW> 
                    end
                end
            end
        end
    end

    % Warn if not enough dark images found
    if any(isnan(srcs))
        warnings{end+1} = sprintf('%d images were NOT PROPERLY dark-corrected (because they were outside the calibration range, and no applicable dark images were found)', nnz(isnan(srcs)));
    end
end