function data = elf_io_readwrite(para, action, fname, varinput)
% ELF_IO_READWRITE is the main function for reading and writing data files
% and results in ELF. Needs to be calles once when starting a new environment
% to create all necessary file names and make sure output folders are
% present [para = elf_io_readwrite(para, 'createfilenames')].
%
% Inputs:
% para    - para structure for this environment
% action  - a string defining what action is to be taken, for example which
%           files to read/write.
% data    - the variable to be saved. Or, for action 'savevep_pdf', a figure handle to the figure to be saved
% fname   - full filename of the original input file during this loop.

%% Example calls as used in main ELF functions:
% General uses:
% para            = elf_io_readwrite(para, 'createfilenames')
% para            = elf_io_readwrite(para, 'loadpara')    %all that para needs for this one is para.paths.fname_infosum_mat

% MAIN1: elf_main1_HDRscenes
%                   elf_io_readwrite(para, 'saveinfosum', [], infosum)
%                   elf_io_readwrite(para, 'saveproj_tif', fname, im)
%                   elf_io_readwrite(para, 'saveHDR_tif', scenename, im_HDR)
%                   elf_io_readwrite(para, 'saveHDR_mat', scenename, im_HDR)

% MAIN2: elf_main2_meanimage
% infosum         = elf_io_readwrite(para, 'loadinfosum')
% im_HDR          = elf_io_readwrite(para, 'loadHDR_tif', scenename)
%                   elf_io_readwrite(para, 'savemeanimg_tif', '', meanimage)
%                   elf_io_readwrite(para, 'savemeanimg_jpg', '', meanimage)

% MAIN3: elf_main3_luminance
% infosum         = elf_io_readwrite(para, 'loadinfosum')
% data            = elf_io_readwrite(para, 'loadproj_tif', fname, info)
% im_HDR          = elf_io_readwrite(para, 'loadHDR_tif', scenename)
%                   elf_io_readwrite(para, 'saveres', fname, data)
%                   elf_io_readwrite(para, 'saveivep_jpg', fname, fh)

% MAIN3p5: elf_main3p5_intsummary
% infosum         = elf_io_readwrite(para, 'loadinfosum')
% data            = elf_io_readwrite(para, 'loadres', fname)
% meanim          = elf_io_readwrite(para, 'loadmeanimg_tif')
%                   elf_io_readwrite(para, 'savemeanivep_jpg', '', fh)
%                   elf_io_readwrite(para, 'savemeanivep_pdf', '', fh)

% MAIN4: elf_main4_filter
% infosum         = elf_io_readwrite(para, 'loadinfosum')
% data            = elf_io_readwrite(para, 'loadHDR_mat', scenename)
%                   elf_io_readwrite(para, 'savefilt_mat', scenename, im_filt_HDR)

% MAIN5: elf_main5_contrasts
% im_filt         = elf_io_readwrite(para, 'loadfilt_mat', scenename)
% data            = elf_io_readwrite(para, 'loadres', fname)
% im_HDR          = elf_io_readwrite(para, 'loadHDR_tif', scenename)
%                   elf_io_readwrite(para, 'saveres', fname, data)
%                   elf_io_readwrite(para, 'savevep_jpg', fname, fh)

% MAIN6: elf_main6_summary
% data            = elf_io_readwrite(para, 'loadres', fname)
%                   elf_io_readwrite(para, 'savemeanres', '', meandata)

% MAIN7: elf_main7_stats_and_plots
% meandata        = elf_io_readwrite(para, 'loadmeanres')
% meanim          = elf_io_readwrite(para, 'loadmeanimg_tif')
%                   elf_io_readwrite(para, 'savemeanvep_jpg', '', fh)
%                   elf_io_readwrite(para, 'savemeanvep_pdf', '', fh)

