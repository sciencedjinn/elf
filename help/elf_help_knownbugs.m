% known bugs

% Bug:        In Matlab version 8.0 and below, latex fonts may not be properly
%             displayed on a Mac.
% Solution:   Upgrade to Matlab 8.1 (2013a) ot newer.
% Workaround: The workaround is to manually load the LaTeX fonts onto the operating system. 
%             The LaTeX true type fonts are found in the following directory: $matlabroot/sys/fonts/ttf/cm/
%             Use the Mac Font Book to the load the LaTeX fonts onto the O/S.
% Source:     http://www.mathworks.com/support/bugreports/249537