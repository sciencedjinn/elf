function elf_support_maxfig(fh)

%% inputs
if nargin<1, fh = gcf; end

if verLessThan('matlab', '9.4') 
    %% for matlab version before 2018a, use Java

    % deactivate warnings
    s = warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved');

    % maximise figure
    pause(0.01); % makes this work even if the figure has only just been opened 
    jf = get(fh, 'JavaFrame');
    set(jf,'Maximized',1);

    % reset warnings
    warning(s)
else
    %% from 2018a onwards, use new figure property
    fh.WindowState = 'maximized';
end