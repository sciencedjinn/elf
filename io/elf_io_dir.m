function content = elf_io_dir(basepath)
    % read contents of a directory and remove invalid file/folder names
    
    content = dir(basepath);
    validdatasets   = ~arrayfun(@(x) strcmp('$RECYCLE.BIN', x.name), content)...
                    & ~arrayfun(@(x) strncmp('.', x.name, 1), content)...
                    & ~arrayfun(@(x) strcmp('dark', x.name), content);
    content = content(validdatasets);
end