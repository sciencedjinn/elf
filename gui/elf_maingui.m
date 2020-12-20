function gui = elf_maingui(status, para, datasets, exts, cbhandle)
% Creates the main GUI for elf, allowing the user to process and examine individual data sets

pnum_cols = para.gui.pnum_cols;
pnum_rows = para.gui.pnum_rows; 

%% parameters
numsets         = size(status, 1);         % total number of sets
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
gui.fh          = elf_support_formatA3(1);
set(gui.fh, 'name', 'ELF');

%% browse button
uicontrol('Units', 'normalized', 'parent', gui.fh, 'callback', cbhandle, 'Style', 'pushbutton', 'Position', [0 1-browseheight 0.05 browseheight], 'tag', 'maingui_folderbrowse', ...
        'string', 'Browse');
uicontrol('Units', 'normalized', 'parent', gui.fh, 'Style', 'edit', 'Position', [0.054 1-browseheight 0.946 browseheight], 'tag', 'maingui_folderedit', ...
        'string', para.paths.root, 'horizontalalignment', 'left', 'enable', 'inactive'); %, 'backgroundcolor', [0 0 0]);

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
    stdo        = {'Units', 'normalized', 'parent', gui.p(i).ph, 'callback', cbhandle}; % standard options for gui elements
    
    % textbox: data set name
    if isnan(exts{i}) % this happens when there are only raw files in the folder
        ud = '*.*';
    else
        ud = ['*' exts{i}];
    end
    gui.p(i).tb = uicontrol(stdo{:}, 'Style', 'text', 'Position', [.2 0 .8 .2], 'tag', 'dataset', 'String', datasets{i}, 'userdata', ud);
    
    % buttons
    gui.p(i).b1     = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .85 .09 .1], 'tag', 'maingui_button1', 'String', '1');
    gui.p(i).b2     = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .75 .09 .1], 'tag', 'maingui_button2', 'String', '2');
    gui.p(i).b3     = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .65 .09 .1], 'tag', 'maingui_button3', 'String', '3');
    gui.p(i).b4     = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .55 .09 .1], 'tag', 'maingui_button4', 'String', '4');
    gui.p(i).ball   = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .45 .18 .1], 'tag', 'maingui_buttonall', 'String', 'Full', 'tooltip', 'Calculate Steps 2, 3 & 4 for this dataset.');
    gui.p(i).exp    = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .35 .18 .1], 'tag', 'maingui_buttonexp', 'String', 'Explore', 'tooltip', 'Explore the results for individual images.');
    gui.p(i).b5     = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 .10 .18 .1], 'tag', 'maingui_button5', 'String', 'Info');
    gui.p(i).b6     = uicontrol(stdo{:}, 'Style', 'pushbutton', 'Position', [0 0 .18 .1],   'tag', 'maingui_button6', 'String', 'Show');
    gui.p(i).range  = uicontrol(stdo{:}, 'Style', 'edit',       'Position', [0 .2 .18 .1],  'tag', 'maingui_range', 'String', 'all', 'backgroundcolor', 'w', 'tooltip', 'Use this field to restrict the range of images to calculate with all functions. Enter a range as, e.g. 1:12 for images 1 to 12 or [1 3 7] for images 1,3 and 7. To use all images, enter all or leave the field empty.');
    set(gui.p(i).range, 'visible', 'off'); % TODO: Reactivate and use the input
    
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
gui.menu.help.gs        = uimenu(gui.menu.help.h, 'label', 'Getting Started...', 'callback', cbhandle, 'tag', 'help_gettingstarted');
gui.menu.help.kb        = uimenu(gui.menu.help.h, 'label', 'Known bugs...', 'callback', cbhandle, 'tag', 'help_knownbugs');

%% set visibility and colours
elf_maingui_visibility(gui, status);




