function hi = elf_plot_image(im, I_info, h, proj, correct, plotPara)
% elf_plot_image(im, I_info, h, proj, correct, plotPara)
% displays an image of any given projection with appropriate axis labels
%
% im        - image to plot (can be of any image format)
% I_info    - info structure for the image (as created by elf_loadimage). If 
%             proj is anything but 'undefined', this has to include axes
%             information (usually added by elf_project_image).
% h         - graphics handle. This can be a uipanel or an axes handle.
%             If an axes handle is provided, only the image will be plotted.
%             If a uipanel handle is provided, axes will be created in the
%             panel. In either case, clicking on the image will provide a
%             magnified view in a new window.
% proj      - projection, can be
%               'undefined'/'default' (default) - just plot the image, no axes
%               'equirectangular' - plot azimuth and elevation on axes, and a 10 deg grid
%               'equisolid' - fisheye
%             Other values are supported, but might not be up-to-date / only applicable for certain modules. Use at your own risk.
% [correct] - logical, indicates whether im is a linear image that should be colour- and gamma-corrected (default: false)
%
% Returns hi, a handle to the image object.
% Input I_info and prj are saved to the image object's 'UserInfo' and 'Tag'
% properties, respectively.
% 
% Uses: Only in-built functions
% Toolboxes: IP

%% Check inputs, set defaults
if nargin<6, plotPara = []; end
if nargin<5, correct = false; end
if nargin<4 || isempty(proj)
    proj = 'undefined';
end
if nargin<3 || isempty(h)
    hf = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]); % open a screen-sized figure window
    h = uipanel('Parent', hf); % Create a maximum size panel
    try
        elf_support_maxfig
    end
end
if nargin<2
    I_info = []; %% TODO: Could add a simple guess here
end

%% Check or create axes
handletype = get(h, 'Type');
switch handletype
    case 'figure'
        ha = axes('parent', h);
    case 'axes'
        % an axes handle was provided. Clear the axes and display image.
        cla(h);
        ha = h;
    case 'uipanel'
        % a panel object was provided. Clear the panel and create axes.
        delete(get(h, 'Children'));
        switch proj
            case {'undefined', 'default', 'equisolid', 'zone', 'filt1', 'filt10'}
                % No axes needed
                ha = axes('Parent', h, 'Position', [0 0 1 1], 'Units', 'normalized');
            otherwise
                % leave room for axes
                ha = axes('Parent', h, 'OuterPosition', [0 0 1 1], 'Units', 'normalized'); % Position will be reset later
        end
    otherwise
        error('Unknown handle type.');
end

%% correct image
switch correct
    case 'bright'
        im = elf_io_correctdng(im, I_info, 'bright');
    case true
        im = elf_io_correctdng(im, I_info);
end

%% show image
switch proj
    case {'contrzone', 'contrzone_h'}
        hi = imagesc(im, 'Parent', ha);
    otherwise
        hi = image(im, 'Parent', ha);
        set(hi, 'ButtonDownFcn', @elf_callbacks_image, 'Tag', proj, 'UserData', I_info);
end

%% plot grid and adjust axes
if ~strcmpi(proj, 'squashed') %don't make equal axes for squashed images
    axis(ha, 'image', 'ij');
