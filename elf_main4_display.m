function elf_main4_display(dataset, imgformat)
% ELF_MAIN4_DISPLAY simply displays the intensity mean and mean image for a dataset
%
% elf_main4_display(dataset, imgformat)

if nargin < 2 || isempty(imgformat), imgformat = '*.dng'; end

          elf_paths;
para    = elf_para('', dataset, imgformat);
          elf_main3_intsummary(dataset, imgformat)
fh      = elf_support_formatA4(48, 2);
          elf_plot_image(elf_io_readwrite(para, 'loadmeanimg_tif'), [], fh); % open mean image





