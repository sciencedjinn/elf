function im = elf_io_correctdng(lin_im, meta_info, method, maxval)
% ELF_IO_CORRECTDNG takes a linear DNG image (uint16 values), converts its
%   colour space to sRGB and gamma-corrects it for "normal" display (assuming normal white balance is set). 
%   Algorithm adapted from Rob Sumner (2014) "Processing RAW Images in
%   MATLAB", http://users.soe.ucsc.edu/~rcsumner/rawguide/RAWguide.pdf
%
% Usage: im = elf_io_correctdng(lin_im, meta_info)
%
% Inputs:
%   lin_im      - linear image to be displayed, can be double, uint8, uint16 
%   meta_info   - exif info struct, only needed for the ColorMatrix2 value, so can be infosum
%   method      -  normalisation method:    'bitdepth' : default method, normalise depending on maximum of lin_im 
%                                                        (1 if max<1, 2^8 if max<2^8, 2^16 if max<2^16, max otherwise)
%                                           'max'      : normalise to the maximum of lin_im
%                                           'maxval'   : normalise to the input argument maxval
%                                           'bright'/'maxbright'/'maxvalbright' : use a bright version of gamma correction
%

%%
if nargin<3, method = 'default'; end
if nargin<2 || isempty(meta_info) || (length(meta_info.ColorMatrix2) == 1 && meta_info.ColorMatrix2 == 0)
    meta_info.ColorMatrix2 = [0.7866, -0.2108, -0.0555, -0.4869, 1.2483, 0.2681, -0.1176, 0.2069, 0.7501];
    warning('io_correctdng: No valid colour correction matrix provided. Using standard D800 matrix.');
end

%% Parameters
% create conversion matrices
rgb2xyz  = [.4124564 .3575761 .1804375
            .2126729 .7151522 .0721750
            .0193339 .1191920 .9503041];           % from Adobe sRGB to XYZ colour space
xyz2cam  = reshape(meta_info.ColorMatrix2, 3, 3)'; % from XYZ to camera colour space
rgb2cam  = xyz2cam * rgb2xyz;                      % from sRGB to camera colour space
rgb2cam  = rgb2cam ./ repmat(sum(rgb2cam,2),1,3);  % normalize rows to 1
cam2rgb  = rgb2cam^-1;                             % from camera to sRGB colour space

%% 1) Normalise
lin_im   = double(lin_im);

switch method
    case {'default', 'bitdepth', 'bright'}
        if max(lin_im(:)) <= 1,         mv   = 1;
        elseif max(lin_im(:)) <= 2^8,   mv   = 2^8;
        elseif max(lin_im(:)) <= 2^16,  mv   = 2^16; 
        else                            mv   = max(lin_im(:));
        end
    case {'max', 'maxbright'}
                                        mv   = max(lin_im(:));
    case {'maxval', 'maxvalbright'}
                                        mv = maxval;
    otherwise
        error('Unknown correctdng method: %s', method);
end
lin_im   = lin_im / mv;

%% 2) Colour Space Conversion to sRGB
lin_srgb = sub_apply_cmatrix(lin_im, cam2rgb);     % apply conversion matrix
lin_srgb = max(0, min(lin_srgb,1));                 % Always keep image clipped b/w 0-1

%% 3) Gamma correction
im       = sub_srgbGamma(lin_srgb);
if strcmp(method, 'bright') || strcmp(method, 'maxvalbright') || strcmp(method, 'maxbright')
    %% 3) Gamma correction (bright version)
    grayim      = rgb2gray(lin_srgb);
    grayscale   = 0.25/mean(grayim(:));
    bright_srgb = min(1, lin_srgb*grayscale);
    im          = sub_srgbGamma(bright_srgb);
end

end

%% subfunctions
function corrected = sub_apply_cmatrix(im, cmatrix)
    % CORRECTED = sub_apply_cmatrix(IM, CMATRIX)
    %
    % Applies CMATRIX to RGB input IM. Finds the appropriate weighting of the
    % old color planes to form the new color planes, equivalent to but much
    % more efficient than applying a matrix transformation to each pixel.

    if size(im,3)~=3
        error('Apply cmatrix to RGB image only.')
    end

    r = cmatrix(1,1)*im(:,:,1) + cmatrix(1,2)*im(:,:,2) + cmatrix(1,3)*im(:,:,3);
    g = cmatrix(2,1)*im(:,:,1) + cmatrix(2,2)*im(:,:,2) + cmatrix(2,3)*im(:,:,3);
    b = cmatrix(3,1)*im(:,:,1) + cmatrix(3,2)*im(:,:,2) + cmatrix(3,3)*im(:,:,3);
    corrected = cat(3,r,g,b);
end

function im = sub_srgbGamma(im)
    % im = sub_srgbGamma(im)
    %
    % Applies  a standard (inverse) sRGB gamma correction to an RGB image.
    % Assumes input values are scaled between 0 and 1, returns a similar range.
    
    im(im > 1)  = 1; % Clip values to between 0-1 (unnecessary in this case; already done above)
    im(im < 0)  = 0;
    nl          = im > 0.0031308; % anything > a count of ~205
    im(nl)      = 1.055 * im(nl).^(1/2.4) - 0.055;
    im(~nl)     = 12.92 * im(~nl);
end