%% Main
switch action
    case 'createfilenames' % para = elf_io_readwrite(para, 'createfilenames')
        [~, ds, ext] = fileparts(para.paths.dataset);
        ds = [ds ext]; % make sure dots and names after the dot don't get lost
        para.paths.fname_infosum_mat  = fullfile(para.paths.datapath, para.paths.matfolder, [ds '_info.mat']);   % save file for the infosum and para structures
        
        para.paths.fname_meanimg_tif  = fullfile(para.paths.outputfolder, [ds '_mean_image.tif']);
        para.paths.fname_meanimg_jpg  = fullfile(para.paths.outputfolder_pub, [ds '_mean_image.jpg']);
        para.paths.fname_meanimg_ind  = fullfile(para.paths.outputfolder, [ds '_mean_image_ind.tif']);
        
        para.paths.fname_meanvep_pdf  = fullfile(para.paths.outputfolder, [ds '_mean.pdf']);
        para.paths.fname_meanvep_jpg  = fullfile(para.paths.outputfolder_pub, [ds '_mean.jpg']);
        
        para.paths.fname_meanivep_pdf = fullfile(para.paths.outputfolder, [ds '_meanint.pdf']);
        para.paths.fname_meanivep_jpg = fullfile(para.paths.outputfolder_pub, [ds '_meanint.jpg']);
        
        para.paths.fname_stats        = fullfile(para.paths.outputfolder, [ds '_stats.csv']);
        para.paths.fname_meanres      = fullfile(para.paths.datapath, para.paths.matfolder, [ds '_meanres.mat']);
        para.paths.fname_meanres_int  = fullfile(para.paths.datapath, para.paths.matfolder, [ds '_meanres_int.mat']);
        para.paths.fname_collres      = fullfile(para.paths.outputfolder, [ds '_collres.mat']);
        
        % all other filenames are calculated dynamically each iteration
        data                         = para; % return para
        
        % check whether folders exist
        if ~exist(fullfile(para.paths.datapath, para.paths.scenefolder), 'file')
            mkdir(para.paths.datapath, para.paths.scenefolder);
        end
        if ~exist(fullfile(para.paths.datapath, para.paths.matfolder), 'file')
            mkdir(para.paths.datapath, para.paths.matfolder);
        end
