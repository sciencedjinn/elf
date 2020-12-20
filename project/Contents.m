% Contents of folder "PROJECT"
%   Contains functions concerned with the transformation between different coordinate systems, i.e. the "unwarping" of fisheye images
%
% Dependencies: No toolbox functions currently needed.
%               (Currently unused function elf_project_findcircle uses edge from the Image Processing Toolbox)
%
% Files
%   elf_project_cart2fisheye                 - Projects Cartesian coordinates (x/y/z) into fisheye image coordinates                                        Tested for correct coordinate transformation 26/10/2017
%   elf_project_rect2fisheye                 - Projects equirectangular coordinates (azimuth/elevation) into fisheye image coordinates                      Tested for correct coordinate transformation 26/10/2017
%   elf_project_rect2fisheye_simple          - Projects equirectangular coordinates (azimuth/elevation) into fisheye image coordinates (simple version)     Tested for correct coordinate transformation 26/10/2017
%   elf_project_fisheye2cart                 - Projects fisheye image coordinates into Cartesian coordinates (x/y/z)                                        Tested for correct coordinate transformation 26/10/2017
%   elf_project_fisheye2rect                 - Projects fisheye image coordinates into equirectangular coordinates (azimuth/elevation)                      Tested for correct coordinate transformation 26/10/2017
%   elf_project_fisheye2rect_simple          - Projects fisheye image coordinates into equirectangular coordinates (azimuth/elevation) (simple version)     Tested for correct coordinate transformation 26/10/2017
%
%   elf_project_image                        - Calculates an index vector to transform a fisheye image into a equirectangular image                         Tested for correct coordinate transformation 26/10/2017
%   elf_project_reproject2fisheye            - Calculates an index vector to transform an equirectangular image back into a fisheye image                   Tested for correct coordinate transformation 26/10/2017
%   elf_project_reproject2fisheye_simple     - Transforms a equirectangular image back into a fisheye image                                                 Tested for correct coordinate transformation 26/10/2017
%   elf_project_reproject2fisheye_frominfo   - Calculates an index vector to transform an equirectangular image back into a fisheye image matching I_info   Tested for correct coordinate transformation 26/10/2017
%
%   elf_project_sub2ind                      - Helper function to turns x/y subscript index vectors into a single linear index vector                       Tested for correct coordinate transformation 26/10/2017
%   elf_project_apply                        - Helper function to applies a linear index vector to an image                                                 Tested for correct coordinate transformation 26/10/2017
%   elf_project_findcircle                   - Helper function to find the image circle on fisheye images (not currently in use)
