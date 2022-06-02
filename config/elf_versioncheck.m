function [simplesyst, thisv, usegpu] = elf_versioncheck(verbose, mayusegpu)
% ELF_VERSIONCHECK tests which operating system and Matlab version is running, and whether necessary toolboxes are installed.
%
% Input:
%           verbose    - 1x1 bool, triggers verbose output (default false)
%           mayusegpu  - 1x1 bool, whether or not gpu computing may be used (default true)
%           
% Output:
%           simplesyst - can be 'pc'/'mac'/'linux'/'other'
%           thisv      - 1x1 double, the Matlab version number run on this machine
%           usegpu     - 1x1 bool, whether to use gpu computing in image filtering or not

%% check inputs
if nargin<2, mayusegpu = true; end
if nargin<1, verbose = false; end

%% verbose output
if verbose
    elf_support_logmsg('----- Version check -----\n');
end

%% determine and check version
v     = ver('matlab');
thisv = str2double(v.Version);
syst  = computer;

% check whether usable GPUs are present
if mayusegpu
    try
        usegpu = license('test', 'Distrib_Computing_Toolbox') && gpuDeviceCount>0;
    catch me
        usegpu = false;
        warning('ELF:GpuWarning', 'No GPU computation possible, because an error occured while trying to detect GPUs: \n %s', me.message);
    end
else 
    usegpu = false;
%      warning('GPU computation manually disabled in elf_para->elf_versioncheck');
end

switch syst
    case 'PCWIN'
        compstr = '32-bit Windows PC';             osfine = 1; simplesyst = 'pc';
    case 'PCWIN64'
        compstr = '64-bit Windows PC';             osfine = 1; simplesyst = 'pc';
    case 'MACI'
        compstr = '32-bit Mac';                    osfine = 1; simplesyst = 'mac';
    case 'MACI64'
        compstr = '64-bit Mac';                    osfine = 1; simplesyst = 'mac';
    case 'GLNX86'
        compstr = '32-bit Linux system';           osfine = 0; simplesyst = 'linux';
    case 'GLNXA64'
        compstr = '64-bit Linus system';           osfine = 0; simplesyst = 'linux';
    otherwise
        compstr = '\bn unknown operating system';  osfine = 0; simplesyst = 'other';
end

%% Results output
if verbose
    elf_support_logmsg('      You are running MATLAB version %s on a %s.\n', v.Version, compstr);
end
if verLessThan('matlab', '9.0')
    if verbose
        elf_support_logmsg('\n');
        elf_support_logmsg('      This program has only been tested for version 9.0 (2016a) and above. Please report any errors or bugs.\n');
    end
    warning('This program has only been tested for version 9.0 (2016a) and above. Please report any errors or bugs.');
end
if ~osfine
    if verbose
        elf_support_logmsg('\n');
        elf_support_logmsg('      This program has not been tested on your operating system. Please report any errors or bugs.\n');
    end
    warning('This program has not been tested on your operating system. Please report any errors or bugs.');
end
if ~license('test', 'Image_Toolbox') 
    error('No Image Processing Toolbox license found. This program will not run properly without this toolbox.');
elseif verbose
    elf_support_logmsg('      Image Processing Toolbox license found.\n');
end
if ~license('test', 'Statistics_Toolbox')
    error('No Statistics Toolbox license found. This program will not run properly without this toolbox.');
elseif verbose
    elf_support_logmsg('      Statistics Toolbox license found.\n');
end
if verbose 
    elf_support_logmsg('      Please make sure the toolboxes are also INSTALLED.\n');
end
if ~verLessThan('matlab', '9.0') && osfine && verbose && license('test', 'Image_Toolbox') && license('test', 'Statistics_Toolbox')
    elf_support_logmsg('      This program should be running fine.\n');
end