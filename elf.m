function elf(varargin)
% ELF creates an interactive window allowing the user to browse folders and see the processed and potential datasets in this folder.
% Practically all other ELF functions can then be called through buttons next to the images.
% 
% Once a folder has been selected, it will be saved as a default for the future. To select a new folder, call 'elf --reset'.
%
% Other command options:
%
% --help / -h       - Display this help text
% --verbose / -v    - Display verbose output text for debugging
% --reset / -r      - Reset the saved data folder
% --manual / -m     - Display the ELF manual PDF

%% defaults
useoldfolder = true;
verbose = false;

vMajor = 1;
vMinor = 1;
vPatch = 0;
fprintf('Starting ELF %d.%d.%d\n', vMajor, vMinor, vPatch);

%% parameters
for i = 1:length(varargin)
    par = varargin{i};
    if ischar(par)
        % supported string arguments
        switch par
            case {'-h', '--help'}
                help(fullfile('.', 'elf.m'))
                return
            case {'-v', '--verbose'}
                verbose = true;
            case {'--reset', '-r'}
                useoldfolder = false;
            case {'--manual', '-m'}
                open('ELF Getting started guide.pdf');
                return
            otherwise
                error('elf: ''%s'' is not an elf command or option. See ''elf --help''.', varargin(i));
        end
    elseif isnumeric(par)
        if isnan(par) || par==-1 || par==0
            useoldfolder = false;
        else
            warning('elf: ''%d'' is not an elf command or option. See ''elf --help''.', varargin(i));
            return
        end
    else
        error('elf: Unknown elf command or option. See ''elf --help''.');
    end
end

%% set paths and parameters
elf_paths;

%% read parameter file, and build GUI
[para, status, gui] = elf_startup(@maincb, '', verbose, useoldfolder);

%% nested function
    function maincb(src, ~)
        if strcmp(get(src, 'tag'), 'maingui_folderbrowse')
            % new folder has been selected, confirm in a gui and, if necessary, restart GUI
            newFolder = elf_support_fileDialog('Select a new root data folder', 'uigetdir', para.paths.root, 'Select new folder');
            if ~all(newFolder == 0) && exist(newFolder, 'file')
                [para, status, gui] = elf_startup(@maincb, newFolder, verbose);
            end
        elseif strcmp(get(src, 'tag'), 'file_reload')
            [para, status, gui] = elf_startup(@maincb, '', verbose);
        else % any other button or key callback
            [status, gui] = elf_callbacks_maingui(src, status, gui, para);
        end
    end

end % main