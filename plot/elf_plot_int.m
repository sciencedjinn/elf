function elf_plot_int(para, d, d2, ah1, ah2, ah2b, ah3, ah4, ahbi, fignum)
%
%
%
%
%

%% define some variables
cols          = para.plot.intChannelColours;        % standard rgb colours for the four channels R, G, B, BW
lws           = para.plot.intChannelLinewidths;     % linewidths for the four channels R, G, B, BW
reflevels     = para.plot.radianceReferenceLevels; % These are the reference light levels for starlight, moonlight, mid dusk, overcast, sunlight %FIXME
xlab          = {'spectral photon radiance (lit)', '(log_{10} photons m^{-2} s^{-1} sr^{-1} nm^{-1})'}; % x-axis label
nch           = size(d.means, 1);
yy            = d2.region_meanele(:)';

%% prepare plots
hold(ah1, 'on');
hold(ah2, 'on');
if ~isempty(ah3), hold(ah3, 'on'); end
if ~isempty(ah4), hold(ah4, 'on'); end

%% Deactivate warnings
s = warning('off', 'MATLAB:plot:IgnoreImaginaryXYPart');
% TODO: When this warning occurs, it indicates saturated pixels. A separate warning should be issued.

%% ax2: for each channel, extract and plot the percentiles
for ch = 1:nch
    switch para.plot.intmeantype
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
    
    % plot all invisible (they will later be made visible in elf_plot_int_setvis
    stdo = {'parent', ah1, 'Visible', 'off'};
    fill([imin fliplr(imax)], [yy fliplr(yy)], para.plot.perc50Shading(:)' + (1-para.plot.perc50Shading(:)').*cols{ch}(:)', stdo{:}, 'EdgeColor', 'none', 'Clipping', 'on', 'tag', sprintf('fig%d_plot_ch%d', fignum, ch));
    fill([iss1 fliplr(iss2)], [yy fliplr(yy)], para.plot.perc95Shading(:)' + (1-para.plot.perc95Shading(:)').*cols{ch}(:)', stdo{:}, 'EdgeColor', 'none', 'Clipping', 'on', 'tag', sprintf('fig%d_plot_ch%d', fignum, ch));
    line(imin, yy,     stdo{:}, 'color', cols{ch}, 'linestyle', ':', 'tag', sprintf('fig%d_plot_ch%d', fignum, ch));
    line(imax, yy,     stdo{:}, 'color', cols{ch}, 'linestyle', ':', 'tag', sprintf('fig%d_plot_ch%d', fignum, ch));
    line(iss1, yy, stdo{:}, 'color', cols{ch}, 'linestyle', '-', 'tag', sprintf('fig%d_plot_ch%d', fignum, ch));
    line(iss2, yy, stdo{:}, 'color', cols{ch}, 'linestyle', '-', 'tag', sprintf('fig%d_plot_ch%d', fignum, ch));
end

%% for each channel, plots the means
for ch = 1:nch
    switch para.plot.intmeantype
        case 'mean'
            imean = d.means(ch,:);
        case 'median'
            imean = d.median(ch,:);
    end
    
    % mean is always on
    line(imean, yy,    'parent', ah1, 'color', cols{ch}, 'linewidth', lws{ch},   'tag', sprintf('plot_mean_ch%d', ch));
end

%% add grids, labels, etc.
plot(ah1, [reflevels(:)'; reflevels(:)'], [-90 -90 -90 -90 -90; 90 90 90 90 90], 'k--', 'tag', 'ax1reflevels');

% set axes and labels
% calculate good axis limits

cmin = log10(min(imean(imean>0)));
cmax = log10(max(imean));
c = mean([cmin cmax]); % Use the log mean of the min and max of the black (last channel) me(di)an curve as x-centre

% c = d2.median(end); % total mean should be in axes centre
axlims = [10^(c-1.5) 10^(c+1.5) -90 90]; % set to a default width of 3 log units
% save centre in gui
set(findobj('tag', 'gui_posslider'), 'UserData', log10(c));

axis(ah1, axlims);
set(ah1, 'XScale', 'log', 'YTick', [], 'XTick', []);
%set(ah1, 'XTick', logspace(floor(c-1.5), ceil(c+1.5), 41));     % set ticks to be linear
%set(ah1, 'XTickLabel', num2str(log10(get(ah1, 'XTick'))'));

axlims_2b = [c-1.5 c+1.5 -90 90];
axis(ah2b, axlims_2b);
set(ah2b, 'YTick', [], 'XTick', floor(c-1.5):ceil(c+1.5));
set(ah2b, 'Visible', 'on', 'Box', 'on', 'XMinorTick', 'on', 'layer', 'top', 'color', 'none');    
xlabel(ah2b, xlab, 'fontweight', 'bold');

%% plot horizontal grid on invisible, transparent top axes ah2
plot(ah2, [0 1;0 1;0 1;0 1;0 1]', [60 60;30 30;0 0;-30 -30;-60 -60]', 'k:');
plot(ah2, [0 1;0 1]', [-10 -10;10 10]', 'k--');
plot(ah2, [1.01 1.01; 1.01 1.01; 1.01 1.01]', [-89.8 -10.5; -9.5 9.5; 10.5 89.5]', 'k', 'LineWidth', 10);

stdo = {'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle', 'FontWeight', 'bold', 'Color', 'w', 'parent', ah2}; % standard options
text(1.01, -50, 'D', stdo{:});
text(1.01,   0, 'H', stdo{:});
text(1.01,  50, 'U', stdo{:});

axis(ah2, [0 1.02 -90 90], 'off');
set(ah2, 'Layer', 'top', 'color', 'none');

%% ax3: Spectral band plot; plot RGB normalised to W
if ~isempty(ah3)
    for ch = 1:nch-1
        switch para.plot.intmeantype
            case 'mean'
                imean = d.means(ch, :) ./ d.means(end, :);
            case 'median'
                imean = d.median(ch, :) ./ d.median(end, :);
        end
        line(imean, yy, 'parent', ah3, 'color', cols{ch}, 'linewidth', 2, 'tag', sprintf('plot_mean_ch%d', ch));
    end

    % calculate good axis limits
    set(ah3, 'XScale', 'log', 'YTick', -90:30:90, 'box', 'on');
    xlabel(ah3, 'relative colour', 'fontweight', 'bold');
    xlims = xlim(ah3);

    % plot horizontal grid on invisible, transparent top axes ah2
    plot(ah3, [0.001 1000;0.001 1000;0.001 1000;0.001 1000;0.001 1000]', [60 60;30 30;0 0;-30 -30;-60 -60]', 'k:');
    plot(ah3, [0.001 1000;0.001 1000]', [-10 -10;10 10]', 'k--');
    plot(ah3, [1 1]', [-90 90]', 'k:');
    axis(ah3, [0.5 1.5 -90 90]);
    
    if xlims(1)<0.5 || xlims(2)>1.5
        axis(ah3, [0.25 2 -90 90]); set(ah3, 'XTick', [0.25 0.5 1 2]);
    end
    if xlims(1)<0.25 || xlims(2)>2
        axis(ah3, [0.1 3 -90 90]); set(ah3, 'XTick', [0.1 0.5 1 2 3]);
    end
    
    % stdo = {'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle', 'FontWeight', 'bold', 'Color', 'w', 'parent', ah2}; % standard options
    % text(1.01, -50, 'D', stdo{:});
    % text(1.01,   0, 'H', stdo{:});
    % text(1.01,  50, 'U', stdo{:});
    % 
    % axis(ah2, [0 1.02 -90 90], 'off');
    % set(ah2, 'Layer', 'top', 'color', 'none');
end

%% ax4: Contrast plot; plot ranges normalised to W
if ~isempty(ah4) 
    % for each channel, extract and plot the percentiles
    for ch = 1:nch
        switch para.plot.intmeantype
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

        % plot
        stdo = {'parent', ah4, 'linewidth', 2};
        line(log10(imin ./ imean), yy, stdo{:}, 'color', cols{ch}, 'linestyle', ':');
        line(log10(imax ./ imean), yy, stdo{:}, 'color', cols{ch}, 'linestyle', ':');
        line(log10(iss1 ./ imean), yy, stdo{:}, 'color', cols{ch}, 'linestyle', '-');
        line(log10(iss2 ./ imean), yy, stdo{:}, 'color', cols{ch}, 'linestyle', '-');
    end

    % calculate good axis limits
    set(ah4, 'YTick', -90:30:90, 'box', 'on');
    xlabel(ah4, 'log_{10} intensity range', 'fontweight', 'bold');
    xlims = xlim(ah4);

    % plot horizontal grid on invisible, transparent top axes ah2
    plot(ah4, [-3 3;-3 3;-3 3;-3 3;-3 3]', [60 60;30 30;0 0;-30 -30;-60 -60]', 'k:');
    plot(ah4, [-3 3;-3 3]', [-10 -10;10 10]', 'k--');
    plot(ah4, [-2 -2;-1 -1;0 0;1 1;2 2]', [-90 90;-90 90;-90 90;-90 90;-90 90]', 'k:');

    axis(ah4, [-2 2 -90 90]);
    if xlims(1)<-2 || xlims(2)>2
        axis(ah4, [-3 3 -90 90]);
    end
end

%% plot ref level names in invisible axes ah4
stdo = {'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle', 'FontSize', para.plot.axesFontsize, 'FontWeight', 'bold', 'FontAngle', 'italic', 'Color', 'k', 'Clipping', 'on', 'parent', ahbi}; % standard options
for i = 1:length(reflevels)
    text(reflevels(i), 0.5, strrep(para.plot.radianceReferenceNames{i}, '_', ' '), stdo{:});
end
axis(ahbi, [axlims(1:2) 0 1], 'off');
set(ahbi, 'XScale', 'log');

%% Reset warnings
warning(s)








