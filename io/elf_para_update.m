function para = elf_para_update(para)

%% Combine old parameter file with potentially changed information in current elf_para
oldpara        = elf_io_readwrite(para, 'loadpara');             % loads the old para file (which contains projection information, too)
oldpara.ana    = para.ana;
oldpara.plot   = para.plot;
oldpara.paths  = para.paths;
oldpara.usegpu = para.usegpu;
para           = compStruct(oldpara, para);       % if a field does not exist in oldpara, it is copied from para
