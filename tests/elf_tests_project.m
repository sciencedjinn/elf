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
azi = [-90, 0.1, 90];
ele = [90, -0.1, -90];
azi2 = [-20, 0.1, 80];
ele2 = [60, -0.1, -90];
imsize_rect = [length(ele(1):ele(2):ele(3)) length(azi(1):azi(2):azi(3)) 3];
imsize_rect2 = [length(ele2(1):ele2(2):ele2(3)) length(azi2(1):azi2(2):azi2(3)) 3];
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
proj = Projector.fromInfoStructs(infoSum, cal.ProjectionInfo, azi, ele);
proj2 = Projector.fromInfoStructs(infoSum, cal.ProjectionInfo, azi2, ele2);
im_ori = cal.applyAbsolute(im_raw, I_info);
im_ori  = cal.applySpectral(im_ori, I_info); % apply spectral calibration
toc1 = toc;

%% Image circle cropping
im_black = proj.blackout(im_ori);

% 1
tic
[projection_ind, newProj]      = proj.crop2imageCircle(90);
infoSumCC1 = infoSum; infoSumCC1.grids = newProj.getProjectionInfo(0);
im_projCC1                     = Projector.apply(im_black, projection_ind, newProj.Size);
tocX1 = toc;

% 1
tic
[projection_ind, newProj]      = newProj.crop2ImageCircle(90);
infoSumCC2 = infoSum; infoSumCC2.grids = newProj.getProjectionInfo(0);
im_projCC2                     = Projector.apply(im_projCC1, projection_ind, newProj.Size);
tocX2 = toc;

% 1
tic
[projection_ind, newProj]      = proj.crop2ImageCircle(45);
infoSumCC3 = infoSum; infoSumCC3.grids = newProj.getProjectionInfo(0);
im_projCC3                     = Projector.apply(im_black, projection_ind, newProj.Size);
tocX3 = toc;

% 1
tic
[projection_ind, newProj]      = newProj.crop2ImageCircle(90);
infoSumCC4 = infoSum; infoSumCC4.grids = newProj.getProjectionInfo(0);
im_projCC4                     = Projector.apply(im_projCC3, projection_ind, newProj.Size);
im_projCC4(im_projCC4<0) = 0;
tocX4 = toc;

figure(2); clf; drawnow;
h = axes;
infoSum1 = infoSum; infoSum1.grids = proj.getProjectionInfo(0);
elf_plot_image(im_ori, infoSum1, h, 'equisolid', 'bright');
title(sprintf('original'))

figure(3); clf; drawnow;
h = axes;
elf_plot_image(im_projCC1, infoSumCC1, h, 'equisolid', 'bright');
title(sprintf('Cropped to 90 deg\n%.2f seconds', tocX1))

figure(4); clf; drawnow;
h = axes;
elf_plot_image(im_projCC2, infoSumCC2, h, 'equisolid', 'bright');
title(sprintf('Cropped again to 90 deg\n%.2f seconds', tocX2))

figure(5); clf; drawnow;
h = axes;
elf_plot_image(im_projCC3, infoSumCC3, h, 'equisolid', 'bright');
title(sprintf('Cropped to 45 deg\n%.2f seconds', tocX1))

figure(6); clf; drawnow;
h = axes;
elf_plot_image(im_projCC4/max(im_projCC4(:)), infoSumCC4, h, 'equisolid', 'bright');
title(sprintf('Cropped back to 90 deg\n%.2f seconds', tocX2))
% NOTE the issue here: colour correction comes out weird with this unusual image
return

%% Test fisheye reprojection
% 1
tic
[projection_ind, newProj]      = proj.fisheye2fisheyeProjection("equisolid", [1000, 1000, 3], 0);
infoSumRP1 = infoSum; infoSumRP1.grids = newProj.getProjectionInfo(0);
im_projRP1                     = Projector.apply(im_ori, projection_ind, [1000, 1000, 3]);
tocX1 = toc;

% 4
tic
[projection_ind, newProj]      = proj.fisheye2fisheyeProjection("equidistant", [1000, 1000, 3], 0);
infoSumRP2 = infoSum; infoSumRP2.grids = newProj.getProjectionInfo(0);
im_projRP2                      = Projector.apply(im_ori, projection_ind, [1000, 1000, 3]);
tocX2 = toc;

