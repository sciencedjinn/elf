function [im, conf, confFactors] = elf_calibrate_abssens(im, info, blackLevel)
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
% Call sequence: elf -> elf_main1_HdrAndInt -> elf_calibrate_abssens
%
% See also: elf_main1_HdrAndInt, elf_info_load, elf_io_loaddng, elf_calibrate_darkandreadout, elf_calibrate_spectral

%% Check inputs
assert(min(size(info))==1, 'Input argument info must be one-dimensional');
if ~isa(im, 'double') % If read from elf_io_loaddng, images will usually still be uint16
    im = double(im);  % Type-cast image to double if necessary
end 

%% load calibration factors depending on camera model
cal = Calibrator(info.Model, size(im, 1), size(im, 2), blackLevel, info.SubIFDs{1}.WhiteLevel(1), info);

%% apply calibration
[im, conf, confFactors] = sub_applyCalib(im, info, cal);


% Further calibration (for spectral sensitivity) will be done after HDR calculation in elf_calibrate_spectral

if nargin<1, figure(748); clf; image(im./mean(im(:))/4); axis image; end % debug

end % main function



%% subfunctions
function [im, conf, confFactors] = sub_applyCalib(im, info, cal)

    % Extract camera parameters and calibration factors
    exp         = info.DigitalCamera.ExposureTime;      % exposure time in seconds
    iso         = info.DigitalCamera.ISOSpeedRatings;   % ISO speed
    apt         = info.DigitalCamera.FNumber;           % Aperture F-Stop

    %% Apply calibration
    % Subtract the camera's black level (saturation level has to be taken into account later)
    im          = im - cal.BlackLevelMat;
    conf        = im; % Use these raw values (after dark subtraction) to define every pixel's confidence: 
                      % In HDR calculation, each HDR pixel will be assigned the radiance value it holds in the image where it has the highest confidence 
    confFactors = cal.SaturationLevel - cal.BlackLevel(:)';

    switch lower(cal.CameraString)
        case {'nikon d800e', 'nikon d810', 'nikon z 6'}
            % 2. ISO/EXP/APT 2016 calibration

            % correct for uneven aperture spacing, and calculate aperture "area" 
            ev_num      = round(log(apt) / log(sqrt(2)) * 3);
            apt_even    = sqrt(2).^(ev_num/3);
            aparea      = pi * (4./apt_even).^2.292; % 2.292 was determined during 2017 aperture calibration

            settingFactor  = exp * iso * aparea;
            
        case 'nikon d850'

            % 2. ISO/EXP/APT calibration
            acf     = cal.Acf(cal.Acf(:, 1)==apt, 2);
            settingFactor  = exp * iso * acf;
        
        otherwise
            settingFactor  = exp * iso / apt.^2;
    end   
    
    % correct for exposure time, ISO setting (gain) and aperture
    im          = im ./ settingFactor ./ cal.AbsoluteMat;            % counts per second per ISO per aperture
    
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
    im          = im ./ cal.VignettingMat{apInd};

end


