function elf_main1_HdrAndInt(dataset, imgformat, verbose, rotation)
% ELF_MAIN1_HDRANDINT calibrates and unwarps all images in a data set, sorts them into
% scenes, and calculates HDR representations of these scenes as mat for later contrast calculations and as tif for the mean image. 
% Intensity descriptors are calculated for each exposure and then combined for scenes based on individual pixel reliability.
%
% Uses: elf_paths, elf_support_logmsg, elf_para, elf_info_collect, 
%       elf_info_summarise, elf_hdr_brackets, elf_project_image, 
%       elf_io_readwrite, elf_hdr_calcHDR, elf_io_correctdng, elf_io_imread
%       elf_analysis_int, elf_support_formatA4l, elf_plot_intsummary
%
% Loads files: DNG image files in data folder
% Saves files: HDR image files in scene subfolder, *.mat files in scenes subfolder, per-scene intensity results in mat folder

elf_paths;

%% Run parameters
savejpgs        = false;                                              % save individual jpgs for each image? (takes extra time)

%% check inputs
if nargin < 4, rotation = 0; end
if nargin < 3, verbose = false; end
if nargin < 2 || isempty(imgformat), imgformat = '*.dng'; end
if nargin < 1 || isempty(dataset), error('You have to provide a valid dataset name'); end 

                    elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b\n');
                    elf_support_logmsg('----- ELF Step 1: Calibration, HDR and Intensity -----\n')

%% Set up paths and file names; read info, infosum and para, calculate sets
para            = elf_para('', dataset, imgformat, verbose);
info            = elf_info_collect(para.paths.datapath, imgformat);   % this contains EXIF information and filenames, verbose==1 means there will be output during system check
infosum         = elf_info_summarise(info, verbose);                  % summarise EXIF information for this dataset. This will be saved for later use below
infosum.linims  = strcmp(imgformat, '*.dng');                         % if linear images are used, correct for that during plotting
sets            = elf_hdr_brackets(info);                             % determine which images are part of the same scene
                    elf_support_logmsg('      Processing %d scenes in environment %s.\n', size(sets, 1), dataset);

%% Set up projection constants
% Calculate a projection vector to transform an orthographic/equidistant/equisolid input image into an equirectangular output image
% Also creates I_info.ori_grid_x1, I_info.ori_grid_y1 (and 2) which can be used to plot a 10 degree resolution grid onto the original image

                    elf_support_logmsg('      Calculating projection constants...');

[projection_ind, infosum] = elf_project_image(infosum, para.azi, para.ele2, para.projtype, rotation); % default: 'equisolid'; also possible: 'orthographic' / 'equidistant' / 'noproj'
elf_io_readwrite(para, 'saveinfosum', [], infosum); % saves infosum AND para for use in later stages
                    
                    elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\bdone.\n');

%% Step 1: Unwarp images and calculate HDR scenes

tic; % Start taking time

