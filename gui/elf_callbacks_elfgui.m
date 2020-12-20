function elf_callbacks_elfgui(src, ~)
% elf_callbacks_elfgui(src, ~)
%
% This is the callback for the gui elements on an ELF results sheet

switch get(src, 'tag')
    case {'gui_posslider', 'gui_rangeslider'}
        newwidth = get(findobj('tag', 'gui_rangeslider'), 'Value');       % between -1 and 1, log10 of x-axis width
        medcentre = get(findobj('tag', 'gui_posslider'), 'UserData');       % log10 of x-axis pos centre
        newcentre = medcentre + get(findobj('tag', 'gui_posslider'), 'Value');       % between -4 and 4, log10 of x-axis pos offset
        ax1 = findobj('tag', 'gui_ax1');
        ax3 = findobj('tag', 'gui_ax3');
        ax4 = findobj('tag', 'gui_ax4');
        newax = [10^(newcentre - newwidth/2) 10^(newcentre + newwidth/2)];
        xlim(ax1, newax);
        xlim(ax3, newax);
        xlim(ax4, newax);
    otherwise
        % probably a RGB/BW button
        if regexp(get(src, 'tag'), 'fig\w*_gui_\w*')
            % determine figure number
            C = textscan(get(src, 'tag'), 'fig%d_gui_%s');
            fignum = C{1};
            buttontype = C{2};

            switch get(src, 'Value')
                case 1 % switched on
                    % set all others to off
                    set(findobj('tag', sprintf('fig%d_gui_R', fignum)), 'Value', 0);
                    set(findobj('tag', sprintf('fig%d_gui_G', fignum)), 'Value', 0);
                    set(findobj('tag', sprintf('fig%d_gui_B', fignum)), 'Value', 0);
                    set(findobj('tag', sprintf('fig%d_gui_BW', fignum)), 'Value', 0);
                    set(src, 'Value', 1);
                case 0 % switched off, don't allow it
                    set(src, 'Value', 1);

                otherwise
                    error('Internal error: Unknown Value');
            end
            elf_plot_int_setvis(fignum);

        else
            %ignore for now
        end
end

