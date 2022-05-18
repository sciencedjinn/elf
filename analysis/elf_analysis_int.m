function [res, totalres] = elf_analysis_int(im, ele, type, hdivn, perc, verbose)
% ELF_ANALYSIS_INT calculates intensity descriptors in a calibrated image stack.
%   Type can be read from para.ana.intanalysistype
%   Statistics are calculated both on the whole image and on a strip-by-strip basis, and are given for each individual channel as well as for total
%   "white" intensity. This is currently calculated as the mean of the red, blue, and green channel.
%
%   Example:
%   [res, totalres]  = elf_analysis_int(im, ele, type[, hdivn, perc, verbose])  
%
% Inputs: 
% im                - RxPxC double, unfiltered, calibrated image in equirectangular (azimuth / elevation) projection,
%                     OR a RxPxCxX double, a stack of X images belonging to the same bracketing stack
% ele               - 1xR double, in degrees, y-vector into im. Has to be reversed, e.g. ele = -90:.1:90
% type              - 'hdr' (default): Uses the HDR image to calculate intensity descriptors
%                     'histcomb':      Uses individual images histograms and combines them based on confidence factors using elf_analysis_int_combine
% hdivn             - 1x1 double, how many strips to split elevation into (default: 60, i.e. 3-degree bins)
% perc              - 1x1 double, What percentage of the data should be between displayed min and max intensity? (default: 95)
% verbose           - logical, triggering display of bin boundaries (default: false)
% conf              - only for type "histcomb", calibration confidence
% conffactors       - only for type "histcomb", calirbation confidence factors
%
% Outputs:
% res               - results structure containing all strip-by-strip intensity statistics
% totalres          - results structure containing all whole-image intensity statistics
%
% Uses:       elf_analysis_average, elf_analysis_int_combine (for type 'histcomb')
% Used by:    elf_main1_HdrAndInt
% Call stack: elf_main1_HdrAndInt -> elf_analysis_int
% See also:   elf_main1_HdrAndInt, elf_analysis_int_fromHDR, elf_analysis_int_combine, elf_analysis_average

%% check inputs
if nargin < 6 || isempty(verbose),  verbose = false;     end
if nargin < 5 || isempty(perc),     perc    = 95;        end % by default, return a "range" that includes 95% of the data
if nargin < 4 || isempty(hdivn),    hdivn   = 60;        end % 3-degree bins
if nargin < 3 || isempty(type),     type    = 'hdr';     end
if nargin < 2 || isempty(ele),      ele     = -90:.1:90; end

%% display parameters
if verbose
    elf_support_logmsg('         Performing intensity analysis (type %s) with %d elevation bins (%g%c wide each).\n', type, hdivn, (max(ele)-min(ele))/hdivn, 186);
    elf_support_logmsg('         Minimum and maximum will be calculated to include %g%% of the data.\n', perc);
    elf_support_logmsg('         BW channel is calculated as the mean of RGB.\n');
end

%% Some basic variables
imh         = size(im, 1);              % image height
img4ch      = cat(3, im, mean(im, 3));  % Construct 4 channels (R,G,B,BW) for intensity measurements
allrows     = cell(imh, size(img4ch, 3)); % pre-allocate

%% Create HDR histograms for each row
% if strcmp(type, 'histcomb')
%     conf(:, :, 4, :)    = max(conf, [], 3);         % for BW channel, use max %% TODO: Does this make sense?
%     conffactors(4, :)   = min(conffactors(:, :), [], 1);  % for BW channel, use min %% TODO: Does this make sense?
% end
for row = 1:imh                 % for each row
	for ch = 1:size(img4ch, 3)  % for each channel (R,G,B,BW)
        switch type
            case 'hdr'
                allrows{row, ch}   = img4ch(row, :, ch);
            case 'histcomb'
                error('Currently not supported!')
%                 % combine image histograms across all images in the stack
%                 allrows{row, ch} = elf_analysis_int_combine(img4ch(row, :, ch, :), conf(row, :, ch, :), conffactors(1, :), conffactors(ch+1, :));
%                 %%% allrows can have empty elements; does this happen when there are none in the confidence interval? This should be fixed!
%                 if isempty(allrows{row,ch})
%                     warning('Empty image histogram for row %d, channel %d', row, ch);
%                     allrows{row,ch} = NaN;
%                 end
            otherwise
                error('Unknown type: %s', type);
        end
	end
end

%% Create HDR histograms and stats for each strip
% 1. Divide elevation into strips for intensity statistics
% (tested and verified. all regions are the same size, and centres calculated below are correct if elevation is evenly sampled)
stripwidth_m1   = (imh-1) / hdivn;                                  % every strip has this many rows plus one
stripborders    = round(1:stripwidth_m1:imh);
hor_cut         = [stripborders(1:end-1); stripborders(2:end)]';    % border elements are included in BOTH strips

% 2. For each strip and channel, select the appropriate rows, and calculate stats for the whole set of pixels in that slice
res             = elf_analysis_average(allrows, 'strips', perc, hor_cut);       % res will be data.int

%% Create HDR histograms and stats, corrected for elevation, for whole image
totalres        = elf_analysis_average(allrows, 'image', perc, ele); % Bin size is defined inside this function

%% save a y-axis for plotting
totalres.region_meanele      = mean(ele(hor_cut),2);      % mean of start and end elevation of each region, used for plotting



