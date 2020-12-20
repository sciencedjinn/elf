function im_fisheye = elf_project_reproject2fisheye_simple(im, azi, ele, imsize_fisheye, rotation, method)
% ELF_PROJECT_REPROJECT2FISHEYE takes a equirectangular image and project it back to an equisolid fisheye image.
%
% [x_im, y_im] = elf_project_cart2fisheye(im, azi, ele, imsize, Rotation)
%
% Inputs:
% im             - MxNxC double, the equirectangular image to be transformed
% azi, ele       - Azimuth/elevation vectors IN DEGREES defining the x and y axes of im, respectively
% imsize_fisheye - 2x1 double, the height and width (in pixels) of the desired fisheye image (default 4000 and 4000)
% rotation       - Angle (in degrees) by which the image should be rotated before processing (Use 90 or -90 for portrait images)
% method         - 'interpolate' (default): projects each equirectangular pixel into fisheye space, and then interpolates using griddata
%                  'nearestneighbour':      projects each fisheye pixel onto equirectangular space, and them samples the nearest pixel
%
% Outputs:
% im_proj        - Output fisheye image

if nargin < 6 || isempty(method), method = 'default'; end
if nargin < 5 || isempty(rotation), rotation = 0; end
if nargin < 4 || isempty(imsize_fisheye), imsize_fisheye = [4000 5000]; end
if nargin < 3 || isempty(ele), ele = linspace(-90, 90, size(im, 1)); end
if nargin < 2 || isempty(azi), azi = linspace(-90, 90, size(im, 2)); end

switch method
    case {'interpolate', 'interp', 'default'}
        [azi_grid, ele_grid]    = meshgrid(azi, ele);                                   % grid of desired angles
        [w_im, h_im]            = elf_project_rect2fisheye_simple(azi_grid, ele_grid, imsize_fisheye(2), imsize_fisheye(1), [], -rotation);
        [w_grid, h_grid]        = meshgrid(1:imsize_fisheye(2), 1:imsize_fisheye(1));   % grid of desired output pixels

        im_fisheye              = zeros(imsize_fisheye(1), imsize_fisheye(2), size(im, 3)); % pre-allocate
        for ch = 1:size(im, 3) % for each channel
            thisch               = im(:, :, ch);
                                   warning('off', 'MATLAB:griddata:DuplicateDataPoints');
            im_fisheye(:, :, ch) = griddata(h_im(:), w_im(:), thisch(:), h_grid, w_grid, 'cubic'); %#ok<GRIDD>
                                   warning('on', 'MATLAB:griddata:DuplicateDataPoints');

            %% Alternative: scatteredInterpolant version, which is a LOT slower (~10x), but gives the same results
%             F = scatteredInterpolant(y_im(:), x_im(:), thisch(:));
%             im_fisheye(:, :, ch) = F(y_grid, x_grid);
        end
        im_fisheye = elf_project_blackout(im_fisheye, 90, [], 0); % set points beyond 90 degrees to 0
    case {'nearestneighbour', 'nn', 'nearestpixel'}
        projection_ind           = elf_project_reproject2fisheye(azi, ele, imsize_fisheye, rotation);
        im_temp                  = elf_project_apply(im, projection_ind, imsize_fisheye);
        im_fisheye               = elf_project_blackout(im_temp);
end
