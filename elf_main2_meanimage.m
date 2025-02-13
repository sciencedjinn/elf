function elf_main2_meanimage(dataSet, verbose)
% ELF_MAIN2_MEANIMAGE calculates the mean image for an environment as the mean
% of all normalised HDR scenes. Scenes are normalised in elf_main1 using the correctdng
% "bright" method, which sets the mean luminance to 1/4 of maximum.
%
% Uses: elf_paths, elf_para, elf_io_readwrite, 
%       elf_plot_image, elf_analysis_int, elf_support_formatA4l
%
% Loads files: *.tif files in scenes subfolder
% Saves files: Mean image as tif in Detailed results folder, and as jpg in public output folder
%
% Typical timing for a 50-scene environment (on ELFPC):
%      12.5s total
%      +2.5s verbose

%% Set up paths and file names
if nargin < 2, verbose = false; end % verbose determines whether each individual image is plotted during the process, and thumbs are provided at the end
if nargin < 1 || isempty(dataSet), error('You have to provide a valid dataset name'); end 

                    Logger.log(LogLevel.INFO, '\b\b\b\b\b\b\b\b\b\b\b\b\b\n');
                    Logger.log(LogLevel.INFO, '----- ELF Step 2: Mean Image -----\n');
                    Logger.log(LogLevel.INFO, '      Processing environment %s\n', dataSet);

%% Set up paths and file names; read info, infosum and para
elf_paths;
para            = elf_para({}, '', dataSet);                   % This function only uses para.paths, so we don't have to load the old para file, verbose==1 means there will be output during system check
allFiles        = elf_io_dir(fullfile(para.paths.datapath, para.paths.scenefolder, '*.tif'));
fNames_im       = {allFiles.name};                          % collect image names
infoSum         = elf_io_readwrite(para, 'loadinfosum');      % loads the old infosum file (which contains projection information, and linims)

para.stages.project = false;

%% Calculate mean image and thumbs
if para.stages.project
    sumImage    = zeros(length(infoSum.grids.ele), length(infoSum.grids.azi), infoSum.SamplesPerPixel, 'double');  % pre-allocate for sum of all processed images
else
    sumImage    = zeros(infoSum.Height, infoSum.Width, infoSum.SamplesPerPixel, 'double');  % pre-allocate for sum of all processed images
end
thumbs      = zeros(100, 100, infoSum.SamplesPerPixel, length(allFiles), infoSum.class{1});      % pre-allocate for  thumbnails of all processed images

if verbose, fh = figure(22); clf; hp = uipanel('Parent', fh); hi = []; end

for imnr = 1:length(allFiles)
    thisIm     = elf_io_readwrite(para, 'loadHDR_tif', fNames_im{imnr});  % output is uint16
    sumImage   = sumImage + double(thisIm);                             % add this image to the sum image
    
    if verbose
        % calculate thumbnails of each image to display in a montage later
        thumbs(:, :, :, imnr) = imresize(thisIm, [100 100]);

        if isempty(hi) % first execution
            hi = elf_plot_image(thisIm, [], hp);
        else 
            set(hi, 'CData', thisIm);
        end
        set(fh, 'name', sprintf('Image %d of %d', imnr, length(allFiles))); 
        drawnow;
    end
end
if verbose, close(fh); end
meanImage = sumImage/length(allFiles);

%% Plot results
% a) Display montage of thumbs
if verbose
    fh2 = figure(2);
    set(fh2, 'Name', 'Thumbnails (click to enlarge)');
    hi2 = montage(thumbs, 'thumbnailsize', [100 100]);
    res.fnames_im = fNames_im;
    res.infosum = infoSum;
    res.para = para;
    res.data = elf_io_readwrite(para, 'loadres', fNames_im);
    
    
    
%     res.calib = infosum.linims;
    
    set(hi2, 'ButtonDownFcn', @elf_callbacks_montage, 'UserData', res);
end

% b) Display mean image in figure 2
fh3 = elf_support_formatA4(21, 2);
set(fh3, 'Name', 'Mean image');
p3 = uipanel('Parent', fh3);
elf_plot_image(meanImage, infoSum, p3, 'equirectangular', infoSum.linims);

%% Save output to tif
elf_io_readwrite(para, 'savemeanimg_tif', '', uint16(meanImage));
elf_io_readwrite(para, 'savemeanimg_jpg', '', uint16(meanImage));


















