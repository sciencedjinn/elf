% function elf_tests_project(test_filename)
%
%
%
% test_filename - Filename of a fisheye DNG image that can be used for tests

% if nargin<1, 
    test_filename = 'G:\data\ELF data sets\ELF test data\475 Danbulla rainfor clouds 1200\VE3_7117.dng'; 
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

%% load test image
% 1
tic
I_info = elf_info_load(test_filename);
infoSum   = elf_info_summarise(I_info);
imsize_fish2 = [infoSum.Height infoSum.Width infoSum.SamplesPerPixel];
im_raw    = double(elf_io_imread(test_filename));
I_info = Calibrator.calculateBlackLevels(I_info, "*.dng");
cal = Calibrator(I_info.Model, [I_info.Width I_info.Height], 'wb');
proj = Projector(infoSum, cal.ProjectionInfo);
im_ori = cal.applyAbsolute(im_raw, I_info);
im_ori  = cal.applySpectral(im_ori, I_info); % apply spectral calibration
toc1 = toc;

%%
% 2
tic
im_black = proj.blackout(im_ori);
toc2 = toc;

% 3
tic
im_black2 = proj.blackout(im_ori, 45);
toc3 = toc;

% 4
tic
projection_ind                = proj.calculateProjection(azi, ele, 0);
infoSum1                      = proj.getProjectionInfo(infoSum, azi, ele, 0);
im_proj1                      = Projector.apply(im_ori, projection_ind, imsize_rect);
toc4 = toc;

% 5
tic
projection_ind                = proj.calculateProjection(azi, ele, 45);
infoSum2                      = proj.getProjectionInfo(infoSum, azi, ele, 45);
im_proj2                      = Projector.apply(im_ori, projection_ind, imsize_rect);
toc5 = toc;

% 6
tic
projection_ind                = proj.calculateProjection(azi, ele, -45);
infoSum3                      = proj.getProjectionInfo(infoSum, azi, ele, -45);
im_proj3                      = Projector.apply(im_ori, projection_ind, imsize_rect);
toc6 = toc;

% 7
tic
projection_ind                = proj.calculateProjection(azi2, ele2, 0);
infoSum4                      = proj.getProjectionInfo(infoSum, azi2, ele2, 0);
im_proj4                      = proj.apply(im_ori, projection_ind, imsize_rect2);
toc7 = toc;

% 8
tic
im_reproj1                    = proj.fastBackProjection(im_proj2, azi, ele, -45);
toc8 = toc;

% 9
tic
im_reproj2                    = proj.fastBackProjection(im_proj4, azi2, ele2, 0);
im_reproj2(isnan(im_reproj2)) = 0;
toc9 = toc;

% 10
tic
im_reproj3                    = proj.fastBackProjection(im_proj4, azi2, ele2, 45);
im_reproj3(isnan(im_reproj3)) = 0;
toc10 = toc;

%%
% 11
tic
projection_ind                = proj.calculateBackProjection(azi, ele, -45);
im_temp                       = proj.apply(im_proj2, projection_ind, imsize_fish2);
im_reproj4                    = proj.blackout(im_temp);
toc11 = toc;
 
% 12
tic
projection_ind                = proj.calculateBackProjection(azi2, ele2, 45);
im_temp                       = proj.apply(im_proj4, projection_ind, imsize_fish2);
im_reproj5                    = proj.blackout(im_temp);
im_reproj5(isnan(im_reproj5)) = 0;
toc12 = toc;

% 13
tic
projection_ind                = proj.calculateBackProjection(azi, ele, 0);
im_temp                       = proj.apply(im_proj2, projection_ind, imsize_fish2);
im_reproj6                    = proj.blackout(im_temp);
toc13 = toc;

% 14
tic
projection_ind                = proj.calculateBackProjection(azi, ele, -45);
im_temp                       = proj.apply(im_proj2, projection_ind, imsize_fish2);
im_reproj7                    = proj.blackout(im_temp);
toc14 = toc;

% 15
tic
projection_ind                = proj.calculateBackProjection(azi2, ele2, 45);
im_temp                       = proj.apply(im_proj4, projection_ind, imsize_fish2);
im_reproj8                    = proj.blackout(im_temp);
im_reproj8(isnan(im_reproj8)) = 0;
toc15 = toc;

%% plot results
figure(1); clf; drawnow;
h = subplot(3, 5, 1); 
elf_plot_image(im_ori, infoSum1, h, 'equisolid', 'bright')
title(sprintf('original\n%.2f seconds to load and calibrate', toc1))

h = subplot(3, 5, 2);
elf_plot_image(im_black, infoSum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_blackout\n%.2f seconds', toc2))

h = subplot(3, 5, 3);
elf_plot_image(im_black2, infoSum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_blackout 45\\circ\n%.2f seconds', toc3))

h = subplot(3, 5, 4);
elf_plot_image(im_proj1, infoSum1, h, 'equirectangular', 'bright')
title(sprintf('elf\\_project\\_image without rotation\n%.2f seconds', toc4))

h = subplot(3, 5, 5);
elf_plot_image(im_proj2, infoSum2, h, 'equirectangular', 'bright')
title(sprintf('elf\\_project\\_image with 45\\circ rotation\n%.2f seconds', toc5))



h = subplot(3, 5, 6);
elf_plot_image(im_proj3, infoSum3, h, 'equirectangular', 'bright')
title(sprintf('elf\\_project\\_image with -45\\circ rotation\n%.2f seconds', toc6))

h = subplot(3, 5, 7);
elf_plot_image(im_proj4, infoSum4, h, 'equirectangular', 'bright')
title(sprintf('elf\\_project\\_image crop \nto -90:60 elevation and -20:80 azimuth\n%.2f seconds', toc7))

h = subplot(3, 5, 8);
elf_plot_image(im_reproj1, infoSum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_simple of \n45\\circ-rotated image with -45\\circ rotation\n%.2f seconds', toc8))

h = subplot(3, 5, 9);
elf_plot_image(im_reproj2, infoSum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_simple of \ncropped image\n%.2f seconds', toc9))

h = subplot(3, 5, 10);
elf_plot_image(im_reproj3, infoSum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_simple of \ncropped image, rotated 45\\circ\n%.2f seconds', toc10))

h = subplot(3, 5, 11);
elf_plot_image(im_reproj4, infoSum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye of \n45\\circ-rotated image with -45\\circ rotation\n%.2f seconds', toc11))

h = subplot(3, 5, 12);
elf_plot_image(im_reproj5, infoSum1, h, 'undefined', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye of \ncropped image, rotated 45\\circ\n%.2f seconds', toc12))

h = subplot(3, 5, 13);
elf_plot_image(im_reproj6, infoSum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_frominfo of \n45\\circ-rotated image with 0\\circ rotation\n%.2f seconds', toc13))

h = subplot(3, 5, 14);
elf_plot_image(im_reproj7, infoSum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_frominfo of \n45\\circ-rotated image with -45\\circ rotation\n%.2f seconds', toc14))

h = subplot(3, 5, 15);
elf_plot_image(im_reproj8, infoSum1, h, 'equisolid', 'bright')
title(sprintf('elf\\_project\\_reproject2fisheye\\_frominfo of \ncropped image, rotated 45\\circ\n%.2f seconds', toc15))







