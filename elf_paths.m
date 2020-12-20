function elf_paths
% ELF_PATHS adds the ELF main folder and its necessary subfolders to the Matlab path.
%   The function elf_paths must stay in the ELF main folder for this to function.
%
%   Example:
%   elf_paths
%
% Uses:       None
% Used by:    all elf_main functions

thispath = fileparts(mfilename('fullpath'));

addpath(thispath);
addpath(fullfile(thispath, 'analysis'));
addpath(fullfile(thispath, 'calibration'));
addpath(fullfile(thispath, 'config'));
addpath(fullfile(thispath, 'gui'));
addpath(fullfile(thispath, 'help'));
addpath(fullfile(thispath, 'io'));
addpath(fullfile(thispath, 'plot'));
addpath(fullfile(thispath, 'project'));
addpath(fullfile(thispath, 'support'));
addpath(genpath(fullfile(thispath, 'modules'))); % add all installed modules