function [xfit, yfit, R, a] = elf_project_findcircle(I, verbose)

% fn = 'J:\Data and Documents\data\2014 VEPS test data\Kohagar_rev_2septkl1300\_D3x1011.dng';
% I  = elf_io_imread(fn);

% Define thresholds for channel 1 based on histogram settings
channelMin = 500;

% Create mask based on chosen histogram thresholds
BW = I(:,:,1) >= channelMin & I(:,:,2) >= channelMin & I(:,:,3) >= channelMin;

% find all edges
E = edge(BW);
[x,y] = find(E);

% remove anything unreasonable
cx = size(I, 1)/2+0.5;
cy = size(I, 2)/2+0.5;
d = sqrt((x-cx).^2+(y-cy).^2);

maxr = size(I, 1)/2;
unreasonable = d > maxr | d < 0.90*maxr;

x_reas = x(~unreasonable);
y_reas = y(~unreasonable);
s2i = sub2ind(size(I), x(unreasonable), y(unreasonable));
E(s2i) = 0;
%
[xfit, yfit, R, a] = circfit(x_reas, y_reas);

fprintf('assumed:  %g / %g\n measured: %g / %g\nradius:   %g\n\n', cx, cy, xfit, yfit,R);
%% plotting
if verbose
    figure(11);clf;
    elf_plot_image(I, [], 11);hold on;
    rectangle('position',[yfit-R,xfit-R,R*2,R*2],'curvature',[1,1],'linestyle','-','edgecolor','r');
    rectangle('position',[cy-maxr,cx-maxr,maxr*2,maxr*2],'curvature',[1,1],'linestyle','-','edgecolor','b');
    
    figure(12); clf;
    imagesc(BW); colormap(gray)
    axis image
    
    figure(13); clf;
    imagesc(E); colormap(gray)
    hold on;
    plot(yfit, xfit, 'rx');
    rectangle('position',[yfit-R,xfit-R,R*2,R*2],'curvature',[1,1],'linestyle','-','edgecolor','r');
    axis image

end