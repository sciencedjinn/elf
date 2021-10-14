function elf_main2_meanimage(dataset, verbose)
% ELF_MAIN2_MEANIMAGE calculates the mean image for an environment as the mean
% of all normalised HDR scenes. Scenes are normalised in elf_main1 using the correctdng
% "bright" method, which sets the mean luminance to 1/4 of maximum.
%
% Uses: elf_support_logmsg, elf_paths, elf_para, elf_io_readwrite, 
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
if nargin < 1 || isempty(dataset), error('You have to provide a valid dataset name'); end 

                    elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b\n');
                    elf_support_logmsg('----- ELF Step 2: Mean Image -----\n');
                    elf_support_logmsg('      Processing environment %s\n', dataset);

%% Set up paths and file names; read info, infosum and para
elf_paths;
para            = elf_para('', dataset);                   % This function only uses para.paths, so we don't have to load the old para file, verbose==1 means there will be output during system check
allfiles        = elf_io_dir(fullfile(para.paths.datapath, para.paths.scenefolder, '*.tif'));
fnames_im       = {allfiles.name};                          % collect image names
infosum         = elf_io_readwrite(para, 'loadinfosum');      % loads the old infosum file (which contains projection information, and linims)

%% Calculate mean image and thumbs
sumimage    = zeros(length(infosum.proj_ele), length(infosum.proj_azi), infosum.SamplesPerPixel, 'double');  % pre-allocate for sum of all processed images
thumbs      = zeros(100, 100, infosum.SamplesPerPixel, length(allfiles), infosum.class{1});      % pre-allocate for  thumbnails of all processed images

if verbose, fh = figure(22); clf; hp = uipanel('Parent', fh); hi = []; end

for imnr = 1:length(allfiles)
    thisim     = elf_io_readwrite(para, 'loadHDR_tif', fnames_im{imnr});  % output is uint16
    sumimage   = sumimage + double(thisim);                             % add this image to the sum image
    
    if verbose
        % calculate thumbnails of each image to display in a montage later
        thumbs(:, :, :, imnr) = imresize(thisim, [100 100]);

        if isempty(hi) % first execution
            hi = elf_plot_image(thisim, [], hp);
        else 
            set(hi, 'CData', thisim);
        end
        set(fh, 'name', sprintf('Image %d of %d', imnr, length(allfiles))); 
        drawnow;
    end
end
if verbose, close(fh); end
meanimage = sumimage/length(allfiles);

%% Plot results
% a) Display montage of thumbs
if verbose
    fh2 = figure(2);
    set(fh2, 'Name', 'Thumbnails (click to enlarge)');
    hi2 = montage(thumbs, 'thumbnailsize', [100 100]);
    res.fnames_im = fnames_im;
    res.infosum = infosum;
    res.para = para;
    res.data = elf_io_readwrite(para, 'loadres', fnames_im);
    
    
    
%     res.calib = infosum.linims;
    
    set(hi2, 'ButtonDownFcn', @elf_callbacks_montage, 'UserData', res);
end

% b) Display mean image in figure 2
fh3 = elf_support_formatA4(21, 2);
set(fh3, 'Name', 'Mean image');
p3 = uipanel('Parent', fh3);
elf_plot_image(meanimage, infosum, p3, 'equirectangular', infosum.linims);

%% Save output to tif
elf_io_readwrite(para, 'savemeanimg_tif', '', uint16(meanimage));
elf_io_readwrite(para, 'savemeanimg_jpg', '', uint16(meanimage));


















