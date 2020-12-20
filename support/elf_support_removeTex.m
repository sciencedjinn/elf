function str = elf_support_removeTex(str)
% escapes some characters from a string that might otherwise be interpreted as Tex

str = strrep(str, '_', '\_');