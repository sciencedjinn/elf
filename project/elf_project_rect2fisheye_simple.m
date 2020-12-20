function [w_im, h_im] = elf_project_rect2fisheye_simple(azi, ele, Width, Height, FocalLength, Rotation)
% ELF_PROJECT_RECT2FISHEYE_SIMPLE takes equirectangular/spherical coordinates (azimuth/elevation) and projects them onto an equisolid fisheye image.
% The output index vectors can be used to reproject an equisolid fisheye image (e.g. from Nikon D810 with Sigma 8mm lens) onto a equirectangular grid.
% 
% [w_im, h_im] = elf_project_rect2fisheye_simple(az, el, Width, Height, FocalLength, Rotation)
%
% Inputs:
% az, el        - Azimuth/elevation grids IN DEGREES defining the desired grid of the projected image
% Width, Height - The width and height (in pixels) of the fisheye image (default 6144 and 4912 fro D810)
% FocalLength   - The focal length of the lens (in mm) (default 8mm for Sigma 8mm fisheye lens)
% Rotation      - Angle (in degrees) by which the image should be rotated clockwise before processing (Use 90 or -90 for portrait images)
%
% Outputs:
% w_im, h_im    - same size as azi/ele, and contain the corresponding image coordinates along image width and height, respectively
%
% Usage example:
% ele = 90:-0.1:-90;
% azi = -90:0.1:90;
% [azi_grid, ele_grid] = meshgrid(azi, ele);
% [w_im, h_im] = elf_project_rect2fisheye(azi_grid, ele_grid, 6144, 4912, 8, 0)

if nargin < 6 || isempty(Rotation),     Rotation = 0;    end
if nargin < 5 || isempty(FocalLength),  FocalLength = 8; end
if nargin < 4 || isempty(Height),       Height = 4912;   end
if nargin < 3 || isempty(Width),        Width = 6144;    end

mid         = [1+(Height-1)/2; 1+(Width-1)/2];        % centre of image
shortSide   = min([Height Width]);
r           = FocalLength * shortSide / 24;           % theoretical value for 24mm high chip that is fully covered by fisheye circular image

% Reminder: Matlab images have their horizontal axis as the SECOND coordinate
[X, Y, Z]   = sph2cart(deg2rad(azi), deg2rad(ele), 1);
theta       = acosd(X);                                % theta is the angle between a viewing direction and the X-axis (X is equal to the scalar dot product of that direction and the X-axis)
gamma       = atan2d(-Z, Y);                           % gamma is the angle between the Y/Z projection of a viewing direction and the Y axis; the -Z makes sure that high elevation values are mapped onto a low image index

% rotate
gamma       = gamma - Rotation;

r2          = 2 * r * sind(theta/2);                  % this relationship defines the equisolid projection

w_im        = r2 .* cosd(gamma) + mid(2);             % along w; this is 0 + mid for azimuth 0
h_im        = r2 .* sind(gamma) + mid(1);             % along h; this is 0 + mid for elevation 0, and -1 + mid for elevation 90



