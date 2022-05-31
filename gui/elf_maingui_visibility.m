function elf_maingui_visibility(gui, status)

col = {'r', [0 .5 0], [1 .6 0], 'g', [1 .6 0]};    % colors indicating analysis progress
tooltips = {{'No images were found in this folder.', ...
    'Only raw image files were found in this folder. Please convert them into uncompressed DNG files with Adobe''s DNG-Converter (see ELF manual for instructions).', ...
    'Images were found, but it appears that they were converted to DNG in the wrong way. Please review the conversion instructions (Help->Getting Started...)', ...
    'Usable images were found in this folder (either DNGs or non-raw). Proceed to the next step.', ...
    'Images were found, but an error occurred while reading them. Please refer to the error popup displayed during startup.'}, ...
    {'The images in this data set have not been processed yet. Press this button to start processing.', ...
    'Some, but not all of the images in this data set have been processed. Press this button to start processing.', ...
    'All images in this data set have been filtered, but some of the images have been processed since then. Press this button to re-process all images or proceed to the next step.', ...
    'All images in this data set have been processed. Proceed to the next step or click here to re-process them all.', ...
    ''}, ...
    {'The mean image for this data set has not been calculated yet. Press this button to start calculating.', ...
    '', ...
    'A mean image for this data set has been calculated, but some of the images have been modified or re-processed since then. Press this button to re-calculate the mean image or proceed to the next step.', ...
    'The mean image for this data set has been calculated. Proceed to the next step or click here to re-calculate it.', ...
    ''}, ...
    {'The summary for this data set has not been calculated yet.', ...
    '', ...
    'A summary has been calculated, but some images have been modified or re-processed afterwards. Press this cutton to recalculate the summary.', ...
    'The summary has been calculated and saved for this data set.', ...
    ''}};

% set button colours
for i = 1:size(status, 1)
    set(gui.p(i).b1, 'backgroundcolor', col{status(i, 1)+1}, 'tooltip', tooltips{1}{status(i, 1)+1});
    set(gui.p(i).b2, 'backgroundcolor', col{status(i, 2)+1}, 'tooltip', tooltips{2}{status(i, 2)+1});
    set(gui.p(i).b3, 'backgroundcolor', col{status(i, 3)+1}, 'tooltip', tooltips{3}{status(i, 3)+1});
    set(gui.p(i).b4, 'backgroundcolor', col{status(i, 4)+1}, 'tooltip', tooltips{4}{status(i, 4)+1});
    
    if status(i, 4), en = 'on'; else en = 'off'; end % only enable show button if summary has been calculated
    set(gui.p(i).b6, 'enable', en);
end