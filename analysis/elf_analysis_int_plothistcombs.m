function elf_analysis_int_plothistcombs(res, img4ch, hor_cut, EV, conf, conf_final)
% ELF_ANALYSIS_INT_PLOTHISTCOMBS is a debugging helper function called exclusively in elf_analysis_int 
%   It plot individual anc combined histograms to check how well the confidence-0based combination is working.


figure(777);
chcols   = {'r', 'g', 'b', 'k'};
[~, ind] = sort(EV);
for kk = 1:size(hor_cut, 1)                         % for each region
    rows = hor_cut(kk, 1):hor_cut(kk, 2);           % these are the row indices for this region
    for ch = 1:4                                    % for each channel (R,G,B,BW)
        for i = 1:length(ind)                       % for each exposure
            plotnum = (ind(i)-1) * 4 + ch;
            subplot(length(ind)+1, 4, plotnum); 
            cla; 
            hold on;
            
            a = img4ch(rows, :, ch, ind(i));
            histogram(log10(a(:)), 50, 'facecolor', chcols{ch}, 'edgecolor', 'none');
            plot(log10([conf_final(1, 1, ind(i)), conf_final(1, 1, ind(i)), NaN, conf_final(1, 2, ind(i)), conf_final(1, 2, ind(i))]), [0 200 NaN 0 200], 'g', 'linewidth', 3);
            plot(log10([conf(ch, 1, ind(i)), conf(ch, 1, ind(i)), NaN, conf(ch, 2, ind(i)), conf(ch, 2, ind(i))]), [0 200 NaN 0 200], 'r', 'linewidth', 2);
            
            if ch == 1 % y-labels only for channel 1
                ylabel(sprintf('%+d EV', EV(ind(i))));
            end
            set(gca, 'xticklabel', '');
        end
        subplot(length(ind)+1, 4, length(ind) * 4 + ch); cla;
        histogram(log10(res(ch, kk).hist), 50, 'facecolor', chcols{ch}, 'edgecolor', 'none');
        
        % for all axes, set the xlimits to the min and max of the total
        ax = findobj('parent', gcf);
        for i = 1:length(ax)
            xlim(ax(i), [0.9*log10(res(ch, kk).min), 1.1*log10(res(ch, kk).max)]); 
        end
        xlabel('Photon flux');
        subplot(length(ind)+1, 4, 1);
        title(sprintf('Region %d of %d, rows %d - %d', kk, size(hor_cut, 1), hor_cut(kk, 1), hor_cut(kk, 2)));
    end
    pause;
end