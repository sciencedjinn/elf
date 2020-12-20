function imhist_comb = elf_analysis_int_combine(im, conf, confmult, confsat)
% ELF_ANALYSIS_INT_COMBINE is an intensity analysis helper function, only used by elf_analysis_int when type is "fromhist" (not the current default)
% Combines the values in im across 4th dimension, based on confidence/noise levels
%
%   Example:
%   allrows{row, ch} = elf_analysis_int_combine(img4ch(row, :, ch, :), conf(row, :, ch, :), conffactors(1, :), conffactors(ch+1, :));
%
% Inputs: 
% im          - NxMx4xR double, all photon flux values in the image part to analyse
% conf        - NxMx4xR double, confidence matrix for the image
% confmult    - calibration multiplier
% confsat     - calibration saturation limit
%
% Outputs:
% imhist_comb - 1xX combined image histogram
%
% Uses:       None
% Used by:    elf_analysis
% Call stack: elf_main1_HdrAndInt -> elf_analysis_int
% See also:   elf_main1_HdrAndInt, elf_analysis_int


%% 
ul                  = confsat;
ul(1)               = Inf;
ll(1:length(ul)-1)  = ul(2:end) ./ confmult(2:end) .* confmult(1:end-1);
ll(length(ul))      = -Inf;

%% Calculate combined histogram
imhist_comb = [];
for ii = 1:size(im, 4)  % for each image, starting at the lowest EV image
    cc            = im(:, :, :, ii); % extract THIS row for THIS channel for THIS image
    thisconf      = conf(:, :, :, ii);
    imhist_comb   = [imhist_comb cc(thisconf>ll(ii) & thisconf<=ul(ii))];
end

return

%% debugging plots
for ii = 1:size(im, 4)  % for each image, starting at the lowest EV image
    cc            = im(:, :, :, ii); % extract THIS row for THIS channel for THIS image
    thisconf      = conf(:, :, :, ii);
    imhist_full{ii} = cc;
    imhist{ii}    = cc(thisconf>ll(ii) & thisconf<=ul(ii));        
    imconf_full{ii} = thisconf;
    imconf{ii}    = thisconf(thisconf>ll(ii) & thisconf<=ul(ii));
end

figure(101); clf; hold on;
for i = 1:length(imhist)
    subplot(4, 2, i);
    hold on;
    histogram(real(log10(imhist_full{i})), 13:0.1:18, 'facecolor', 'k');
    histogram(real(log10(imhist{i})), 13:0.1:18, 'facecolor', 'r');
    title(sprintf('%d: %.04g %.0f', i, confmult(i), confsat(i)));
    xlabel('photon radiance');
end
subplot(4, 2, 8); 
histogram(real(log10(imhist_comb)), 13:0.1:18, 'facecolor', 'b');

figure(102); clf; hold on;
for i = 1:length(imhist)
    subplot(4, 2, i);
    hold on;
    histogram(real(log10(imconf_full{i})), -2:0.1:6, 'facecolor', 'k');
    histogram(real(log10(imconf{i})), -2:0.1:6, 'facecolor', 'r');
    title(sprintf('%d: %.04g %.0f', i, confmult(i), confsat(i)));
    xlabel('dark-corr. counts');
end