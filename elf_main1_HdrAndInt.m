function elf_main1_HdrAndInt(dataSet, imgFormat, verbose, rotation)
% ELF_MAIN1_HDRANDINT calibrates and unwarps all images in a data set, sorts them into
% scenes, and calculates HDR representations of these scenes as mat for later contrast calculations and as tif for the mean image. 
% Intensity descriptors are calculated for each exposure and then combined for scenes based on individual pixel reliability.
%
% Uses: elf_paths, elf_support_logmsg, elf_para, elf_info_collect, 
%       elf_info_summarise, elf_hdr_brackets, elf_project_image, 
%       elf_io_readwrite, elf_hdr_calcHDR, elf_io_correctdng, elf_io_imread
%       elf_analysis_int, elf_support_formatA4l
%
% Loads files: DNG image files in data folder
% Saves files: HDR image files in scene subfolder, *.mat files in scenes subfolder, per-scene intensity results in mat folder

elf_paths;

%% Run parameters
saveJpgs        = false;                                              % save individual jpgs for each image? (takes extra time)

%% check inputs
if nargin < 4, rotation = 0; end
if nargin < 3, verbose = false; end
if nargin < 2 || isempty(imgFormat), imgFormat = '*.dng'; end
if nargin < 1 || isempty(dataSet), error('You have to provide a valid dataset name'); end 

                    elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b\n');
                    elf_support_logmsg('----- ELF Step 1: Calibration, HDR and Intensity -----\n')

%% Set up paths and file names; read info, infosum and para, calculate sets
para            = elf_para('', dataSet, imgFormat, verbose);
info            = elf_info_collect(para.paths.datapath, imgFormat);   % this contains EXIF information and filenames, verbose==1 means there will be output during system check
infoSum         = elf_info_summarise(info, false);                  % summarise EXIF information for this dataset. This will be saved for later use below
infoSum.linims  = strcmp(imgFormat, '*.dng');                         % if linear images are used, correct for that during plotting
sets            = elf_hdr_brackets(info);                             % determine which images are part of the same scene
                    elf_support_logmsg('      Processing %d scenes in environment %s.\n', size(sets, 1), dataSet);

%% Set up projection constants
% Calculate a projection vector to transform an orthographic/equidistant/equisolid input image into an equirectangular output image
% Also creates I_info.ori_grid_x1, I_info.ori_grid_y1 (and 2) which can be used to plot a 10 degree resolution grid onto the original image
[projection_ind, infoSum] = elf_project_image(infoSum, para.azi, para.ele2, para.projtype, rotation); % default: 'equisolid'; also possible: 'orthographic' / 'equidistant' / 'noproj'

%% Calculate black levels for all images (from calibration or dark images)
[infoSum.blackLevels, blackLevelSource, infoSum.blackWarnings] = elf_calibrate_blackLevels(info, imgFormat);
elf_io_readwrite(para, 'saveinfosum', [], infoSum); % saves infosum AND para for use in later stages

%% Step 1: Unwarp images and calculate HDR scenes

tic; % Start taking time

% Process one scene at a time
for iSet = 1:size(sets, 1)
    clear im_filt res
    
    setStart    = sets(iSet, 1);          % first image in this set
    setEnd      = sets(iSet, 2);          % last image in this set
    nIms        = setEnd - setStart + 1;   % total number of images in this set
    im_proj     = zeros(length(para.ele), length(para.azi), infoSum.SamplesPerPixel, nIms);  % pre-allocate
%     im_proj_cal = zeros(length(para.ele), length(para.azi), infoSum.SamplesPerPixel, numims);  % pre-allocate
    conf_proj   = zeros(length(para.ele), length(para.azi), infoSum.SamplesPerPixel, nIms);  % pre-allocate
    rawWhiteLevels = zeros(3, nIms);        % pre-allocate; raw white levels (after black subtraction)
    
    for i = 1:nIms % for each image in this set
        % Load image        
        imNo                    = setStart + i - 1;     % the number of this image
        fName                   = info(imNo).Filename;  % full path to input image file
        im_raw                  = elf_io_imread(fName); % load the image (uint16)

        % Calibrate and calculate intensity confidence
        [im_cal, conf, rawWhiteLevels(:, i)] = elf_calibrate_abssens(im_raw, info(imNo), infoSum.blackLevels(imNo, :)); 
        
        % Umwarp image        
        im_proj(:, :, :, i)     = elf_project_apply(im_cal, projection_ind, [length(para.ele) length(para.azi) infoSum.SamplesPerPixel]);
        %         im_proj_cal(:, :, :, i) = elf_calibrate_spectral(im_proj(:, :, :, i), info(imnr), para.ana.colourcalibtype); % only needed for 'histcomb'-type intensity calculation, but not time-intensive

        conf_proj(:, :, :, i)   = elf_project_apply(conf, projection_ind, [length(para.ele) length(para.azi) infoSum.SamplesPerPixel]);
    end
    
    % Sort images by EV
    EV               = arrayfun(@(x) x.DigitalCamera.ExposureBiasValue, info(setStart:setEnd));
    [~, imOrder]     = sort(EV);         % sorted EV (ascending), for HDR calculation
    im_proj          = im_proj(:, :, :, imOrder);