%         if ~exist(fullfile(para.paths.datapath, para.paths.projfolder), 'file')
%             mkdir(para.paths.datapath, para.paths.projfolder);
%         end
        if ~exist(fullfile(para.paths.datapath, para.paths.filtfolder), 'file')
            mkdir(para.paths.datapath, para.paths.filtfolder);
        end
        if ~exist(para.paths.outputfolder, 'file')
            mkdir(para.paths.outputfolder);
        end
        if ~exist(para.paths.outputfolder_pub, 'file')
            mkdir(para.paths.outputfolder_pub);
        end
        
    case 'saveinfosum'      % elf_io_readwrite(para, 'saveinfosum', [], infosum)
        %% save the infosum structure for this environment, containing common EXIF information; also saves para
        save(para.paths.fname_infosum_mat, 'varinput', 'para');
        
    case 'loadinfosum'      % infosum = elf_io_readwrite(para, 'loadinfosum')
        %% load the infosum structure for this environment, containing common EXIF information
        temp        = load(para.paths.fname_infosum_mat);
        data        = temp.varinput;
        
    case 'saveinfosum_comb'      % elf_io_readwrite(para, 'saveinfosum', [], infosum)
        %% save the infosum structure for this environment, containing common EXIF information; also saves para
        [~,ds] = fileparts(para.paths.dataset);
        save(fullfile(para.paths.outputfolder, [ds '_info.mat']), 'varinput', 'para');
        
    case 'loadinfosum_comb'      % infosum = elf_io_readwrite(para, 'loadinfosum')
        %% load the infosum structure for this environment, containing common EXIF information
        [~,ds]      = fileparts(para.paths.dataset);
        temp        = load(fullfile(para.paths.outputfolder, [ds '_info.mat']));
        data        = temp.varinput;

        
    case 'loadpara'         % infosum = elf_io_readwrite(para, 'loadpara')
        %% load the para structure from the infosum file for this environment
        temp        = load(para.paths.fname_infosum_mat);
        data        = temp.para;
        
	case 'saveproj_tif'     % elf_io_readwrite(para, 'saveproj_tif', fname, im)
        % still used in pol and milkyway modules
        if ~exist(fullfile(para.paths.datapath, para.paths.projfolder), 'file')
            mkdir(para.paths.datapath, para.paths.projfolder);
        end
        %% save the projected image for one exposure as a tif. 
        [~,f]       = fileparts(fname); 
        fname       = fullfile(para.paths.datapath, para.paths.projfolder, [f '.tif']);
        imwrite(varinput, fname, 'tif', 'Compression', 'lzw');  % varinput holds the image
        
    case 'loadproj_tif'     % data = elf_io_readwrite(para, 'loadproj_tif', fname)
        %% returns a uint16 LINEAR image for one exposure
        [~,f]       = fileparts(fname); 
        fname       = fullfile(para.paths.datapath, para.paths.projfolder, [f '.tif']);
        data        = imread(fname);         % load .tif-file

    case 'saveproj_mat'     % elf_io_readwrite(para, 'saveproj_mat', fname, im_proj)
        %% saves the projected, calibrated image for one exposure to a mat file
        [~,f]       = fileparts(fname); 
        fname       = fullfile(para.paths.datapath, para.paths.projfolder, [f '.mat']);
        save(fname, 'varinput');
        
    case 'loadproj_mat'     % im_proj = elf_io_readwrite(para, 'loadproj_mat', fname)
        %% loads the projected, calibrated image for one exposure from a mat file
        [~,f]       = fileparts(fname); 
        fname       = fullfile(para.paths.datapath, para.paths.projfolder, [f '.mat']);
        temp        = load(fname);
        data        = temp.varinput;         % load .mat-file
        
    case 'saveHDR_mat'      % elf_io_readwrite(para, 'saveHDR_mat', sprintf('scene%03d', setnr), im_HDR)
        %% saves the HDR image for one scene in a mat file
        [~,f]       = fileparts(fname);
        fname       = fullfile(para.paths.datapath, para.paths.scenefolder, [f '.mat']);
        save(fname, 'varinput');

    case 'loadHDR_mat'      % data = elf_io_readwrite(para, 'loadHDR_mat', sprintf('scene%03d', setnr))
        %% loads the HDR image for one scene from a mat file
        [~,f]       = fileparts(fname); 
        fname       = fullfile(para.paths.datapath, para.paths.scenefolder, [f '.mat']);
        temp        = load(fname);
        data        = temp.varinput;         % load .mat-file
        
    case 'saveHDR_tif'      % elf_io_readwrite(para, 'saveHDR_tif', sprintf('scene%03d', setnr), im_HDR)
        %% saves the HDR image for one scene in a tif; will be used for plotting and calculating the mean image. Could maybe be jpg to save space.
        % assumes that input image is normalised to 1
        [~,f]       = fileparts(fname);
        fname       = fullfile(para.paths.datapath, para.paths.scenefolder, [f '.tif']);
        I           = uint16((2^16-1)*varinput);
        imwrite(I, fname, 'tif', 'Compression', 'lzw');
        
    case 'loadHDR_tif'      % im_HDR = elf_io_readwrite(para, 'loadHDR_tif', sprintf('scene%03d', setnr))
        %% loads the HDR image for one scene from tif
        [~,f]       = fileparts(fname); 
        fname       = fullfile(para.paths.datapath, para.paths.scenefolder, [f '.tif']);
        data        = imread(fname);

    case 'savefilt_mat'     % elf_io_readwrite(para, 'savefilt_mat', sprintf('scene%03d', setnr), im_filt_HDR)
        %% saves several filtered HDR images for one scene to mat
        [~,f]       = fileparts(fname); 
        fname_filt  = fullfile(para.paths.datapath, para.paths.filtfolder, [f '_filt.mat']);
        im_filt_HDR = varinput; % this is only necessary for backward compatibility. TODO: refilter all datasets so they contain varinput instead of im_filt_HDR
        save(fname_filt, 'im_filt_HDR');
                            elf_support_logmsg('      Filtered %s saved to %s\n', f, fname);
                            
    case 'loadfilt_mat'     % im_filt = elf_io_readwrite(para, 'loadfilt_mat', sprintf('scene%03d', setnr))
        %% loads several filtered HDR images for one scene from mat file
        [~,f]       = fileparts(fname); 
        fname_filt  = fullfile(para.paths.datapath, para.paths.filtfolder, [f '_filt.mat']);
        temp        = load(fname_filt);
        data        = temp.im_filt_HDR;
                
