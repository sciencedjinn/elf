function elf_callbacks_image(src, ~)
% elf_callbacks_image(src, ~)
%
% This is the callback for the ButtonDown function for all image objects
% It opens the image in a new large window (useful to inspect image details)

hi = elf_plot_image(get(src, 'CData'), get(src, 'UserData'), [], get(src, 'Tag')); % display the image

set(hi, 'ButtonDownFcn', ''); % Disable the ButtonDown function, so clicking on this image does not open another one.

try 
    elf_support_maxfig; 
end % Try to maximise figure (not sure if this works on Mac)