%     im_proj_cal      = im_proj_cal(:, :, :, imOrder);
    conf_proj        = conf_proj(:, :, :, imOrder);
    rawWhiteLevels   = rawWhiteLevels(:, imOrder);
    
    % scale images to match middle exposure (creates a warning if scaling by more than 30%)
    [im_proj, res.scalefac] = elf_hdr_scaleStack(im_proj, conf_proj, rawWhiteLevels);
    
    % Pass a figure number and an outputfilename here only if you want diagnostic pdfs.
    % However, MATLAB can't currently deal with saving these large figures, so no pdf will be created either way.
    im_HDR      = elf_hdr_calcHDR(im_proj, conf_proj, para.ana.hdrmethod, rawWhiteLevels); % para.ana.hdrmethod can be 'overwrite', 'overwrite2', 'validranges', 'allvalid', 'allvalid2' (default), 'noise', para.ana.hdrmethod
    im_HDR_cal  = elf_calibrate_spectral(im_HDR, info(setStart), para.ana.colourcalibtype); % apply spectral calibration
    I           = elf_io_correctdng(im_HDR_cal, info(setStart), 'bright');

    % Save HDR file as MAT and TIF.
    % TIF is not strictly necessary, but good diagnostic. 
    % Cost of saving it: ~300GB/6TB disk space, 2s per scene for calculation/saving = 6.7h extra for the current ~12000 scenes.
    % Cost of instead recalculating it in main2: 1.5s per scene for loading/converting = 5h extra ".
    elf_io_readwrite(para, 'saveHDR_mat', sprintf('scene%03d', iSet), im_HDR_cal);
    elf_io_readwrite(para, 'saveHDR_tif', sprintf('scene%03d', iSet), I);
    
    %% Intensity descriptors %%
    %% Calculate intensity descriptors
    switch para.ana.intanalysistype
        case 'histcomb' % Calculate histograms for each exposure and combine using conf
            error('Currently not supported!')
%             [res.int, res.totalint] = elf_analysis_int(im_proj_cal, para.ele2, 'histcomb', para.ana.hdivn_int, para.ana.rangeperc, setnr==1, conf_proj, confFactors); % verbose output (analysis parameters) only for the first set
        case 'hdr' % Calculate histograms from HDR image (current default in para)
            [res.int, res.totalint] = elf_analysis_int(im_HDR_cal, para.ele2, 'hdr', para.ana.hdivn_int, para.ana.rangeperc, iSet==1); % verbose output (analysis parameters) only for the first set
        otherwise
            error('Unknown intensity calculation method: %s', para.ana.intanalysistype);
    end

    %% Plot summary figure for this scene
    dataSetName = strrep(para.paths.dataset, '\', '\\'); % On PC, paths contain backslashes. Replace them by double backslashes to avoid a warning
    nScenes     = size(sets, 1);
    name        = sprintf('%s, scene #%d of %d', dataSetName, iSet, nScenes);
    h           = elf_plot_intSummary(res, I, infoSum, name, nScenes);

%     info2 = sprintf('%d exposure, exposure m.a.d %.0f%% (max %.0f%%)', numims, 100*mean(abs(res.scalefac-1)), 100*max(abs(res.scalefac-1)) );
    set(h.fh, 'Name', sprintf('Scene #%d of %d', iSet, nScenes));
    drawnow;
    
    %% save output files
    res.info  = info(setStart); % use the info of the first read image
    sceneName = sprintf('scene%03d', iSet);
    elf_io_readwrite(para, 'saveres', sceneName, res);
    if saveJpgs, elf_io_readwrite(para, 'saveivep_jpg', [sceneName '_int'], h.fh); end    % small bottleneck
    
    
                    if iSet == 1
                        elf_support_logmsg('      Starting scene-by-scene calibration, HDR creation and intensity analysis. Projected time: %.2f minutes.\n', toc/60*size(sets, 1));
                        elf_support_logmsg('      Scene: 1..');
                    elseif mod(iSet-1, 20)==0
                        elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b\n');
                        elf_support_logmsg('             %d..', iSet);
                    else
                        elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b%d..', iSet);
                    end
end

                    elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\bdone.\n');    
                    elf_support_logmsg('      Summary: All HDR scenes for environment %s calculated and saved to mat and tif.\n\n', dataSet); % write confirmation to log
                    elf_support_logmsg('      Summary: All intensity descriptors for environment %s calculated and saved to mat.\n\n', para.paths.dataset);




