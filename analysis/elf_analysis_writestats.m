function elf_analysis_writestats(meandata, para, intonly)
% ELF_ANALYSIS_WRITESTATS writes everything that was previously calculated by elf_analysis_datasetmean into an excel file for later analysis.
%
%   Example:
%   elf_analysis_writestats(meandata, intonly)  
%
% Inputs: 
% meandata          - 1 x 1 structure array, containing the mean results structure (created earlier by elf_analysis_datasetmean)
% intonly           - 1 x 1 bool, whether only intensity should be processed (default: true)
%
% Outputs:
% None.
%
% Uses:       None
% Used by:    elf_main3_intsummary
% Call stack: elf_main3_intsummary -> elf_analysis_datasetmean
% See also:   elf_main3_intsummary, elf_analysis

%% Check inputs
if nargin < 3, intonly = true; end
    
warning('off', 'MATLAB:xlswrite:AddSheet');

filename = para.paths.fname_stats;
if exist(filename, 'file')
    delete(filename)
end

% headers
output{1, 1} = 'ELF results for dataset:';
output{2, 1} = para.paths.dataset;

% intensity
output{4, 1} = 'Overall intensity descriptors';
output(5, 2:5) = {'red', 'green', 'blue', 'white'};

output{6, 1} = 'mean';
output(6, 2:5) = num2cell(meandata.totalint.mean);
output{7, 1} = 'std';
output(7, 2:5) = num2cell(meandata.totalint.std);
output{8, 1} = 'min';
output(8, 2:5) = num2cell(meandata.totalint.min);
output{9, 1} = 'max';
output(9, 2:5) = num2cell(meandata.totalint.max);
output{10, 1} = 'median';
output(10, 2:5) = num2cell(meandata.totalint.median);
output{11, 1} = '25th percentile';
output(11, 2:5) = num2cell(meandata.totalint.perc25);
output{12, 1} = '75th percentile';
output(12, 2:5) = num2cell(meandata.totalint.perc75);
output{13, 1} = '2.5th percentile';
output(13, 2:5) = num2cell(meandata.totalint.percmin);
output{14, 1} = '97.5th percentile';
output(14, 2:5) = num2cell(meandata.totalint.percmax);

if ~intonly
    % overall spatial
    output{16, 1} = 'Overall spatial descriptors';
    output(17, 2:5) = {'luminance', 'red-green', 'green-blue', 'blue-red'};

    output{18, 1} = 'Up - 1 degree';
    output{18, 2} = mean(meandata.spatial.lum(3, :, 1));
    output{18, 3} = mean(meandata.spatial.rg(3, :, 1));
    output{18, 4} = mean(meandata.spatial.gb(3, :, 1));
    output{18, 5} = mean(meandata.spatial.rb(3, :, 1));
    output{19, 1} = 'Up - 10 degrees';
    output{19, 2} = mean(meandata.spatial.lum(3, :, 2));
    output{19, 3} = mean(meandata.spatial.rg(3, :, 2));
    output{19, 4} = mean(meandata.spatial.gb(3, :, 2));
    output{19, 5} = mean(meandata.spatial.rb(3, :, 2));

    output{20, 1} = 'Horizon - 1 degree';
    output{20, 2} = mean(meandata.spatial.lum(2, :, 1));
    output{20, 3} = mean(meandata.spatial.rg(2, :, 1));
    output{20, 4} = mean(meandata.spatial.gb(2, :, 1));
    output{20, 5} = mean(meandata.spatial.rb(2, :, 1));
    output{21, 1} = 'Horizon - 10 degrees';
    output{21, 2} = mean(meandata.spatial.lum(2, :, 2));
    output{21, 3} = mean(meandata.spatial.rg(2, :, 2));
    output{21, 4} = mean(meandata.spatial.gb(2, :, 2));
    output{21, 5} = mean(meandata.spatial.rb(2, :, 2));

    output{22, 1} = 'Down - 1 degree';
    output{22, 2} = mean(meandata.spatial.lum(1, :, 1));
    output{22, 3} = mean(meandata.spatial.rg(1, :, 1));
    output{22, 4} = mean(meandata.spatial.gb(1, :, 1));
    output{22, 5} = mean(meandata.spatial.rb(1, :, 1));
    output{23, 1} = 'Down - 10 degrees';
    output{23, 2} = mean(meandata.spatial.lum(1, :, 2));
    output{23, 3} = mean(meandata.spatial.rg(1, :, 2));
    output{23, 4} = mean(meandata.spatial.gb(1, :, 2));
    output{23, 5} = mean(meandata.spatial.rb(1, :, 2));
end

xlswrite(filename, output, 'Global');
    
