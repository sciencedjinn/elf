function elf_support_logmsg(str, varargin)
%%

% currently, this function directly uses fprintf. In the future, there
% should be an option in para to save everything to a file instead.

fprintf('[%s]   ', datestr(now, 'HH:MM:SS'));
fprintf(str, varargin{:});

