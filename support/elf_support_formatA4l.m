function [fh, corrFac] = elf_support_formatA4l(fignum, screenpos)
% figh = elf_support_formatA4l(fignum, screenpos)

if nargin<2, screenpos = 1; end
if nargin<1, fh = figure; else, fh = figure(fignum); end

ss  = get(0, 'ScreenSize');   % [1 1 1920 1200]
screenHeight = ss(4);

if screenHeight>1080
    % For larger screens, always use a 1000 pixel high window. This makes it easiest to keep figures consistent
    figureHeight = 1000;
    corrFac = 1;
else
    % For smaller screens, reduce the window size, but keep some room for the taskbar
    figureHeight = 0.9*screenHeight;
    corrFac = figureHeight/1000; % this correction factor can later be used to adjust fontsizes and other absolute sizing
end
     
figureWidth = figureHeight / (21/29.7); % width in pixels         
pos = [1+(screenpos-1)*figureWidth screenHeight-figureHeight-30 figureWidth figureHeight];
orient(fh, 'landscape');
set(fh, 'MenuBar', 'none', 'ToolBar', 'none', 'Units', 'pixels', 'NumberTitle', 'off', 'position', pos, ...
    'PaperUnits', 'centimeters', 'PaperSize', [29.7 21], ...
    'color', 'w', 'paperpositionmode', 'manual', 'paperposition', [1 .5 27.7 20], ...
    'Renderer', 'painters');
drawnow;

