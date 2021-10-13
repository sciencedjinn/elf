function elf_main3_intsummary(dataset, imgformat)
% ELF_MAIN3_INTSUMMARY averages the intensity descriptors for an environment, 
% plots the results, and saves the plot to jpg 
%
% Uses: elf_support_logmsg, elf_paths, elf_para, elf_para_update, 
%       elf_info_collect, elf_io_readwrite, elf_analysis_datasetmean, 
%       elf_support_formatA4l, elf_plot_intsummary
%
% Loads files: mean results file in mat folder, mean image in detailed results folder
% Saves files: XLSX file and PDF in Detailed results folder, JPG in public
%              results folder
% 
% Typical timing for a 50-scene environment (on ELFPC):
%       6s total

%% check inputs
if nargin < 2 || isempty(imgformat), imgformat = '*.dng'; end
if nargin < 1 || isempty(dataset), error('You have to provide a valid dataset name'); end 

                    elf_support_logmsg('\b\b\b\b\b\b\b\b\b\b\b\b\b\n');
                    elf_support_logmsg('----- ELF Step 3: Calculating and plotting intensity summary -----\n');

%% Set up paths and file names; read info, infosum and para
elf_paths;
para            = elf_para('', dataset, imgformat);
para            = elf_para_update(para);                                                               % Combine old parameter file with potentially changed information in current elf_para
info            = elf_info_collect(fullfile(para.paths.datapath, para.paths.scenefolder), '*.tif');    % this contains tif exif information and filenames %%FIXME should be mat folder
infosum         = elf_io_readwrite(para, 'loadinfosum');                                                  % loads the old infosum file (which contains projection information)
fnames_im       = {info.Filename};                                                                      % collect image names

                    elf_support_logmsg('      Averaging intensity across all %d scenes in environment %s\n', length(fnames_im), dataset)
                    
%% Load data, calculate data mean
data            = elf_io_readwrite(para, 'loadres', fnames_im);
intmean         = elf_analysis_datasetmean(data, 1:length(data), 1, para.plot.datasetmeantype);                                   % Calculate descriptor mean only for intensities
elf_io_readwrite(para, 'savemeanres_int', '', intmean); % write data mean

%% Write stats into Excel file
if strcmp(para.syst, 'pc')
    elf_analysis_writestats(intmean, para, true);
else
    warning('Writing statistics to an Excel file is currently only supported for PC. Text file output on Mac will be available soon.');
end

%% Load mean image
meanim          = elf_io_readwrite(para, 'loadmeanimg_tif');

%% Plot results
% Present stats in figure 1
figInfo1 = {para.paths.dataset, sprintf('n = %d scenes, %d exposure per scene', length(info), length(infosum.DateTimeOriginal)/length(info))};
datefmt = 'yyyy-mm-dd HH:MM';
figInfo2 = {sprintf('%s to', datestr(min(infosum.DateTimeOriginal), datefmt)), sprintf('%s', datestr(max(infosum.DateTimeOriginal), datefmt))};


fh              = elf_support_formatA4l(35); clf;
                  set(fh, 'Name', 'Environmental Light Field');
                  elf_plot_intsummary(para, intmean, meanim, infosum, fh, figInfo1, figInfo2); % generate summary ELF plot

%% Save output to pdf and tif
fh = elf_support_formatA4l(35);
elf_io_readwrite(para, 'savemeanivep_jpg', '', fh);
elf_io_readwrite(para, 'savemeanivep_pdf', '', fh);

















