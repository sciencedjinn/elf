function elf_plot_int(h, d, d2, plotPara)
%
%
%
%
%

if plotPara.version==0.1
    elf_plot_int_v0p1(h, d, d2, plotPara);
    return
end

%% define some variables
cols          = plotPara.intChannelColours;                             % standard rgb colours for the four channels R, G, B, BW
lws           = round(plotPara.intChannelLinewidths*plotPara.corrFac);  % linewidths for the four channels R, G, B, BW
refLevels     = plotPara.radianceReferenceLevels;                       % These are the reference light levels for starlight, moonlight, mid dusk, overcast, sunlight %FIXME
xLabMain      = {plotPara.mainXLabel1, plotPara.mainXLabel2};           % x-axis label for main plot
xLabColour    = plotPara.colourXLabel;                                  % x-axis label for colour plot
xLabRange     = plotPara.rangeXLabel;                                   % x-axis label for range plot
nch           = size(d.means, 1);
yy            = d2.region_meanele(:)';

defWidth = plotPara.defaultRadianceRange;
zoneLineWidth = round(10*plotPara.corrFac * plotPara.axesFontsize/10);
labelFS = round(plotPara.axesFontsize*plotPara.corrFac);

%% prepare plots
hold(h.ahMainPlot, 'on');
hold(h.ahMainOverlay, 'on');
if ~isempty(h.ahColourPlot), hold(h.ahColourPlot, 'on'); end
if ~isempty(h.ahRangePlot), hold(h.ahRangePlot, 'on'); end

%% Deactivate warnings
s = warning('off', 'MATLAB:plot:IgnoreImaginaryXYPart');
% TODO: When this warning occurs, it indicates saturated pixels. A separate warning could be issued.



%% MAIN PLOT: for each channel, plots the means
for ch = 1:nch
    if plotPara.mainChannelsActive{ch}
        switch plotPara.intmeantype
            case 'mean'
                imean = d.means(ch,:);
            case 'median'
                imean = d.median(ch,:);
        end
        
        line(imean, yy, 'parent', h.ahMainPlot, 'color', cols{ch}, 'linewidth', lws(ch));
    end
end

%% MAIN PLOT: grids and elevation zones
% plot horizontal grid on invisible, transparent top axes ah2
gridX = [zeros(size(plotPara.gridTicks)) 1.02*ones(size(plotPara.gridTicks))]';
gridY = [plotPara.gridTicks plotPara.gridTicks]';
plot(h.ahMainOverlay, gridX, gridY, 'linestyle', plotPara.gridLinestyle, 'linewidth', plotPara.gridLinewidth, 'Color', plotPara.gridColour);

if plotPara.showElevationZones
    plot(h.ahMainOverlay, [0 1;0 1]', [-10 -10;10 10]', 'k--'); % dashed horizontal zone lines 
    plot(h.ahMainOverlay, [1.01 1.01; 1.01 1.01; 1.01 1.01]', [-89.8 -10.5; -9.5 9.5; 10.5 89.5]', 'k', 'LineWidth', zoneLineWidth); % thick black lines behind zone letters

    stdo = {'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle', 'FontWeight', 'bold', 'Color', 'w', 'parent', h.ahMainOverlay, 'fontsize', labelFS};
    text(1.01, -50, 'D', stdo{:});
    text(1.01,   0, 'H', stdo{:});
    text(1.01,  50, 'U', stdo{:});
end

axis(h.ahMainOverlay, [0 1.02 -90 90], 'off');
set(h.ahMainOverlay, 'Layer', 'top', 'color', 'none');

%% MAIN PLOT: axes limits and labels
% calculate good x-axis limits
if ~any(imean>0)
    warning('All radiance values are below 0. The image is severely underexposed!');
    axLims = axis(h.ahMainPlot);
else
    cmin = log10(min(imean(imean>0)));
    cmax = log10(max(imean));
    c = mean([cmin cmax]); % Use the log mean of the min and max of the black (last channel) me(di)an curve as x-centre
    
    axLims = [10^(c-defWidth/2) 10^(c+defWidth/2) -90 90]; % set to a default width of 3 log units
    
    axis(h.ahMainPlot, axLims);
    set(h.ahMainPlot, 'XScale', 'log');
    axLims2 = [c-defWidth/2 c+defWidth/2 -90 90];
    axis(h.ahTicks, axLims2);
    set(h.ahTicks, 'YTick', [], 'XTick', floor(c-defWidth/2):ceil(c+defWidth/2), ...
        'Visible', 'on', 'Box', 'on', 'XMinorTick', 'on', 'layer', 'top', 'color', 'none');    
end
set(h.ahMainPlot, 'YTick', [], 'XTick', []);
xlabel(h.ahTicks, xLabMain, 'fontweight', 'bold');

%% MAIN PLOT: radiance reference levels
if plotPara.showRadianceReferences
    plot(h.ahMainPlot, [refLevels(:)'; refLevels(:)'], [-90 -90 -90 -90 -90; 90 90 90 90 90], 'k--'); % vertical reference lines

    stdo = {'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle', 'FontSize', labelFS, ...
        'FontWeight', 'bold', 'FontAngle', 'italic', 'Color', 'k', 'Clipping', 'on', 'parent', h.ahReferenceLabels};
    for i = 1:length(refLevels)
        text(refLevels(i), 0.5, strrep(plotPara.radianceReferenceNames{i}, '_', ' '), stdo{:});
    end
    set(h.ahReferenceLabels, 'XScale', 'log');
end
axis(h.ahReferenceLabels, [axLims(1:2) 0 1], 'off');

