function res = elf_analysis_average(allrows, over, perc, varinput)
% ELF_ANALYSIS_AVERAGE calculates relevant image statistics across strips or across the whole image.
%   Several different statistics are always claculated, which ones are used in the final plot is 
%   determined by para.plot.intmeantype and para.plot.inttotalmeantype.
%
% Inputs:
%   allrows  - 2D cell array, usually 4xR, containing a histogram vector for each row and channel
%   over     - str - flag indicating whether to integrate over 'rows', 'strips' or the whole 'image'
%   perc     - percentage to include in the min-max range (default: 95)
%   varinput - for 'rows', this is ignored
%              for 'strips', this is a matrix defining the strips (Nx2 hor_cut)
%              for 'image', it is ele, the elevation of each row (used to calculate elevation correction)
%
% Outputs:
%   res      - results struct
%
% elf_analysis_int -> elf_analysis_average -> 
%                                          -> elf_analysis_prctile_weighted


%% TODO: What we want here is a 4x60 array of means in res.means
%%       NOT a scalar value in means in 4x60 res fields

switch over
    case 'rows'
        error('Currently not implemented for rows (but should be simple)');
        
    case 'strips'
        %% calculate histogram and stats per strip
        hor_cut = varinput;
        for kk = 1:size(hor_cut, 1)                 % for each strip
            rows = hor_cut(kk, 1):hor_cut(kk, 2);  	% these are the row indices for this strip
            for ch = 1:size(allrows, 2)             % for each channel (R,G,B,BW)
                imhist      = [allrows{rows, ch}];  % This combination is NOT elevation corrected, but the error is minimal
                res.hist(ch, kk).h  = imhist;    
                res.means(ch, kk)   = mean(imhist(:));
                res.std(ch, kk)     = std(imhist(:));
                res.max(ch, kk)     = max(imhist(:));
                res.min(ch, kk)     = min(imhist(:));
                temp                = prctile(imhist(:), [50 25 75 (100-perc)/2 (100+perc)/2]); % This is the main bottleneck. Speed could be improved by further vectorisation, but it would reduce readability.
                res.median(ch, kk)  = temp(1);
                res.perc25(ch, kk)  = temp(2);
                res.perc75(ch, kk)  = temp(3);
                res.percmin(ch, kk) = temp(4);
                res.percmax(ch, kk) = temp(5);
            end
        end
        
    case 'image'
        %% 1. calculate histogram, corrected for elevation, for whole image
        ele         = varinput;
        elecorr     = cosd(ele); % weighting factor to correct for elevation distortion
        bins        = [-inf logspace(-5, 25, 50*(25--5)+1) inf]; % bin edges
        totalhist   = zeros(length(bins), 4);

        for ch = 1:size(allrows, 2)    % for each channel (R,G,B,BW)    
            for e = 1:length(ele)
                thisele         = allrows{e, ch};
                thishist        = histc(thisele, bins);
                totalhist(:, ch) = totalhist(:, ch) + thishist' * elecorr(e);
            end
        end
        res.hist = totalhist;
        res.bins = bins;

        % 2. calculate overall means/std/min, corrected for elevation
        for ch = 1:4    % for each channel (R,G,B,BW)
            thisch = allrows(:, ch); %img4ch(:, :, ch);

            % mean
            rowmean          = cellfun(@mean, allrows(:, ch));  % mean for each elevation (= row)
            rowmean_w        = rowmean(:) .* elecorr(:);        % row means weighted for elevation
            res.mean(ch)     = sum(rowmean_w) / sum(elecorr);

            % std
            sum_square_diffs = cellfun(@(x) sum((x - res.mean(ch)).^2), allrows(:, ch));
            num_els          = cellfun(@length, allrows(:, ch));
            weighteddiffs    = sum_square_diffs(:) .* elecorr(:);         % multiply the whole channel's squared deviations by the elevation weights
            res.std(ch)      = sqrt(sum(weighteddiffs) / (sum(num_els)-1)); % sum up and divide by n-1.

            % percentiles
            values  = nan(sum(num_els), 1);
            weights = nan(sum(num_els), 1);
            i = 1;
            for row = 1:length(thisch)
                newvalues = thisch{row}(:);
                nexti     = i + length(newvalues);
                values(i:nexti-1)  = newvalues;
                weights(i:nexti-1) = elecorr(row)*ones(size(newvalues));
                i = nexti;
            end
            temp = sun_prctile_weighted(values, weights, [50 25 75 (100-perc)/2 (100+perc)/2 0 100]);
            res.median(ch)  = temp(1);
            res.perc25(ch)  = temp(2);
            res.perc75(ch)  = temp(3);
            res.percmin(ch) = temp(4);
            res.percmax(ch) = temp(5);
            
            % min/max (no correction neccessary)
            res.min(ch)      = temp(6);
            res.max(ch)      = temp(7);
        end
        
    otherwise
        error('Unknown type: %s', over);
end

end % main

%% subfunctions
function outperc = sun_prctile_weighted(x, w, p)

[xs, ind]   = sort(x); % sort the data points (intensities)
ws          = w(ind);  % sort the weights (elecorr values)
percentdata = cumsum(ws); % vector containing the percentage of data below and up to this data point
percentdata = 100 / percentdata(end) * (percentdata - ws/2); % half of each weight is above, half below the point

outperc = nan(size(p));
for i = 1:length(p)
    pos = find(percentdata>=p(i), 1, 'first');
    if isempty(pos)
        outperc(i) = xs(end); % if no ranks are higher than the requested percentile, use the last sorted value
    elseif percentdata(pos) == p(i)
        outperc(i) = xs(pos);
    else
        p1 = max([pos-1 1]); % make sure you don't index below 1
        outperc(i) = mean(xs(p1:pos)); % this could be more accurately interpolated, but for the large pixel sets used in ELF that seems unneccesary
    end
end
end