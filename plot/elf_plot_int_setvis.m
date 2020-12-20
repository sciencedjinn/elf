function elf_plot_int_setvis(fignum)

vis = {'off', 'on'};
ch(1) = get(findobj('tag', sprintf('fig%d_gui_R', fignum)), 'Value');
ch(2) = get(findobj('tag', sprintf('fig%d_gui_G', fignum)), 'Value');
ch(3) = get(findobj('tag', sprintf('fig%d_gui_B', fignum)), 'Value');
ch(4) = get(findobj('tag', sprintf('fig%d_gui_BW', fignum)), 'Value');

for i = 1:length(ch)
    set(findobj('tag', sprintf('fig%d_plot_ch%d', fignum, i)), 'Visible', vis{ch(i)+1});  
end

set(findobj('tag', 'gui_axb'), 'Visible', 'off');  

% for i = 1:length(ch)
%     uistack(findobj('tag', sprintf('plot_mean_ch%d', i)), 'up');
%     uistack(findobj('tag', sprintf('plot_median_ch%d', i)), 'up');
% end