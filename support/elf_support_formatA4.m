function figh = elf_support_formatA4(fignum, screenpos)
% figh = elf_support_formatA4(fignum, screenpos)

if nargin < 2
    screenpos = 1;
end
if nargin < 1
    figh = figure;
else
    figh = figure(fignum);
end

clf;
orient portrait;
ss = get(0, 'ScreenSize');  % [1 1 1920 1200]
w = (ss(4)-60) * 21/29.7;   % width in pixels
h = (ss(4)-60);             % height in pixels               
pos = [1+(screenpos-1)*w  60 w h];
set(figh, 'Units', 'pixels', 'outerposition', pos, ...
    'PaperType', 'A4', 'PaperUnits', 'normalized', 'color', 'w', 'PaperPositionMode', 'auto', ...
    'Renderer', 'painters');%'zbuffer');
% 60 offset if to accommodate Taskbar