% Intensity

output2(1, 1:37) = {'ele', 'mean', '', '', '', 'std', '', '', '', 'median', '', '', '', '25th perc', '', '', '', '75th perc', '', '', '', 'min', '', '', '', 'max', '', '', '', '2.5th perc', '', '', '', '97.5th perc', '', '', ''};
output2(2, 1:37) = {'', 'R', 'G', 'B', 'W', 'R', 'G', 'B', 'W', 'R', 'G', 'B', 'W', 'R', 'G', 'B', 'W', 'R', 'G', 'B', 'W', 'R', 'G', 'B', 'W', 'R', 'G', 'B', 'W', 'R', 'G', 'B', 'W', 'R', 'G', 'B', 'W'};
output2(3:62, 1) = num2cell(meandata.totalint.region_meanele);
output2(3:62, 2:5) = num2cell(meandata.int.means');
output2(3:62, 6:9) = num2cell(meandata.int.std');
output2(3:62, 10:13) = num2cell(meandata.int.median');
output2(3:62, 14:17) = num2cell(meandata.int.perc25');
output2(3:62, 18:21) = num2cell(meandata.int.perc75');
output2(3:62, 22:25) = num2cell(meandata.int.min');
output2(3:62, 26:29) = num2cell(meandata.int.max');
output2(3:62, 30:33) = num2cell(meandata.int.percmin');
output2(3:62, 34:37) = num2cell(meandata.int.percmax');

xlswrite(filename, output2, 'Intensity');

if ~intonly
    % spatial

    output3(1, 1:9) = {'ele', '1 degree', '', '', '', '10 degree', '', '', ''};
    output3(2, 1:9) = {'', 'lum', 'rg', 'gb', 'br', 'lum', 'rg', 'gb', 'br'};
    output3(3:62, 1) = num2cell(meandata.totalint.region_meanele);
    output3(3:62, 2) = num2cell(meandata.spatial.lumprof{1}');
    output3(3:62, 3) = num2cell(meandata.spatial.rgprof{1}');
    output3(3:62, 4) = num2cell(meandata.spatial.gbprof{1}');
    output3(3:62, 5) = num2cell(meandata.spatial.rbprof{1}');
    output3(3:62, 6) = num2cell(meandata.spatial.lumprof{2}');
    output3(3:62, 7) = num2cell(meandata.spatial.rgprof{2}');
    output3(3:62, 8) = num2cell(meandata.spatial.gbprof{2}');
    output3(3:62, 9) = num2cell(meandata.spatial.rbprof{2}');

    xlswrite(filename, output3, 'Spatial profiles');

    % spatial bubbles

    output4(1, 1:25)     = {'angle', 'luminance', '', '', '', '', '', 'red-green', '', '', '', '', '', 'green-blue', '', '', '', '', '', 'blue-red', '', '', '', '', ''};
    output4(2, 1:25)     = {'', '1 degree', '', '', '10 degrees', '', '', '1 degree', '', '', '10 degrees', '', '', '1 degree', '', '', '10 degrees', '', '', '1 degree', '', '', '10 degrees', '', ''};
    output4(3, 1:25)     = {'', 'Up', 'Horizon', 'Down', 'Up', 'Horizon', 'Down', 'Up', 'Horizon', 'Down', 'Up', 'Horizon', 'Down', 'Up', 'Horizon', 'Down', 'Up', 'Horizon', 'Down', 'Up', 'Horizon', 'Down', 'Up', 'Horizon', 'Down'};
    output4(4:27, 1)     = num2cell(meandata.spatial.angles');
    output4(4:27, 2:4)   = num2cell(meandata.spatial.lum(:, :, 1)');
    output4(4:27, 5:7)   = num2cell(meandata.spatial.lum(:, :, 2)');
    output4(4:27, 8:10)  = num2cell(meandata.spatial.rg(:, :, 1)');
    output4(4:27, 11:13) = num2cell(meandata.spatial.rg(:, :, 2)');
    output4(4:27, 14:16) = num2cell(meandata.spatial.gb(:, :, 1)');
    output4(4:27, 17:19) = num2cell(meandata.spatial.gb(:, :, 2)');
    output4(4:27, 20:22) = num2cell(meandata.spatial.rb(:, :, 1)');
    output4(4:27, 23:25) = num2cell(meandata.spatial.rb(:, :, 2)');

    xlswrite(filename, output4, 'Contrast bubbles');
end

                        elf_support_logmsg('      Statistics written to <a href="matlab:winopen(''%s'')">%s</a>\n', filename, filename);

warning('on', 'MATLAB:xlswrite:AddSheet');

return

end % main
