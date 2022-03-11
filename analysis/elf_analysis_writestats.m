function elf_analysis_writestats(meandata, filename)
% ELF_ANALYSIS_WRITESTATS writes everything that was previously calculated by elf_analysis_datasetmean into a csv file for later analysis.
%
%   Example:
%   elf_analysis_writestats(meandata, para)  
%
% Inputs: 
% meandata          - 1 x 1 structure array, containing the mean results structure (created earlier by elf_analysis_datasetmean)
% filename          - filename to save data to
%
% Outputs:
% None.
%
% Uses:       None
% Used by:    elf_main3_intsummary
% Call stack: elf_main3_intsummary -> elf_analysis_datasetmean
% See also:   elf_main3_intsummary, elf_analysis

    if exist(filename, 'file')
        delete(filename)
    end
    
    dti = meandata.totalint;
    di = meandata.int;
    
    outTable = table(["red"; "green"; "blue"; "white"], dti.mean', dti.std', dti.median', dti.perc25', dti.perc75', dti.min', dti.max', dti.percmin', dti.percmax');
    outTable.Properties.VariableNames = {'channel', 'mean', 'std', 'median', '25th percentile', '75th percentile', 'min', 'max', '2.5th percentile', '97.5th percentile'};
    writetable(outTable, filename);
    
    outTable2 = array2table([dti.region_meanele(:), di.means', di.std', di.median', di.perc25', di.perc75', di.min', di.max', di.percmin', di.percmax']);
    outTable2.Properties.VariableNames = {'elevation', ...
                        'mean R',        'mean G',        'mean B',        'mean W', ...
                        'std R',         'std G',         'std B',         'std W', ...
                        'median R',      'median G',      'median B',      'median W', ...
                        '25th perc R',   '25th perc G',   '25th perc B',   '25th perc W', ...
                        '75th perc R',   '75th perc G',   '75th perc B',   '75th perc W', ...
                        'min R',         'min G',         'min B',         'min W', ...
                        'max R',         'max G',         'max B',         'max W', ...
                        '2.5th perc R',  '2.5th perc G',  '2.5th perc B',  '2.5th perc W', ...
                        '97.5th perc R', '97.5th perc G', '97.5th perc B', '97.5th perc W'};
    writetable(outTable2, filename, 'WriteMode', 'append', 'WriteVariableNames', true);
    
                            elf_support_logmsg('      Statistics written to <a href="matlab:winopen(''%s'')">%s</a>\n', filename, filename);
end
