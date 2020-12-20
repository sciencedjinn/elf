function [X, Y, Z] = elf_project_fisheye2cart(w_im, h_im, I_info, method, rotation)
% ELF_PROJECT_FISHEYE2CART takes fisheye image coordinates and projects them onto Cartesian coordinates (X/Y/Z)
% The output index vectors can be used to reproject a cartesian image (e.g. on a sphere) into a fisheye image.
% 
% [X, Y, Z] = elf_project_fisheye2cart(w_im, h_im, I_info, method, rotation)
%
% Inputs:
% w_im, h_im    - x and y grids (image coordinates) defining the desired grid of the projected image along image width and height, respectively
% I_info        - Image information structure (only uses Height, Width, FocalLength and Model)
% method        - The desired fisheye projection. Currently supports 'equisolid'(e.g. D810)/'orthographic'/'equidistant'
% rotation      - Angle (in degrees) by which the image should be rotated clockwise before processing (Use 90 or -90 for portrait images)
%
% Outputs:
% X, Y, Z       - same size as w_im/h_im, and contain the corresponding image coordinates 
%
% Usage example:
% [w_grid, h_grid] = meshgrid(1:I_info.Width, 1:I_info.Height);
% [X, Y, Z] = elf_project_fisheye2rect(w_grid, h_grid, I_info, 'equisolid', 0)

if nargin<5 || isempty(rotation), rotation = 0; end
if nargin<4 || isempty(method), method = 'default'; end
  
mid         = [1+(I_info.Height-1)/2; 1+(I_info.Width-1)/2];        % centre of image
shortSide   = min([I_info.Height I_info.Width]);

switch method
    case {'equisolid', 'default'}
        r = I_info.FocalLength * shortSide / 24;              % theoretical value for 24mm high chip that is fully covered by fisheye circular image
        R_pix       = sqrt((h_im-mid(1)).^2 + (w_im-mid(2)).^2);    % a point's radial position on the sensor (in pixels)
        R_mm        = R_pix / shortSide * 24;                    % a point's radial position on the sensor (in mm on a 24 mm chip)

        theta       = 2 * asind(R_mm / 2 / I_info.FocalLength);      % angle between point in the real world and the optical axis
        gamma       = atan2d((h_im-mid(1)), (w_im-mid(2))) - rotation;

        X           = cosd(theta) * r;
        r_yz        = sind(theta) * r;
        r_yz(~isreal(r_yz)) = NaN; % set to NaN some points far out of the image circle
        r_yz = real(r_yz);
        Y           = r_yz .* cosd(gamma);
        Z           = r_yz .* -sind(gamma); % This minus makes sure that low image indeces are mapped onto high-elevation points 
    case 'equidistant'
        error('This method has not yet been implemented'); 
    case 'orthographic'
        error('This method has not yet been implemented');
    otherwise
        error('Unknown method')
end