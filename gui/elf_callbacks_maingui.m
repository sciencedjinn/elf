function [status, gui] = elf_callbacks_maingui(src, status, gui, para)
% ELF_CALLBACKS_MAINGUI deals with the callbacks of the ELF gui's buttons

if strcmp(get(src, 'tag'), 'maingui_slider')
    newp2 = get(src, 'Value');
    sph = findobj('tag', 'maingui_superpanel'); % handle to superpanel
    oldpos = get(sph, 'position');
    newpos = [oldpos(1) -newp2 oldpos(3:4)];
    set(sph, 'position', newpos);
    
    % The subpanels and axes do not update properly when the slider is moved.
    % This is a work-around that works in Windows 7 with Matlab 2014a. However, it
    % seems VERY likely that it will not work on other systems or other Matlab versions.
    % Maybe the slider should be de-activated then?
    s = hgexport('factorystyle');
    hgexport(gcf, 'temp_dummy', s, 'applystyle', true);
    
else
    ismenu = 0;
    if strcmp(get(src, 'type'), 'uicontrol')
        set(get(src, 'Parent'), 'backgroundcolor', 'y');
        drawnow
        % get dataset name and image format
        thistextbox = findobj('parent', get(src, 'parent'), 'tag', 'dataset');
        dataset     = get(thistextbox, 'String');
        imgformat   = get(thistextbox, 'UserData');
        verbose     = true;
        saveit      = true;
        calcmean    = true;

        % get range if button callback
    
        rangebox = findobj('parent', get(src, 'parent'), 'tag', 'maingui_range');
        rangestr = get(rangebox, 'string');
        if ismember(rangestr, {'', ' ', 'all', 'full', '1:end', ':'})
            frange = [];
        else
            frange = eval(rangestr);
        end
    end
    
    switch get(src, 'tag')
        case 'maingui_button1'
            % If this is green, do nothing.
            % Otherwise, display information about how to convert raw files.
            if ~all(get(src, 'backgroundcolor') == [0 1 0])
                helpdlg(['No usable files were found in this folder. To convert RAW files (e.g. NEF or CR2 formats), download and install Adobe DNG Converter ', ...
                    '(http://www.adobe.com/products/photoshop/extend.displayTab2.html#downloads) After opening Adobe DNG Converter, click on Change Preferences ', ...
                    'and in the window that opens, use the drop-down menu to create a Custom Compatibility. IMPORTANT: Make sure the ''Uncompressed'' box is checked ', ... 
                    'in this custom compatibility mode and the ''Linear (demosaiced)'' box is unchecked. ''Backward Version'' can be whatever you like. ', ...
                   ' This information can also be found in the ''Getting Started'' Guide accessible from the ELF Help menu.'], ...
                    'Covert RAW files');
            end
            refresh = 0;
        case 'maingui_button2'
            elf_main1_HdrAndInt(dataset, imgformat, verbose);
            refresh = 1;
        case 'maingui_button3'
            elf_main2_meanimage(dataset, verbose);
            refresh = 1;
        case 'maingui_button4'
            elf_main3_intsummary(dataset, imgformat);
            refresh = 1;
        case 'maingui_button5'
            elf_gui_chooseext(fullfile(para.paths.root, dataset), false);
            refresh = 0;
        case 'maingui_button6'
            elf_main4_display(dataset, imgformat);
            refresh = 1;
        case 'maingui_buttonall'
            elf_main1_HdrAndInt(dataset, imgformat, verbose);
            elf_main2_meanimage(dataset, verbose);
            elf_main3_intsummary(dataset, imgformat);
            refresh = 1;
        case 'maingui_buttonexp'
            elf_mainX_explore(dataset, imgformat); % TODO use frange
            refresh = 0;
        case 'maingui_range'
            refresh = 0;
        case 'file_refresh'
            refresh = 1;
            ismenu = 1;
        case 'file_exit'
            close(gui.fh);
            ismenu = 1;
            return;
        case 'para_edit'
            edit elf_para;
            ismenu = 1;
            refresh = 0;
        case 'help_knownbugs'
            type elf_help_knownbugs
            ismenu = 1;
            refresh = 0;
        case 'help_gettingstarted'
            open('ELF Getting started guide.pdf');
            ismenu = 1;
            refresh = 0;
            
        otherwise
            refresh = 0;
    end
    
    if refresh
        % update gui visibility
        status = elf_checkdata(para);
        elf_maingui_visibility(gui, status);
    end
    if ~ismenu
        set(get(src, 'Parent'), 'backgroundcolor', [.9412 .9412 .9412]); %%FIXME for menus 20150318
    end
end