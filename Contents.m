% Contents of folder "ELF"
%   This is the main folder for the ELF Matlab package, including any functions that are meant to be directly interacted with by the user.
% 
% Dependencies for the ELF package:     Image Processing Toolbox
%                                       Statistics and Machine Learning Toolbox
%
% Dependencies for this folder:         montage         - Image Processing Toolbox
%                                       im2uint16       - Image Processing Toolbox
%
% Files:
%   GUI version:
%       elf                         - Main function for the ELF project. Starts a GUI to browse and manage projects.
%   
%   Programmatic version:
%       elf_main1_HdrAndInt         - Calibrates/unwarps images in an environment, then calculates HDR and intensity statistics for each scene
%       elf_main2_meanimage         - Calculates the mean image for an environment as the mean of all normalised HDR scenes
%       elf_main3_intsummary        - Averages the intensity statistics for an environment and creates ELF plots
%       elf_main4_display           - Displays the intensity statistics and mean image for a previously analysed dataset
%       elf_mainX_explore           - Shows a montage of all scenes, and the mean image for a processed ELF data set
%       calc_wholefolder            - Performs full ELF analysis for a whole folder of ELF environments (the "run all data overnight" function)
%
%   Helper functions:
%       elf_paths                   - Contains the paths to all subfolders and modules