function elf_main4_display(dataSet, imgFormat)
% ELF_MAIN4_DISPLAY simply displays the intensity mean and mean image for a dataset
%
% elf_main4_display(dataSet, imgFormat)

if nargin < 2 || isempty(imgFormat), imgFormat = '*.dng'; end

          elf_paths;
para    = elf_para('', dataSet, imgFormat);
          elf_main3_intsummary(dataSet, imgFormat)
fh      = elf_support_formatA4(48, 2);
          elf_plot_image(elf_io_readwrite(para, 'loadmeanimg_tif'), [], fh); % open mean image





