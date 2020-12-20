function im = elf_project_blackout(im, exclimit, exc, zerovalue)
% ELF_PROJECT_BLACKOUT takes a fisheye image and sets all image point beyond a certain excentricity (default 90 degrees) to 0 or NaN 
%
% If no excentricitry function is given, the function assumes that the image is from a full-frame sensor with a Sigma 8mm fisheye lens

[Height, Width, spp] = size(im);

if nargin<4 || isempty(zerovalue), zerovalue = 0; end
if nargin<3 || isempty(exc), 
    mid         = [1+(Height-1)/2; 1+(Width-1)/2];        % centre of image
    shortSide   = min([Height Width]);
    r_full      = 8 * shortSide / 24;                     % theoretical value for 24mm high chip that is fully covered by fisheye circular image
    [y, x]      = meshgrid(1:Width, 1:Height);
    r           = sqrt((x-mid(1)).^2 + (y-mid(2)).^2);
    exc         = asind(r / 2 / r_full) * 2;
end
if nargin<2 || isempty(exclimit), exclimit = 90; end

sel     = exc>exclimit;
tempim  = cell(spp, 1);
for i = 1:spp
    tempim{i}      = im(:, :, i); tempim{i}(sel) = zerovalue;
end
im      = cat(3, tempim{:});
