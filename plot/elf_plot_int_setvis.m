function elf_plot_int_setvis(figID)

vis = {'off', 'on'};
ch(1) = get(findobj('tag', sprintf('%s_gui_R', figID)), 'Value');
ch(2) = get(findobj('tag', sprintf('%s_gui_G', figID)), 'Value');
ch(3) = get(findobj('tag', sprintf('%s_gui_B', figID)), 'Value');
ch(4) = get(findobj('tag', sprintf('%s_gui_BW', figID)), 'Value');

for i = 1:length(ch)
    set(findobj('tag', sprintf('%s_plot_ch%d', figID, i)), 'Visible', vis{ch(i)+1});  
end

set(findobj('tag', 'gui_axb'), 'Visible', 'off');  
