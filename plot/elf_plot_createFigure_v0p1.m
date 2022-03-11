function [h, p] = elf_plot_createFigure()

%% parameters
p               = elf_plottingPara;

switch p.version
    case 0.2
        [h.fh, p.corrFac]  = elf_support_formatA4l(35); clf;
        set(h.fh, 'Name', 'Environmental Light Field');

        % extract some values from p
        pad                 = p.padding;            % [L R B T]
        colSpacing          = p.columnSpacing;      % x-gap between main axes
        regionMarkerWidth   = p.regionMarkerWidth;  % width of the black bar marking elevation regions
        colourAxisHeight    = p.colourAxisHeight;   % height reserved for the colour plot x-axis label
        yAxisLabelWidth     = p.yAxisLabelWidth;    % width of y-axes label
        infoPanelHeight     = p.infoPanelHeight;    % height of the bottom panel
        rowSpacing          = p.rowSpacing;         % gap above bottom panel

        % calculate axes sizing
        axWidth             = (1-2*colSpacing-2*regionMarkerWidth-2*yAxisLabelWidth-pad(1)-pad(2))/2;       % width of the main axes; size axes are half this width
        axHeight            = 1-infoPanelHeight-rowSpacing-pad(3)-pad(4);                                   % height of the main axes and mean image
        axHeight2           = (1-infoPanelHeight-rowSpacing-pad(3)-pad(4)-colSpacing-colourAxisHeight)/2;   % height of colour and range plot axes
        infoPanelWidth      = (1-2*colSpacing-pad(1)-pad(2))/3;                                             % width of info panels

        %% extract and adjust font sizes
        axFS = round(p.axesFontsize*p.corrFac);

        %% create axes
        stdoAx  = {'Parent', h.fh, 'Units', 'normalized', 'fontsize', axFS};              % standard options for each axes element
        h.ahMeanImage   = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+0*colSpacing+0*axWidth pad(3)+infoPanelHeight+rowSpacing axWidth/2 axHeight], 'tag', 'gui_ax1'); % axes for mean image
        h.ahMainPlot    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+1*colSpacing+.5*axWidth pad(3)+infoPanelHeight+rowSpacing axWidth axHeight], 'tag', 'gui_ax2'); % axes for intensity
        h.ahMainOverlay = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+1*colSpacing+.5*axWidth pad(3)+infoPanelHeight+rowSpacing axWidth axHeight], 'tag', 'gui_ax2i', 'visible', 'off'); % axes for overlay
        h.ahTicks       = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+1*colSpacing+.5*axWidth pad(3)+infoPanelHeight+rowSpacing axWidth axHeight], 'tag', 'gui_ax2ii', 'visible', 'off'); % axes for ticks
        h.ahColourPlot  = axes(stdoAx{:}, 'Position', [pad(1)+1.5*yAxisLabelWidth+2*colSpacing+1.5*axWidth+regionMarkerWidth pad(3)+infoPanelHeight+rowSpacing+axHeight2+colSpacing+colourAxisHeight axWidth/2 axHeight2], 'tag', 'gui_ax4'); % axes for colour
        h.ahRangePlot   = axes(stdoAx{:}, 'Position', [pad(1)+1.5*yAxisLabelWidth+2*colSpacing+1.5*axWidth+regionMarkerWidth pad(3)+infoPanelHeight+rowSpacing axWidth/2 axHeight2], 'tag', 'gui_ax3'); % axes for range
        h.ahInfo1       = axes(stdoAx{:}, 'Position', [pad(1)+0*colSpacing pad(3) infoPanelWidth infoPanelHeight], 'tag', 'gui_ax7'); % axes for elf logo
        h.ahTitle       = axes(stdoAx{:}, 'Position', [pad(1)+1*colSpacing+infoPanelWidth pad(3) infoPanelWidth infoPanelHeight], 'tag', 'gui_ax6'); % axes for elf logo
        h.ahInfo2       = axes(stdoAx{:}, 'Position', [pad(1)+2*colSpacing+2*infoPanelWidth pad(3) infoPanelWidth infoPanelHeight], 'tag', 'gui_ax8'); % axes for elf logo

        %% axes for reference labels
        switch p.radianceReferencesLocation
            case 'outside'
                h.ahReferenceLabels    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+3*colSpacing/2+.5*axWidth pad(3)+3/4*infoPanelHeight+rowSpacing axWidth pad(4)/2], 'tag', 'gui_axbi'); % outside bottom
            case 'inside'
                h.ahReferenceLabels    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+3*colSpacing/2+.5*axWidth pad(3)+3/4*infoPanelHeight+rowSpacing+infoPanelHeight/2.5 axWidth pad(4)/2], 'tag', 'gui_axbi'); % inside bottom %TODO
            case 'top'
                h.ahReferenceLabels    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+3*colSpacing/2+.5*axWidth 1-pad(4)*0.75 axWidth pad(4)/2], 'tag', 'gui_axbi'); % outside top
            otherwise
                warning('Invalid value for PLOT_RADIANCE_REFERENCES_LOCATION: %s. Must be ''inside'', ''outside'' or ''top''', p.radianceReferencesLocation)
                h.ahReferenceLabels    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+3*colSpacing/2+.5*axWidth 1-pad(4)*0.75 axWidth pad(4)/2], 'tag', 'gui_axbi'); % outside top
        end

        %% Buttons to switch range indicators for different colour channels
        stdoB = {'Parent', h.fh, 'Units', 'normalized', 'Style', 'togglebutton', 'backgroundcolor', [.8 .8 .8], ...
            'fontweight', 'bold', 'fontsize', axFS, 'callback', @elf_callbacks_elfgui};     % standard options for each button
        x = pad(1)+yAxisLabelWidth+3*colSpacing/2+0.5*axWidth;
        y = 1-pad(4)-0.03;
        uicontrol(stdoB{:}, 'Position', [x+0.01 y .04 .02], 'tag', 'intfig_gui_BW', 'String', 'W', 'foregroundcolor', p.intChannelColours{4}, 'Value', 1);
        uicontrol(stdoB{:}, 'Position', [x+0.05 y .02 .02], 'tag', 'intfig_gui_R',  'String', 'R', 'foregroundcolor', p.intChannelColours{1}, 'Value', 0);
        uicontrol(stdoB{:}, 'Position', [x+0.07 y .02 .02], 'tag', 'intfig_gui_G',  'String', 'G', 'foregroundcolor', p.intChannelColours{2}, 'Value', 0);
        uicontrol(stdoB{:}, 'Position', [x+0.09 y .02 .02], 'tag', 'intfig_gui_B',  'String', 'B', 'foregroundcolor', p.intChannelColours{3}, 'Value', 0);

    case 0.1
        % older version, as published in Nilsson&Smolka 2020
        %% parameters
        [h.fh, p.corrFac]  = elf_support_formatA4l(35); clf;
        set(h.fh, 'Name', 'Environmental Light Field');

        % extract some values from p
        pad                 = p.padding;            % [L R B T]
        colSpacing          = p.columnSpacing;      % x-gap between main axes
        regionMarkerWidth   = p.regionMarkerWidth;  % width of the black bar marking elevation regions
        colourAxisHeight    = p.colourAxisHeight;   % height reserved for the colour plot x-axis label
        yAxisLabelWidth     = p.yAxisLabelWidth;    % width of y-axes label
        infoPanelHeight     = p.infoPanelHeight;    % height of the bottom panel
        rowSpacing          = p.rowSpacing;         % gap above bottom panel

        % calculate axes sizing
        axWidth             = (1-2*colSpacing-2*regionMarkerWidth-2*yAxisLabelWidth-pad(1)-pad(2))/2;       % width of the main axes; size axes are half this width
        axHeight            = 1-infoPanelHeight-rowSpacing-pad(3)-pad(4);                                   % height of the main axes and mean image
        axHeight2           = (1-infoPanelHeight-rowSpacing-pad(3)-pad(4)-colSpacing-colourAxisHeight)/2;   % height of colour and range plot axes
        infoPanelWidth      = (1-2*colSpacing-pad(1)-pad(2))/3;                                             % width of info panels

        %% extract and adjust font sizes
        axFS = round(p.axesFontsize*p.corrFac);

        %% create axes
        stdoAx  = {'Parent', h.fh, 'Units', 'normalized', 'fontsize', axFS};              % standard options for each axes element
        h.ahMeanImage   = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+0*colSpacing+0*axWidth pad(3)+infoPanelHeight+rowSpacing axWidth/2 axHeight], 'tag', 'gui_ax1'); % axes for mean image
        h.ahMainPlot    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+1*colSpacing+.5*axWidth pad(3)+infoPanelHeight+rowSpacing axWidth axHeight], 'tag', 'gui_ax2'); % axes for intensity
        h.ahMainOverlay = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+1*colSpacing+.5*axWidth pad(3)+infoPanelHeight+rowSpacing axWidth axHeight], 'tag', 'gui_ax2i', 'visible', 'off'); % axes for overlay
        h.ahTicks       = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+1*colSpacing+.5*axWidth pad(3)+infoPanelHeight+rowSpacing axWidth axHeight], 'tag', 'gui_ax2ii', 'visible', 'off'); % axes for ticks
        h.ahColourPlot  = axes(stdoAx{:}, 'Position', [pad(1)+1.5*yAxisLabelWidth+2*colSpacing+1.5*axWidth+regionMarkerWidth pad(3)+infoPanelHeight+rowSpacing+axHeight2+colSpacing+colourAxisHeight axWidth/2 axHeight2], 'tag', 'gui_ax4'); % axes for colour
        h.ahRangePlot   = axes(stdoAx{:}, 'Position', [pad(1)+1.5*yAxisLabelWidth+2*colSpacing+1.5*axWidth+regionMarkerWidth pad(3)+infoPanelHeight+rowSpacing axWidth/2 axHeight2], 'tag', 'gui_ax3'); % axes for range
        h.ahInfo1       = axes(stdoAx{:}, 'Position', [pad(1)+0*colSpacing pad(3) infoPanelWidth infoPanelHeight], 'tag', 'gui_ax7'); % axes for elf logo
        h.ahTitle       = axes(stdoAx{:}, 'Position', [pad(1)+1*colSpacing+infoPanelWidth pad(3) infoPanelWidth infoPanelHeight], 'tag', 'gui_ax6'); % axes for elf logo
        h.ahInfo2       = axes(stdoAx{:}, 'Position', [pad(1)+2*colSpacing+2*infoPanelWidth pad(3) infoPanelWidth infoPanelHeight], 'tag', 'gui_ax8'); % axes for elf logo

        %% axes for reference labels
        switch p.radianceReferencesLocation
            case 'outside'
                h.ahReferenceLabels    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+3*colSpacing/2+.5*axWidth pad(3)+3/4*infoPanelHeight+rowSpacing axWidth pad(4)/2], 'tag', 'gui_axbi'); % outside bottom
            case 'inside'
                h.ahReferenceLabels    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+3*colSpacing/2+.5*axWidth pad(3)+3/4*infoPanelHeight+rowSpacing+infoPanelHeight/2.5 axWidth pad(4)/2], 'tag', 'gui_axbi'); % inside bottom %TODO
            case 'top'
                h.ahReferenceLabels    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+3*colSpacing/2+.5*axWidth 1-pad(4)*0.75 axWidth pad(4)/2], 'tag', 'gui_axbi'); % outside top
            otherwise
                warning('Invalid value for PLOT_RADIANCE_REFERENCES_LOCATION: %s. Must be ''inside'', ''outside'' or ''top''', p.radianceReferencesLocation)
                h.ahReferenceLabels    = axes(stdoAx{:}, 'Position', [pad(1)+yAxisLabelWidth+3*colSpacing/2+.5*axWidth 1-pad(4)*0.75 axWidth pad(4)/2], 'tag', 'gui_axbi'); % outside top
        end

        %% Buttons to switch range indicators for different colour channels
        stdoB = {'Parent', h.fh, 'Units', 'normalized', 'Style', 'togglebutton', 'backgroundcolor', [.8 .8 .8], ...
            'fontweight', 'bold', 'fontsize', axFS, 'callback', @elf_callbacks_elfgui};     % standard options for each button
        x = pad(1)+yAxisLabelWidth+3*colSpacing/2+0.5*axWidth;
        y = 1-pad(4)-0.03;
        uicontrol(stdoB{:}, 'Position', [x+0.01 y .04 .02], 'tag', 'intfig_gui_BW', 'String', 'W', 'foregroundcolor', p.intChannelColours{4}, 'Value', 1);
        uicontrol(stdoB{:}, 'Position', [x+0.05 y .02 .02], 'tag', 'intfig_gui_R',  'String', 'R', 'foregroundcolor', p.intChannelColours{1}, 'Value', 0);
        uicontrol(stdoB{:}, 'Position', [x+0.07 y .02 .02], 'tag', 'intfig_gui_G',  'String', 'G', 'foregroundcolor', p.intChannelColours{2}, 'Value', 0);
        uicontrol(stdoB{:}, 'Position', [x+0.09 y .02 .02], 'tag', 'intfig_gui_B',  'String', 'B', 'foregroundcolor', p.intChannelColours{3}, 'Value', 0);

    otherwise
        error('Unknown .env file version');
end