% Process one scene at a time
for setnr = 1:size(sets, 1)
    clear im_filt res
    
    setstart    = sets(setnr, 1);          % first image in this set
    setend      = sets(setnr, 2);          % last image in this set
    numims      = setend - setstart + 1;   % total number of images in this set
    im_proj     = zeros(length(para.ele), length(para.azi), infosum.SamplesPerPixel, numims);  % pre-allocate
    im_proj_cal = zeros(length(para.ele), length(para.azi), infosum.SamplesPerPixel, numims);  % pre-allocate
    conf_proj   = zeros(length(para.ele), length(para.azi), infosum.SamplesPerPixel, numims);  % pre-allocate
    conffactors = zeros(4, numims);        % pre-allocate
    
    for i = 1:numims % for each image in this set
        % Load image        
        imnr                    = setstart + i - 1;     % the number of this image
        fname                   = info(imnr).Filename;  % full path to input image file
        im_raw                  = elf_io_imread(fname);   % load the image (uint16)

        % Calibrate and calculate intensity confidence
        [im_cal, conf, conffactors(:, i)] = elf_calibrate_abssens(im_raw, info(imnr)); 
        
        % Umwarp image        
        im_proj(:, :, :, i)     = elf_project_apply(im_cal, projection_ind, [length(para.ele) length(para.azi) infosum.SamplesPerPixel]);
        im_proj_cal(:, :, :, i) = elf_calibrate_spectral(im_proj(:, :, :, i), info(imnr), para.ana.colourcalibtype); % only needed for 'histcomb'-type intensity calculation, but not time-intensive

        conf_proj(:, :, :, i)   = elf_project_apply(conf, projection_ind, [length(para.ele) length(para.azi) infosum.SamplesPerPixel]);
    end
    
    % Sort images by EV
    EV          = arrayfun(@(x) x.DigitalCamera.ExposureBiasValue, info(setstart:setend));
    [~, imInd]  = sort(EV);         % sorted EV (ascending), for HDR calculation
    im_proj     = im_proj(:, :, :, imInd);
    im_proj_cal = im_proj_cal(:, :, :, imInd);
    conf_proj   = conf_proj(:, :, :, imInd);
    conffactors = conffactors(:, imInd);
    
    % scale images to match middle exposure (creates a warning if scaling by more than 30%)
    [im_proj, res.scalefac] = elf_hdr_scaleStack(im_proj, conf_proj, conffactors(2:end, :));
    
    % Pass a figure number and an outputfilename here only if you want diagnostic pdfs.
    % However, MATLAB can't currently deal with saving these large figures, so no pdf will be created either way.
    im_HDR      = elf_hdr_calcHDR(im_proj, conf_proj, para.ana.hdrmethod, conffactors(1, :), conffactors(2:end, :)); % para.ana.hdrmethod can be 'overwrite', 'overwrite2', 'validranges', 'allvalid', 'allvalid2' (default), 'noise', para.ana.hdrmethod
    im_HDR_cal  = elf_calibrate_spectral(im_HDR, info(setstart), para.ana.colourcalibtype); % apply spectral calibration
    I           = elf_io_correctdng(im_HDR_cal, info(setstart), 'bright');

    % Save HDR file as MAT and TIF.
    % TIF is not strictly necessary, but good diagnostic. 
    % Cost of saving it: ~300GB/6TB disk space, 2s per scene for calculation/saving = 6.7h extra for the current ~12000 scenes.
    % Cost of instead recalculating it in main2: 1.5s per scene for loading/converting = 5h extra ".
    elf_io_readwrite(para, 'saveHDR_mat', sprintf('scene%03d', setnr), im_HDR_cal);
    elf_io_readwrite(para, 'saveHDR_tif', sprintf('scene%03d', setnr), I);
    
    %% Intensity descriptors %%
    %% Calculate intensity descriptors
    switch para.ana.intanalysistype
        case 'histcomb' % Calculate histograms for each exposure and combine using conf
            [res.int, res.totalint] = elf_analysis_int(im_proj_cal, para.ele2, 'histcomb', para.ana.hdivn_int, para.ana.rangeperc, setnr==1, conf_proj, conffactors); % verbose output (analysis parameters) only for the first set
        case 'hdr' % Calculate histograms from HDR image (current default in para)
            [res.int, res.totalint] = elf_analysis_int(im_HDR_cal, para.ele2, 'hdr', para.ana.hdivn_int, para.ana.rangeperc, setnr==1);                       % verbose output (analysis parameters) only for the first set
        otherwise
            error('Unknown intensity calculation method: %s', para.ana.intanalysistype);
    end

    %% Plot summary figure for this scene
    fh = elf_support_formatA4l(4); clf;
    datasetname = strrep(para.paths.dataset, '\', '\\'); % On PC, paths contain backslashes. Replace them by double backslashes to avoid a warning
    elf_plot_intsummary(para, res, I, infosum, fh, sprintf('%s, scene #%d of %d', datasetname, setnr, size(sets, 1)), ...
        sprintf('%d exposure, exposure m.a.d %.0f%% (max %.0f%%)', numims, 100*mean(abs(res.scalefac-1)), 100*max(abs(res.scalefac-1)) )); % res.scalefac are the factors to scale each image to the mean exposure
    set(fh, 'Name', sprintf('Scene #%d of %d', setnr, size(sets, 1)));
    drawnow;
    
    %% save output files
    res.info  = info(setstart); % use the info of the first read image
    scenename = sprintf('scene%03d', setnr);
    elf_io_readwrite(para, 'saveres', scenename, res);
    if savejpgs, elf_io_readwrite(para, 'saveivep_jpg', [scenename '_int'], fh); end    % small bottleneck
    
    
                    if setnr == 1
                        elf_support_logmsg('      Starting scene-by-scene calibration, HDR creation and intensity analysis. Projected time: %.2f minutes.\n', toc/60*size(sets, 1));
                        elf_support_logmsg('      Scene: 1..');
                    elseif mod(setnr-1, 20)==0
                        elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b\n');
                        elf_support_logmsg('             %d..', setnr);
                    else
                        elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b%d..', setnr);
                    end
end

                    elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\bdone.\n');    
                    elf_support_logmsg('      Summary: All HDR scenes for environment %s calculated and saved to mat and tif.\n\n', dataset); % write confirmation to log
                    elf_support_logmsg('      Summary: All intensity descriptors for environment %s calculated and saved to mat.\n\n', para.paths.dataset);




