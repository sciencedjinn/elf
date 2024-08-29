classdef Calibrator
    %CALIBRATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    % FYI
    % ELF_CALIBRATE_ABSSENS transforms a raw digital image to absolute spectral photon luminance (in photons/nm/s/sr/m^2)
    % For a full calibration, elf_calibrate_spectral has to be called afterwards!
    %
    % [im, conf, conffactors] = elf_calibrate_abssens(im, info)
    %
    % Inputs:
    %   im          - M x N x 3 double, raw digital image (as obtained from elf_io_loaddng)
    %   info        - 1 x 1 struct, info structure, containing the exif information of the raw image file (created by elf_info_collect or elf_info_load)
    %   blackLevel  - 1 x 3 double, the black level, i.e. the number of counts that need to be subtracted from the raw counts, for this image, for each channel; 
    %                   obtained from calibration or dark images    
    % Outputs:
    %   im          - M x N x 3 double, calibrated digital image (in photons/nm/s/sr/m^2), but not spectrally corrected
    %   conf        - M x N x 3 double, an estimate of confidence based on noise for each pixel (used for HDR calculations)
    %   confFactors - 2 x 1 double, the combined calibration factor (correcting for exp/iso/apt) and the saturation limit (minus dark)
    %
    % Call sequence: elf -> elf_main1_HdrAndInt -> Calibrator
    %
    % See also: elf_main1_HdrAndInt, elf_info_load, elf_io_loaddng, elf_calibrate_spectral

    % ELF_CALIBRATE_SPECTRAL performs colour correction on an otherwise calibrated image
    % 
    % im = elf_calibrate_spectral(im, info, method)
    %
    % Inputs:
    %   im          - M x N x 3 double, calibrated digital image (as obtained from Calibrator)
    %   info        - 1 x 1 struct, info structure, containing the exif information of the raw image file (created by elf_info_collect or elf_info_load)
    %   method      - 'col' (default) - each channel of the output image represents the weighted mean over that pixels sensitivity function, assuming a flat spectrum over its full range
    %                 'colmat'        - solves the linear equation of all three channels to calculate a spectrum that is flat between 400-500/500-600/600-700nm and would create the same camera output
    %                                   This method theoretically creates the most interesting result, but is extremely sensitive to saturation in individual channels and can not be recommended for
    %                                   general use outside of laboratory situations
    %                 'wb'            - simply applies the normal white balance suggested by the camera
    %       
    % Outputs:
    %   im          - M x N x 3 double, calibrated digital image (in photons/nm/s/sr/m^2)
    %
    % Call sequence: elf -> elf_main1_HdrAndInt -> elf_calibrate_spectral
    %
    % See also: elf_main1_HdrAndInt, elf_info_load, elf_io_loaddng, Calibrator


    % ELF_CALIBRATE_SPECTRAL performs colour correction on an otherwise calibrated image
    % 
    % im = elf_calibrate_spectral(im, info, method)
    %
    % Inputs:
    %   im          - M x N x 3 double, calibrated digital image (as obtained from Calibrator)
    %   info        - 1 x 1 struct, info structure, containing the exif information of the raw image file (created by elf_info_collect or elf_info_load)
    %   method      - 'col' (default) - each channel of the output image represents the weighted mean over that pixels sensitivity function, assuming a flat spectrum over its full range
    %                 'colmat'        - solves the linear equation of all three channels to calculate a spectrum that is flat between 400-500/500-600/600-700nm and would create the same camera output
    %                                   This method theoretically creates the most interesting result, but is extremely sensitive to saturation in individual channels and can not be recommended for
    %                                   general use outside of laboratory situations
    %                 'wb'            - simply applies the normal white balance suggested by the camera
    %       
    % Outputs:
    %   im          - M x N x 3 double, calibrated digital image (in photons/nm/s/sr/m^2)
    %
    % Call sequence: elf -> elf_main1_HdrAndInt -> elf_calibrate_spectral
    %
    % See also: elf_main1_HdrAndInt, elf_info_load, elf_io_loaddng, Calibrator

    properties
        AbsoluteFactor
        AbsoluteMat
        VignettingMat
        Acf     % Aperture correction factor in new d850 calibration
        SpectralMatrix
        SpectralMethod
    end

    properties(SetAccess=immutable)
        CameraString
        Height
        Width
    end
    
    methods
        function obj = Calibrator(camString, wh, spectralMethod)
            %CALIBRATOR Construct an instance of this class
            %   Detailed explanation goes here
            if nargin<3, spectralMethod = "col"; end
            obj.CameraString = camString;
            obj.Width  = wh(1);
            obj.Height = wh(2);
            obj.SpectralMethod = spectralMethod;
            obj = obj.loadAbsoluteCalib(); % load the absolute factors and vignetting correction
            obj = obj.loadSpectralCalibration();
        end
    end

    methods
        function [im, conf, confFactors] = applyAbsolute(obj, im, info)

            % Extract camera parameters and calibration factors
            exp         = info.DigitalCamera.ExposureTime;      % exposure time in seconds
            iso         = info.DigitalCamera.ISOSpeedRatings;   % ISO speed
            apt         = info.DigitalCamera.FNumber;           % Aperture F-Stop
        
            %% Apply calibration
            % Subtract the camera's black level (saturation level has to be taken into account later)
            im          = im - obj.getBlackLevelMat(info.blackLevels);
            conf        = im; % Use these raw values (after dark subtraction) to define every pixel's confidence: 
                              % In HDR calculation, each HDR pixel will be assigned the radiance value it holds in the image where it has the highest confidence 
            confFactors = obj.getSaturationLevel(info) - info.blackLevels(:)';
        
            switch lower(obj.CameraString)
                case {'nikon d800e', 'nikon d810', 'nikon z 6'}
                    % 2. ISO/EXP/APT 2016 calibration
        
                    % correct for uneven aperture spacing, and calculate aperture "area" 
                    ev_num      = round(log(apt) / log(sqrt(2)) * 3);
                    apt_even    = sqrt(2).^(ev_num/3);
                    aparea      = pi * (4./apt_even).^2.292; % 2.292 was determined during 2017 aperture calibration
        
                    settingFactor  = exp * iso * aparea;
                    
                case 'nikon d850'
        
                    % 2. ISO/EXP/APT calibration
                    acf     = obj.Acf(obj.Acf(:, 1)==apt, 2);
                    settingFactor  = exp * iso * acf;
                
                otherwise
                    settingFactor  = exp * iso / apt.^2;
            end   
            
            % correct for exposure time, ISO setting (gain) and aperture
            im          = im ./ settingFactor ./ obj.AbsoluteMat;            % counts per second per ISO per aperture
            
            % correct for vignetting
            switch apt
                case {3.5, 4, 4.5, 4.8, 5.6}
                    apInd     = 1; % treat as aperture 3.5 for vignetting
                case {8, 9, 10, 11, 14}
                    apInd     = 2; % treat as aperture 8 for vignetting
                case 22
                    apInd     = 3; % treat as aperture 22 for vignetting
                otherwise
                    error('Aperture %g currently not supported.', apt);
            end
            im          = im ./ obj.VignettingMat{apInd};
        
        end

        function im = applySpectral(obj, im, info)

            % warning('Using standard D810 colour matrix'); 
            % wb_multipliers = [1.9531 1.0000 1.3359];
            wb_multipliers  = (info.AsShotNeutral).^-1;
            wb_multipliers  = wb_multipliers/wb_multipliers(2); % normalise to green channel
            
            switch obj.SpectralMethod
                case 'colmat'
                    % Full deconvolution of channels to reconstruct a spectrum that is flat between 400-500, 500-600 and 600-700 nm
            
            
                    % correct for spectral and absolute sensitivity
                    imsize = size(im);
                    im     = reshape(im, [imsize(1)*imsize(2) imsize(3)]);  % Reshape image to allow all pixels to be accessed simultaneously in matrix division
                    im     = obj.SpectralMatrix \ im';                                  % Solve equation system assuming constant photon radiance in each of the three spectral bins (see elf_calib_2016full_spectral1)
                    im     = reshape(im', imsize);                          % Reshape to original matrix shape
            
                    % Finally, apply a correction factor based on wide-spectrum bright lights
                    im     = im * 1.0038;
                    
                case 'col'
                    % This is the current default:  Scale individual channels so each one represents the weighted average spectral photon radiance
                    %                               over that pixels sensitivity
                    if isempty(obj.SpectralMatrix)
                        % If there is no calibration, use camera manufacturer's white balance multipliers
                        col = 1./wb_multipliers;
                    else
                        col = obj.SpectralMatrix;
                    end
                    im(:, :, 1) = im(:, :, 1) / col(1);
                    im(:, :, 2) = im(:, :, 2) / col(2);
                    im(:, :, 3) = im(:, :, 3) / col(3);
                    
                case 'wb'
                    % Apply the "As shot" white balance to correct for sensitivity differences in R, G and B pixels
                    im(:, :, 1)     = im(:, :, 1) * wb_multipliers(1);
                    im(:, :, 2)     = im(:, :, 2) * wb_multipliers(2);
                    im(:, :, 3)     = im(:, :, 3) * wb_multipliers(3);
                    
            end

        end
    end


    methods(Hidden, Access=protected)
        function obj = loadAbsoluteCalib(obj)
            switch lower(obj.CameraString)
                case {'nikon d800e', 'nikon d810', 'nikon z 6'}
                    
                    % 1. ISO/EXP/APT 2016 calibration
                    para    = elf_para("noenv");
                    TEMP    = load(fullfile(para.paths.calibfolder, 'nikon d810', 'absolute.mat'));
                    obj.AbsoluteFactor = TEMP.wlcf;
                    
                    % 2. Vignetting
                    obj = obj.getVignMat('nikon d810');
        
                case 'nikon d850'
        
                    % 1. ISO/EXP/APT calibration
                    para    = elf_para("noenv");
                    TEMP    = load(fullfile(para.paths.calibfolder, obj.CameraString, 'absolute.mat'));
                    obj.Acf = TEMP.acf;
                    obj.AbsoluteFactor = TEMP.wlcf;
                                
                    % 2. Vignetting
                    obj = obj.getVignMat('nikon d810');
                    
                otherwise
                    % For an unknown camera, use no calibration correction; an uncalibrated image is better than none
        
                    % 1. ISO/EXP/APT calibration
                    obj.AbsoluteFactor = [1 1 1];
                                
                    % 2. Vignetting
                    obj = obj.getVignMat('nikon d810');
        
                    warning('No intensity calibration available for this camera (%s) ', obj.CameraString);
            end

            % calculate mats for faster calibration later
            obj = obj.getAbsoluteMat();
        end


        function satLevel = getSaturationLevel(obj, info)
            % returns the saturation level for this camera (before dark correction
            switch lower(obj.CameraString)
                case {'nikon d800e', 'nikon d810', 'nikon z 6', 'nikon d850'}
                    satLevel = 15520; % 15992 was found in d810 calibration, 15520 is the black value in EXIF file
                otherwise
                    satLevel = 0.95*info.SubIFDs{1}.WhiteLevel(1);      % white level, this should corresponds to a reasonable saturation level
            end
        end


        function blackLevelMat = getBlackLevelMat(obj, blackLevels)
            % Load or calculate black level correction matrix for this camera type, width/height
            
            persistent storeBLM;
            persistent storedBLMName;
            
            blmname               = sprintf('%d_%d', obj.Height, obj.Width);
            
            if strcmp(blmname, storedBLMName) && ~isempty(storeBLM)
                blackLevelMat = storeBLM;
            else
                blackLevelMat = ones(obj.Height, obj.Width, 3);
                storeBLM          = blackLevelMat;
                storedBLMName     = blmname;
            end

            blackLevelMat(:, :, 1) = blackLevels(1);
            blackLevelMat(:, :, 2) = blackLevels(2);
            blackLevelMat(:, :, 3) = blackLevels(3);
        end
        

        function obj = getAbsoluteMat(obj)
            % Load or calculate black level correction matrix for this camera type, width/height
            
            persistent storeWLCM;
            persistent storedWLCMName;
            
            wlcmname             = sprintf('%s_%d_%d', obj.CameraString, obj.Height, obj.Width);
            
            if strcmp(wlcmname, storedWLCMName) && ~isempty(storeWLCM)
                obj.AbsoluteMat           = storeWLCM;
            else
                obj.AbsoluteMat  = cat(3, obj.AbsoluteFactor(1) * ones(obj.Height, obj.Width), ...
                                          obj.AbsoluteFactor(2) * ones(obj.Height, obj.Width), ...
                                          obj.AbsoluteFactor(3) * ones(obj.Height, obj.Width));
                storeWLCM        = obj.AbsoluteMat;
                storedWLCMName   = wlcmname;
            end
        end
        
        function obj = getVignMat(obj, camstring)
            % Load or calculate vignetting correction for this image camera type, width/height
            % Saving to a file and loading when needed has been tested and takes longer than recalculating on ELFPC (10s v 3s)
            
            persistent storedVign;
            persistent storedVignName;
            
            vignname = sprintf('%s_%d_%d', camstring, obj.Height, obj.Width);
            
            if strcmp(vignname, storedVignName) && ~isempty(storedVign)
                obj.VignettingMat    = storedVign;
            else
                % Calculate excentricity and vignetting correction, and store in persistents
                mid     = [1+(obj.Height-1)/2; 1+(obj.Width-1)/2];   % centre of image (x/y, h/w)
                r_full  = 8 * min([obj.Height obj.Width]) / 24;      % theoretical value for 24mm high chip that is fully covered by fisheye circular image
                [y, x]  = meshgrid(1:obj.Width, 1:obj.Height);       % x/y positions of all points in the image
                r_all   = sqrt((x-mid(1)).^2 + (y-mid(2)).^2);
                exc     = real(asind(r_all / 2 / r_full) * 2);  % remove the complex part that happens for excentricities >90
        
                % Calculate vignetting correction
                para    = elf_para;
                fname   = fullfile(para.paths.calibfolder, lower(camstring), 'vign_calib.mat');
                if isfile(fname)
                    TEMP = load(fname); % holds pf, fitted vignetting-correction function
                    pf = TEMP.pf;
                else
                    warning('No vignetting calibration exists for this camera; not correcting for vignetting');
                    pf = cat(3, zeros(3, 3), zeros(3, 3), zeros(3, 3), ones(3, 3));
                end
                
                fr      = sub_feval(pf(1, 1, :), exc) / sub_feval(pf(1, 1, :), 0);
                fg      = sub_feval(pf(1, 2, :), exc) / sub_feval(pf(1, 2, :), 0);
                fb      = sub_feval(pf(1, 3, :), exc) / sub_feval(pf(1, 3, :), 0);
                obj.VignettingMat{1} = cat(3, fr, fg, fb);
                fr      = sub_feval(pf(2, 1, :), exc) / sub_feval(pf(2, 1, :), 0);
                fg      = sub_feval(pf(2, 2, :), exc) / sub_feval(pf(2, 2, :), 0);
                fb      = sub_feval(pf(2, 3, :), exc) / sub_feval(pf(2, 3, :), 0);
                obj.VignettingMat{2} = cat(3, fr, fg, fb);
                fr      = sub_feval(pf(3, 1, :), exc) / sub_feval(pf(3, 1, :), 0);
                fg      = sub_feval(pf(3, 2, :), exc) / sub_feval(pf(3, 2, :), 0);
                fb      = sub_feval(pf(3, 3, :), exc) / sub_feval(pf(3, 3, :), 0);
                obj.VignettingMat{3} = cat(3, fr, fg, fb);
                
                storedVign = obj.VignettingMat;
                storedVignName = vignname;
            end


            function y = sub_feval(fun, x)
                y = fun(1)*x.^3 + fun(2)*x.^2 + fun(3)*x + fun(4);
            end
        end

        %% SPECTRAL FUNCTIONS
        function obj = loadSpectralCalibration(obj)

            switch lower(obj.CameraString)
                case {'nikon d800e', 'nikon d810', 'nikon z 6'}
                    camstring = 'nikon d810'; % use d810 calibration for all these models
                otherwise
                    camstring = obj.CameraString;
            end

            switch obj.SpectralMethod
                case 'colmat' % Full deconvolution of channels to reconstruct a spectrum that is flat between 400-500, 500-600 and 600-700 nm
                    obj.SpectralMatrix  = obj.getColMat(camstring);                                
                case 'col' % Scale individual channels so each one represents the weighted average spectral photon radiance over that pixels sensitivity
                    obj.SpectralMatrix  = obj.getCol(camstring);                    
                case 'wb'
                    % Uses the white balance multipliers from each files exif information
            end

        end
     

        function colmat = getColMat(obj, camstring)
            % load or calculate color correction matrix for this image camera type
            % Saving to a file and loading when needed has been tested and takes longer than recalculating on ELFPC (0.8s v 0.2s)
            
            persistent storedColMat;
            persistent storedColMatName;
                
            if strcmp(camstring, storedColMatName) && ~isempty(storedColMat)
                colmat  = storedColMat;
            else % load from file
                para    = elf_para;
                fname = fullfile(para.paths.calibfolder, lower(camstring), 'rgb_calib.mat');
                if isfile(fname)
                    TEMP    = load(fname, 'colmat');  
                    colmat  = TEMP.colmat;
                else
                    error('No colour calibration exists for this camera, and colmat method is not possible: %s', camstring);
                end
        
                storedColMat     = colmat;
                storedColMatName = camstring;
            end
        end
        

        function col = getCol(obj, camstring)
            % load or calculate color correction vector for this image camera type
            % Saving to a file and loading when needed has been tested and takes longer than recalculating on ELFPC (0.8s v 0.2s)
            
            persistent storedCol;
            persistent storedColName;
                
            if strcmp(camstring, storedColName) && ~isempty(storedCol)
                col     = storedCol;
            else % load from file
                para    = elf_para;
                fname = fullfile(para.paths.calibfolder, lower(camstring), 'rgb_calib.mat');
                if isfile(fname)
                    TEMP    = load(fname, 'col');            
                    col     = TEMP.col;
                else
                    col = [];
                end
        
                storedCol     = col;
                storedColName = camstring;
            end
        end
    end
end

