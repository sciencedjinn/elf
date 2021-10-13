function elf_plot_intsummary(para, res, meanim, infosum, fh, info1, info2)
% ELF_PLOT_SUMMARY creates the main ELF intensity summary graph
%
% elf_plot_intsummary(para, res, meanim, infosum, fh, name, name2)
% 
% Inputs: 
%     para      - elf parameter struct
%     res       - results struct for this dataset
%     meanim    - mean image
%     infosum   - infosum struct for this dataset
%     fh        - figure handle to plot in (creates a new figure window if empty)
%     name      - data set name (default "no name")
%     name2     - line to show underneath name (e.g. to show number of scenes and exposures)
%
% Uses elf_plot_int

if nargin < 7, info2 = ''; end
if nargin < 6, info1 = ''; end
if nargin < 5, fh = elf_support_formatA4l(1); end
fignum = get(fh, 'Number');

rim             = [0.01 0 0.02 0.02]; % [L R B T]
gap             = 0.002; % x-gap between main axes
regionw         = 0.01; % width of the black bar marking elevation regions
colouraxgap     = 0.06; % height of the colour plot x-axis label
axlab           = 0.03; % width of axes label
bottompan       = 0.08; % height of the bottom panel
bottomgap       = 0.08; % gap above bottom panel 
axw             = (1-2*gap-2*regionw-2*axlab-rim(1)-rim(2))/2;
axw2            = (1-2*gap-rim(1)-rim(2))/3;
axh             = 1-bottompan-bottomgap-rim(3)-rim(4);
axh2            = (1-bottompan-bottomgap-rim(3)-rim(4)-gap-colouraxgap)/2;

%% create axes 1 to 5
stdoax  = {'Parent', fh, 'Units', 'normalized', 'fontsize', para.plot.axesFontsize};             % standard options for each axes element

ahMeanImage     = axes(stdoax{:}, 'Position', [rim(1)+axlab+0*gap+0*axw rim(3)+bottompan+bottomgap axw/2 axh], 'tag', 'gui_ax1'); % axes for mean image
ahMainPlot      = axes(stdoax{:}, 'Position', [rim(1)+axlab+1*gap+.5*axw rim(3)+bottompan+bottomgap axw axh], 'tag', 'gui_ax2'); % axes for intensity
ahMainOverlay   = axes(stdoax{:}, 'Position', [rim(1)+axlab+1*gap+.5*axw rim(3)+bottompan+bottomgap axw axh], 'tag', 'gui_ax2i', 'visible', 'off'); % axes for overlay
ahTicks         = axes(stdoax{:}, 'Position', [rim(1)+axlab+1*gap+.5*axw rim(3)+bottompan+bottomgap axw axh], 'tag', 'gui_ax2ii', 'visible', 'off'); % axes for ticks
ahColourPlot    = axes(stdoax{:}, 'Position', [rim(1)+1.5*axlab+2*gap+1.5*axw+regionw rim(3)+bottompan+bottomgap+axh2+gap+colouraxgap axw/2 axh2], 'tag', 'gui_ax4'); % axes for colour
ahRangePlot     = axes(stdoax{:}, 'Position', [rim(1)+1.5*axlab+2*gap+1.5*axw+regionw rim(3)+bottompan+bottomgap axw/2 axh2], 'tag', 'gui_ax3'); % axes for range

%% Buttons to switch range indicators for different colour channels
stdo1 = {'Parent', fh, 'Units', 'normalized'};             % standard options for each gui element
stdo2 = {'backgroundcolor', [.8 .8 .8], 'fontweight', 'bold', 'callback', @elf_callbacks_elfgui};     % standard options for each gui element
x = rim(1)+axlab+3*gap/2+1*axw;
y = 1-rim(4)-0.03;
uicontrol(stdo1{:}, stdo2{:}, 'Style', 'togglebutton', 'Position', [x+0.01 y .04 .02],   'tag', sprintf('fig%d_gui_BW', fignum),   'String', 'White',  'fontsize', 8, 'foregroundcolor', 'w', 'fontweight', 'bold','Value', 1);
uicontrol(stdo1{:}, stdo2{:}, 'Style', 'togglebutton', 'Position', [x+0.05 y .02 .02],   'tag', sprintf('fig%d_gui_R', fignum),    'String', 'R',      'fontsize', 8, 'foregroundcolor', 'r', 'fontweight', 'bold','Value', 0);
uicontrol(stdo1{:}, stdo2{:}, 'Style', 'togglebutton', 'Position', [x+0.07 y .02 .02],  'tag', sprintf('fig%d_gui_G', fignum),    'String', 'G',       'fontsize', 8, 'foregroundcolor', 'g', 'fontweight', 'bold','Value', 0);
uicontrol(stdo1{:}, stdo2{:}, 'Style', 'togglebutton', 'Position', [x+0.09 y .02 .02],   'tag', sprintf('fig%d_gui_B', fignum),    'String', 'B',      'fontsize', 8, 'foregroundcolor', 'b', 'fontweight', 'bold','Value', 0);

