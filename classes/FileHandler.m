classdef FileHandler < handle
    properties
        Paths
    end


    %%%%%%%%%%%%%%%%%
    %% CONSTRUCTOR %%
    %%%%%%%%%%%%%%%%%
    methods
        function obj = FileHandler(paths)
            if nargin>=1
                obj.Paths = paths;
            end
        end
    end


    %%%%%%%%%%%%%%%%%%%%
    %% PUBLIC METHODS %%
    %%%%%%%%%%%%%%%%%%%%
    methods
        function init(obj)
            % Create all file names and make sure directories exist
            [~, ds, ext] = fileparts(string(obj.Paths.dataset));
            ds = ds+ext; % make sure dots and names after the dot don't get lost
            obj.Paths.fname_infosum_mat  = fullfile(obj.Paths.datapath, obj.Paths.matfolder, ds+"_info.mat");   % save file for the infosum and para structures
            obj.Paths.fname_infosum_json = fullfile(obj.Paths.datapath, obj.Paths.matfolder, ds+"_info.json");   % save file for the infosum and para structures
            
            obj.Paths.fname_meanimg_tif  = fullfile(obj.Paths.outputfolder, ds+"_mean_image.tif");
            obj.Paths.fname_meanimg_jpg  = fullfile(obj.Paths.outputfolder_pub, ds+"_mean_image.jpg");
            
            obj.Paths.fname_meanelf_pdf  = fullfile(obj.Paths.outputfolder, ds+"_meanint.pdf");
            obj.Paths.fname_meanelf_jpg  = fullfile(obj.Paths.outputfolder_pub, ds+"_meanint.jpg");
                        
            obj.Paths.fname_stats        = fullfile(obj.Paths.outputfolder, ds+"_stats.csv");
            obj.Paths.fname_meanres      = fullfile(obj.Paths.datapath, obj.Paths.matfolder, ds+"_meanres.mat");
            obj.Paths.fname_meanres_int  = fullfile(obj.Paths.datapath, obj.Paths.matfolder, ds+"_meanres_int.mat");
            obj.Paths.fname_collres      = fullfile(obj.Paths.outputfolder, ds+"_collres.mat");
            
            % all other filenames are calculated dynamically each iteration
            
            % check whether folders exist
            if ~exist(fullfile(obj.Paths.datapath, obj.Paths.scenefolder), 'file')
                mkdir(obj.Paths.datapath, obj.Paths.scenefolder);
            end
            if ~exist(fullfile(obj.Paths.datapath, obj.Paths.matfolder), 'file')
                mkdir(obj.Paths.datapath, obj.Paths.matfolder);
            end
            if ~exist(fullfile(obj.Paths.datapath, obj.Paths.diagfolder), 'file')
                mkdir(obj.Paths.datapath, obj.Paths.diagfolder);
            end
            if ~exist(fullfile(obj.Paths.datapath, obj.Paths.filtfolder), 'file')
                mkdir(obj.Paths.datapath, obj.Paths.filtfolder);
            end
            if ~exist(fullfile(obj.Paths.datapath, obj.Paths.polarfolder), 'file')
                mkdir(obj.Paths.datapath, obj.Paths.polarfolder);
            end
            if ~exist(fullfile(obj.Paths.datapath, obj.Paths.skyfolder), 'file')
                mkdir(obj.Paths.datapath, obj.Paths.skyfolder);
            end
            if ~exist(obj.Paths.outputfolder, 'file')
                mkdir(obj.Paths.outputfolder);
            end
            if ~exist(obj.Paths.outputfolder_pub, 'file')
                mkdir(obj.Paths.outputfolder_pub);
            end
        end

        %% Info data
        function saveInfoSum(obj, para, infoSum)

            save(obj.Paths.fname_infosum_mat, 'infoSum', 'para');
            data.infoSum = infoSum;
            data.para = para;
            fid = fopen(obj.Paths.fname_infosum_json, 'w');
            fprintf(fid, '%s', jsonencode(data));
            fclose(fid);
        end

        function infoSum = loadInfoSum(obj)
            
            temp = load(obj.Paths.fname_infosum_mat);
            infoSum = FileHandler.getField(temp, "infoSum", "varinput");
        end

        function para = loadPara(obj)
            
            temp = load(obj.Paths.fname_infosum_mat);
            para = temp.para;
        end

        %% HDR scenes
        function saveScene_mat(obj, sceneName, im)
            obj.saveToMat(im, obj.Paths.scenefolder, sceneName)
        end

        function data = loadScene_mat(obj, sceneName)
            data = obj.loadFromMat(obj.Paths.scenefolder, sceneName);
        end

        function saveScene_tif(obj, sceneName, im)
            % Could maybe be jpg to save space. Assumes that input image is normalised to 1
            obj.saveToIm(im, 16, obj.Paths.scenefolder, sceneName)
        end

        function data = loadScene_tif(obj, sceneName)
            data = obj.loadFromIm(16, obj.Paths.scenefolder, sceneName);
        end

        %% Diagnostic images (R: saturation, G: low signal, B: movement between exposures)
        function saveSceneDiag_tif(obj, sceneName, im)
            obj.saveToIm(im, 8, obj.Paths.diagfolder, sceneName)
        end

        function data = loadSceneDiag_tif(obj, sceneName)
            data = obj.loadFromIm(8, obj.Paths.diagfolder, sceneName);
        end

        %% Filtered images
        function saveFilter_mat(obj, sceneName, im)
            obj.saveToMat(im, obj.Paths.filtfolder, sceneName)
        end

        function data = loadFilter_mat(obj, sceneName)
            data = obj.loadFromMat(obj.Paths.filtfolder, sceneName);
        end

        function saveFilter_tif(obj, sceneName, ims, fwhms)
            for i = 1:length(ims)
                obj.saveToIm(ims{i}, 16, obj.Paths.filtfolder, sceneName, sprintf("_%.1f", fwhms(i)))
            end
        end
        
        function saveFilterDiag_tif(obj, sceneName, ims, fwhms)
            for i = 1:length(ims)
                obj.saveToIm(ims{i}, 8, obj.Paths.diagfolder, sceneName, sprintf("_%.1f", fwhms(i)))
            end
        end

        function ims = loadFilterDiag_tif(obj, sceneName, fwhms)
            ims = cell(length(fwhms), 1);
            for i = 1:length(fwhms)
                ims{i} = obj.loadFromIm(8, obj.Paths.diagfolder, sceneName, sprintf("_%.1f", fwhms(i)));
            end
        end
        
        function saveFilterArray_mat(obj, sceneName, im)
            obj.saveToMat(im, obj.Paths.filtfolder, sceneName, "_array")
        end

        function data = loadFilterArray_mat(obj, sceneName)
            data = obj.loadFromMat(obj.Paths.filtfolder, sceneName, "_array");
        end

        function saveFilterArray_jpg(obj, sceneName, ims, fwhms)            
            for i = 1:length(ims)
                obj.saveToIm(ims{i}, 8, obj.Paths.filtfolder, sceneName, sprintf("_array_%.1f", fwhms(i)), "jpg")
            end
        end

        function saveFilterArray_tif(obj, sceneName, ims, fwhms)            
            for i = 1:length(ims)
                obj.saveToIm(ims{i}, 16, obj.Paths.filtfolder, sceneName, sprintf("_array_%.1f", fwhms(i)))
            end
        end

        function saveFilterDiagArray_mat(obj, sceneName, ims)
            obj.saveToMat(ims, obj.Paths.diagfolder, sceneName, "_array");
        end

        function ims = loadFilterDiagArray_mat(obj, sceneName)
            ims = obj.loadFromMat(obj.Paths.diagfolder, sceneName, "_array");
        end

        %% Polar
        function savePolar_mat(obj, sceneName, pol_vectors)
            obj.saveToMat(pol_vectors, obj.Paths.polarfolder, sceneName)

            % read example:
            % i = pol_vectors{1};
            % vop = squeeze(i(:, :, 3, :));
            % dolp = sqrt(sum(vop.^2, 3));
            % figure; imagesc(dolp); axis equal; colormap jet; clim([0 1])
        end

        function savePolarArray_mat(obj, sceneName, pol_vectors)
            obj.saveToMat(pol_vectors, obj.Paths.polarfolder, sceneName, "_array")

            % read example:
            % i = pol_vectors{1};
            % vop = squeeze(i(:, 3, :));
            % dolp = sqrt(sum(vop.^2, 2));
            % figure; imagesc(dolp); axis equal; colormap jet; clim([0 1])
        end

        function savePolar_jpg(obj, sceneName, ims, fwhms, ch)
            [~, f] = fileparts(sceneName); 
            %%TODO: Some of this should be done outside, maybe save from plotting function
            for i = 1:size(ims, 2)
                int = ims{1, i};
                aop = ims{2, i}(:, :, ch);
                dolp = ims{3, i}(:, :, ch);

                im_int = uint8((2^8-1)*int);

                hsvimage        = zeros(size(aop, 1), size(aop, 2));
                hsvimage(:,:,1) = mod(aop-90, 180)/180;    % Hue
                hsvimage(:,:,2) = 1;                    % Saturation
                hsvimage(:,:,3) = dolp;                 % Intensity
                rgb2            = hsv2rgb(hsvimage);    % Map to RGB colour space for display
                im_aop = uint8((2^8-1)*rgb2);
                
                dolp(dolp>1) = 1;
                im_dolp = uint8((2^8-1)*dolp);
                fnamegen  = @(x) fullfile(obj.Paths.datapath, obj.Paths.polarfolder, sprintf("%s_%s_%.1f.jpg", f, x, fwhms(i)));
                imwrite(im_int, fnamegen("int"), 'jpg');
                imwrite(im_aop, fnamegen("aop"), 'jpg');
                imwrite(im_dolp, jet(180), fnamegen("dolp"), 'jpg');
                                Logger.log(LogLevel.INFO, "      Polarisation files %s saved\n", f);
            end
        end

        function savePolarArray_jpg(obj, sceneName, ims, fwhms, ch)
            [~, f]= fileparts(sceneName); 
            %%TODO: Some of this should be done outside, maybe save from plotting function
            for i = 1:size(ims, 2)
                int = ims{1, i};
                aop = ims{2, i}(:, :, ch);
                dolp = ims{3, i}(:, :, ch);

                im_int = uint8((2^8-1)*int);

                hsvimage        = zeros(size(aop, 1), size(aop, 2));
                hsvimage(:,:,1) = mod(aop-90, 180)/180;    % Hue
                hsvimage(:,:,2) = 1;                    % Saturation
                hsvimage(:,:,3) = dolp;                 % Intensity
                rgb2            = hsv2rgb(hsvimage);    % Map to RGB colour space for display
                im_aop = uint8((2^8-1)*rgb2);
                
                dolp(dolp>1) = 1;
                im_dolp = uint8((2^8-1)*dolp);
                
                fnamegen  = @(x) fullfile(obj.Paths.datapath, obj.Paths.polarfolder, sprintf("%s_array_%s_%.1f.jpg", f, x, fwhms(i)));
                imwrite(im_int, fnamegen("int"), 'jpg');
                imwrite(im_aop, fnamegen("aop"), 'jpg');
                imwrite(im_dolp, jet(180), fnamegen("dolp"), 'jpg');
                                Logger.log(LogLevel.INFO, '      Polarisation files %s saved\n', f);
            end
        end

        function savePolarDiag_tif(obj, setName, ims, fwhms)
            for i = 1:length(ims)
                obj.saveToIm(ims{i}, 8, obj.Paths.diagfolder, setName, sprintf("_%.1f", fwhms(i)))
            end
        end

        function savePolarDiagArray_mat(obj, setName, ims)
            obj.saveToMat(ims, obj.Paths.diagfolder, setName, "_array");
        end

        function ims = loadPolarDiagArray_mat(obj, setName)
            ims = obj.loadFromMat(obj.Paths.diagfolder, setName, "_array");
        end

        %% Mean image
        function saveMeanImage_tif(obj, im)
            I = uint16((2^16-1)*im);
            imwrite(I, obj.Paths.fname_meanimg_tif, 'tif', 'Compression', 'lzw') % save mean image as tif
        end

        function saveMeanImage_jpg(obj, im)
            I = uint8((2^8-1)*im);
            imwrite(I, obj.Paths.fname_meanimg_jpg, 'jpeg') % save mean image as jpg
        end

        function data = loadMeanImage_tif(obj)
            data = imread(obj.Paths.fname_meanimg_tif);
        end

        function data = loadMeanImage_jpg(obj)
            data = imread(obj.Paths.fname_meanimg_jpg);
        end

        %% CORE ELF results
        function saveCoreResults(obj, sceneName, data)
            % saves results mat for one scene; this is called during every loop iteration
                
            % remove large, unnecessary parts
            data.int.hist = [];
            data.spatial.lumfft = [];
            data.spatial.rgfft = [];
            data.spatial.rbfft = [];
            data.spatial.gbfft = [];
            data.spatial.lumhist = [];
            data.spatial.rghist = [];
            data.spatial.rbhist = [];
            data.spatial.gbhist = [];
            data.info.DNGPrivateData = [];
            
            obj.saveToMat(data, obj.Paths.matfolder, sceneName)
        end

        function data = loadCoreResults(obj, sceneNames)
            % load results mats for each scene in an environment; this is called only once per environment
            % sceneNames has to be a cell array of all file names
            for iScene = length(sceneNames):-1:1
                data(iScene) = obj.loadFromMat(obj.Paths.matfolder, sceneNames{iScene});
            end
        end

        function saveMeanCoreResults(obj, data)
            % remove large, unnecessary parts
            data.int.hist = [];
            data.spatial.lumfft = [];
            data.spatial.rgfft = [];
            data.spatial.rbfft = [];
            data.spatial.gbfft = [];
            data.spatial.lumhist = [];
            data.spatial.rghist = [];
            data.spatial.rbhist = [];
            data.spatial.gbhist = [];
            data.info.DNGPrivateData = [];
            
            obj.saveToMat(data, obj.Paths.matfolder, obj.Paths.fname_meanres)
        end

        function data = loadMeanCoreResults(obj)
            data = obj.loadFromMat(obj.Paths.matfolder, obj.Paths.fname_meanres);
        end

        function saveMeanCoreIntResults(obj, data)
            % remove large, unnecessary parts
            data.int.hist = [];
            data.info.DNGPrivateData = [];
            
            obj.saveToMat(data, obj.Paths.matfolder, obj.Paths.fname_meanres_int)
        end

        function data = loadMeanCoreIntResults(obj)
            data = obj.loadFromMat(obj.Paths.matfolder, obj.Paths.fname_meanres_int);
        end

        %% CORE ELF plots
        function saveElfPlot_jpg(obj, sceneName, fh)
            [~, f] = fileparts(sceneName); 
            fName  = fullfile(obj.Paths.datapath, obj.Paths.matfolder, f + ".jpg");
            obj.savePlot(fh, fName, "jpg", true);
        end

        function saveElfPlot_pdf(obj, sceneName, fh)
            [~, f] = fileparts(sceneName); 
            fName  = fullfile(obj.Paths.datapath, obj.Paths.matfolder, f + ".pdf");
            obj.savePlot(fh, fName, "pdf", true);
        end

        function saveMeanElfPlot_jpg(obj, fh)
            obj.savePlot(fh, obj.Paths.fname_meanelf_jpg, "jpg", true);
        end

        function saveMeanElfPlot_pdf(obj, fh)
            obj.savePlot(fh, obj.Paths.fname_meanelf_pdf, "pdf", true);
        end

        %% SKY module plots
        function saveSkyPlot_jpg(obj, sceneName, fhs, fwhms)
            [~, f] = fileparts(sceneName); 
            for i = 1:length(fhs)
                fName  = fullfile(obj.Paths.datapath, obj.Paths.skyfolder, f + sprintf("_%.1f.jpg", fwhms(i)));
                obj.savePlot(fhs(i), fName, "jpg", true);
            end
        end
    end



    %%%%%%%%%%%%%%%%%%%%%
    %% PRIVATE METHODS %%
    %%%%%%%%%%%%%%%%%%%%%
    methods (Access=protected)
        function saveToIm(obj, im, bitDepth, relPath, fName, suffix, format, verbose)
            % Save data to an image file

            if nargin<8, verbose = false; end
            if nargin<7 || isempty(format), format = "tif"; end
            if nargin<6, suffix = ""; end

            [~, f]      = fileparts(fName);
            fname       = fullfile(obj.Paths.datapath, relPath, f + suffix + "." + format);
            switch bitDepth
                case 1
                    I = im;
                case 8
                    I = uint8((2^8-1)*im);
                case 16
                    I = uint16((2^16-1)*im);
                otherwise
                    error("Unknown bit-depth")
            end
            switch format
                case "tif"
                    imwrite(I, fname, 'tif', 'Compression', 'lzw');
                case "jpg"
                    imwrite(I, fname, 'jpg');
                otherwise
                    error("Unknown format")
            end

            if verbose
                Logger.log(LogLevel.INFO, '      Data saved as %s to <a href="matlab:winopen(''%s'')">%s</a>\n', upper(format), fName, fName);
            end
        end

        function I = loadFromIm(obj, bitDepth, relPath, fName, suffix, format)
            % Load data from an image file

            if nargin<6, format = "tif"; end
            if nargin<5, suffix = ""; end

            [~, f]      = fileparts(fName); 
            fname       = fullfile(obj.Paths.datapath, relPath, f + suffix + "." + format);
            data        = imread(fname);
            switch bitDepth
                case 1
                    I = data;
                case 8
                    I = double(data)/(2^8-1);
                case 16
                    I = double(data)/(2^16-1);
                otherwise
                    error("Unknown bit-depth")
            end
        end

        function saveToMat(obj, im, relPath, fName, suffix, verbose)
            % Save data to a binary mat file

            if nargin<6, verbose = false; end
            if nargin<5, suffix = ""; end

            [~, f]      = fileparts(fName);
            fname       = fullfile(obj.Paths.datapath, relPath, f + suffix + ".mat");
            save(fname, 'im', '-v7.3');

            if verbose
                Logger.log(LogLevel.INFO, '      Data saved as %s to <a href="matlab:winopen(''%s'')">%s</a>\n', "MAT", fName, fName);
            end
        end

        function data = loadFromMat(obj, relPath, fName, suffix)
            % load data from a binary mat file

            if nargin<4, suffix = ""; end
            [~, f]      = fileparts(fName); 
            fname       = fullfile(obj.Paths.datapath, relPath, f + suffix + ".mat");
            temp        = load(fname);
            data        = FileHandler.getField(temp, "im", "varinput");
        end

        function savePlot(~, fh, absPath, format, verbose)
            % Save a plot to an image of pdf file

            if nargin<5, verbose = false; end
            if nargin<4 || isempty(format), format = "jpg"; end

            sub_hideui(fh, false); % hide user interface for plotting
            set(fh, 'Units', 'centimeters');
            pos = get(fh,'Position');
            set(fh, 'PaperPositionMode', 'Auto', 'PaperUnits', 'centimeters', 'PaperSize', [pos(4), pos(3)]); %% TODO: Or [pos(3), pos(4)] for pdf??

            switch lower(format)
                case "jpg"
                    args = {'-djpeg'};
                case "pdf"
                    args = {'-r600', '-dpdf'};
                otherwise
                    error("Unknown format")
            end

            if verLessThan('matlab', '8.4')
                print(sprintf('-f%d', fh), absPath, args{:});
            else
                exportgraphics(fh, absPath);
            end
            
            sub_hideui(fh, true); % re-activate user interface

            if verbose
                [~, f] = fileparts(absPath);
                Logger.log(LogLevel.INFO, '      ELF plot for %s saved as %s to <a href="matlab:winopen(''%s'')">%s</a>\n', f, upper(format), absPath, absPath);
            end

            function sub_hideui(fh, activate)
                % sub function to hide ui buttons for plotting
                fignum = get(fh, 'Number');
                if activate
                    state = 'on';
                else
                    state = 'off';
                end

                set(findobj('tag', sprintf('fig%d_gui_posslider', fignum)), 'visible', state);
                set(findobj('tag', sprintf('fig%d_gui_rangeslider', fignum)), 'visible', state);

                drawnow;
            end
        end
    end


    %%%%%%%%%%%%%%%%%%%%
    %% STATIC METHODS %%
    %%%%%%%%%%%%%%%%%%%%
    methods (Static)
        function data = getField(s, varargin)
            % extract the first of a number of fields that exists in structure s
            % This is mainly used to allow for old saved data where fields might have been saved as varinput

            for i = 1:length(varargin)
                if isfield(s, varargin{i})
                    data = s.(varargin{i});
                    return
                end
            end
            error("Field not found");
        end % function
    end % methods
end % classdef
