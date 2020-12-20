function [info, valid] = elf_info_collect(foldname, fmt)
% [info, valid] = elf_info_collect(foldname, fmt)
% Collects the file information for all image files in a certain folder.
%
% Afterwards, use elf_info_summarise to summarise info.
%
% Input:
% foldname - full path of a folder
% fmt - image format, e.g. '*.tif'
%
% Output:
% info - info structure containing exif data
%
% Uses: elf_info_load

if nargin < 2, fmt = 'dng'; end

switch fmt(1)
    case '*'
        % this is the format we need; do nothing
    case '.'
        % add a star in front
        fmt = ['*' fmt];
    otherwise
        % assume that it starts with a letter
        fmt = ['*.' fmt];
end

if exist(foldname, 'file') ~= 7
    error('%d is not a valid folder.', foldname);
end

fnames = elf_io_dir(fullfile(foldname, fmt));   % all filenames in the data folder

if isempty(fnames)
    [~, dataset] = fileparts(foldname);
    error('ELF:io:NoFilesFound', 'No image files of the correct type (%s) were found in data set folder ''%s''', fmt, dataset);
end

valid = 1;
for i = length(fnames):-1:1     % index reversed to preallocate during first iteration
    fullfilename = fullfile(foldname, fnames(i).name);
    try
        info(i) = elf_info_load(fullfilename);
    catch me % this happens for non-image formats, or if exif can't be parsed
        disp(me)
        info(i).Filename = fullfilename;
        valid = 0;
    end
end