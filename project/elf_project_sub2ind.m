function ind = elf_project_sub2ind(imsize, w_im, h_im)
% ELF_PROJECT_SUB2IND turns x/y subscript index vectors into a linear index vector ind for a three-dimensional matrix
% Use this for quick reprojection of images.
%
% Inputs:
% imsize            - 3x1 double, size of the image to be sampled
% w_im, h_im        - image coordinates obtained from elf_project_rect2fisheye
%
% Outputs:
% projection_ind    - projections index matrix. The projected image can be calculated as im_proj = im(projection_ind)
%
% Example:
% imsize       = [I_info.Height I_info.Width I_info.SamplesPerPixel];
% [w_im, h_im] = elf_project_rect2fisheye(az, el, I_info, method);
% ind          = elf_project_sub2ind(imsize, x_im, y_im)
%
% See also: elf_project_apply

%% calculate linear index vector for projection
ind1    = repmat(round(h_im(:)), imsize(3), 1); % repeat three times to call for each channel
ind2    = repmat(round(w_im(:)), imsize(3), 1); % repeat three times to call for each channel
ind3    = reshape(repmat(1:imsize(3), length(w_im(:)), 1), [], 1);

ind1(ind1>imsize(1)) = NaN;
ind2(ind2>imsize(2)) = NaN;
ind1(ind1<1) = NaN;
ind2(ind2<1) = NaN;

ind     = sub2ind(imsize, ind1, ind2, ind3);    % transform into linear indexes