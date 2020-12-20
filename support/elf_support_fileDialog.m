function returnPath = elf_support_fileDialog(dlgtext, uitype, dlgfilter, dlgtitle, dlgdefname, varargin)
% elf_support_fileDialog is an extension of uigetfile/uiputfile/uigetdir that displays
% a prompt for a file/folder name in a dialog window. This is useful
% especially on MacOS, where the title field of the ui functions is not
% shown and no information is passed on to the user.
%
% returnPath = elf_support_fileDialog(dlgtext, uitype, dlgfilter, dlgtitle, dlgdefname, varargin)
%
% Inputs:
% dlgtext                           - String to inform the user what to select
% uitype                            - 'uigetfile' (default) / 'uiputfile' / 'uigetdir'
% dlgfilter, dlgtitle, dlgdefname   - are passed on to uigetfile/uigetdir/uiputfile
% varargin                          - Any number of Name/Value pairs to be passed on to the dialog box
%
% Outputs:
% returnPath                        - The full path selected by the user, or an empty string if canceled

if nargin<5 || isempty(dlgdefname), dlgdefname = ''; end
if nargin<4 || isempty(dlgtitle), dlgtitle = ''; end
if nargin<3 || isempty(dlgfilter), dlgfilter = ''; end
if nargin<2 || isempty(uitype), uitype = 'uigetfile'; end
if nargin<1 || isempty(dlgtext), dlgtext = 'This is a test of the dialog system. This is a test of the dialog system. This is a test of the dialog system. This is a test of the dialog system. This is a test of the dialog system. '; end

%% init variables
gui     = [];
returnPath = '';

% create GUI
sub_creategui;

%% set figure to modal late after you know there are no errors
set(gui.fh, 'windowStyle', 'modal', 'CloseRequestFcn', @sub_cancel);

%% handle Return/Escape/Figure close, redraw to remove wrong previews and finish
try
    uiwait(gui.fh);
    delete(gui.fh);
catch anyerror
    delete(gui.fh);        %delete the modal figure, otherwise we'll be stuck in it forever
    rethrow(anyerror);
end





%%%%%%%%%%%%%%%%%%%

%% Nested functions for callbacks and panel creation
function sub_OK(varargin)
    % OK: ok button callback, checks if the path is valid, and returns it
    switch uitype
        case 'uiputfile'
            [testTarget, f, e] = fileparts(gui.path.String);
            if isempty(testTarget)
                % local path           
                testTarget = pwd;
                returnPath = fullfile(testTarget, [f e]);      
            else
                returnPath = gui.path.String;
            end
            valid = isfolder(testTarget);
            warnMsg = 'Folder not found';
        case 'uigetfile'
            testTarget = gui.path.String;
            if isempty(fileparts(testTarget))
                % local path           
                testTarget = fullfile(pwd, gui.path.String);
            end
            returnPath = testTarget;
            valid = isfile(testTarget);
            warnMsg = 'File not found';
        case 'uigetdir'
            testTarget = gui.path.String;
             if isempty(fileparts(testTarget))
                % local path           
                testTarget = fullfile(pwd, gui.path.String);
             end
             returnPath = testTarget;
            valid = isfolder(testTarget);
            warnMsg = 'Folder not found';
        otherwise
            error('Internal error: Unknown uitype passed to function: %s', uitype);
    end
    if valid
        uiresume;
    else
        warndlg(sprintf('%s: %s', warnMsg, testTarget));
    end
end

function sub_cancel(varargin)
    % CANCEL: cancel button callback, returns empty path
    returnPath = '';
    uiresume;
end

function sub_browse(varargin)
    switch uitype
        case 'uiputfile'
            [f, p] = uiputfile(dlgfilter, dlgtitle, gui.path.String);
        case 'uigetfile'
            [f, p] = uigetfile(dlgfilter, dlgtitle, gui.path.String);
        case 'uigetdir'
            p = uigetdir(gui.path.String, dlgtitle);
            f = '';
        otherwise
            error('Internal error: Unknown uitype passed to function: %s', uitype);
    end
    if ~isequal(p,0)
        gui.path.String = fullfile(p, f);
    end
end

