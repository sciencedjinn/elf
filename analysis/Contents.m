% Contents of folder "ANALYSIS"
%   This folder contains functions pertaining to the calculation of HDR images and of intensity profiles from these images
%
% Dependencies: prctile   - Statistics and Machine Learning Toolbox
%               nanmean   - Statistics and Machine Learning Toolbox
%               nansum    - Statistics and Machine Learning Toolbox
%               nanmedian - Statistics and Machine Learning Toolbox
%
% Files
%   elf_analysis_int               - Main analysis function, calculates intensity descriptors in a calibrated image stack.
%   elf_analysis_int_combine       - Intensity analysis helper function, only used by elf_analysis_int when type is "fromhist" (not the current default)
%   elf_analysis_average           - Calculates the relevant image statistics across strips or across the whole image.
%   elf_analysis_datasetmean       - Calculates the means of intensity (and spatial) descriptors across a whole dataset.
%   elf_analysis_writestats        - Writes everything that was previously calculated by elf_analysis_datasetmean into an excel file for later analysis.
%
%   elf_hdr_scalestack             - Scales c a stack of calibrated images to each other using the median factorial difference between non-saturated, non-NaN pixels
%   elf_hdr_calcHDR                - Calculates an HDR image from a stack of calibrated images.
%   elf_hdr_brackets               - Detects the bracketing sets in the input images.
%
%   elf_analysis_int_plothistcombs - Debugging function called exclusively in elf_analysis_int 