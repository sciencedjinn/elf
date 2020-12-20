function [im, conf, conffactors] = elf_calibrate_abssens(im, info)
% ELF_CALIBRATE_ABSSENS transforms a raw digital image to absolute spectral photon luminance (in photons/nm/s/sr/m^2)
% For a full calibration, elf_calibrate_spectral has to be called afterwards!
%
% [im, conf, conffactors] = elf_calibrate_abssens(im, info)
%
% Inputs:
%   im          - M x N x 3 double, raw digital image (as obtained from elf_io_loaddng)
%   info        - 1 x 1 struct, info structure, containing the exif information of the raw image file (created by elf_info_collect or elf_info_load)
%       
% Outputs:
%   im          - M x N x 3 double, calibrated digital image (in photons/nm/s/sr/m^2), but not spectrally corrected
%   conf        - M x N x 3 double, an estimate of confidence based on noise for each pixel (used for HDR calculations)
%   conffactors - 2 x 1 double, the combined calibration factor (correcting for exp/iso/apt) and the saturation limit (minus dark)
%
% Call sequence: elf -> elf_main1_HdrAndInt -> elf_calibrate_abssens
%
% See also: elf_main1_HdrAndInt, elf_info_load, elf_io_loaddng, elf_calibrate_darkandreadout, elf_calibrate_spectral


%% Check inputs
assert(min(size(info))==1, 'Input argument info must be one-dimensional');
if ~isa(im, 'double') % If read from elf_io_loaddng, images will usually still be uint16
    im = double(im);  % Type-cast image to double if necessary
end 

%% Extract camera parameters and calibration factors
exp         = info.DigitalCamera.ExposureTime;      % exposure time in seconds
iso         = info.DigitalCamera.ISOSpeedRatings;   % ISO speed
apt         = info.DigitalCamera.FNumber;           % Aperture F-Stop

% correct for uneven aperture spacing, and calculate aperture "area" 
ev_num      = round(log(apt) / log(sqrt(2)) * 3);
apt_even    = sqrt(2).^(ev_num/3);
aparea      = pi * (4./apt_even).^2.292; % 2.292 was determined during 2017 aperture calibration

% load calibration factors depending on camera model
calfactors  = sub_loadCalib(info.Model, size(im, 1), size(im, 2), exp, iso, info);
combfac     = exp * iso * aparea * calfactors.absolute; % factor to get to absolute sensitivity (taking into account spectral calibration)
% This calibration factor is the product of the old expcorr*aptcorr*isocorr factors and the 0.871378457487805 correction factor found for white light
% in 2017 linearity calibration

%% Perform calibration
% Subtract the camera's black level (saturation level has to be taken into account later)
im          = im - calfactors.darkmeanmat;

conf        = im; % Use these raw values (after dark subtraction) to define every pixels confidence: 
                  % In HDR calculation, each HDR pixel will be assigned the radiance value it holds in the image where it has the highest confidence 
