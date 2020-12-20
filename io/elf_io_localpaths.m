function outpath = elf_io_localpaths(method, forcereset, varinput)
% ELF_IO_LOCALPATHS manages a number of paths on the local machine. Paths are saved in Matlab's "prefdir".
% If a path has not been set before, a dialog is opened to ask the user to select the path
%
%   method     - 'loadroot'/'saveroot'
%                'loadoutput'/'saveoutput'
%                'loadoutput_pub'/'saveoutput_pub'
%   forcereset - Force a reset of local paths (asks user to define them)
%   varinput   - For all "save" methods, this is the value to be saved. It is up to the calling function to make sure this path is valid.
%
% Outputs:
%   outpath    - the value of the loaded or saved path

if nargin < 2 || isempty(forcereset), forcereset = false; end

field = method(5:end); % name of the field to be laoded or saved
pref_fname = fullfile(prefdir, 'elf_paths.vpf'); % full path to the preference file
switch method(1:4)
    case 'save'
        eval([field ' = varinput;']);
        if exist(pref_fname, 'file')
            save(pref_fname, field, '-mat', '-append');
        else
            save(pref_fname, field, '-mat');            
        end
        outpath = varinput;
    case 'load'
        if forcereset || ~exist(pref_fname, 'file') || ~isfield(load(pref_fname, '-mat'), field)
            % ask for user input
            switch field
                case 'root'
                    qstr = 'Please select the root data directory (which includes all the data folders)';
                case 'output'
                    qstr = 'Please select the main output folder (for full results, as pdfs, tifs and Excel files)';
                case 'output_pub'
                    qstr = 'Please select the public output folder (for small shareable results, as jpgs)';
                otherwise
                    error('Internal error: Unknown field');
            end
            userdir = elf_support_fileDialog(qstr, 'uigetdir', pwd, 'Select new folder');
            if ~all(userdir == 0)
                outpath = userdir;
                elf_io_localpaths(['save' field], '', outpath);
            else
                error('Folder selection aborted by user');
            end
        else
            % if the file exists and has the right field, load it
            temp = load(pref_fname, field, '-mat');
            outpath = temp.(field);
        end
    otherwise
        error('Internal error: Unknown method');
end
      