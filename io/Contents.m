% Contents of folder "IO"
%   Contains functions concerned with file input-output, calibration and EXIF information
% 
% Dependencies: demosaic   - Image Processing Toolbox
%               im2uint8   - Image Processing Toolbox
%
% Files
%   elf_calibrate_abssens                   - Performs absolute sensitivity calibration and corrects vignetting
%   elf_calibrate_spectral                  - Performs colour correction on an otherwise calibrated image
%   elf_calibrate_darkandreadout            - Returns an estimate of dark noise, and the saturation limit, for a given camera setting
%
%   elf_info_load                           - Loads EXIF information for an image file and returns a struct
%   elf_info_collect                        - Collects the file information for all image files of a given type in a given folder and returns a struct array
%   elf_info_summarise                      - Summarises EXIF information from an EXIF struct array
%   elf_info_printsummary                   - Prints an EXIF information summary to the console, a file, or an axes handle
%
%   elf_io_imread                           - Wrapper function for reading different image types. For DNGs, calls elf_io_loaddng
%   elf_io_loaddng                          - Loads a raw image from a DNG file, and performs cropping, demosaicing, and linearisation if necessary
%   elf_io_correctdng                       - Transforms a linear image for display (colour space transformation, normalisation, gamma-correction, brightness)%  
%   elf_io_readwrite                        - Main input/output function, contains all read and write calls for files in a project
%   elf_io_localpaths                       - Manages a number of paths (for input images and results output) on the local machine. Paths are saved in Matlab's "prefdir".
%   
%   elf_para_update                         - Helper function for combining old (saved) and current parameter files