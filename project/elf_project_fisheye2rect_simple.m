function [azi, ele] = elf_project_fisheye2rect_simple(w_im, h_im, Width, Height, FocalLength, Rotation)
% ELF_PROJECT_FISHEYE2RECT_SIMPLE takes equisolid fisheye coordinates (azimuth/elevation) and projects them onto a equirectangular/spherical image.
% The output index vectors can be used to reproject a equirectangular image into an equisolid fisheye image (e.g. from Nikon D810 with Sigma 8mm lens).
% 
% [azi, ele] = elf_project_fisheye2rect_simple(w_im, h_im, Width, Height, FocalLength, Rotation)
%
% Inputs:
% w_im, h_im    - w and h grids (image coordinates) defining the desired grid of the projected image
% Width, Height - The width and height (in pixels) of the fisheye image (default 6144 and 4912 fro D810)
% FocalLength   - The focal length of the lens (in mm) (default 8mm for Sigma 8mm fisheye lens)
% Rotation      - Angle (in degrees) by which the image should be rotated clockwise before processing (Use 90 or -90 for portrait images)
%
% Outputs:
% azi, ele      - same size as x/y, and contain the corresponding image coordinates 
%
% Usage example:
% [w_grid, h_grid]  = meshgrid(1:6000, 1:4000);
% [azi, ele]        = elf_project_fisheye2rect_simple(w_grid, h_grid, 6000, 4000, 8, 0)

if nargin < 6 || isempty(Rotation),     Rotation = 0;    end
if nargin < 5 || isempty(FocalLength),  FocalLength = 8; end
if nargin < 4 || isempty(Height),       Height = 4912;   end
if nargin < 3 || isempty(Width),        Width = 6144;    end
    
mid         = [1+(Height-1)/2; 1+(Width-1)/2];        % centre of image
shortSide   = min([Height Width]);
r           = FocalLength * shortSide / 24;           % theoretical value for 24mm high chip that is fully covered by fisheye circular image

R_pix       = sqrt((h_im-mid(1)).^2 + (w_im-mid(2)).^2);    % a point's radial position on the sensor (in pixels)
R_mm        = R_pix / shortSide * 24;                    % a point's radial position on the sensor (in mm on a 24 mm chip)

theta       = 2 * asind(R_mm / 2 / FocalLength);      % angle between point in the real world and the optical axis
gamma       = atan2d((h_im-mid(1)), (w_im-mid(2))) - Rotation;

r_yz        = sind(theta) * r;
r_yz(~isreal(r_yz)) = NaN; % set to NaN some points far out of the image circle
r_yz        = real(r_yz);

X           = cosd(theta) * r;
Y           = r_yz .* cosd(gamma);
Z           = r_yz .* -sind(gamma); % This minus makes sure that low image indeces are mapped onto high-elevation points  
  
[azi_r, ele_r] = cart2sph(X, Y, Z);

azi         = rad2deg(azi_r);
ele         = rad2deg(ele_r);