function sub_creategui

    %% layout parameters
    txtMarginHor = 10;
    txtMarginVer = 5;
    pthMarginHor = 10;
    pthMarginVer = 2;
    btnsMarginVer = 5;
    pthToBrowse  = 5; % gap between path field and browse button, in pixels
    btnPadding = 3;
    minBtnWidth = 100;

    %%
    gui.fh = dialog('Units', 'normalized', 'Position', [.4 .4 .2 .01], 'Name', 'Select file/directory', varargin{:});

    set(gui.fh, 'units', 'pixels', 'windowstyle', 'normal');
    fPos = gui.fh.Position;

    % Initialise ui element sizes
    txtPos = [1+txtMarginHor ceil(0.5*fPos(4))+txtMarginVer fPos(3)-2*txtMarginHor 0];
    btn1Pos = [1 1 1 1];
    btn2Pos = [1 1 1 1];
    btn3Pos = [1 1 1 1];
    pthPos = [1+pthMarginHor 1 fPos(3)-2*pthMarginHor 0];

    % Initialise ui elements
    txt = uicontrol('parent', gui.fh, 'units', 'pixels', 'style', 'text',...
        'position', txtPos, 'string', dlgtext);
    switch uitype
        case {'uiputfile', 'uigetfile'}
            defname = dlgdefname;
        case'uigetdir'
            defname = dlgfilter;
    end
    pth = uicontrol('Parent', gui.fh, 'Units', 'pixels', 'position', pthPos,...
        'horizontalalignment', 'right', 'Style', 'edit', 'String', defname, 'callback', @sub_OK);
    btn1 = uicontrol('Parent', gui.fh, 'Units', 'pixels',...
        'Position', btn1Pos, 'String', 'Browse...', 'callback', @sub_browse);
    btn2 = uicontrol('Parent', gui.fh, 'Units', 'pixels',...
        'Position', btn2Pos, 'FontWeight', 'bold', 'String', 'OK', 'callback', @sub_OK);
    btn3 = uicontrol('Parent', gui.fh, 'Units', 'pixels',...
        'Position', btn3Pos, 'FontWeight', 'bold', 'String', 'Cancel', 'callback', @sub_cancel);

    %% Get extent of boxes and adjust sizes   
    txtExt = txt.Extent;
    btn1Ext = btn1.Extent;
    btn2Ext = btn2.Extent;
    btn3Ext = btn3.Extent;
    pthExt = pth.Extent;

    % Calculate vertical heights
    txtPos(4)  = txtExt(4)*ceil(txtExt(3)/txtPos(3));
    btn1Pos(4) = max([pthExt(4) btn1Ext(4)])+2*btnPadding;
    pthPos(4)  = btn1Pos(4);
    btn3Pos(4) = btn3Ext(4)+2*btnPadding;
    btn2Pos(4) = btn2Ext(4)+2*btnPadding;

    totalVertExt = txtPos(4) + btn1Pos(4) + btn3Pos(4) + 2*txtMarginVer + 2*pthMarginVer + 2*btnsMarginVer;

    if totalVertExt>fPos(4)
        gui.fh.Position(4) = totalVertExt;
        fPos = gui.fh.Position;
    %     error('This isnt going to fit in the box. Do something about it.');
    end

    % Calculate a good position for each element so that everything is centered
    % in the dialog box
    midPoint   = (1+fPos(4))/2;
    txtPos(2)  = midPoint+totalVertExt/2-txtPos(4)-txtMarginVer;
    pthPos(2)  = txtPos(2)-pthPos(4)-txtMarginVer-pthMarginVer;
    btn1Pos(2) = pthPos(2);
    btn3Pos(2) = pthPos(2)-btn1Pos(4)-pthMarginVer-btnsMarginVer;
    btn2Pos(2) = btn3Pos(2);

    % same for widths and horizontal positions
    txtPos(3)  = fPos(3)-2*txtMarginHor;
    btn1Pos(3) = max([minBtnWidth btn1Ext(3)+2*btnPadding]);
    pthPos(3)  = fPos(3)-2*pthMarginHor-pthToBrowse-btn1Pos(3);
    btn3Pos(3) = max([minBtnWidth btn3Ext(3)+2*btnPadding]);
    btn2Pos(3) = max([minBtnWidth btn2Ext(3)+2*btnPadding]);

    midWidth   = (1+fPos(3))/2;
    txtPos(1)  = 1+txtMarginHor;
    pthPos(1)  = 1+pthMarginHor;
    btn1Pos(1) = fPos(3)-pthMarginHor-btn1Pos(3);
    btn3Pos(1) = midWidth+btnPadding/2;
    btn2Pos(1) = midWidth-btnPadding/2-btn2Pos(3);

    set(txt, 'position', txtPos);
    set(pth, 'position', pthPos);
    set(btn1, 'position', btn1Pos);
    set(btn2, 'position', btn2Pos);
    set(btn3, 'position', btn3Pos);
    
    gui.path = pth;
end
   
end % main