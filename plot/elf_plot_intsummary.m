function h = elf_plot_intSummary(res, meanIm, infoSum, name, nScenes)
% ELF_PLOT_SUMMARY creates the main ELF intensity summary graph
%
% elf_plot_intsummary(para, res, meanim, infosum, fh, name, name2)
% 
% Inputs: 
%     res       - results struct for this dataset
%     meanIm    - mean image
%     infoSum   - infoSum struct for this dataset
%     name      - data set name (default "no name")
%     nScenes   - number of scenes (to calculate exposures/scene)
%
% Uses elf_plot_createFigure, elf_plot_image, elf_plot_int, elf_plot_info

[h, plotPara] = elf_plot_createFigure; % generate summary ELF plot
elf_plot_image(meanIm, infoSum, h.ahMeanImage, 'equirectangular_summary_squished', 0, plotPara); % plot the mean image
elf_plot_int(h, res.int, res.totalint, plotPara);
elf_plot_info(h, infoSum, name, nScenes, plotPara)

% set(h.ahMeanImage, 'fontsize', para.plot.axesFontsize);

