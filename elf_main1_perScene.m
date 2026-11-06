function elf_main1_perScene(dataSet, modules, imgFormat)
% ELF_MAIN1_PERSCENE calibrates and unwarps all images in a data set, sorts them into
% scenes, and calculates HDR representations of these scenes as mat for later contrast calculations and as tif for the mean image. 
% Per-scene analysis is performed for all loaded modules.
%
% Loads files: DNG image files in data folder
% Saves files: HDR image files in scene subfolder, *.mat files in scenes subfolder, per-scene intensity results in mat folder

elf_paths;

%% check inputs
if nargin < 3 || isempty(imgFormat), imgFormat = "*.dng"; end
if nargin < 2 , modules = {}; end
if nargin < 1 || isempty(dataSet), error('You have to provide a valid dataset name'); end 

                    Logger.log(LogLevel.INFO, '\n----- ELF Step 1: Calibration, HDR and Per-Scene Analysis -----\n')

%% Set up paths and file names; read info, infosum and para, calculate sets
para            = elf_para(modules, '', dataSet, imgFormat);
info            = elf_info_collect(para.fh.Paths.datapath, imgFormat);   % this contains EXIF information and filenames, verbose==1 means there will be output during system check
infoSum         = elf_info_summarise(info, false);                    % summarise EXIF information for this dataset. This will be saved for later use below
infoSum.linims  = strcmp(imgFormat, "*.dng");                         % if linear images are used, correct for that during plotting
scenes          = elf_hdr_brackets(info);                             % determine which images are part of the same scene
nScenes         = size(scenes, 1);
                    Logger.log(LogLevel.INFO, '      Processing %d scenes in environment %s.\n', nScenes, dataSet);

%% Expand some parameters to one per image
if isscalar(para.ana.imageRotation)
    para.ana.imageRotation = repmat(para.ana.imageRotation, [nScenes, 1]);
end
if length(para.ana.imageRotation) ~= nScenes
    error("Number of image rotation elements must be 1 or equal to the number of scenes in the dataset")
end
if isscalar(para.ana.imageDirection)
    para.ana.imageDirection = repmat(para.ana.imageDirection, [nScenes, 1]);
end
if length(para.ana.imageDirection) ~= nScenes
    error("Number of image direction elements must be 1 or equal to the number of scenes in the dataset")
end

%% Calculate black levels for all images (from calibration or dark images)
[info, ~, infoSum.blackWarnings] = Calibrator.calculateBlackLevels(info, imgFormat);
cal = Calibrator(infoSum.Model{1}, [infoSum.Width infoSum.Height], para.ana.colourCalibType, infoSum.SerialNumber);
proj = Projector.fromInfoStructs(infoSum, cal.ProjectionInfo, para.azi, para.ele2);

%% Set up projection constants
% Also creates I_info.grids
switch para.ana.targetProjection
    case "equirectangular"
        % Calculate a projection vector to transform a fisheye input image 
        % into an equirectangular output image
        projection_ind = proj.calculateProjection();
        infoSum.projs.scene = proj;
        infoSum.grids.scene = proj.getProjectionInfo(0, para.ana.imageDirection(1));
        projSize = proj.RectSize;

    case {"equisolid", "equidistant", "stereographic", "orthographic"}
        % Calculate a projection vector to crop/resize a fisheye input image 
        % and/or change its fisheye projection
        if para.ana.targetImageSize(1)==0 && para.ana.targetImageSize(2)==0
            [projection_ind, newProj] = proj.crop2ImageCircle(90); % TODO: This should also do the rotation
        else
            [projection_ind, newProj] = proj.fisheye2fisheyeProjection(para.ana.targetProjection, para.ana.targetImageSize, para.ana.imageRotation(1));
        end
        infoSum.projs.scene = newProj;
        infoSum.grids.scene = newProj.getProjectionInfo(0, para.ana.imageDirection(1)); %% NOTE: We are currently only storing one grid: That for the first image
        projSize = newProj.Size;

    otherwise
        error("Unknown target projection: %s", para.ana.targetProjection);
end
para.fh.saveInfoSum(para, infoSum); % saves infosum AND para for use in later stages

%% Step 1: Unwarp images and calculate HDR scenes

tic; % Start taking time
wbh = waitbar(0, "Starting scene-by-scene calibration, HDR creation and analysis...");

