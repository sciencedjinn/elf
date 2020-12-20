function elf_mainX_explore(dataset, imgformat, frange, verbose)
% ELF_MAINX_EXPLORE shows a montage of all scenes, and the mean image for a processed ELF data set

% Loads files: *.mat files in data folder, *.tif files in data/proj folder

%% Set up paths and file names
if nargin < 4 || isempty(verbose), verbose = false; end
if nargin < 3 || isempty(frange), frange = []; end
if nargin < 2 || isempty(imgformat), imgformat = '*.dng'; end

%%
fprintf('----- ELF Step X: Explore -----\n');
fprintf('      Processing data set %s\n', dataset);

%% House-keeping and initialisations
res.calib       = strcmp(imgformat, '*.dng');

%% Set up paths and file names; read info, infosum and para
elf_paths;
para            = elf_para('', dataset, imgformat);
para            = elf_para_update(para);     
infosum         = elf_io_readwrite(para, 'loadinfosum');                 % loads the old infosum file (which contains projection information)
allfiles        = elf_io_dir(fullfile(para.paths.datapath, para.paths.scenefolder, '*.tif'));
fnames_im       = {allfiles.name};                                    % collect image names

%% Calculate thumbs
if isempty(frange)
    frange = 1:length(fnames_im); % by default take all frames
else
    frange = frange(frange<length(fnames_im)); % limit frame range to existing frames
end

% preallocate
thumbs      = zeros(100, 100, infosum.SamplesPerPixel, length(frange), infosum.class{1});      % This will hold the thumbnails of all processed images

if verbose, hf = figure(66); clf; hp = uipanel('Parent', hf); hi = []; else hf = waitbar(0, 'Loading data...'); end

for setnr = 1:length(frange)
    % a) .tif-file: Load it and add it to the sum of all tifs so far
    thisim = elf_io_readwrite(para, 'loadHDR_tif', sprintf('scene%03d', frange(setnr)));
    if res.calib
        thumbs(:, :, :, frange(setnr)) = im2uint16(elf_io_correctdng(imresize(thisim, [100 100]), infosum));                  % calculate thumbnails of each image to display in a montage later
    else
        thumbs(:, :, :, frange(setnr)) = imresize(thisim, [100 100]);                  % calculate thumbnails of each image to display in a montage later
    end
    
    if verbose
        if ~isempty(hi)
            set(hi, 'CData', thisim);
        else %first execution
            hi = elf_plot_image(thisim, [], hp);
        end
        drawnow;
    else
        waitbar(setnr/length(frange), hf);
    end
end
if verbose, close(66); else, close(hf); end
    
%% Load data, calculate data mean
res.data = elf_io_readwrite(para, 'loadres', fnames_im);
res.para = para;
res.fnames_im = fnames_im;
res.infosum = infosum;

%% Display montage of thumbs
fh2 = figure(4);
set(fh2, 'Name', 'Thumbnails (click to enlarge)');
if size(thumbs, 4) == 1
    hi2 = elf_plot_image(thumbs, [], fh2);
else
    hi2 = montage(thumbs, 'thumbnailsize', [100 100]);
end
set(hi2, 'ButtonDownFcn', @elf_callbacks_montage, 'UserData', res);

