%     case 'savepolar'     % elf_io_readwrite(para, 'savepolar', [], pol)
%         fname = fullfile(para.paths.root, sprintf('polresults.mat'));
%         save(fname, 'varinput');
%                             elf_support_logmsg('      Polarisation results saved to %s\n', fname);
%         
%     case 'loadpolar'     % pol = elf_io_readwrite(para, 'loadpolar')
%         fname = fullfile(para.paths.root, sprintf('polresults.mat'));
%         temp = load(fname);
%         data = temp.varinput;        
        
    case 'savestokes_mat'     % elf_io_readwrite(para, 'savestokes_mat', sprintf('scene%03d', setnr), imStokes_filt)
        %% saves two filtered HDR images for one scene to mat
        [~, f]      = fileparts(fname); 
        fname_filt  = fullfile(para.paths.datapath, para.paths.filtfolder, [f '_stokes_filt.mat']);
        imStokes_filt = varinput;  % this is only necessary for backward compatibility. TODO: refilter all datasets so they contain varinput instead of im_filt_HDR
        save(fname_filt, 'imStokes_filt');
                            elf_support_logmsg('      Stokes parameters for dataset %s saved to %s\n', f, fname_filt);
                            
    case 'loadstokes_mat'     % imStokes_filt = elf_io_readwrite(para, 'loadstokes_mat', sprintf('scene%03d', setnr))
        %% loads both filtered HDR images for one scene from mat file
        [~, f]      = fileparts(fname); 
        fname_filt  = fullfile(para.paths.datapath, para.paths.filtfolder, [f '_stokes_filt.mat']);
        temp        = load(fname_filt);
        data        = temp.imStokes_filt;
        
    case 'saveres'          % elf_io_readwrite(para, 'saveres', fname, data)
        %% saves results mat for one scene; this is called during every loop iteration
        [~,f]       = fileparts(fname); 
        fname       = fullfile(para.paths.datapath, para.paths.matfolder, [f '.mat']);
        
        % remove large, unneccesary parts
        varinput.int.hist = [];
        varinput.spatial.lumfft = [];
        varinput.spatial.rgfft = [];
        varinput.spatial.rbfft = [];
        varinput.spatial.gbfft = [];
        varinput.spatial.lumhist = [];
        varinput.spatial.rghist = [];
        varinput.spatial.rbhist = [];
        varinput.spatial.gbhist = [];
        varinput.info.DNGPrivateData = [];
        
        save(fname, 'varinput');
    
    case 'loadres'          % data = elf_io_readwrite(para, 'loadres', fname)
        %% load results mats for each scene in an environment; this is called only once per environment
        % fname has to be a cell array of all file names
        for fn = length(fname):-1:1
            [~,f]   = fileparts(fname{fn});
            temp    = load(fullfile(para.paths.datapath, para.paths.matfolder, [f '.mat']));
            data(fn)= temp.varinput;
        end

        
    case 'savemeanimg_tif'  % elf_io_readwrite(para, 'savemeanimg_tif', '', meanimage)
        %% saves the mean image for an environment to a 16-bit tif; assumes that input is uint16
        imwrite(varinput, para.paths.fname_meanimg_tif, 'tif', 'Compression', 'lzw') %save mean image as tif
                            elf_support_logmsg('      Mean image saved as TIF to <a href="matlab:winopen(''%s'')">%s</a>\n', para.paths.fname_meanimg_tif, para.paths.fname_meanimg_tif);
    
    case 'savemeanimg_jpg'  % elf_io_readwrite(para, 'savemeanimg_jpg', '', meanimage)
        %% saves the mean image for an environment to a jpg
        imwrite(im2uint8(varinput), para.paths.fname_meanimg_jpg, 'jpeg') %save mean image as jpg
                            elf_support_logmsg('      Mean image saved as JPG to <a href="matlab:winopen(''%s'')">%s</a>\n', para.paths.fname_meanimg_jpg, para.paths.fname_meanimg_jpg);

    case 'loadmeanimg_tif'  % meanim = elf_io_readwrite(para, 'loadmeanimg_tif')
        %% loads mean image for an environment from tif
        data        = imread(para.paths.fname_meanimg_tif);

    case 'savemeanimg_ind'  % elf_io_readwrite(para, 'savemeanimg_ind', '', meanimage)
        %% saves the mean image, calculated from individual exposures, for an environment to a 16-bit tif; assumes that input is uint16
        imwrite(varinput, para.paths.fname_meanimg_ind, 'tif', 'Compression', 'lzw') %save mean image as tif

    case 'loadmeanimg_ind'  % meanim = elf_io_readwrite(para, 'loadmeanimg_ind')
        %% loads the mean image, calculated from individual exposures, for an environment from 16-bit tif
        data        = imread(para.paths.fname_meanimg_ind);
     
    case 'savemeanres'      % elf_io_readwrite(para, 'savemeanres', '', meandata)
        %% saves mean results mat for an environment; this is called at the end of intensity calculations, and then only saves intensity data
        
        % remove large, unneccesary parts
        varinput.int.hist = [];
        varinput.spatial.lumfft = [];
        varinput.spatial.rgfft = [];
        varinput.spatial.rbfft = [];
        varinput.spatial.gbfft = [];
        varinput.spatial.lumhist = [];
        varinput.spatial.rghist = [];
        varinput.spatial.rbhist = [];
        varinput.spatial.gbhist = [];
        varinput.info.DNGPrivateData = [];

        save(para.paths.fname_meanres, 'varinput');
    
    case 'loadmeanres'      % meandata = elf_io_readwrite(para, 'loadmeanres')
        %% load mean results mat for an environment
        temp        = load(para.paths.fname_meanres);
        data        = temp.varinput;
          
    case 'savemeanres_int'      % elf_io_readwrite(para, 'savemeanres_int', '', intmean)
        %% saves mean results mat for an environment; this is called at the end of intensity calculations, and then only saves intensity data
        
        % remove large, unneccesary parts
        varinput.int.hist = [];
        varinput.info.DNGPrivateData = [];

        save(para.paths.fname_meanres_int, 'varinput');
    
    case 'loadmeanres_int'      % intmean = elf_io_readwrite(para, 'loadmeanres_int')
        %% load mean results mat for an environment
        temp        = load(para.paths.fname_meanres_int);
        data        = temp.varinput;
        
	case 'savecollres'      % elf_io_readwrite(para, 'savecollres', '', data)
        %% saves collated results mat for an environment
        for i = 1:length(varinput)
            % remove large, unneccesary parts
            varinput(i).int.hist = [];
            varinput(i).spatial.lumfft = [];
            varinput(i).spatial.rgfft = [];
            varinput(i).spatial.rbfft = [];
            varinput(i).spatial.gbfft = [];
            varinput(i).spatial.lumhist = [];
            varinput(i).spatial.rghist = [];
            varinput(i).spatial.rbhist = [];
            varinput(i).spatial.gbhist = [];
            varinput(i).info.DNGPrivateData = [];
            varinput(i).info.XMP = [];
        end
        save(para.paths.fname_collres, 'varinput', '-mat', '-v7.3');
         
    case 'loadcollres'      % data = elf_io_readwrite(para, 'loadcollres')
        %% loads collated results mat for an environment
        temp        = load(para.paths.fname_collres);
        data        = temp.varinput;        
        
    case 'savemeanres_comb'      % elf_io_readwrite(para, 'savemeanres', '', meandata)
        %% saves mean results mat for an environment; this is called at the end of intensity calculations, and then only saves intensity data
        
        % remove large, unneccesary parts
        varinput.int.hist = [];
        varinput.spatial.lumfft = [];
        varinput.spatial.rgfft = [];
        varinput.spatial.rbfft = [];
        varinput.spatial.gbfft = [];

        [~,ds] = fileparts(para.paths.dataset);
        save(fullfile(para.paths.outputfolder, [ds '_meanres.mat']), 'varinput');
    
    case 'loadmeanres_comb'      % meandata = elf_io_readwrite(para, 'loadmeanres')
        %% load mean results mat for an environment
        [~,ds]      = fileparts(para.paths.dataset);
        temp        = load(fullfile(para.paths.outputfolder, [ds '_meanres.mat']));
        data        = temp.varinput;

        
    case 'savevep_jpg'      % elf_io_readwrite(para, 'savevep_jpg', fname, fh)
        %% saves the VEP for a single scene to JPG
        [~,f]       = fileparts(fname);
        fname       = fullfile(para.paths.datapath, para.paths.matfolder, [f '.jpg']);
        sub_savejpg(varinput, fname);
                            elf_support_logmsg('      VEP for %s saved as JPG to <a href="matlab:winopen(''%s'')">%s</a>\n', f, fname, fname);
    
    case 'savevep_pdf'      % elf_io_readwrite(para, 'savevep_pdf', fname, fh)
        %% saves the VEP for a single scene to PDF
        [~,f]       = fileparts(fname);
        fname       = fullfile(para.paths.datapath, para.paths.matfolder, [f '.pdf']);
        sub_savepdf(varinput, fname);
                            elf_support_logmsg('      VEP for %s saved as PDF to <a href="matlab:open(''%s'')">%s</a>\n', f, fname, fname);
        
    case 'saveivep_jpg'     % elf_io_readwrite(para, 'saveivep_jpg', fname, fh)
        %% saves the intensity VEP for a single scene to JPG
        [~,f]       = fileparts(fname);
        fname       = fullfile(para.paths.datapath, para.paths.matfolder, [f '.jpg']);
        sub_savejpg(varinput, fname);
                            elf_support_logmsg('      iVEP for %s saved as JPG to <a href="matlab:winopen(''%s'')">%s</a>\n', f, fname, fname);
        
    case 'saveivep_pdf'     % elf_io_readwrite(para, 'saveivep_pdf', fname, fh)
        %% saves the intensity VEP for a single scene to PDF
        [~,f]       = fileparts(fname);
        fname       = fullfile(para.paths.datapath, para.paths.matfolder, [f '.pdf']);
        sub_savepdf(varinput, fname);
                            elf_support_logmsg('      iVEP for %s saved as PDF to <a href="matlab:winopen(''%s'')">%s</a>\n', f, fname, fname);

    case 'savemeanvep_jpg'  % elf_io_readwrite(para, 'savemeanvep_jpg', '', fh)
        %% saves the mean VEP for an environment to JPG
        filename = para.paths.fname_meanvep_jpg;
        sub_savejpg(varinput, filename);
                            elf_support_logmsg('      Mean VEP saved as JPG to <a href="matlab:winopen(''%s'')">%s</a>\n', filename, filename);

    case 'savemeanvep_pdf'  % elf_io_readwrite(para, 'savemeanvep_pdf', '', fh)
        %% saves the mean VEP for an environment to PDF
        filename = para.paths.fname_meanvep_pdf;
        sub_savepdf(varinput, filename);
                            elf_support_logmsg('      Mean VEP saved as PDF to <a href="matlab:open(''%s'')">%s</a>\n', filename, filename);
        
    case 'savemeanivep_jpg' % elf_io_readwrite(para, 'savemeanivep_jpg', '', fh)
        %% saves the mean intensity VEP for an environment to JPG
        filename = para.paths.fname_meanivep_jpg;
        sub_savejpg(varinput, filename);
                            elf_support_logmsg('      Mean iVEP saved as JPG to <a href="matlab:winopen(''%s'')">%s</a>\n', filename, filename);
        
    case 'savemeanivep_pdf' % elf_io_readwrite(para, 'savemeanivep_pdf', '', fh)
        %% saves the mean intensity VEP for an environment to PDF
        filename = para.paths.fname_meanivep_pdf;
        sub_savepdf(varinput, filename);
                            elf_support_logmsg('      Mean iVEP saved as PDF to <a href="matlab:open(''%s'')">%s</a>\n', filename, filename);

    otherwise
        error('Unknown action');
        
