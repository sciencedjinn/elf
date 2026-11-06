function [status, gui] = elf_callbacks_maingui(modules, src, status, gui, para)
% ELF_CALLBACKS_MAINGUI deals with the callbacks of the ELF gui's buttons

if strcmp(src.Tag, 'maingui_slider')
    newp2 = src.Value;
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
    if strcmp(src.Type, 'uicontrol')
        src.Parent.Enable = "off";
        drawnow
    end
    try
        if strcmp(src.Type, 'uicontrol')
            % get dataset name and image format
            warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved')
            thistextbox = findobj(src.Parent, 'tag', 'dataset');
            dataset     = get(thistextbox, 'String');
            imgformat   = get(thistextbox, 'UserData');
            verbose     = true;
            saveit      = true;
            calcmean    = true;
        end
    
        switch src.Tag
            case 'maingui_dng'
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
            case 'maingui_scenes'
                elf_main1_perScene(dataset, modules, imgformat);
                refresh = 1;
            case 'maingui_info'
                elf_gui_chooseext(fullfile(para.fh.Paths.root, dataset), false);
                refresh = 0;
            case 'maingui_show'
                elf_main4_display(dataset, modules);
                refresh = 1;
            case 'maingui_buttonall'
                elf_main1_perScene(dataset, modules, imgformat);
                elf_main2_perEnvironment(dataset, modules, verbose);
                refresh = 1;
            case 'maingui_buttonexp'
                elf_mainX_explore(dataset, modules);
                refresh = 0;
            case 'maingui_buttondiag'
                elf_mainX_exploreDiag(dataset, modules);
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
                thisPath    = fileparts(mfilename("fullpath"));
                open(fullfile(thisPath, "..", "help", "User's Manual.pdf"));
                ismenu = 1;
                refresh = 0;            
            otherwise
                % Check if this is a module's perEnvironment button
                modName = textscan(src.Tag, "maingui_perEnvironment_%s");
                if ~isempty(modName{1})
                    modName = modName{1}{1};
                    thisPara = elf_para(modules, '', dataset);
                    thisPara = elf_para_update(thisPara, modName);   % Combine old parameter file with potentially changed information in current config
                    infoSum  = thisPara.fh.loadInfoSum();       % loads the old infosum file (which contains projection information, and linims)
                    
                    modPerEnvFilename = [modName '_perEnvironment'];
                    [para, infoSum] = feval(modPerEnvFilename, thisPara, infoSum, verbose);
                    para.fh.saveInfoSum(para, infoSum); % saves infosum AND para for use in later stages
                    refresh = 1;
                else
                    error("Unknown button")
                end
        end
    
        if refresh
            % update gui visibility
            %% TODO: Would be great if the image was updated here, as well
            status = elf_checkdata(para, false);
            elf_maingui_visibility(gui, para, status);
        end
    catch me
        if strcmp(src.Type, 'uicontrol')
            src.Parent.BackgroundColor = "r";
            src.Parent.Enable = "on";
            drawnow
        end
        rethrow(me);
    end

    if strcmp(src.Type, 'uicontrol')
        src.Parent.BackgroundColor = [.9412 .9412 .9412];
        src.Parent.Enable = "on";
        drawnow
    end
end