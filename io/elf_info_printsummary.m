function elf_info_printsummary(infosum, fh)
% ELF_INFO_PRINTSUMMARY(infosum, fh)
% prints a summary of the image information structure infosum to the
% command line (default) or to the file given by filehandle fh
% 
% fh can also be an axes or uipanel handle
% Panel or axes should be at least 350 x 260 pixels!

%% check input
if nargin<2
    fh = 1; % print to standard output (command line)
end
% File identifier, specified as one of the following:
% A file identifier obtained from fopen.
% 1 for standard output (the screen).
% 2 for standard error.

if fh==1 || fh==2
    % standard out or standard error
    handletype = 'fileid';
elseif ishandle(fh)
    textbox = {}; % this variable will hold all text and later plot it into the axes
    handletype = get(fh, 'Type');
    switch handletype
        case 'axes'
            % an axes handle was provided. Clear the axes.
            cla(fh);
        case 'uipanel'
            % a panel object was provided. Clear the panel and create axes.
            delete(get(fh, 'Children'));
            % No axes needed
            fh = axes('Parent', fh, 'Position', [0 0 1 1], 'Units', 'normalized');
        otherwise
            error('Unknown handle type.');
    end
    clear sub_text;
else
    % must be a file identifier
    handletype = 'fileid';
end
    
    
%% next
    nested_disp(sprintf(''));
    nested_disp(sprintf('  Image properties summary:'));
    nested_disp(sprintf(''));
    nested_disp(sprintf('  Dimensions:        %d x %d', infosum.Width, infosum.Height));
    nested_disp(sprintf('  # of channels:     %d', infosum.SamplesPerPixel));
    nested_disp(sprintf('  Depth per channel: %d bit', infosum.bpc));
    nested_disp(sprintf('  Image format:      %s-%s', infosum.class{:}, infosum.Format{:}));
    nested_disp(sprintf('  Camera model:      %s', infosum.Model{:}));
if length(infosum.FNumber)>1
    nested_disp(sprintf('  F-stop:            f/%g to f/%g', min(infosum.FNumber), max(infosum.FNumber)));
else
    nested_disp(sprintf('  F-stop:            f/%g', infosum.FNumber));
end
if length(infosum.ExposureTime)>1
    nested_disp(sprintf('  Exposure time:     1/%.0f to 1/%.0f sec', 1/min(infosum.ExposureTime), 1/max(infosum.ExposureTime)));
else
    nested_disp(sprintf('  Exposure time:     1/%.0f sec', 1/infosum.ExposureTime)); 
end
if length(infosum.ISOSpeedRatings)>1
    nested_disp(sprintf('  ISO speed:         ISO-%d to ISO-%d', min(infosum.ISOSpeedRatings), max(infosum.ISOSpeedRatings)));
else
    nested_disp(sprintf('  ISO speed:         ISO-%d', infosum.ISOSpeedRatings));
end
if length(infosum.ExposureBiasValue)>1
    nested_disp(sprintf('  Exposure bias:     %+g to %+g steps', min(infosum.ExposureBiasValue), max(infosum.ExposureBiasValue)));
else
    nested_disp(sprintf('  \\bf\\color{red}Exposure bias:     %+g steps\\rm\\color{black}', infosum.ExposureBiasValue));
end
    nested_disp(sprintf('  Focal length:      %g mm', infosum.FocalLength));
if length(infosum.ExposureProgram)>1
    nested_disp(sprintf('  Exposure program:  %s', infosum.ExposureProgram{1}));
    for j = 2:length(infosum.ExposureProgram)
    nested_disp(sprintf('                     %s', infosum.ExposureProgram{j}));
    end
else
    nested_disp(sprintf('  Exposure program:  %s', infosum.ExposureProgram{1}));
end
    nested_disp(sprintf('  Original dates:    %s', datestr(min(infosum.DateTimeOriginal))));
    nested_disp(sprintf('                  to %s', datestr(max(infosum.DateTimeOriginal))));
    nested_disp(sprintf(''));

    nested_finish; % plot into axis and adjust axis limits


%% nested functions

    function nested_disp(str)
        % takes a string and displays it depending on the input handle type

        switch handletype
            case 'fileid'
                fprintf('%s\n', str);
            case {'axes', 'uipanel'}
                textbox{end+1} = str;
        end

    end %nested_disp

    function nested_finish
        switch handletype
            case 'fileid'

            case {'axes', 'uipanel'}
                text(0, 0.5, textbox, 'Parent', fh, 'FontName', 'FixedWidth');
                axis([0 1 0 1]);
                axis off;

        end
    end %nested_finish

end %main










