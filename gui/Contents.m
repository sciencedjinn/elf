% Contents of folder "GUI"
%   Contains functions related to the design and functionality of the graphical user interface
% 
% Dependencies: No toolbox functions required. The elf gui currently doesn't use any of the newer ui functions (uifigure, etc), so it should work fine 
%               on older Matlab installations.
%
% Files
%   elf_startup                 - ELF startup procedures
%   elf_maingui                 - Creates the main ELF user interface
%   elf_maingui_visibility      - Update visibility and enabled state of gui elements
%
%   Callbacks:
%   elf_callbacks_maingui       - Callbacks for the ELF gui's buttons
%   elf_callbacks_image         - ButtonDown function for all image objects
%   elf_callbacks_montage       - ButtonDown function for all montage image object (displays full-size image)
%   elf_callbacks_elfgui        - Callback for the gui elements on an ELF results sheet
%
%   elf_checkdata               - Checks folder structure and extract valid data sets and their analysis state (for display in GUI panels)
%   elf_explore                 - Display individual scenes and main image for a finished data set
%   elf_gui_chooseext           - Prompts the user to choose an image file extension from all file types present in a folder