% 4
tic
[projection_ind, newProj]      = proj.fisheye2fisheyeProjection("stereographic", [1000, 1000, 3], 0);
infoSumRP3 = infoSum; infoSumRP3.grids = newProj.getProjectionInfo(0);
im_projRP3                      = Projector.apply(im_ori, projection_ind, [1000, 1000, 3]);
tocX3 = toc;

% 4
tic
[projection_ind, newProj]      = proj.fisheye2fisheyeProjection("orthographic", [1000, 1000, 3], 0);
infoSumRP4 = infoSum; infoSumRP4.grids = newProj.getProjectionInfo(0);
im_projRP4                      = Projector.apply(im_ori, projection_ind, [1000, 1000, 3]);
tocX4 = toc;

figure(5); clf; drawnow;
h = axes;
infoSum1 = infoSum; infoSum1.grids = proj.getProjectionInfo(0);
elf_plot_image(im_ori, infoSum1, h, 'equisolid', 'bright');
title(sprintf('original'))

figure(6); clf; drawnow;
h = axes;
elf_plot_image(im_projRP1, infoSumRP1, h, 'equisolid', 'bright');
title(sprintf('RP equisolid\n%.2f seconds', tocX1))

figure(7); clf; drawnow;
h = axes;
elf_plot_image(im_projRP2, infoSumRP2, h, 'equisolid', 'bright');
title(sprintf('RP equidistant\n%.2f seconds', tocX2))

figure(8); clf; drawnow;
h = axes;
elf_plot_image(im_projRP3, infoSumRP3, h, 'equisolid', 'bright');
title(sprintf('RP stereographic\n%.2f seconds', tocX3))

figure(9); clf; drawnow;
h = axes;
elf_plot_image(im_projRP4, infoSumRP4, h, 'equisolid', 'bright')
title(sprintf('RP orthographic\n%.2f seconds', tocX4))

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
projection_ind                = proj.calculateProjection(0);
infoSum1 = infoSum; infoSum1.grids = proj.getProjectionInfo(0);
im_proj1                      = Projector.apply(im_ori, projection_ind, proj.RectSize);
toc4 = toc;

% 5
tic
projection_ind                = proj.calculateProjection(45);
infoSum2 = infoSum; infoSum2.grids = proj.getProjectionInfo(45);
im_proj2                      = Projector.apply(im_ori, projection_ind, proj.RectSize);
toc5 = toc;

% 6
tic
projection_ind                = proj.calculateProjection(-45);
infoSum3 = infoSum; infoSum3.grids = proj.getProjectionInfo(-45);
im_proj3                      = Projector.apply(im_ori, projection_ind, proj.RectSize);
toc6 = toc;

% 7
tic
projection_ind                = proj2.calculateProjection(0);
infoSum4 = infoSum; infoSum4.grids = proj2.getProjectionInfo(0);
im_proj4                      = proj2.apply(im_ori, projection_ind, proj2.RectSize);
toc7 = toc;

% 8
tic
im_reproj1                    = proj.fastBackProjection(im_proj2, -45);
toc8 = toc;

% 9
tic
im_reproj2                    = proj2.fastBackProjection(im_proj4, 0);
im_reproj2(isnan(im_reproj2)) = 0;
toc9 = toc;

% 10
tic
im_reproj3                    = proj2.fastBackProjection(im_proj4, 45);
im_reproj3(isnan(im_reproj3)) = 0;
toc10 = toc;

%%
% 11
tic
projection_ind                = proj.calculateBackProjection(-45);
im_temp                       = proj.apply(im_proj2, projection_ind, imsize_fish2);
im_reproj4                    = proj.blackout(im_temp);
toc11 = toc;
 
% 12
tic
projection_ind                = proj2.calculateBackProjection(45);
im_temp                       = proj.apply(im_proj4, projection_ind, imsize_fish2);
im_reproj5                    = proj.blackout(im_temp);
im_reproj5(isnan(im_reproj5)) = 0;
toc12 = toc;

% 13
tic
projection_ind                = proj.calculateBackProjection(0);
im_temp                       = proj.apply(im_proj2, projection_ind, imsize_fish2);
im_reproj6                    = proj.blackout(im_temp);
toc13 = toc;

% 14
tic
projection_ind                = proj.calculateBackProjection(-45);
im_temp                       = proj.apply(im_proj2, projection_ind, imsize_fish2);
im_reproj7                    = proj.blackout(im_temp);
toc14 = toc;

% 15
tic
projection_ind                = proj2.calculateBackProjection(45);
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