% Process one scene at a time
try
    for iScene = 1:nScenes
        clear res
        
        setStart    = scenes(iScene, 1);        % first image in this scene
        setEnd      = scenes(iScene, 2);        % last image in this scene
        nIms        = setEnd - setStart + 1;    % total number of images in this scene
    
        im_proj     = zeros(projSize(1), projSize(2), projSize(3), nIms);  % pre-allocate
        conf_proj   = im_proj;  % pre-allocate
    %     im_proj_cal = zeros(lEle, lAzi, infoSum.SamplesPerPixel, numims);  % pre-allocate
        rawWhiteLevels = zeros(3, nIms);        % pre-allocate; raw white levels (after black subtraction)
        
        if (para.ana.targetImageSize(1)~=0 || para.ana.targetImageSize(2)~=0) && ...
                ismember(para.ana.targetProjection, ["equisolid", "equidistant", "stereographic", "orthographic"]) && ...
                para.ana.imageRotation(iScene)~=para.ana.imageRotation(max([1, iScene-1]))
            % recalculate image index to take into account new rotation
            [projection_ind, ~] = proj.fisheye2fisheyeProjection(para.ana.targetProjection, para.ana.targetImageSize, para.ana.imageRotation(iScene));
        end
    
        for i = 1:nIms % for each image in this set
            % Load image
            imNo                    = setStart + i - 1;     % the number of this image
            fName                   = info(imNo).Filename;  % full path to input image file
            im_raw                  = double(elf_io_imread(fName)); % load the image (uint16) and transform to double
    
            % Calibrate and calculate intensity confidence
            [im_cal, conf, rawWhiteLevels(:, i)] = cal.applyAbsolute(im_raw, info(imNo));
            
            % Reproject/Resize/Crop image
            im_proj(:, :, :, i)   = Projector.apply(im_cal, projection_ind, projSize);
            conf_proj(:, :, :, i) = Projector.apply(conf, projection_ind, projSize);
            %         im_proj_cal(:, :, :, i) = cal.applySpectral(im_proj(:, :, :, i), info(imnr), para.ana.colourCalibType); % only needed for 'histcomb'-type intensity calculation, but not time-intensive
    
        end
        
        % Sort images by EV = exp * iso / apt^2
        EV               = arrayfun(@(x) x.DigitalCamera.ExposureTime * x.DigitalCamera.ISOSpeedRatings / x.DigitalCamera.FNumber^2, info(setStart:setEnd));
        [~, imOrder]     = sort(EV);         % sorted EV (ascending), for HDR calculation
        im_proj          = im_proj(:, :, :, imOrder);
    %     im_proj_cal      = im_proj_cal(:, :, :, imOrder);
        conf_proj        = conf_proj(:, :, :, imOrder);
        rawWhiteLevels   = rawWhiteLevels(:, imOrder);
        
        % scale images to match middle exposure (creates a warning if scaling by more than 30%)
        [im_proj, res.scalefac] = elf_hdr_scaleStack(im_proj, conf_proj, rawWhiteLevels);
        
        % Pass a figure number and an outputfilename here only if you want diagnostic pdfs.
        % However, MATLAB can't currently deal with saving these large figures, so no pdf will be created either way.
        [im_HDR, im_diag] = elf_hdr_calcHDR(im_proj, conf_proj, para.ana.hdrMethod, rawWhiteLevels); % para.ana.hdrMethod can be 'overwrite', 'overwrite2', 'validranges', 'allvalid', 'allvalid2' (default), 'noise', para.ana.hdrMethod    
        im_HDR_cal        = cal.applySpectral(im_HDR, info(setStart)); % apply spectral calibration
        
        %% Black out horizon if needed
        if para.ana.targetProjection~="equirectangular" && isfield(para.ana, "validImageRadius") && para.ana.validImageRadius>0
            im_HDR_cal = newProj.blackout(im_HDR_cal, para.ana.validImageRadius);
            im_diag = newProj.blackout(im_diag, para.ana.validImageRadius, 0);
        end    
    
        % Save HDR file as MAT and TIF.
        % TIF is not strictly necessary, but a good diagnostic. 
        para.fh.saveScene_mat(sprintf('scene%03d', iScene), im_HDR_cal);
        I = elf_io_correctdng(im_HDR_cal, info(setStart), 'bright');
    
        if para.ana.saveSceneTifs
            para.fh.saveScene_tif(sprintf('scene%03d', iScene), I);
        end
    
        if para.ana.saveDiagnosticTifs
            para.fh.saveSceneDiag_tif(sprintf('scene%03d', iScene), im_diag);
        end
    
        %% Perform per-scene analysis and plotting for all modules
        res.info = info(setStart);
        for i = 1:length(para.modules)
            modPerSceneFilename = [para.modules{i} '_perScene'];
            if ~isempty(which(modPerSceneFilename))
                res = feval(modPerSceneFilename, para, res, im_HDR_cal, I, infoSum, iScene, nScenes);
            end
        end
    
        %% save results output files, including all per-scene analyses (this might be almost nothing, if core isn't calculated)
        sceneName = sprintf('scene%03d', iScene);
        para.fh.saveCoreResults(sceneName, res);

                        if iScene == 1
                            projTime = toc/60*nScenes;
                            s = sprintf('Starting scene-by-scene calibration, HDR creation and analysis.\nProjected time: %.1f minutes.', projTime);
                            waitbar(0, wbh, s); drawnow
                            Logger.log(LogLevel.INFO, "\t%s\n", s);
                            Logger.log(LogLevel.INFO, '\tScene: 1..');
                        elseif mod(iScene-1, 20)==0
                            Logger.log(LogLevel.INFO, '\n\t%d..', iScene);
                        else
                            Logger.log(LogLevel.INFO, '\b%d..', iScene);
                        end

        waitbar(iScene/nScenes, wbh);
    end
catch me
    try close(wbh); end
    rethrow(me);
end

try close(wbh); end

                    Logger.log(LogLevel.INFO, '\b\t\tdone.\n');
                    saveFolder = fullfile(para.fh.Paths.root, dataSet, para.fh.Paths.scenefolder);
                    Logger.log(LogLevel.INFO, '\tSummary: All HDR scenes for environment %s calculated and saved to <a href="matlab:winopen(''%s'')">%s</a>.\n\n', dataSet, saveFolder, saveFolder);