end % switch

end % main


%% sub functions
function sub_savepdf(fh, filename)
    sub_hideui(fh, false); % hide user interface for plotting
    set(fh, 'Units', 'centimeters');
    pos = get(fh,'Position');
    set(fh, 'PaperPositionMode', 'Auto', 'PaperUnits', 'centimeters', 'PaperSize', [pos(3), pos(4)]);

    if verLessThan('matlab', '8.4')
        print(sprintf('-f%d', fh), filename, '-r600', '-dpdf');  % save the pdf
    else
        print(fh, filename, '-r600', '-dpdf');  % save the pdf
    end
    sub_hideui(fh, true); % re-activate user interface
end

function sub_savejpg(fh, filename)
    sub_hideui(fh, false); % hide user interface for plotting
    set(fh, 'Units', 'centimeters');
    pos = get(fh,'Position');
    set(fh, 'PaperPositionMode', 'Auto', 'PaperUnits', 'centimeters', 'PaperSize', [pos(4), pos(3)]);

    if verLessThan('matlab', '8.4')
        print(sprintf('-f%d', fh), filename, '-djpeg');  % save the jpg
    else
        print(fh, filename, '-djpeg');  % save the jpg
    end
    sub_hideui(fh, true); % re-activate user interface
end

function sub_hideui(fh, activate)
    % sub function to hide ui buttons for plotting
    fignum = get(fh, 'Number');
    if activate
        state = 'on';
    else
        state = 'off';
    end

    set(findobj('tag', sprintf('fig%d_gui_BW', fignum)), 'visible', state);
    set(findobj('tag', sprintf('fig%d_gui_R', fignum)), 'visible', state);
    set(findobj('tag', sprintf('fig%d_gui_G', fignum)), 'visible', state);
    set(findobj('tag', sprintf('fig%d_gui_B', fignum)), 'visible', state);
    set(findobj('tag', sprintf('fig%d_gui_posslider', fignum)), 'visible', state);
    set(findobj('tag', sprintf('fig%d_gui_rangeslider', fignum)), 'visible', state);

    drawnow;
end