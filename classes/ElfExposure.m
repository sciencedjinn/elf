classdef ElfExposure
    % ELFEXPOSURE Summary of this class goes here
    %   Detailed explanation goes here

    % This class is meant to replace the current constructs in elf_main1_HdrAndInt
    % There could be two other classes, ElfScene and Calibrator
    % Started on 2024/02/16, should be continued some time...

    properties
        FileName(1,1) string
        BlackLevel(1,1) double
        SaturationLevel(1,1) double
        Exif(1,1) struct
        Image(:, :, :) double
    end

    properties(Dependent)
        ExposureValue(1,1) double
        Exp(1,1) double
        Apt(1,1) double
        Iso(1,1) double
    end

    methods
        function obj = ElfExposure(fileName, info)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.FileName = fileName;
            if nargin<2
                obj.Exif = elf_info_load(obj.FileName);
            else
                obj.Exif = info;
            end
            
            % Set the black level and saturation level to camera manufacturer values; these can/will be overwritten by calibration routines
            if isfield(obj.Exif, 'BlackLevel')
                manufacturerBlackLevel = obj.Exif.BlackLevel;
            else
                manufacturerBlackLevel = obj.Exif.SubIFDs{1}.BlackLevel;
            end
            if length(unique(manufacturerBlackLevel))>1
                error('The EXIF data includes more than one black level. Presumably this means they are different for different colour channels, but ELF has never dealt with this before. Investigate before proceeding!');
            elseif isempty(unique(manufacturerBlackLevel))
                error('The EXIF data includes an empty black level field. Investigate before proceeding!');
            else
                obj.BlackLevel = manufacturerBlackLevel(1);
            end

            % White level, same as for black
            if isfield(obj.Exif, 'WhiteLevel')
                manufacturerWhiteLevel = obj.Exif.WhiteLevel;
            else
                manufacturerWhiteLevel = obj.Exif.SubIFDs{1}.WhiteLevel;
            end
            if length(unique(manufacturerWhiteLevel))>1
                error('The EXIF data includes more than one white level. Presumably this means they are different for different colour channels, but ELF has never dealt with this before. Investigate before proceeding!');
            elseif isempty(unique(manufacturerWhiteLevel))
                error('The EXIF data includes an empty white level field. Investigate before proceeding!');
            else
                obj.SaturationLevel = 0.95*manufacturerWhiteLevel(1);
            end                
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end

    %% Get methods for dependent properties
    methods
        function exp  = get.Exp(obj)
            exp = obj.Exif.DigitalCamera.ExposureTime;
        end
        function iso = get.Iso(obj)
            iso = obj.Exif.DigitalCamera.ISOSpeedRatings;
        end
        function apt = get.Apt(obj)
            apt = obj.Exif.DigitalCamera.FNumber;           % Aperture F-Stop
        end
        function ev = get.ExposureValue(obj)
            ev = obj.Exp * obj.Iso * pi * (4./obj.Apt).^2; % Todo: This can be better, if there is a calibration
        end
    end
end