%% bottom bar
ahInfo1 = axes(stdoax{:}, 'Position', [rim(1)+0*gap rim(3) axw2 bottompan], 'tag', 'gui_ax7'); % axes for elf logo
ahTitle = axes(stdoax{:}, 'Position', [rim(1)+1*gap+axw2 rim(3) axw2 bottompan], 'tag', 'gui_ax6'); % axes for elf logo
ahInfo2 = axes(stdoax{:}, 'Position', [rim(1)+2*gap+2*axw2 rim(3) axw2 bottompan], 'tag', 'gui_ax8'); % axes for elf logo

% ax6     = axes(stdoax{:}, 'Position', [rim(1)+axlab+1*gap+.5*axw rim(3) axw bottompan], 'tag', 'gui_ax6', 'visible', 'off'); % axes for elf logo

text(0, 0, {'\makebox[4in][c]{\fontsize{60}{40}\textbf{E}\fontsize{15}{40}\textbf{nvironmental} \fontsize{60}{40}\textbf{L}\fontsize{15}{40}\textbf{ight} \fontsize{60}{40}\textbf{F}\fontsize{15}{40}\textbf{ield}}'}, ...
            'Interpreter', 'latex', 'HorizontalAlignment', 'Center', 'Parent', ahTitle, 'FontSize', para.plot.infoFontsize); 
text(0, 0, info1, 'HorizontalAlignment', 'Center', 'Parent', ahInfo1, 'FontSize', para.plot.infoFontsize);
text(0, 0, info2, 'HorizontalAlignment', 'Center', 'Parent', ahInfo2, 'FontSize', para.plot.infoFontsize);
axis(ahTitle, [-.1 .1 -.5 .5])
axis(ahInfo1, [-.5 .5 -.5 .5])
axis(ahInfo2, [-.5 .5 -.5 .5])
set(ahTitle, 'Color', 'none')
axis(ahTitle, 'off')
set(ahInfo1, 'Color', 'none')
axis(ahInfo1, 'off')
set(ahInfo2, 'Color', 'none')
axis(ahInfo2, 'off')

%% axes for reference labels
% ahReferenceLabels    = axes(stdoax{:}, 'Position', [rim(1)+axlab+3*gap/2+.5*axw rim(3)+3/4*bottompan+bottomgap axw bottompan/4], 'tag', 'gui_axbi'); % outside bottom
% ahReferenceLabels    = axes(stdoax{:}, 'Position', [rim(1)+axlab+3*gap/2+.5*axw rim(3)+3/4*bottompan+bottomgap axw bottompan/4], 'tag', 'gui_axbi'); % inside bottom %TODO
ahReferenceLabels    = axes(stdoax{:}, 'Position', [rim(1)+axlab+3*gap/2+.5*axw 1-rim(4)*0.75 axw rim(4)/2], 'tag', 'gui_axbi'); % outside top

%% plot both subplots
elf_plot_image(meanim, infosum, ahMeanImage, 'equirectangular_summary', 0);
set(ahMeanImage, 'DataAspectRatioMode', 'auto', 'fontsize', para.plot.axesFontsize);
elf_plot_int(para, res.int, res.totalint, ahMainPlot, ahMainOverlay, ahTicks, ahColourPlot, ahRangePlot, ahReferenceLabels, fignum);
elf_plot_int_setvis(fignum); % sets visibility of RGB plot using graphics object tags
