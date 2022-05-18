function [darkmean, saturation] = elf_calibrate_darkandreadout(camstring, exp, iso, info, long_exposure_NR)
% ELF_CALIBRATE_DARKANDREADOUT returns an estimate of dark noise and saturation levels for a given camera setting
% exp and iso can be scalars or vectors

if nargin<5, long_exposure_NR = true; end

switch lower(camstring)
    case {'nikon d810', ''}
        para = elf_para;
        calibfilefolder = para.paths.calibfolder; % Where to find the finished calibration files
        load(fullfile(calibfilefolder, 'nikon d810', 'noise.mat'), 'rf_mean'); 
        
        darkmean = zeros(length(iso), 3);
        
        for c = 1:3
            XX = [ones(length(iso), 1) iso(:) exp(:) iso(:).*exp(:)];
            darkmean(:, c) = XX*rf_mean{c}; 
        end
        
        % for ISO>6400 or exposures >1s, send a warning
        if any(iso>6400)
            warning('ISO values >6400 found. No noise calibration is available for these values.');
            darkmean(iso>6400, :) = 600;
        end
        if any(exp>=1)
            darkmean(exp>=1, :) = 600;
            if long_exposure_NR
                % These are corrected by the camera
            else
                warning('Exposures longer than 1 second found. No noise calibration is available for these values.');
            end
        end
        
        saturation   = 15520; % 15992 was found in calibration, 15520 is the black value in EXIF file

    case 'nikon d850'        
        darkmean = 400*ones(length(iso), 3);

        % check that there is a valid calibration for all settings
        darkmean_source = nan(length(iso), 1);
        darkmean_source(iso<=1600 & exp<=1) = 1; % 1: iso<=1600 and exp<=1; here, calib shows that noise is low

        % for ISO>1600 or exposures >1s, dark measurements are needed
        if any(iso>1600)
            warning('ISO values >1600 found. No noise calibration is available for these values.');
            darkmean(iso>6400, :) = 400;
        end
        if any(exp>=1)
            darkmean(exp>=1, :) = 400;
            if long_exposure_NR
                % These are corrected by the camera
            else
                warning('Exposures longer than 1 second found. No noise calibration is available for these values.');
            end
        end
        
        saturation   = 15520; % 15520 is the black value in EXIF file, and calibration never showed values below 16000

    otherwise
        darkmean     = info.SubIFDs{1}.BlackLevel(1) * ones(length(exp), 3);   % black level saved by camera in exif file. This seems to very closely correspond to measured readout noise
        saturation   = info.SubIFDs{1}.WhiteLevel;      % white level, this should corresponds to a reasonable saturation level
end

end % main