end
switch proj
    case {'undefined'}
        axis(ha, 'off');
        
    case {'equisolid', 'default'}
        % plot grid
        hold(ha, 'on');
        plot(ha, I_info.ori_grid_x, I_info.ori_grid_y, 'k:');
        
        % remove axis
        axis(ha, 'off');
        
    case 'squashed'
        % plot grid
        hold(ha, 'on');
        plot(ha, [-90 90 nan -90 90 nan -90 90 nan -90 90-nan -90 90 nan], ...
                 [-60 -60 nan -30 -30 nan 0 0 nan 30 30 nan 60 60], 'k:');
        
        % plot grid
        [ism,ypos] = ismember(-60:30:60, I_info.proj_ele); 
        yts = sort(ypos(ism)); % YTick sorted
        x = [0 size(im, 1) nan 0 size(im, 1) nan 0 size(im, 1) nan 0 size(im, 1) nan 0 size(im, 1)];
        y = [yts(1) yts(1) nan yts(2) yts(2) nan yts(3) yts(3) nan yts(4) yts(4) nan yts(5) yts(5)];
        plot(ha, x, y, 'k:');
        
        %calculate x-ticks and y-ticks
        [ism,ypos] = ismember(-90:90:90, I_info.proj_ele); 
        yts = sort(ypos(ism)); % YTick sorted
        set(ha, 'XTick', [], 'YTick', yts, 'YTickLabel', num2str(I_info.proj_ele(yts)'));

        % set labels and position
        ylabel(ha, 'elevation (\circ)');
        switch handletype
            case {'figure', 'uipanel'}
                b = get(ha, 'TightInset');
                set(ha, 'Position', [0+b(1) 0+b(2) 1-b(1)-b(3) 1-b(2)-b(4)]);
        end
        
    case 'equirectangular'
        % plot grid
        hold(ha, 'on');
        plot(ha, I_info.proj_grid_x, I_info.proj_grid_y, 'k:');
        
        %calculate x-ticks and y-ticks
        azi = I_info.proj_azi; % This information should have been added during projection
        ele = I_info.proj_ele; 
        [ism, xpos] = ismember(-90:30:90, azi); 
        xts = sort(xpos(ism)); % XTick sorted
        [ism, ypos] = ismember(-90:30:90, ele); 
        yts = sort(ypos(ism)); % YTick sorted
        set(ha, 'XTick', xts, 'XTickLabel', num2str(azi(xts)'), 'YTick', yts, 'YTickLabel', num2str(ele(yts)'));

        % set labels and position
        xlabel(ha, 'azimuth (\circ)');
        ylabel(ha, 'elevation (\circ)');
        switch handletype
            case {'figure', 'uipanel'}
                b = get(ha, 'TightInset');
                set(ha, 'Position', [0+b(1) 0+b(2) 1-b(1)-b(3) 1-b(2)-b(4)]);
        end
        
    case 'equirectangular_summary' 
        azi = I_info.proj_azi; % This information should have been added during projection
        ele = I_info.proj_ele; 

        % plot grid
        hold(ha, 'on');
        x = length(azi);
        [~, ypos] = ismember([60 60 30 30 0 0 -30 -30 -60 -60], ele); 
        plot(ha, [1 x;1 x;1 x;1 x;1 x]', reshape(ypos, [2 5]), 'k:');
        [~, ypos] = ismember([10 10 -10 -10], ele); 
        plot(ha, [1 x;1 x]', reshape(ypos, [2 2]), 'k--');
        
        % calculate x-ticks and y-ticks
        [ism, xpos] = ismember(-90:30:90, azi); 
        xts = sort(xpos(ism)); % XTick sorted
        [ism, ypos] = ismember(-90:30:90, ele); 
        yts = sort(ypos(ism)); % YTick sorted
        set(ha, 'XTick', [], 'XTickLabel', [], 'YTick', yts, 'YTickLabel', num2str(ele(yts)'));

        % set labels and position
        ylabel(ha, 'elevation (\circ)', 'fontweight', 'bold');
        switch handletype
            case {'figure', 'uipanel'}
                b = get(ha, 'TightInset');
                set(ha, 'Position', [0+b(1) 0+b(2) 1-b(1)-b(3) 1-b(2)-b(4)]);
        end

    case 'equirectangular_summary_squished' 
        azi = I_info.proj_azi; % This information should have been added during projection
        ele = I_info.proj_ele; 

        % plot grid
        hold(ha, 'on');
        x = length(azi);
        [~, ypos] = ismember([60 60 30 30 0 0 -30 -30 -60 -60], ele); 
        plot(ha, [1 x;1 x;1 x;1 x;1 x]', reshape(ypos, [2 5]), 'k:');
        if ~isempty(plotPara) && plotPara.showElevationZones
            [~, ypos] = ismember([10 10 -10 -10], ele); 
            plot(ha, [1 x;1 x]', reshape(ypos, [2 2]), 'k--');
        end
        
        % calculate x-ticks and y-ticks
        [ism, xpos] = ismember(-90:30:90, azi); 
        xts = sort(xpos(ism)); % XTick sorted
        [ism, ypos] = ismember(-90:30:90, ele); 
        yts = sort(ypos(ism)); % YTick sorted
        labelFS = round(plotPara.axesFontsize*plotPara.corrFac);
        set(ha, 'XTick', [], 'XTickLabel', [], 'YTick', yts, 'YTickLabel', num2str(ele(yts)'), 'fontsize', labelFS);

        % set labels and position
        ylabel(ha, 'elevation (\circ)', 'fontweight', 'bold');
        switch handletype
            case {'figure', 'uipanel'}
                b = get(ha, 'TightInset');
                set(ha, 'Position', [0+b(1) 0+b(2) 1-b(1)-b(3) 1-b(2)-b(4)]);
        end
        set(ha, 'DataAspectRatioMode', 'auto')

    case 'zone'
        % Display zones (hack!)
        hold(ha, 'on');
        plot([0 0 0 0;1802 1802 1802 1802], [401 801 1001 1401; 401 801 1001 1401], 'r--');
        axis(ha, 'off');
   case 'contrzone'
        % Display zones (hack!)
        hold(ha, 'on');
        plot([0 0 0 0;360 360 360 360], [81 161 201 281; 81 161 201 281], 'r--');
        colormap(gray);
        axis(ha, 'square', 'off');
        cb = colorbar;
        if verLessThan('matlab','8.4.0')
            % execute code for R2014a or earlier
            a = get(cb, 'ytick');
            set(cb, 'yticklabel', num2str(100*(1-a)'), 'ydir', 'reverse');
            ylabel(cb, 'Contrast (%)')
        else
            % execute code for R2014b or later
            a = get(cb, 'Ticks');
            set(cb, 'TickLabels', num2str(100*(1-a)'), 'Direction', 'reverse');
            cb.Label.String = 'Contrast (%)';
        end
   case 'contrzone_h'
        % Display zones (hack!)
        hold(ha, 'on');
        plot([0 0 0 0;1802 1802 1802 1802], [81 161 201 281; 81 161 201 281], 'r--');
        colormap(gray);
        axis(ha, 'square', 'off');
        colorbar;
        cb = colorbar;
        if verLessThan('matlab','8.4.0')
            % execute code for R2014a or earlier
            a = get(cb, 'ytick');
            set(cb, 'yticklabel', num2str(100*(1-a)'), 'ydir', 'reverse');
            ylabel(cb, 'Contrast (%)');
        else
            % execute code for R2014b or later
            a = get(cb, 'Ticks');
            set(cb, 'TickLabels', num2str(100*(1-a)'), 'Direction', 'reverse');
            cb.Label.String = 'Contrast (%)';
        end
    case 'filt1'
        % Display zones (hack!)
        hold(ha, 'on');
        plot([0 0 0 0;362 362 362 362], [81 161 201 281; 81 161 201 281], 'r--');
        axis(ha, 'off');
    case 'filt10'
        % Display zones (hack!)
        hold(ha, 'on');
        plot([0 0 0 0;38 38 38 38], [9 17 21 29; 9 17 21 29], 'r--');
        axis(ha, 'off');
    otherwise
        error('Unknown projection');
end
    



