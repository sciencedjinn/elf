function im = elf_project_apply(im, proj_ind, imsize)
% ELF_PROJECT_APPLY applies a linear index vector ind to a three-dimensional matrix (image).
% Use this for quick reprojection of images.
%
% Inputs:
% im            - image to unwarp
% ind           - linear index vector into the first two dimensions of im (obtained from elf_project_sub2ind)
% imsize        - 3x1 double, size of the output image
%
% Outputs:
% im            - projections index matrix. The projected image can be calculated as im_proj = im(projection_ind)
%
% Example:
% imsize_fisheye = [I_info.Height I_info.Width I_info.SamplesPerPixel];
% [x_im, y_im]   = elf_project_rect2fisheye(az, el, I_info, method);
% ind            = elf_project_sub2ind(imsize_fisheye, x_im, y_im)
% imsize_rect    = [length(ele) length(azi) I_info.SamplesPerPixel];
% im             = elf_project_apply(im, ind, imsize_rect)

%% NaNs in the projection index indicate invalid points. Remove for now, and set to NaN later
sel = isnan(proj_ind);
proj_ind(sel) = 1;

%% index image
im_temp = im(proj_ind);

%% now set invalid points to NaN
im_temp(sel) = NaN;

%% and reshape back into an image
im = reshape(im_temp, imsize);