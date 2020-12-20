function meandata = elf_analysis_datasetmean(data, sel, intOnly, meanType)
% ELF_ANALYSIS_DATASETMEAN averages intensity (and spatial) descriptors for a whole dataset.
%   Individual descriptors should have been calculated and saved before by elf_main1_HdrAndInt.
%
%   Example:
%   meandata = elf_analysis_datasetmean(data, sel, verbose, para.plot.datasetmeantype)  
%
% Inputs: 
%   data              - 1 x N struct array, containing the results structs for each individual image (created earlier by elf_analysis)
%   sel               - 1 x N bool, indicates which images to include in the calculation of the mean (default: true(1, N))
%   intOnly           - 1 x 1 bool, whether or not to only calculate intensity descriptors and skip spatial descriptors (default: true)
%   meanType          - str, determines which type of averaging to use, should be set to para.plot.datasetmeantype (current default: logmean)
% Outputs:
%   meandata          - 1 x 1 struct, containing the same fields as data, contains the mean results
%
% Uses:       None
% Used by:    elf_main3_intsummary
% Call stack: elf_main3_intsummary -> elf_analysis_datasetmean
% See also:   elf_main3_intsummary, elf_analysis

%% Check inputs
if nargin < 4 || isempty(meanType), meanType = 'logmean'; end
if nargin < 3 || isempty(intOnly), intOnly = true; end
if nargin < 2 || isempty(sel), sel = 1:length(data); end
    
%% initialise from first element to get all label fields and histbins
meandata = data(1); %% FIXME: THIS IS RISKY!

%% Calculate means for intensity descriptors
% mean
meandata.int.means = sub_mean(data(sel), 'int', 'means', meanType);

% std
meandata.int.std = sub_mean(data(sel), 'int', 'std', meanType);

% min
temp = sub_extract(data, 'int', 'means') - sub_extract(data, 'int', 'min');
meandata.int.minrange = sub_average(temp(:, :, sel), 3, meanType);
meandata.int.min = meandata.int.means - meandata.int.minrange;

% max
temp = sub_extract(data, 'int', 'max') - sub_extract(data, 'int', 'means');
meandata.int.maxrange = sub_average(temp(:, :, sel), 3, meanType);
meandata.int.max = meandata.int.means + meandata.int.maxrange;

% median
meandata.int.median = sub_mean(data(sel), 'int', 'median', meanType);

% 25th percentile
temp = sub_extract(data, 'int', 'median') - sub_extract(data, 'int', 'perc25');
meandata.int.perc25range = sub_average(temp(:, :, sel), 3, meanType);
meandata.int.perc25 = meandata.int.median - meandata.int.perc25range;

% 75th percentile
temp = sub_extract(data, 'int', 'perc75') - sub_extract(data, 'int', 'median');
meandata.int.perc75range = sub_average(temp(:, :, sel), 3, meanType);
meandata.int.perc75 = meandata.int.median + meandata.int.perc75range;

% min percentile
temp = sub_extract(data, 'int', 'median') - sub_extract(data, 'int', 'percmin');
meandata.int.percminrange = sub_average(temp(:, :, sel), 3, meanType);
meandata.int.percmin = meandata.int.median - meandata.int.percminrange;

% max percentile
temp = sub_extract(data, 'int', 'percmax') - sub_extract(data, 'int', 'median');
meandata.int.percmaxrange = sub_average(temp(:, :, sel), 3, meanType);
meandata.int.percmax = meandata.int.median + meandata.int.percmaxrange;

%% Calculate whole-image means for intensity descriptors
% mean
meandata.totalint.mean = sub_mean(data(sel), 'totalint', 'mean', meanType);

% std
meandata.totalint.std = sub_mean(data(sel), 'totalint', 'std', meanType);

% min
temp = sub_extract(data, 'totalint', 'mean') - sub_extract(data, 'totalint', 'min');
meandata.totalint.minrange = sub_average(temp(:, :, sel), 3, meanType);
meandata.totalint.min = meandata.totalint.mean - meandata.totalint.minrange;

% max
temp = sub_extract(data, 'totalint', 'max') - sub_extract(data, 'totalint', 'mean');
meandata.totalint.maxrange = sub_average(temp(:, :, sel), 3, meanType);
meandata.totalint.max = meandata.totalint.mean + meandata.totalint.maxrange;

% median
meandata.totalint.median = sub_mean(data(sel), 'totalint', 'median', meanType);

% 25th percentile
temp = sub_extract(data, 'totalint', 'median') - sub_extract(data, 'totalint', 'perc25');
meandata.totalint.perc25range = sub_average(temp(:, :, sel), 3, meanType);
meandata.totalint.perc25 = meandata.totalint.median - meandata.totalint.perc25range;

