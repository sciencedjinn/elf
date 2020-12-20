function [azi, ele] = elf_project_fisheye2rect(w_im, h_im, I_info, method, rotation)
% ELF_PROJECT_FISHEYE2RECT takes fisheye image coordinates and projects them onto a equirectangular image (azimuth/elevation)
% The output index vectors can be used to reproject a equirectangular image into a fisheye image.
% 
% [w_im, h_im] = elf_project_fisheye2rect(az, el, I_info, method) 
%
% Inputs:
% w_im, h_im    - x and y grids (image coordinates) defining the desired grid of the projected image along image width and height, respectively
% I_info        - Image information structure (only uses Height, Width, FocalLength and Model)
% method        - The desired fisheye projection. Currently supports 'equisolid'(e.g. D810)/'orthographic'/'equidistant'
% rotation      - Angle (in degrees) by which the image should be rotated clockwise before processing (Use 90 or -90 for portrait images)
%
% Outputs:
% azi, ele      - same size as w/h, and contain the corresponding image coordinates 
%
% Usage example:
% [w_grid, h_grid] = meshgrid(1:I_info.Width, 1:I_info.Height);
% [azi, ele] = elf_project_fisheye2rect(w_grid, h_grid, I_info, 'equisolid', 0)

if nargin < 5 || isempty(rotation), rotation = []; end

[X, Y, Z]           = elf_project_fisheye2cart(w_im, h_im, I_info, method, rotation);
[azi_rad, ele_rad]  = cart2sph(X, Y, Z);
azi                 = rad2deg(azi_rad);
ele                 = rad2deg(ele_rad);
