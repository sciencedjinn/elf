function elf_main3_intsummary(dataSet, imgFormat)
% ELF_MAIN3_INTSUMMARY averages the intensity descriptors for an environment, 
% plots the results, and saves the plot to jpg 
%
% Uses: elf_support_logmsg, elf_paths, elf_para, elf_para_update, 
%       elf_info_collect, elf_io_readwrite, elf_analysis_datasetmean, 
%       elf_plot_intsummary
%
% Loads files: mean results file in mat folder, mean image in detailed results folder
% Saves files: XLSX file and PDF in Detailed results folder, JPG in public
%              results folder
% 
% Typical timing for a 50-scene environment (on ELFPC):
%       6s total

%% check inputs
if nargin < 2 || isempty(imgFormat), imgFormat = '*.dng'; end
if nargin < 1 || isempty(dataSet), error('You have to provide a valid dataset name'); end 

                    elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b\n');
                    elf_support_logmsg('----- ELF Step 3: Calculating and plotting intensity summary -----\n');

%% Set up paths and file names; read info, infosum and para
elf_paths;
para            = elf_para('', dataSet, imgFormat);
para            = elf_para_update(para);                                                               % Combine old parameter file with potentially changed information in current elf_para
info            = elf_info_collect(fullfile(para.paths.datapath, para.paths.scenefolder), '*.tif');    % this contains tif exif information and filenames %%FIXME should be mat folder
infoSum         = elf_io_readwrite(para, 'loadinfosum');                                               % loads the old infosum file (which contains projection information)
fNames_im       = {info.Filename};                                                                     % collect image names

                    elf_support_logmsg('      Averaging intensity across all %d scenes in environment %s\n', length(fNames_im), dataSet)
                    
%% Load data, calculate data mean
data            = elf_io_readwrite(para, 'loadres', fNames_im);
intMean         = elf_analysis_datasetmean(data, 1:length(data), 1, para.plot.datasetmeantype);                                   % Calculate descriptor mean only for intensities
elf_io_readwrite(para, 'savemeanres_int', '', intMean); % write data mean

%% Write stats into CSV file
elf_analysis_writestats(intMean, para.paths.fname_stats);

%% Load mean image
meanIm  = elf_io_readwrite(para, 'loadmeanimg_tif');

%% Plot results
h       = elf_plot_intSummary(intMean, meanIm, infoSum, para.paths.dataset, length(info));

%% Save output to pdf and tif
elf_io_readwrite(para, 'savemeanivep_jpg', '', h.fh);
elf_io_readwrite(para, 'savemeanivep_pdf', '', h.fh);

















