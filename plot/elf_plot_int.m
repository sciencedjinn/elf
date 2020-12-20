function elf_plot_int(para, d, d2, ah1, ah2, ah2b, ah3, ah4, ahb, ahbi, fignum)
%
%
%
%
%

%% define some variables
cols          = para.plot.intchannelcolours; % standard rgb colours for the four channels R, G, B, BW
reflevels     = para.plot.intreflevels; % These are the reference light levels for starlight, moonlight, mid dusk, overcast, sunlight %FIXME
xlab          = {'Spectral photon radiance', '(log_{10} photons m^{-2} s^{-1} sr^{-1} nm^{-1})'}; % x-axis label
nch           = size(d.means, 1);
yy            = d2.region_meanele(:)';

%% prepare plots
hold(ah1, 'on');
hold(ah2, 'on');
hold(ahb, 'on');
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
    fill([imin fliplr(imax)], [yy fliplr(yy)], [.9 .9 .9] + 0.1*cols{ch}, stdo{:}, 'EdgeColor', 'none', 'Clipping', 'on', 'tag', sprintf('fig%d_plot_ch%d', fignum, ch));
    fill([iss1 fliplr(iss2)], [yy fliplr(yy)], [.8 .8 .8] + 0.2*cols{ch}, stdo{:}, 'EdgeColor', 'none', 'Clipping', 'on', 'tag', sprintf('fig%d_plot_ch%d', fignum, ch));
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
    line(imean, yy,    'parent', ah1, 'color', cols{ch}, 'linewidth', 2,   'tag', sprintf('plot_mean_ch%d', ch));
end

