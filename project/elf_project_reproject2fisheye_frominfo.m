function projection_ind = elf_project_reproject2fisheye_frominfo(I_info, azi, ele, method, rotation)
% ELF_PROJECT_REPROJECT2FISHEYE takes a equirectangular image and project it back to an equisolid fisheye image.
%
% [x_im, y_im] = elf_project_cart2fisheye(im, azi, ele, imsize_fisheye, Rotation)
%
% Inputs:
% I_info        - Image information structure (only uses Height, Width, SamplesPerPixel, FocalLength and Model)
% azi, ele      - Azimuth/elevation vectors IN DEGREES defining the x and y axes of im, respectively. These MUST be evenly sampled and monotonous.
% method        - The desired fisheye projection. Currently supports 'equisolid'(e.g. D810)/'orthographic'/'equidistant'
% rotation      - Angle (in degrees) by which the image should be rotated clockwise before processing (Use 90 or -90 for portrait images)
%
% Outputs:
% projection_ind  - projections index matrix. The projected image can be calculated as im_proj = im(projection_ind)

if nargin < 5 || isempty(rotation), rotation = 0; end
if nargin < 4 || isempty(method), method = 'default'; end
if nargin < 3 || isempty(ele), ele = linspace(90, -90, size(im, 1)); end
if nargin < 2 || isempty(azi), azi = linspace(-90, 90, size(im, 2)); end

%% Calculate azi/ele sampling
azisteps = diff(azi);
elesteps = diff(ele);
if length(unique(round(1./azisteps)))>1, error('azi MUST be evenly sampled.'); else azires = mean(azisteps); end
if length(unique(round(1./elesteps)))>1, error('ele MUST be evenly sampled.'); else eleres = mean(elesteps); end

%% Calculate main projections        
[w_grid, h_grid]         = meshgrid(1:I_info.Width, 1:I_info.Height);          % grid of desired output image coordinates
[target_azi, target_ele] = elf_project_fisheye2rect(w_grid, h_grid, I_info, method, rotation);
% calculate azi/ele index vectors
azi_ind                  = (target_azi - azi(1)) / azires + 1;
ele_ind                  = (target_ele - ele(1)) / eleres + 1;
% remove out-of-bounds azi and ele pairs
sel                      = target_azi>max(azi) | target_azi<min(azi) | target_ele>max(ele) | target_ele<min(ele);
azi_ind(sel)             = NaN; 
ele_ind(sel)             = NaN;
% and create linear index vector
projection_ind           = elf_project_sub2ind([length(ele) length(azi) I_info.SamplesPerPixel], azi_ind, ele_ind);