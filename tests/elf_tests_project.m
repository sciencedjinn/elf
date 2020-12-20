% function elf_tests_project(test_filename)
%
%
%
% test_filename - Filename of a fisheye DNG image that can be used for tests

% if nargin<1, 
    test_filename = 'G:\VE3_6770.dng'; 
% end

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
elf_paths;

%% some variables
azi = -90:0.1:90;
ele = 90:-0.1:-90;
azi2 = -20:0.1:80;
ele2 = 60:-0.1:-90;
[azg, elg] = meshgrid(azi, ele);
imsize_rect = [length(ele) length(azi) 3];
imsize_rect2 = [length(ele2) length(azi2) 3];
imsize_fish = [4000 5000 3];
imsize_fish2 = [infosum.Height infosum.Width infosum.SamplesPerPixel];

%% load test image
% 1
tic
I_info    = elf_info_load(test_filename);
infosum   = elf_info_summarise(I_info);
im_raw    = elf_io_imread(test_filename);
im_ori    = elf_calibrate_abssens(im_raw, I_info);
im_ori    = elf_calibrate_spectral(im_ori, I_info, 'wb'); % apply spectral calibration 'wb'/'col'
toc1 = toc;

% 2
tic
im_black = elf_project_blackout(im_ori);
toc2 = toc;

% 3
tic
im_black2 = elf_project_blackout(im_ori, 45);
toc3 = toc;

% 4
tic
[projection_ind, infosum1]    = elf_project_image(infosum, azi, ele, 'equisolid', 0);
im_proj1                      = elf_project_apply(im_ori, projection_ind, imsize_rect);
toc4 = toc;

% 5
tic
[projection_ind, infosum2]    = elf_project_image(infosum, azi, ele, 'equisolid', 45);
im_proj2                      = elf_project_apply(im_ori, projection_ind, imsize_rect);
toc5 = toc;

% 6
tic
[projection_ind, infosum3]    = elf_project_image(infosum, azi, ele, 'equisolid', -45);
im_proj3                      = elf_project_apply(im_ori, projection_ind, imsize_rect);
toc6 = toc;

% 7
tic
[projection_ind, infosum4]    = elf_project_image(infosum, azi2, ele2, 'equisolid', 0);
im_proj4                      = elf_project_apply(im_ori, projection_ind, imsize_rect2);
toc7 = toc;

% 8
tic
im_reproj1                    = elf_project_reproject2fisheye_simple(im_proj2, azi, ele, imsize_fish, -45);
toc8 = toc;

% 9
tic
im_reproj2                    = elf_project_reproject2fisheye_simple(im_proj4, azi2, ele2, imsize_fish, 0);
im_reproj2(isnan(im_reproj2)) = 0;
toc9 = toc;

% 10
tic
im_reproj3                    = elf_project_reproject2fisheye_simple(im_proj4, azi2, ele2, imsize_fish, 45);
im_reproj3(isnan(im_reproj3)) = 0;
toc10 = toc;

% 11
tic
projection_ind                = elf_project_reproject2fisheye(azi, ele, imsize_fish, -45);
im_temp                       = elf_project_apply(im_proj2, projection_ind, imsize_fish);
im_reproj4                    = elf_project_blackout(im_temp);
toc11 = toc;
 
% 12
tic
projection_ind                = elf_project_reproject2fisheye(azi2, ele2, imsize_fish, 45);
im_temp                       = elf_project_apply(im_proj4, projection_ind, imsize_fish);
im_reproj5                    = elf_project_blackout(im_temp);
im_reproj5(isnan(im_reproj5)) = 0;
toc12 = toc;

% 13
tic
projection_ind                = elf_project_reproject2fisheye_frominfo(infosum, azi, ele, 'equisolid', 0);
im_temp                       = elf_project_apply(im_proj2, projection_ind, imsize_fish2);
im_reproj6                    = elf_project_blackout(im_temp);
toc13 = toc;

% 14
tic
projection_ind                = elf_project_reproject2fisheye_frominfo(infosum, azi, ele, 'equisolid', -45);
im_temp                       = elf_project_apply(im_proj2, projection_ind, imsize_fish2);
im_reproj7                    = elf_project_blackout(im_temp);
toc14 = toc;

% 15
tic
projection_ind                = elf_project_reproject2fisheye_frominfo(infosum, azi2, ele2, 'equisolid', 45);
im_temp                       = elf_project_apply(im_proj4, projection_ind, imsize_fish2);
im_reproj8                    = elf_project_blackout(im_temp);
im_reproj8(isnan(im_reproj8)) = 0;
toc15 = toc;

%% plot results
figure(1); clf; drawnow;
h = subplot(3, 5, 1); 
elf_plot_image(im_ori, infosum1, h, 'equisolid', 'bright')
title(sprintf('original\n%.2f seconds to load and calibrate', toc1))

h = subplot(3, 5, 2);
elf_plot_image(im_black, infosum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_blackout\n%.2f seconds', toc2))

h = subplot(3, 5, 3);
elf_plot_image(im_black2, infosum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_blackout 45\\circ\n%.2f seconds', toc3))

h = subplot(3, 5, 4);
elf_plot_image(im_proj1, infosum1, h, 'equirectangular', 'bright')
title(sprintf('elf\\_project\\_image without rotation\n%.2f seconds', toc4))

h = subplot(3, 5, 5);
elf_plot_image(im_proj2, infosum2, h, 'equirectangular', 'bright')
title(sprintf('elf\\_project\\_image with 45\\circ rotation\n%.2f seconds', toc5))



h = subplot(3, 5, 6);
elf_plot_image(im_proj3, infosum3, h, 'equirectangular', 'bright')
title(sprintf('elf\\_project\\_image with -45\\circ rotation\n%.2f seconds', toc6))

h = subplot(3, 5, 7);
elf_plot_image(im_proj4, infosum4, h, 'equirectangular', 'bright')
title(sprintf('elf\\_project\\_image crop \nto -90:60 elevation and -20:80 azimuth\n%.2f seconds', toc7))

h = subplot(3, 5, 8);
elf_plot_image(im_reproj1, infosum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_simple of \n45\\circ-rotated image with -45\\circ rotation\n%.2f seconds', toc8))

h = subplot(3, 5, 9);
elf_plot_image(im_reproj2, infosum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_simple of \ncropped image\n%.2f seconds', toc9))

h = subplot(3, 5, 10);
elf_plot_image(im_reproj3, infosum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_simple of \ncropped image, rotated 45\\circ\n%.2f seconds', toc10))

h = subplot(3, 5, 11);
elf_plot_image(im_reproj4, infosum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye of \n45\\circ-rotated image with -45\\circ rotation\n%.2f seconds', toc11))

h = subplot(3, 5, 12);
elf_plot_image(im_reproj5, infosum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye of \ncropped image, rotated 45\\circ\n%.2f seconds', toc12))

h = subplot(3, 5, 13);
elf_plot_image(im_reproj6, infosum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_frominfo of \n45\\circ-rotated image with 0\\circ rotation\n%.2f seconds', toc13))

h = subplot(3, 5, 14);
elf_plot_image(im_reproj7, infosum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_frominfo of \n45\\circ-rotated image with -45\\circ rotation\n%.2f seconds', toc14))

h = subplot(3, 5, 15);
elf_plot_image(im_reproj8, infosum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_frominfo of \ncropped image, rotated 45\\circ\n%.2f seconds', toc15))







