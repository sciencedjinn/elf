classdef Calibrator
    %CALIBRATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BlackLevel
        BlackLevelMat
        WhiteLevel % the manufacturer's white level
        SaturationLevel % raw counts higher than this (before dark correction) are considered saturated  
        AbsoluteFactor
        AbsoluteMat
        VignettingMat
        Acf     % Aperture correction factor in new d850 calibration
    end

    properties(SetAccess=immutable)
        CameraString
        Height
        Width
    end
    
    methods
        function obj = Calibrator(camString, height, width, blackLevel, whiteLevel, info)
            %CALIBRATOR Construct an instance of this class
            %   Detailed explanation goes here
            obj.CameraString = camString;
            obj.Height = height;
            obj.Width = width;
            obj.BlackLevel = blackLevel;
            obj.WhiteLevel = whiteLevel;
            obj = obj.loadCalib(info.DigitalCamera.ExposureTime, info.DigitalCamera.ISOSpeedRatings); % TODO: This info stuff should be removed here somehow, or streamlined
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end

    methods(Hidden, Access=protected)
        function obj = loadCalib(obj, exp, iso)

            switch lower(obj.CameraString)
                case {'nikon d800e', 'nikon d810', 'nikon z 6'}
                    % 1. black and white levels
                    obj.SaturationLevel = 15520; % 15992 was found in calibration, 15520 is the black value in EXIF file
                    
                    % 2. ISO/EXP/APT 2016 calibration
                    para    = elf_para;
                    TEMP    = load(fullfile(para.paths.calibfolder, 'nikon d810', 'absolute.mat'));
                    obj.AbsoluteFactor = TEMP.wlcf;
                    
                    % 3. Vignetting
                    obj = obj.getVignMat('nikon d810');
        
                case 'nikon d850'
                    % 1. black and white levels
                    obj.SaturationLevel = 15520;
        
                    % 2. ISO/EXP/APT calibration
                    para    = elf_para;
                    TEMP    = load(fullfile(para.paths.calibfolder, obj.CameraString, 'absolute.mat'));
                    obj.Acf      = TEMP.acf;
                    obj.AbsoluteFactor = TEMP.wlcf;
                                
                    % 3. Vignetting
                    obj = obj.getVignMat('nikon d810');
                    
                otherwise
                    % For an unknown camera, use no calibration correction; an uncalibrated image is better than none
                    % 1. black and white levels
                    obj.SaturationLevel   = 0.95*obj.WhiteLevel;      % white level, this should corresponds to a reasonable saturation level
        
                    % 2. ISO/EXP/APT calibration
                    obj.AbsoluteFactor = [1 1 1];
                                
                    % 3. Vignetting
                    obj = obj.getVignMat('nikon d810');
        
                    warning('No intensity calibration available for this camera (%s) ', obj.CameraString);
            end

            % calculate mats for faster calibration later
            obj = obj.getBlackLevelMat(exp, iso);
            obj = obj.getAbsoluteMat();

        end

        function obj = getBlackLevelMat(obj, exp, iso)
            % Load or calculate black level correction matrix for this camera type, width/height
            
            persistent storeBLM;
            persistent storedBLMName;
            
            blmname               = sprintf('%s_%d_%d_%.6f_%d', obj.CameraString, obj.Height, obj.Width, exp, iso);
            
            if strcmp(blmname, storedBLMName) && ~isempty(storeBLM)
                obj.BlackLevelMat = storeBLM;
            else
                obj.BlackLevelMat = cat(3, obj.BlackLevel(1) * ones(obj.Height, obj.Width), obj.BlackLevel(2) * ones(obj.Height, obj.Width), obj.BlackLevel(3) * ones(obj.Height, obj.Width));
                storeBLM          = obj.BlackLevelMat;
                storedBLMName     = blmname;
            end
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
    end
end

