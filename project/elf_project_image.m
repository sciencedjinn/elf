function [projection_ind, I_info] = elf_project_image(I_info, azi, ele, sourceProj, targetProj, rotation)
% ELF_PROJECT_IMAGE creates a projection index vector to transform a fisheye image into a equirectangular (azimuth/elevation) grid
%
% Inputs:
% I_info     - Image information structure (only uses Height, Width, SamplesPerPixel, FocalLength and Model)
% azi, ele   - output angle ranges defining the desired grid of the projected images (default -90:0.1:90, and 90:-0.1:-90)
% sourceProj - The original fisheye projection. Currently supports 'equisolid'(e.g. D810)/'orthographic'/'equidistant'
% targetProj - The desired output projection. This is "equirectangular" for normal ELF analysis, but might be different for modules, e.g. "equisolid"
%                to retain the fisheye projection
% rotated    - 
%
% Outputs:
% projection_ind  - projections index matrix. The projected image can be calculated as im_proj = im(projection_ind)
% I_info          - Image information structure with projection grids added. These can be used in plotting.

% Uses: elf_project_rect2fisheye, which uses elf_project_sub2ind

if nargin<6 || isempty(rotation), rotation = 0; end
if nargin<5 || isempty(targetProj), targetProj = 'default'; end
if nargin<4 || isempty(sourceProj), sourceProj = 'default'; end
if nargin<3 || isempty(ele), ele = 90:-0.1:-90; end
if nargin<2 || isempty(azi), azi = -90:0.1:90; end

                    Logger.log(LogLevel.INFO, '\tCalculating projection constants...\n');

%% Provide 'noproj' mode for internal testing. In this mode, images are assumed to already be projected into equirectangular projection
if strcmp(sourceProj, 'noproj')
    % this mode is available for internal testing
    I_info.ori_grid_x   = [];    
    I_info.ori_grid_y   = [];
    I_info.proj_grid_x  = [];    
    I_info.proj_grid_y  = [];
    I_info.proj_azi     = azi; 
    I_info.proj_ele     = ele;
    projection_ind      = 1:I_info.Height*I_info.Width*I_info.SamplesPerPixel;
    return;
end

%% parameters
gridres1 = 10;  % resolution of the displayed grid between lines
gridres2 = 1;   % resolution of the displayed grid along lines

%% Calculate main projections
[azi_grid, ele_grid] = meshgrid(azi, ele);                    % grid of desired angles
[w_im, h_im]         = elf_project_rect2fisheye(azi_grid, ele_grid, I_info, sourceProj, rotation);
% [w_im, y_im]         = elf_project_rect2fisheye_simple(azi_grid, ele_grid, I_info.Width, I_info.Height, I_info.FocalLength, rotation); % for testing and comparison
projection_ind       = elf_project_sub2ind([I_info.Height I_info.Width I_info.SamplesPerPixel], w_im, h_im);

%% Calculate grids for plotting
% a) grid for original projection
[gazi1, gele1]       = meshgrid(-90:gridres1:90, -90:gridres2:90);
[gazi2, gele2]       = meshgrid(-90:gridres2:90, -90:gridres1:90);
gazi2                = gazi2'; 
gele2                = gele2';

%  Link all grid lines into a single NaN clipped vector
r                    = size(gazi1, 1);
gazi1(r+1, :)        = NaN;
gele1(r+1, :)        = NaN;
r                    = size(gazi2, 1);
gazi2(r+1, :)        = NaN;
gele2(r+1, :)        = NaN;
gazi                 = [gazi1(:); gazi2(:)];
gele                 = [gele1(:); gele2(:)];

[I_info.ori_grid_x, I_info.ori_grid_y] = elf_project_rect2fisheye(gazi, gele, I_info, sourceProj, rotation);

% b) grid for projected image (assumes that grid points are included in image grid)
[~, I_info.proj_grid_x] = ismember(gazi, azi);
[~, I_info.proj_grid_y] = ismember(gele, ele);
I_info.proj_grid_x(I_info.proj_grid_x==0) = NaN;    % 0 indicates the element was not found
I_info.proj_grid_y(I_info.proj_grid_y==0) = NaN;

I_info.proj_azi      = azi;
I_info.proj_ele      = ele;

                    Logger.log(LogLevel.INFO, '\t\tdone.\n');
                    