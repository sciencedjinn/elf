function figh = elf_support_formatA3(fignum, screenpos)
% figh = elf_support_formatA3(fignum, screenpos)

if nargin < 2
    screenpos = 1;
end
if nargin < 1
    figh = figure;
else
    figh = figure(fignum);
end

clf;
orient landscape;
ss = get(0, 'ScreenSize');       % [1 1 1920 1200]
w  = 2 * (0.9*ss(4)) * 21/29.7;   % width in pixels
h  = 0.9*ss(4);                 % height in pixels               
pos = [1+(screenpos-1)*w  60 w h];
set(figh, 'Units', 'pixels', 'outerposition', pos, ...
    'PaperType', 'A3', 'PaperUnits', 'normalized', 'color', 'w', 'PaperPositionMode', 'auto', ...
    'Renderer', 'zbuffer');
% 60 offset if to accommodate Taskbar
