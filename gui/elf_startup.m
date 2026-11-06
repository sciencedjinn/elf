function [para, status, gui] = elf_startup(modules, cbhandle, rootfolder, verbose, useoldfolder, figh)

%% defaults
if nargin < 6 || isempty(figh), figh = []; end
if nargin < 5 || isempty(useoldfolder), useoldfolder = true; end
if nargin < 4 || isempty(verbose), verbose = true; end
if nargin < 3 || isempty(rootfolder), rootfolder = ''; end

%% get basic parameters
if useoldfolder
    para = elf_para(modules, rootfolder, '', '', true); % without arguments, just returns basic parameters (call again later with rootfolder or dataset)
else
    para = elf_para(modules, NaN, '', '', true); % without arguments, just returns basic parameters (call again later with rootfolder or dataset)
end

%% collect and check all datasets parameters
[status, para, datasets, exts] = elf_checkdata(para, verbose);

%% build GUI
if para.modules{1} ~= "core"
    figName = upper(para.modules{1}) + "-ELF";
else
    figName = "ELF";
end
gui = elf_maingui(status, para, datasets, exts, cbhandle, figName, figh);

%% insert images
for i = 1:size(status.Colour, 1)
    para2 = elf_para(modules, para.fh.Paths.root, datasets{i});
    if isfield(para2.fh.Paths, "fname_meanimg_jpg") && ~isempty(para2.fh.Paths.fname_meanimg_jpg) && isfile(para2.fh.Paths.fname_meanimg_jpg)
        fname   = para2.fh.Paths.fname_meanimg_jpg;
        info    = [];
        corr    = false;
    else
        % if no summary exists, show the first scene, or the second raw image (this is usually the first mid-exposure)
        if isnan(exts{i}) % this happens when there are only raw files in the folder
            mask = '*.*';
        else
            mask = ['*' exts{i}];
        end
        scenepath = fullfile(para2.fh.Paths.datapath, para2.fh.Paths.scenefolder);
        if isfolder(scenepath) && ~isempty(elf_io_dir(fullfile(scenepath, '*.tif')))
            allims = elf_io_dir(fullfile(scenepath, '*.tif'));
            fname  = fullfile(allims(1).folder, allims(1).name);
        else
            allims = elf_io_dir(fullfile(para2.fh.Paths.datapath, mask));
            allims([allims.isdir]) = [];
            imind  = min([2, length(allims)]);
            fname  = fullfile(allims(imind).folder, allims(imind).name);
        end

        info = elf_info_load(fname);
        if strcmp(exts{i}, '.dng')
            corr = "bright"; % if these are dng images, perform colour and gamma correction
        else
            corr = false;
        end
    end
    [I, compressed]  = elf_io_imread(fname, true); % pass over a CompressedDNG error here
    switch compressed
        case ''
            % all good
        case 'ELF:io:dngCompressed'
            status.Text{i, 1} = 'Images were found, but it appears that they were converted to DNG in the wrong way. Please review the conversion instructions (Help->Getting Started...)';
            status.Colour(i, 1) = StatusColour.Problem;
        otherwise
            status.Text{i, 1} = 'Images were found, but an error occurred while reading them. Please refer to the error popup displayed during startup.';
            status.Colour(i, 1) = StatusColour.Problem;
    end
    
    scale   = para.plot.guiPreviewSize/size(I, 2);
    I       = imresize(I, scale);
    warning('off', 'io_correctdng:NoMatrix')
    elf_plot_image(I, info, gui.p(i).ah, '', corr);
    warning('on', 'io_correctdng:NoMatrix')
    drawnow;
end

elf_maingui_visibility(gui, para, status);
