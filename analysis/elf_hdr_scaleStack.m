function [im_cal, scalefac] = elf_hdr_scaleStack(im_cal, conf, confsat, compexp)
% ELF_HDR_SCALESTACK scales calibrated images to each other using the mean factorial difference between non-saturated, non-NaN pixels. 
% This method will work poorly if there is not a lot of overlap in non-saturated pixels between different exposures.
%
% [im_cal, scalefac] = elf_hdr_scaleStack(im_cal, conf, confsat, compexp)
%
% Inputs:
%   im_cal   - N x M x C x I double, calibrated image stack
%   conf     - N x M x C x I double, raw (dark-corrected) image stack, used for confidence/saturation calculation
%   confsat  - C x I double, the saturation values for each channel/image
%   compexp  - 1 x 1 double, index of the exposure that should be used as an initial comparison (default: middle of the stack)
%              1 x 1 struct, structure including compexp.comp and compexp.mult (see polar_main5_stitch for an example)
%
% Outputs:
%   im_cal   - N x M x C x I double, calibrated image stack scaled to match the exposure of the middle-exposed image
%   scalefac - I x 1 double, scaling factors

if nargin < 4 || isempty(compexp), compexp = ceil(size(im_cal, 4)/2); end % use medium exposure as comparison

%% First, scale all images to one comparison image
scalefac     = zeros(size(im_cal, 4), 1); % pre-allocate
im_cal_nosat = sub_removeSaturation(im_cal, conf, confsat); % first, remove saturation from all images. 
% It is important not to write this back into im_cal, otherwise NaNs will spread during filtering

if ~isstruct(compexp)
    % if only one comparison image is given, compare all to this image
    im_comp     = im_cal_nosat(:, :, :, compexp); % choose comparison image (ideally, the one with the least saturation and most overlap with other images

    for i = 1:size(im_cal, 4)  % for each image
        thisim                 = im_cal_nosat(:, :, :, i);
        scalefac(i)            = nanmedian(im_comp(:)./thisim(:)); %nanmedian(thisim(:)./im_comp(:));
%         % diagnostic plot showing that median is the better measure
%         figure(444); subplot(1, size(im_cal, 4), i); cla; hold on; hist(im_comp(:)./thisim(:), [0:.01:5]); xlim([0 5]); 
%         plot([nanmedian(im_comp(:)./thisim(:)), nanmedian(im_comp(:)./thisim(:))], [0 1e5], 'm', [nanmean(im_comp(:)./thisim(:)), nanmean(im_comp(:)./thisim(:))], [0 2e4], 'r');
        if scalefac(i)<0.7 || scalefac(i)>1.3
            warning('The exposure difference between image %d and image %d (comparison exposure) is larger than 30%%. Check!', i, compexp);
        end
        im_cal(:, :, :, i)     = im_cal(:, :, :, i) .* scalefac(i);
    end
else
    % if a comparison matrix is given, several comparisons are averaged for each scaling factor   
    for i = 1:length(compexp.comp)
        % calculate all individual comparisons
        im1 = im_cal_nosat(:, :, :, compexp.comp{i}(1));
        im2 = im_cal_nosat(:, :, :, compexp.comp{i}(2));
        indscalefac(i) = nanmedian(im2(:)./im1(:)); % factor getting from im1 to im2
    end
    for i = 1:length(compexp.mult)
        temp = [];
        for j = 1:length(compexp.mult{i})
            temp = [temp indscalefac(compexp.mult{i}{j}(1)) * indscalefac(compexp.mult{i}{j}(2))];
        end
        scalefac(i) = mean(temp);
        im_cal(:, :, :, i) = im_cal(:, :, :, i) .* scalefac(i);
    end
end

%% Secondly, adjust all to be at a mean exposure
meanscalefac = 1./mean(1./scalefac);
im_cal      = im_cal / meanscalefac;
scalefac    = scalefac / meanscalefac; % Multiply images with this for best scaling

end % main

%% subfunctions
function thisim = sub_removeSaturation(thisim, thisconf, thisconfsat)
    ulfull                  = repmat(reshape(thisconfsat, [1 1 size(thisim, 3) size(thisim, 4)]), size(thisim, 1), size(thisim, 2), 1, 1);
    sel                     = thisconf < ulfull;                         % NxMxCxI boolean marking non-saturated values
%     sel                     = repmat(all(sel, 3), [1 1 size(sel, 3) size(sel, 4)]);   % NxMxCxI boolean marking values where NONE of the channels is saturated
    thisim(~sel)             = NaN;                                      % set saturated pixels to NaN
end


%% stack correction test
% for i = 1:10000
%     a = 100 + 10*randn(1, 4);
%     c = a(1) ./ a;
%     mc = 1/mean(1./c);
%     b = a .* c / mc;
%     
%     std1(i) = std(a);
%     std2(i) = std(b);
%     err1(i) = mean(a) - 100;
%     err2(i) = mean(b) - 100;
%     err3(i) = mean(a) - mean(b);
% end
% 
% mean(std1)
% mean(std2)
% mean(abs(err1))
% mean(abs(err2))
% mean(abs(err3))
