function [w_im, h_im] = elf_project_rect2fisheye(az, el, I_info, method, rotation)
% ELF_PROJECT_RECT2FISHEYE takes equirectangular/spherical coordinates (azimuth/elevation) and projects them onto a fisheye image.
% The output index vectors can be used to reproject a fisheye image onto a equirectangular grid.
% 
% [w_im, h_im] = elf_project_rect2fisheye(az, el, I_info, method)
%
% Inputs:
% az, el     - Azimuth/elevation grids IN DEGREES defining the desired grid of the projected image
% I_info     - Image information structure (only uses Height, Width, FocalLength and Model)
% method     - The desired fisheye projection. Currently supports 'equisolid'(e.g. D810)/'orthographic'/'equidistant'
% rotation   - Angle (in degrees) by which the image should be rotated clockwise before processing (Use 90 or -90 for portrait images)
%
% Outputs:
% w_im, h_im - same size as azi/ele, and contain the corresponding image coordinates along image width and height, respectively
%
% Usage example:
% ele = 90:-0.1:-90;
% azi = -90:0.1:90;
% [azi_grid, ele_grid] = meshgrid(azi, ele);
% [w_im, h_im] = elf_project_rect2fisheye(azi_grid, ele_grid, infosum, 'equisolid')

if nargin<5 || isempty(rotation), rotation = []; end

[X, Y, Z]    = sph2cart(deg2rad(az), deg2rad(el), 1);
[w_im, h_im] = elf_project_cart2fisheye(X, Y, Z, I_info, method, rotation);