%% add grids, labels, etc.
plot(ah1, [reflevels; reflevels], [-90 -90 -90 -90 -90; 90 90 90 90 90], 'k--', 'tag', 'ax1reflevels');

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
%set(ah1, 'XTickLabel', num2str(log10(get(ah1, 'XTick'))'), 'fontsize', 8);

axlims_2b = [c-1.5 c+1.5 -90 90];
axis(ah2b, axlims_2b);
set(ah2b, 'YTick', [], 'XTick', floor(c-1.5):ceil(c+1.5));
set(ah2b, 'Visible', 'on', 'Box', 'on', 'XMinorTick', 'on', 'layer', 'top', 'color', 'none', 'fontsize', 8);    
xlabel(ah2b, xlab, 'fontweight', 'bold', 'fontsize', 9);

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
    set(ah3, 'XScale', 'log', 'YTick', -90:30:90, 'box', 'on', 'fontsize', 8);
    xlabel(ah3, 'Relative colour', 'fontweight', 'bold', 'fontsize', 9);
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
    set(ah4, 'YTick', -90:30:90, 'box', 'on', 'fontsize', 8);
    xlabel(ah4, 'log_{10} Relative intensity range', 'fontweight', 'bold', 'fontsize', 9);
    xlims = xlim(ah4);

    % plot horizontal grid on invisible, transparent top axes ah2
%     plot(ah4, [0.001 1000;0.001 1000;0.001 1000;0.001 1000;0.001 1000]', [60 60;30 30;0 0;-30 -30;-60 -60]', 'k:');
%     plot(ah4, [0.001 1000;0.001 1000]', [-10 -10;10 10]', 'k--');
%     plot(ah4, [.01 .01;.1 .1;1 1;10 10;100 100]', [-90 90;-90 90;-90 90;-90 90;-90 90]', 'k:');
    plot(ah4, [-3 3;-3 3;-3 3;-3 3;-3 3]', [60 60;30 30;0 0;-30 -30;-60 -60]', 'k:');
    plot(ah4, [-3 3;-3 3]', [-10 -10;10 10]', 'k--');
    plot(ah4, [-2 -2;-1 -1;0 0;1 1;2 2]', [-90 90;-90 90;-90 90;-90 90;-90 90]', 'k:');

    axis(ah4, [-2 2 -90 90]);
    if xlims(1)<-2 || xlims(2)>2
        axis(ah4, [-3 3 -90 90]);
    end
%     axis(ah4, [xlims -90 90]);

    % stdo = {'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle', 'FontWeight', 'bold', 'Color', 'w', 'parent', ah2}; % standard options
    % text(1.01, -50, 'D', stdo{:});
    % text(1.01,   0, 'H', stdo{:});
    % text(1.01,  50, 'U', stdo{:});
    % 
    % axis(ah2, [0 1.02 -90 90], 'off');
    % set(ah2, 'Layer', 'top', 'color', 'none');
end

%% plot whole image statistics into axb
plotsmallplot = false;
if plotsmallplot
    axes(ahb); hold on;
    if strcmp(para.plot.inttotalmeantype, 'hist')
        for ch = 1:nch
            temph = bar(ahb, d2.bins(2:end-1), d2.hist(2:end-1, ch)/max(d2.hist(:, ch)), 'histc'); %remove the -inf and inf segments
            set(temph, 'facecolor', [.8 .8 .8] + 0.2*cols{ch}, 'tag', sprintf('fig%d_plot_ch%d', fignum, ch), 'EdgeColor', 'none');
        end
        delete(findall(ahb,'marker','*')); %remove the stars at bin borders that Matlab inserts for some obscure reason

        % still plot all medians, just in case
        for ch = 1:nch
            line([d2.median(ch) d2.median(ch)], [0 1], 'color', cols{ch}, 'linewidth', 2, 'tag', sprintf('plot_median_ch%d', ch));
        end

        % also plot the 95% range for the white channel %%TODO: This should be done for all channels and switched appropriately
        line([d2.percmin(end) d2.percmin(end)], [0 1], 'color', 'k', 'linewidth', 2, 'linestyle', ':');
        line([d2.percmax(end) d2.percmax(end)], [0 1], 'color', 'k', 'linewidth', 2, 'linestyle', ':');
        tDR = log10(d2.percmax(end)) - log10(d2.percmin(end));
        text(axlims(1), 0.7, sprintf('  DR_{tot}: %.2f', tDR), 'fontweight', 'bold', 'fontsize', 8);

        % also calculate average elevation dynrange
        eDR = median(log10(d.percmax(4, :))-log10(d.percmin(4, :)));
        text(axlims(1), 0.3, sprintf('  DR_{med}: %.2f', eDR), 'fontweight', 'bold', 'fontsize', 8);

    else
        switch para.plot.inttotalmeantype
            case 'mean'
                totmean = d2.mean(end);
                totmax  = d2.max(end);
                totmin  = d2.min(end);
                totss   = d2.std(end);
                totss1  = totmean-totss;
                totss2  = totmean+totss;
                alltotmean = d2.mean;
            case 'median'
                totmean = d2.median(end);
                totmax  = d2.percmax(end);
                totmin  = d2.percmin(end);
                totss1  = d2.perc25(end);
                totss2  = d2.perc75(end);
                alltotmean = d2.median;
        end

        fill([totmin totmin totmax totmax], [0 1 1 0], [.9 .9 .9], 'EdgeColor', 'none');
        fill([totss1 totss1 totss2 totss2], [0 1 1 0], [.8 .8 .8], 'EdgeColor', 'none');
        plot([totmin totmin],[0 1],'k:');
        plot([totmax totmax],[0 1],'k:');
        plot([totss1 totss1],[0 1],'k');
        plot([totss2 totss2],[0 1],'k');
        plot([totmean totmean],[0 1],'k', 'linewidth', 2);

        line([alltotmean(1) alltotmean(1)], [0 1], 'color', cols{1}, 'linewidth', 2);
        line([alltotmean(2) alltotmean(2)], [0 1], 'color', cols{2}, 'linewidth', 2);
        line([alltotmean(3) alltotmean(3)], [0 1], 'color', cols{3}, 'linewidth', 2);
    end

    % plot ref levels
    plot(ahb, [reflevels; reflevels], [0 0 0 0 0; 1 1 1 1 1], 'k--');

    axis(ahb, [axlims(1:2) 0 1]);
    set(ahb, 'XScale', 'log', 'box', 'on', 'XTick', [], 'YTick', [], 'Layer', 'top');
end

%% plot ref level names in invisible axes ah4
stdo = {'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle', 'FontWeight', 'bold', 'Color', 'k', 'Clipping', 'on', 'parent', ahbi}; % standard options
for i = 1:length(reflevels)
    text(reflevels(i), 0.5, para.plot.intrefnames{i}, stdo{:});
end

axis(ahbi, [axlims(1:2) 0 1], 'off');
set(ahbi, 'XScale', 'log');

%% Reset warnings
warning(s)








