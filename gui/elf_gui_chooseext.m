function outext = elf_gui_chooseext(foldername, showbutton)
% outext = elf_gui_chooseext(foldername)
% Prompts the user to choose an image file extension from all file types
% present in a folder
% 
% Uses: elf_info_collect, elf_info_summarise, elf_info_printsummary
% 
% See also elf_info_collect, elf_info_summarise, elf_info_printsummary.

if nargin < 2, showbutton = true; end

%% init
outext = ''; % initialise to empty in case the window is closed

%% find all extensions
allfiles   = elf_io_dir(foldername); %This includes subfolders
allexts    = arrayfun(@(x) nested_findext(x.name), allfiles, 'UniformOutput', false);
uniqueexts = unique(lower(allexts));
uniqueexts(strcmp('',uniqueexts)) = []; % remove empty strings

%% open a figure window
if length(uniqueexts) > 3
    fh = elf_support_formatA3(49);
else
    fh = elf_support_formatA4(49);
end
if showbutton
    set(fh, 'Name', 'Please select an image format');
end
   
%% for each unique extension, create a panel
stdo = {'Units', 'normalized', 'backgroundcolor', 'w'}; % standard option for all panels
if length(uniqueexts) > 3
    w = 1/2; 
    h = 1/3;
    for i = 1:3
        fp(i)   = uipanel(stdo{:}, 'Parent', fh, 'Position', [0 1-i*h w h], 'BorderWidth', 1);
    end
    for i = 1:3
        fp(i+3) = uipanel(stdo{:}, 'Parent', fh, 'Position', [w 1-i*h w h], 'BorderWidth', 1); 
    end
else
    w = 1; 
    h = 1/3;
    for i = 1:3
        fp(i)  = uipanel(stdo{:}, 'Parent', fh, 'Position', [0 1-i*h w h], 'BorderWidth', 1);
    end
end

%% for each unique extension, get an infosum
for extnum = length(uniqueexts):-1:1
    % first, find all filenames and image info. This will return valid 0 if this is not an image format.
    [info, validim] = elf_info_collect(foldername, uniqueexts{extnum}); %this contains exif information and filenames
    fname{extnum}   = info(min([2, length(info)])).Filename; % pick the second image, or the first, if no second exists
    fnum(extnum)    = length(info);
    if validim
        infosum(extnum) = elf_info_summarise(info);
        exifvalid = 1;
    end

%% display second image, and image properties
    sub1 = uipanel(stdo{:}, 'Parent', fp(extnum), 'Position', [0 .1 .5 .9],  'BorderWidth', 0);
    sub2 = uipanel(stdo{:}, 'Parent', fp(extnum), 'Position', [.5 .2 .5 .8], 'BorderWidth', 0);
    sub3 = uipanel(stdo{:}, 'Parent', fp(extnum), 'Position', [0 0 .5 .1],   'BorderWidth', 0);
    sub4 = uipanel(stdo{:}, 'Parent', fp(extnum), 'Position', [.5 0 .5 .2],  'BorderWidth', 0);
    
    if validim
        if exifvalid
            % i) load second image and plot it
            elf_plot_image(imread(fname{extnum}), infosum(extnum), sub1); % for raw files, this loads the thumbnail, not the raw image itself
            % ii) print summary of image stats
            elf_info_printsummary(infosum(extnum), sub2);
        else
            % i) load second image and plot it
            elf_plot_image(imread(fname{extnum}), [], sub1); % for raw files, this loads the thumbnail, not the raw image itself
            % ii) print summary of image stats
            uicontrol(stdo{:}, 'Parent', sub2, 'Style', 'text', 'Position', [0 .45 1 .1], 'FontName', 'FixedWidth', 'String', 'EXIF information could not be processed.');
        end
    else
        uicontrol(stdo{:}, 'Parent', sub1, 'Style', 'text', 'Position', [0 .45 1 .1], 'FontName', 'FixedWidth', 'String', 'Not an image format.');
    end
    % iii) print number of images found
    uicontrol(stdo{:}, 'Parent', sub3, 'Style', 'text', 'Position', [0 0 1 1], 'FontSize', 10, 'FontWeight', 'bold', 'String', sprintf('%d %s-files found', fnum(extnum), uniqueexts{extnum}));
    % iv) display a big selection button
    if showbutton
        uicontrol('Parent', sub4, 'Units', 'normalized', 'backgroundcolor', [.8 .8 .8], 'FontSize', 12, 'FontWeight', 'bold', 'Style', 'pushbutton', 'Position', [.3 .05 .4 .9], 'String', sprintf('Use %s-files', uniqueexts{extnum}), 'tag', uniqueexts{extnum}, 'callback', @nested_cb);
    end
end

%% wait until a button is pressed
%TODO: add callbacks for cancel button
if showbutton
    uiwait(fh); 
end

%% nested functions
    function ext = nested_findext(filename)
    % returns only the extension of a given filename (without .)
    % or an empty string if it was ., .. or a folder

        [~, ~, ext] = fileparts(filename);
        ext = ext(2:end);

    end

    function nested_cb(src, ~)
        outext = get(src, 'tag');
        uiresume(gcbf);
        close(fh);
    end

end %main