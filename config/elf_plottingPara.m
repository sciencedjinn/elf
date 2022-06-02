function plotP = elf_plottingPara()

envPath = fullfile(fileparts(mfilename("fullpath")), '..', 'config');
d = DotEnv(envPath, '');

plotParameters = ...
    {'RED_CHANNEL_COLOUR',   'doublevector';
     'GREEN_CHANNEL_COLOUR', 'doublevector'; 
     'BLUE_CHANNEL_COLOUR',  'doublevector';
     'WHITE_CHANNEL_COLOUR', 'doublevector';
     'RED_CHANNEL_LINEWIDTH',   'double';
     'GREEN_CHANNEL_LINEWIDTH', 'double'; 
     'BLUE_CHANNEL_LINEWIDTH',  'double';
     'WHITE_CHANNEL_LINEWIDTH', 'double';
     'MAIN_RED_ACTIVE',   'logical';
     'MAIN_GREEN_ACTIVE',   'logical';
     'MAIN_BLUE_ACTIVE',   'logical';
     'MAIN_WHITE_ACTIVE',   'logical';
     'RANGE_RED_ACTIVE',   'logical';
     'RANGE_GREEN_ACTIVE',   'logical';
     'RANGE_BLUE_ACTIVE',   'logical';
     'RANGE_WHITE_ACTIVE',   'logical';
     'PERC50_SHADING', 'doublevector';
     'PERC95_SHADING', 'doublevector';
     'AXES_FONTSIZE', 'double';
     'SHOW_ELEVATION_ZONES', 'logical';
     'SHOW_RADIANCE_REFERENCES', 'logical';
     'RADIANCE_REFERENCES_LOCATION', 'char';
     'INFO_SHOW_NAME_AND_STATS', 'logical';
     'INFO_SHOW_TIME_AND_DATE', 'logical';
     'INFO_SHOW_ELF_TITLE', 'logical';
     'INFO_FONTSIZE', 'double';
     'RADIANCE_REFERENCE_LEVELS', 'doublevector';
     'RADIANCE_REFERENCE_NAMES', 'charvector';
     'PADDING', 'doublevector';
     'COLUMN_SPACING', 'double';
     'REGION_MARKER_WIDTH', 'double';
     'COLOUR_AXIS_HEIGHT', 'double';
     'Y_AXIS_LABEL_WIDTH', 'double';
     'INFO_PANEL_HEIGHT', 'double';
     'ROW_SPACING', 'double';
     'DEFAULT_RADIANCE_RANGE', 'double';
     'MAIN_X_LABEL_1', 'string';
     'MAIN_X_LABEL_2', 'string';
     'COLOUR_X_LABEL', 'string';
     'RANGE_X_LABEL', 'string';
     'COLOUR_Y_AXIS_LOCATION', 'string';
     'RANGE_SHOW_Y_TICKS', 'logical';
     'COLOUR_SHOW_Y_TICKS', 'logical';
     'GRID_TICKS', 'doublevector';
     'GRID_LINESTYLE', 'char';
     'GRID_LINEWIDTH', 'double';
     'GRID_COLOUR', 'doublevector'};

plotP = d.extractValues('PLOT', plotParameters);
plotP.mainChannelsActive = {plotP.mainRedActive, plotP.mainGreenActive, plotP.mainBlueActive, plotP.mainWhiteActive};
plotP.rangeChannelsActive = {plotP.rangeRedActive, plotP.rangeGreenActive, plotP.rangeBlueActive, plotP.rangeWhiteActive};
plotP.intChannelColours = {plotP.redChannelColour, plotP.greenChannelColour, plotP.blueChannelColour, plotP.whiteChannelColour};
plotP.intChannelLinewidths = [plotP.redChannelLinewidth, plotP.greenChannelLinewidth, plotP.blueChannelLinewidth, plotP.whiteChannelLinewidth];
plotP.version = str2double(d.Env.VERSION);


%%TODO
plotP.intmeantype       = 'median';  % determines type of statistics used for intensity plots; can be 'mean' (to plot min/mean-std/mean/mean+std/max) or 'median' (to plot 5th/25th/50th/75th/95th percentiles)
plotP.inttotalmeantype  = 'hist';    % determines type of statistics used for overall intensity plots; can be 'mean'/'median'/'hist'
plotP.datasetmeantype   = 'logmean'; % determines how scenes are averaged across a dataset; can be 'mean'/'median'/'logmean'