conffactors = [combfac; calfactors.saturation - calfactors.darkmean'];

% correct for exposure time, ISO setting (gain) and aperture
im          = im / combfac;            % counts per second per ISO per aperture

%% correct for vignetting
switch apt
    case {3.5, 4, 4.5, 4.8}
        apind = 1; % treat as aperture 3.5 for vignetting
    case {8, 9, 10, 11, 14}
        apind = 2; % treat as aperture 8 for vignetting
    case 22
        apind = 3; % treat as aperture 22 for vignetting
    otherwise
        error('Aperture %g currently not supported.', apt);
end

im = im ./ calfactors.vign{apind};

% Further calibration (for spectral sensitivity) will be done after HDR calculation in elf_calibrate_spectral

if nargin<1, figure(748); clf; image(im./mean(im(:))/4); axis image; end % debug

end % main function



%% subfunctions
function y = sub_feval(fun, x)
    y = fun(1)*x.^3 + fun(2)*x.^2 + fun(3)*x + fun(4);
end

function calfactors = sub_loadCalib(camstring, height, width, exp, iso, info)
    switch lower(camstring)
        case {'nikon d800e', 'nikon d810', 'nikon d850', 'nikon z 6'}
            % Dark noise / readout factors
            [calfactors.darkmean, calfactors.saturation] = elf_calibrate_darkandreadout('nikon d810', exp, iso, info, true);
            if isequal(lower(camstring), 'nikon d850') || isequal(lower(camstring), 'nikon z 6') || isequal(lower(camstring), 'nikon d800e')
                calfactors.darkmean = calfactors.darkmean - 600 + info.BlackLevel(1);
            end
            calfactors.darkmeanmat = sub_getdarkmeanmat(calfactors.darkmean, 'nikon d810', height, width, exp, iso);
            
            % 1. ISO/EXP/APT 2016 calibration
            para    = elf_para;
            TEMP    = load(fullfile(para.paths.calibfolder, lower('nikon d810'), 'absolute.mat'));   
            calfactors.absolute  = TEMP.absolute;
                        
            % 2. Vignetting
            calfactors.vign     = sub_getVign('nikon d810', height, width);
            
            

        otherwise
            warning('No intensity calibration available for this camera (%s) ', camstring);

    end
end

function dmm = sub_getdarkmeanmat(darkmean, camstring, height, width, exp, iso)
    % Load or calculate darkmean correction for this camera type, width/height
    
    persistent storedDMM;
    persistent storedDMMName;
    
    dmmname             = sprintf('%s_%d_%d_%.6f_%d', camstring, height, width, exp, iso);
    
    if strcmp(dmmname, storedDMMName) && ~isempty(storedDMM)
        dmm             = storedDMM;
    else
        dmm             = cat(3, darkmean(1) * ones(height, width), darkmean(2) * ones(height, width), darkmean(3) * ones(height, width));
        storedDMM       = dmm;
        storedDMMName   = dmmname;
    end
end

function vign = sub_getVign(camstring, height, width)
    % Load or calculate vignetting correction for this image camera type, width/height
    % Saving to a file and loading when needed has been tested and takes longer than recalculating on ELFPC (10s v 3s)
    
    persistent storedVign;
    persistent storedVignName;
    
    vignname = sprintf('%s_%d_%d', camstring, height, width);
    
    if strcmp(vignname, storedVignName) && ~isempty(storedVign)
        vign    = storedVign;
    else
        % Calculate excentricity and vignetting correction, and store in persistents
        mid     = [1+(height-1)/2; 1+(width-1)/2];   % centre of image (x/y, h/w)
        r_full  = 8 * min([height width]) / 24;      % theoretical value for 24mm high chip that is fully covered by fisheye circular image
        [y, x]  = meshgrid(1:width, 1:height);       % x/y positions of all points in the image
        r_all   = sqrt((x-mid(1)).^2 + (y-mid(2)).^2);
        exc     = real(asind(r_all / 2 / r_full) * 2);  % remove the complex part that happens for excentricities >90

        % Calculate vignetting correction
        para    = elf_para;
        TEMP    = load(fullfile(para.paths.calibfolder, lower(camstring), 'vign_calib.mat')); % holds pf, fitted vignetting-correction function
        fr      = sub_feval(TEMP.pf(1, 1, :), exc) / sub_feval(TEMP.pf(1, 1, :), 0);
        fg      = sub_feval(TEMP.pf(1, 2, :), exc) / sub_feval(TEMP.pf(1, 2, :), 0);
        fb      = sub_feval(TEMP.pf(1, 3, :), exc) / sub_feval(TEMP.pf(1, 3, :), 0);
        vign{1} = cat(3, fr, fg, fb);
        fr      = sub_feval(TEMP.pf(2, 1, :), exc) / sub_feval(TEMP.pf(2, 1, :), 0);
        fg      = sub_feval(TEMP.pf(2, 2, :), exc) / sub_feval(TEMP.pf(2, 2, :), 0);
        fb      = sub_feval(TEMP.pf(2, 3, :), exc) / sub_feval(TEMP.pf(2, 3, :), 0);
        vign{2} = cat(3, fr, fg, fb);
        fr      = sub_feval(TEMP.pf(3, 1, :), exc) / sub_feval(TEMP.pf(3, 1, :), 0);
        fg      = sub_feval(TEMP.pf(3, 2, :), exc) / sub_feval(TEMP.pf(3, 2, :), 0);
        fb      = sub_feval(TEMP.pf(3, 3, :), exc) / sub_feval(TEMP.pf(3, 3, :), 0);
        vign{3} = cat(3, fr, fg, fb);
        
        storedVign = vign;
        storedVignName = vignname;
    end
end

