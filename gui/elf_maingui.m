function gui = elf_maingui(status, para, datasets, exts, cbhandle, figname, figh)
% Creates the main GUI for elf, allowing the user to process and examine individual data sets

if nargin<7, figh = []; end
if nargin<6, figname = "ELF"; end

pnum_cols = para.plot.guiNumCols;
pnum_rows = para.plot.guiNumRows; 

%% parameters
numsets         = size(status.Colour, 1);         % total number of sets
totalrows       = ceil(numsets/pnum_cols); % total number of rows that will be needed to accommodate all datasets
sliderwidth     = 0.01;                    % width reserved for slider
browseheight    = 0.02;                    % height reserved for folder and browse button
w               = (1)/pnum_cols;           % width of each subpanel
h               = 1/totalrows;             % height of each subpanel
superp_height   = totalrows/pnum_rows;     % height of superpanel

%% preallocate loop variables
gui.ah          = zeros(numsets, 1);
gui.ph          = zeros(numsets, 1);

%% create gui
% create figure and superpanel
if isempty(figh)
    gui.fh = elf_support_formatA3;
else
    gui.fh = figh;
end
clf(gui.fh);
set(gui.fh, 'name', figname);

%% browse button
uicontrol('Units', 'normalized', 'parent', gui.fh, 'callback', cbhandle, 'Style', 'pushbutton', 'Position', [0 1-browseheight 0.05 browseheight], 'tag', 'maingui_folderbrowse', ...
        'string', 'Browse');
uicontrol('Units', 'normalized', 'parent', gui.fh, 'Style', 'edit', 'Position', [0.054 1-browseheight 0.946 browseheight], 'tag', 'maingui_folderedit', ...
        'string', para.fh.Paths.root, 'horizontalalignment', 'left', 'enable', 'inactive'); %, 'backgroundcolor', [0 0 0]);

%% Superpanel
gui.sph         = uipanel('Units', 'normalized', 'Position', [0 1-superp_height-browseheight 1-sliderwidth superp_height], 'parent', gui.fh, 'tag', 'maingui_superpanel');

for i = 1:numsets
    % calculate position for new panel
    panelrow    = ceil(i/pnum_cols);
    panelcol    = mod(i-1, pnum_cols)+1;
    x           = (panelcol-1) * w;
    y           = 1 - panelrow * h;
    
    % create subpanel
    gui.p(i).ph = uipanel('Units', 'normalized', 'Position', [x y w h], 'parent', gui.sph);
    stdo        = {'Units', 'normalized', 'parent', gui.p(i).ph, 'FontSize', 7, 'callback', cbhandle}; % standard options for gui elements
    
    % textbox: data set name
    if isnan(exts{i}) % this happens when there are only raw files in the folder
        ud = '*.*';
    else
        ud = ['*' exts{i}];
    end
    gui.p(i).tb = uicontrol(stdo{:}, 'Style', 'text', 'Position', [.2 0 .8 .2], 'tag', 'dataset', 'String', datasets{i}, 'userdata', ud);
    
    % buttons
    gui.p(i).dng    = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .89 .2 .1], 'tag', 'maingui_dng', 'String', 'DNG');
    gui.p(i).scenes = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .79 .2 .1], 'tag', 'maingui_scenes', 'String', 'scenes');
    validModNum = 1;
    for modNum = length(para.modules):-1:1
        modName = para.modules{modNum};
        if para.ana.(modName).needsToRunPerEnvironment
            gui.p(i).modButtons(modNum) = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .79-0.1*validModNum .2 .1], 'tag', ['maingui_perEnvironment_' modName], 'String', modName);
            validModNum = validModNum + 1;
        end
    end

    gui.p(i).ball   = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .37 .2 .1], 'tag', 'maingui_buttonall', 'String', 'Full', 'tooltip', 'Calculate all steps for this dataset.');
    gui.p(i).exp    = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .27 .1 .1], 'tag', 'maingui_buttonexp', 'String', 'Exp', 'tooltip', 'Explore the results for individual images.');
    gui.p(i).diag   = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [.1 .27 .1 .1], 'tag', 'maingui_buttondiag', 'String', 'Diag', 'tooltip', 'Explore the results for individual images.');
    gui.p(i).info   = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .11 .2 .1], 'tag', 'maingui_info', 'String', 'Info');
    gui.p(i).show   = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .01 .2 .1],   'tag', 'maingui_show', 'String', 'Show');

    % image axes
    gui.p(i).ah = axes('units', 'normalized', 'position', [.2 .2 .8 .8], 'parent', gui.p(i).ph);
    axis(gui.p(i).ah, 'off');
end

%% slider
smin = 0;
smax = totalrows/pnum_rows-1;
sstep = [0.5/pnum_rows/smax 1/smax]; % small step: half a panel; large step: whole page
if smax > 0
    uicontrol('Units', 'normalized', 'parent', gui.fh, 'callback', cbhandle, 'Style', 'slider', 'Position', [1-sliderwidth 0 sliderwidth 1-browseheight], 'tag', 'maingui_slider', ...
        'min', smin, 'max', smax, 'value', smax, 'sliderstep', sstep); % value determines the bottom position of the superpanel
end

%% create menus
set(gui.fh, 'menubar', 'none');
gui.menu.file.h         = uimenu(gui.fh, 'label', 'File');
gui.menu.file.refresh   = uimenu(gui.menu.file.h, 'label', 'Refresh status indicators', 'callback', cbhandle, 'tag', 'file_refresh');
gui.menu.file.refresh   = uimenu(gui.menu.file.h, 'label', 'Reload gui', 'callback', cbhandle, 'tag', 'file_reload');
gui.menu.file.exit      = uimenu(gui.menu.file.h, 'label', 'Exit', 'callback', cbhandle, 'tag', 'file_exit');

gui.menu.para.h         = uimenu(gui.fh, 'label', 'Parameters');
gui.menu.para.editpara  = uimenu(gui.menu.para.h, 'label', 'Edit parameters...', 'callback', cbhandle, 'tag', 'para_edit');

gui.menu.help.h         = uimenu(gui.fh, 'label', 'Help');
gui.menu.help.gs        = uimenu(gui.menu.help.h, 'label', 'User Manual...', 'callback', cbhandle, 'tag', 'help_gettingstarted');
gui.menu.help.kb        = uimenu(gui.menu.help.h, 'label', 'Known bugs...', 'callback', cbhandle, 'tag', 'help_knownbugs');

%% set visibility and colours
elf_maingui_visibility(gui, para, status);




