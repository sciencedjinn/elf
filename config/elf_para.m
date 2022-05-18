function para = elf_para(rootdir, dataset, imgformat, verbose)
% ELF_PARA defines some of the basic anlysis parameters for ELF
% 
%
% if called without dataset, just collects basic info
% rootdir = NaN or rootdir = 'reset' means reset all local folders
% empty rootdir means load all saved folders
% rootdir = 'prompt' means prompt for root dir but use saved output folders

%% defaults
if nargin < 4, verbose = false; end
if nargin < 3, imgformat = ''; end
if nargin < 2, dataset = ''; end
if nargin < 1, rootdir = ''; end

%% find root folder
mayusegpu = false; % this flag can be used to manually (de-)activate use of GPU computing
[para.syst, para.thisv, para.usegpu] = elf_versioncheck(verbose, mayusegpu); % Check operating system and Matlab version

if any(isnan(rootdir)) || strcmp(rootdir, 'reset')
    % reset and prompt for all local input/output folders
    para.paths.root             = elf_io_localpaths('loadroot', true);
    para.paths.outputfolder     = elf_io_localpaths('loadoutput', true);
    para.paths.outputfolder_pub = elf_io_localpaths('loadoutput_pub', true);
elseif any(isempty(rootdir))
    % use saved input/output folders
    para.paths.root             = elf_io_localpaths('loadroot', false);
    para.paths.outputfolder     = elf_io_localpaths('loadoutput', false);
    para.paths.outputfolder_pub = elf_io_localpaths('loadoutput_pub', false);
elseif strcmp(rootdir, 'prompt') || ~exist(rootdir, 'file')
    % prompt for data folder, but use saved output folders
    para.paths.root             = elf_io_localpaths('loadroot', true);
    para.paths.outputfolder     = elf_io_localpaths('loadoutput', false);
    para.paths.outputfolder_pub = elf_io_localpaths('loadoutput_pub', false);
else
    % if a directory was specified, and it exists, use it and save it as the new default
    para.paths.root = rootdir;
    elf_io_localpaths('saveroot', 0, rootdir);
    para.paths.outputfolder     = elf_io_localpaths('loadoutput');
    para.paths.outputfolder_pub = elf_io_localpaths('loadoutput_pub');
end

%% define further folder structure
para.paths.matfolder        = 'mat';            % subfolder of data folder into which to save the .mat descriptor files (and individual .pdf files, if activated) 
para.paths.filtfolder       = 'filt';           % subfolder of data folder into which to save the filtered images 
para.paths.scenefolder      = 'scenes';         % subfolder of data folder into which to save the filtered images 
para.paths.calibfolder      = fullfile(fileparts(mfilename('fullpath')), '..', 'calibration');

%% if this is called for a specific dataset, store that information
if ~isempty(dataset)
    para.paths.dataset      = dataset;
    para.paths.imgformat    = imgformat;
    para.paths.datapath     = fullfile(para.paths.root, para.paths.dataset);
    para                    = elf_io_readwrite(para, 'createfilenames');
end

%% gui parameters
para.gui.pnum_cols = 8; % 8 tiles horizontally
para.gui.pnum_rows = 6; % 6 tiles vertically
para.gui.smallsize = 200; % size of small preview images in ELF gui

%% projection constants (don't change)
para.azi                    = -90:.1:90;          % regular elevation sampling for equirectangular projection
para.ele                    = -90:.1:90;          % regular azimuth sampling for equirectangular projection
para.ele2                   = rot90(para.ele,2);
para.projtype               = 'equisolid';        % if this is 'noproj', no projection will be calculated (original images should be 1801x1801)

%% analysis constants
para.ana.scales_deg         = [1 10];   % half-width (FWHM) of receptors in degrees (sigma of Gaussian)
para.ana.filterazimin       = -90;
para.ana.filterazimax       = 90;
para.ana.filterelemin       = -90; 
para.ana.filterelemax       = 90;

para.ana.hdivn_int          = 60;       % how many regions to divide elevation into for intensity slices
para.ana.rangeperc          = 95;       % What percentage of the data should be between displayed min and max intensity? (default: 95)

para.ana.spatialbins        = [-90 -10 10 90];%[-90 -50 -10 10 50 90]; % define the boundaries of bins for spatial/contrast analysis
para.ana.spatialmeantype    = 'rms';    % can be 'mean'/'rms'/'perc'; if this is changed, step 3 and 4 have to be recalculated
para.ana.spatialmeanthr     = 0;        % contrast threshold in percent; only contrasts >= this value will be included in the mean

para.ana.colourcalibtype    = 'col';    % 'colmat'   - Full deconvolution of channels to reconstruct a spectrum that is flat between 400-500, 500-600 and 600-700 nm
                                        % 'col'      - Scale individual channels so each one represents the weighted average spectral photon radiance
                                        %              over that pixels sensitivity
                                        % 'wb'       - Scale individual channels using the camera's "as shot" white balance, scaled to the mean
                                        %              spectral photon radiance (averaged over all channels)
para.ana.intanalysistype    = 'hdr';    % 'histcomb' - Calculate individual histograms for each exposure, and combine them using valid raw count ranges.
                                        %              This method has the problem that some pixels might contribute more than once, while others never contribute.
                                        % 'hdr'      - Calculate histograms from the HDR image.
para.ana.hdrmethod          = 'allvalid2';         %'overwrite2', 'allvalid2', 'noise'                               
                       
%% plotting parameters (will be loaded again at plotting time)
para.plot = elf_plottingPara;