%% COLOUR PLOT: Spectral band plot; plot RGB normalised to W
if ~isempty(h.ahColourPlot)
    for ch = 1:nch-1
        switch plotPara.intmeantype
            case 'mean'
                imean = d.means(ch, :) ./ d.means(end, :);
            case 'median'
                imean = d.median(ch, :) ./ d.median(end, :);
        end
        line(imean, yy, 'parent', h.ahColourPlot, 'color', cols{ch}, 'linewidth', lws(ch), 'tag', sprintf('plot_mean_ch%d', ch));
    end

    % calculate good axis limits
    if plotPara.colourShowYTicks, ytl = num2str((-90:30:90)'); else, ytl = ''; end
    set(h.ahColourPlot, 'YTick', -90:30:90, 'YTickLabel', ytl, 'box', 'on', 'YAxisLocation', plotPara.colourYAxisLocation);
    xlabel(h.ahColourPlot, xLabColour, 'fontweight', 'bold');
    xlims = xlim(h.ahColourPlot);

    % plot horizontal grid on invisible, transparent top axes ah2
    gridX = [0.001*ones(size(plotPara.gridTicks)) 1000*ones(size(plotPara.gridTicks))]';
    gridY = [plotPara.gridTicks plotPara.gridTicks]';
    plot(h.ahColourPlot, gridX, gridY, 'linestyle', plotPara.gridLinestyle, 'linewidth', plotPara.gridLinewidth, 'Color', plotPara.gridColour);

    if plotPara.showElevationZones
        plot(h.ahColourPlot, [0.001 1000;0.001 1000]', [-10 -10;10 10]', 'k--');
    end
    plot(h.ahColourPlot, [1 1]', [-90 90]', 'linestyle', plotPara.gridLinestyle, 'linewidth', plotPara.gridLinewidth, 'Color', plotPara.gridColour);
    axis(h.ahColourPlot, [0.5 1.5 -90 90]);
    
    if xlims(1)<0.5 || xlims(2)>1.5
        axis(h.ahColourPlot, [0.25 2 -90 90]); set(h.ahColourPlot, 'XTick', [0.25 0.5 1 2]);
    end
    if xlims(1)<0.25 || xlims(2)>2
        axis(h.ahColourPlot, [0.1 3 -90 90]); set(h.ahColourPlot, 'XTick', [0.1 0.5 1 2 3]);
    end
end

%% RANGE PLOT: Contrast plot; plot ranges normalised to W
if ~isempty(h.ahRangePlot) 
    % for the white channel, extract and plot the percentiles
    ch = 4;
    switch plotPara.intmeantype
        case 'mean'
            imean = d.means(ch,:);
            imax  = d.max(ch,:);
            imin  = d.min(ch,:);
            ss    = d.std(ch,:);
            iss1  = imean-ss;
            iss2  = imean+ss;
        case 'median'
            imean = d.median(ch,:);
            imax  = d.percmax(ch,:);
            imin  = d.percmin(ch,:);
            iss1  = d.perc25(ch,:);
            iss2  = d.perc75(ch,:);
    end
    imin_norm = log10(imin ./ imean);
    imax_norm = log10(imax ./ imean);
    iss1_norm = log10(iss1 ./ imean);
    iss2_norm = log10(iss2 ./ imean);

    % plot

    stdo = {'parent', h.ahRangePlot, 'EdgeColor', 'none', 'Clipping', 'on'};
    fill([imin_norm fliplr(imax_norm)], [yy fliplr(yy)], plotPara.perc50Shading(:)' + (1-plotPara.perc50Shading(:)').*cols{ch}(:)', stdo{:}); % shading for IQR
    fill([iss1_norm fliplr(iss2_norm)], [yy fliplr(yy)], plotPara.perc95Shading(:)' + (1-plotPara.perc95Shading(:)').*cols{ch}(:)', stdo{:}); % shading for 95%

    stdo2 = {'parent', h.ahRangePlot, 'Visible', 'on', 'color', cols{ch}, 'linewidth', lws(ch)};
    line([iss1_norm(:) iss2_norm(:)], [yy(:) yy(:)], stdo2{:}, 'linestyle', '-'); % line for IQR
    line([imin_norm(:) imax_norm(:)], [yy(:) yy(:)], stdo2{:}, 'linestyle', ':'); % line for 95%

    % calculate good axis limits
    if plotPara.rangeShowYTicks, ytl = num2str((-90:30:90)'); else, ytl = ''; end
    set(h.ahRangePlot, 'YTick', -90:30:90, 'YTickLabel', ytl, 'box', 'on');
    xlabel(h.ahRangePlot, xLabRange, 'fontweight', 'bold');
    xlims = xlim(h.ahRangePlot);

    % plot horizontal grid on invisible, transparent top axes ah2
    gridX = [-3*ones(size(plotPara.gridTicks)) 3*ones(size(plotPara.gridTicks))]';
    gridY = [plotPara.gridTicks plotPara.gridTicks]';
    plot(h.ahRangePlot, gridX, gridY, 'linestyle', plotPara.gridLinestyle, 'linewidth', plotPara.gridLinewidth, 'Color', plotPara.gridColour);

    if plotPara.showElevationZones
        plot(h.ahRangePlot, [-3 3;-3 3]', [-10 -10;10 10]', 'k--');
    end
    plot(h.ahRangePlot, [-2 -2;-1 -1;0 0;1 1;2 2]', [-90 90;-90 90;-90 90;-90 90;-90 90]', 'linestyle', plotPara.gridLinestyle, 'linewidth', plotPara.gridLinewidth, 'Color', plotPara.gridColour);

    axis(h.ahRangePlot, [-2 2 -90 90]);
    if xlims(1)<-2 || xlims(2)>2
        axis(h.ahRangePlot, [-3 3 -90 90]);
    end
end



%% Reset warnings
warning(s)

%% set visibility
elf_plot_int_setvis('intfig'); % sets visibility of RGB plot using graphics object tags








