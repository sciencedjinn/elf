function elf_plot_info(h, infoSum, name, nScenes, p)
    % plots the info fields in the ELF main plot

    elfText   = {'\makebox[4in][c]{\fontsize{60}{40}\textbf{E}\fontsize{15}{40}\textbf{nvironmental} \fontsize{60}{40}\textbf{L}\fontsize{15}{40}\textbf{ight} \fontsize{60}{40}\textbf{F}\fontsize{15}{40}\textbf{ield}}'};
    nExposuresPerScene = length(infoSum.DateTimeOriginal)/nScenes;
    if isfield(infoSum, 'blackLevels')
        if ~isempty(infoSum.blackWarnings)
            if ismember('No calibration exists for this camera', infoSum.blackWarnings)
                infoText1 = {sprintf('n = %d scenes, %d exp. each, black = %.0f-%.0f, {{\\color{red}UNCALIBRATED!}}', nScenes, nExposuresPerScene, min(infoSum.blackLevels(:)), max(infoSum.blackLevels(:)))};
                opts = {'FontWeight',  'bold', 'FontSize', 40, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', 'Color', [1 .8 .8], 'Rotation', 45};
                text(0.5, 0, 'UNCALIBRATED', 'parent', h.ahMainOverlay, opts{:});
                text(1, 0, 'UNCALIBRATED', 'parent', h.ahColourPlot, opts{:});
                text(0, 0, 'UNCALIBRATED', 'parent', h.ahRangePlot, opts{:});
            else
                infoText1 = {sprintf('n = %d scenes, %d exp. each, black = %.0f-%.0f, {{\\color{red}%d WARNING(S)!}}', nScenes, nExposuresPerScene, min(infoSum.blackLevels(:)), max(infoSum.blackLevels(:)), length(infoSum.blackWarnings))};
            end
        else
            infoText1 = {sprintf('n = %d scenes, %d exp. each, black = %.0f-%.0f', nScenes, nExposuresPerScene, min(infoSum.blackLevels(:)), max(infoSum.blackLevels(:)))};
        end
    else
        infoText1 = {sprintf('n = %d scenes, %d exp. each', nScenes, nExposuresPerScene)};
    end
    datefmt   = 'yyyy-mm-dd HH:MM';
    infoText2 = {sprintf('%s to', datestr(min(infoSum.DateTimeOriginal), datefmt)), sprintf('%s', datestr(max(infoSum.DateTimeOriginal), datefmt))};

    fs = round(p.infoFontsize*p.corrFac);
    stdo = {'HorizontalAlignment', 'Center', 'FontSize', fs};

    % central: ELF name
    if p.infoShowElfTitle
        text(0, 0, elfText,   stdo{:}, 'Parent', h.ahTitle, 'Interpreter', 'latex');
        axis(h.ahTitle, [-.1 .1 -.5 .5])
        set(h.ahTitle, 'Color', 'none')
    end
    axis(h.ahTitle, 'off')

    % left: data set info
    if p.infoShowNameAndStats
        text(0, 0, name, stdo{:}, 'Parent', h.ahInfo1, 'Interpreter', 'none', 'verticalalignment', 'bottom');
        text(0, 0, infoText1, stdo{:}, 'Parent', h.ahInfo1, 'Interpreter', 'tex', 'verticalalignment', 'top');
        axis(h.ahInfo1, [-.5 .5 -.5 .5])
        set(h.ahInfo1, 'Color', 'none')
    end
    axis(h.ahInfo1, 'off')

    % right: time/date info
    if p.infoShowTimeAndDate
        text(0, 0, infoText2, stdo{:}, 'Parent', h.ahInfo2);
        axis(h.ahInfo2, [-.5 .5 -.5 .5])
        set(h.ahInfo2, 'Color', 'none')
    end
    axis(h.ahInfo2, 'off')
end