% 75th percentile
temp = sub_extract(data, 'totalint', 'perc75') - sub_extract(data, 'totalint', 'median');
meandata.totalint.perc75range = sub_average(temp(:, :, sel), 3, meanType);
meandata.totalint.perc75 = meandata.totalint.median + meandata.totalint.perc75range;

% min percentile
temp = sub_extract(data, 'totalint', 'median') - sub_extract(data, 'totalint', 'percmin');
meandata.totalint.percminrange = sub_average(temp(:, :, sel), 3, meanType);
meandata.totalint.percmin = meandata.totalint.median - meandata.totalint.percminrange;

% max percentile
temp = sub_extract(data, 'totalint', 'percmax') - sub_extract(data, 'totalint', 'median');
meandata.totalint.percmaxrange = sub_average(temp(:, :, sel), 3, meanType);
meandata.totalint.percmax = meandata.totalint.median + meandata.totalint.percmaxrange;
% 
% % histograms
meandata.int.totalhist = sub_mean(data(sel), 'totalint', 'hist', meanType); %% FIXME: This has to take into account BINS!

if ~intOnly
    %% Calculate means for spatial descriptors
    %% TODO: Review this when finalising "space" module
    meandata.spatial.lum = sub_mean(data, 'spatial', 'lum');
    meandata.spatial.rg  = sub_mean(data, 'spatial', 'rg');
    meandata.spatial.gb  = sub_mean(data, 'spatial', 'gb');
    meandata.spatial.rb  = sub_mean(data, 'spatial', 'rb');

    for sc = 1:length(meandata.spatial.lumfft)
        for bin = 1:length(meandata.spatial.lumfft{sc})
            meandata.spatial.lumfft{sc}{bin} = sub_meanfft(data, 'spatial', 'lumfft', sc, bin);
            meandata.spatial.rgfft{sc}{bin} = sub_meanfft(data, 'spatial', 'rgfft', sc, bin);
            meandata.spatial.gbfft{sc}{bin} = sub_meanfft(data, 'spatial', 'gbfft', sc, bin);
            meandata.spatial.rbfft{sc}{bin} = sub_meanfft(data, 'spatial', 'rbfft', sc, bin);
        end
    end
    for sc = 1:length(meandata.spatial.lumprof)
        meandata.spatial.lumprof{sc} = sub_meanprof(data, 'spatial', 'lumprof', sc);
        meandata.spatial.rgprof{sc} = sub_meanprof(data, 'spatial', 'rgprof', sc);
        meandata.spatial.gbprof{sc} = sub_meanprof(data, 'spatial', 'gbprof', sc);
        meandata.spatial.rbprof{sc} = sub_meanprof(data, 'spatial', 'rbprof', sc);
    end
end

end % main

%% subfunctions
function av = sub_average(data, meandim, intmeantype)
    switch intmeantype
        case 'mean'
            av = nanmean(data, meandim);
        case 'median'
            av = nanmedian(data, meandim);
        case 'logmean'
            av = exp(nanmean(log(data), meandim));
        otherwise
            error('Unknown mean type: %s', intmeantype);
    end
end

function outmean = sub_mean(s, f1, f2, intmeantype)
    [outmat, meandim] = sub_extract(s, f1, f2);
    outmean = sub_average(outmat, meandim, intmeantype);
end

function [outmat, meandim] = sub_extract(s, f1, f2)
    oldndims = ndims(s(1).(f1).(f2));
    meandim = oldndims + 1;
%     temp = arrayfun(@(x) arrayfun(@(y) y.(f2), x.(f1), 'UniformOutput', true), s, 'UniformOutput', false);
    temp = arrayfun(@(x) x.(f1).(f2), s, 'UniformOutput', false);
    outmat = cat(meandim, temp{:});
end

function outmean = sub_meanfft(s, f1, f2, sc, bin)
    [outmat, meandim] = sub_extractfft(s, f1, f2, sc, bin);
    outmean = nanmean(outmat, meandim);
end

function [outmat, meandim] = sub_extractfft(s, f1, f2, sc, bin)
    oldndims = ndims(s(1).(f1).(f2){sc}{bin});
    meandim = oldndims + 1;
    temp = arrayfun(@(x) x.(f1).(f2){sc}{bin}, s, 'UniformOutput', false);
    outmat = cat(meandim, temp{:});
end

function outmean = sub_meanprof(s, f1, f2, sc)
    [outmat, meandim] = sub_extractprof(s, f1, f2, sc);
    outmean = nanmean(outmat, meandim);
end

function [outmat, meandim] = sub_extractprof(s, f1, f2, sc)
    oldndims = ndims(s(1).(f1).(f2){sc});
    meandim = oldndims + 1;
    temp = arrayfun(@(x) x.(f1).(f2){sc}, s, 'UniformOutput', false);
    outmat = cat(meandim, temp{:});
end