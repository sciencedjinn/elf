function [w_im, h_im] = elf_project_cart2fisheye(X, Y, Z, I_info, method, rotation)
% ELF_PROJECT_CART2FISHEYE takes Cartesian coordinates and projects them onto a fisheye image.
% The output index vectors can be used to reproject a fisheye image onto a sphere.
%
% [w_im, h_im] = elf_project_cart2fisheye(X, Y, Z, I_info, method)
%
% Inputs:
% X, Y, Z    - Cartesian grids defining the desired grid of the projected image
% I_info     - Image information structure (only uses Height, Width, FocalLength and Model)
% method     - The desired fisheye projection. Currently supports 'equisolid'(e.g. D810)/'orthographic'/'equidistant'
% rotation   - Angle (in degrees) by which the image should be rotated clockwise before processing (Use 90 or -90 for portrait images)
%
% Outputs:
% w_im, h_im - same size as X/Y/Z, and contain the corresponding image coordinates along image width and height, respectively

if nargin<6 || isempty(rotation), rotation = 0; end
if nargin<5 || isempty(method), method = 'default'; end

theta       = acosd(X);         % theta is the angle between a viewing direction and the X-axis (X is equal to the scalar dot product of that direction and the X-axis)
gamma       = atan2d(-Z, Y)-rotation;     % gamma is the angle between the Y/Z projection of a viewing direction and the Y axis; the -Z makes sure that high elevation values are mapped onto a low image index

mid         = [1+(I_info.Height-1)/2; 1+(I_info.Width-1)/2];        % centre of image, % Reminder: Images have their horizontal axis as the SECOND coordinate
shortSide   = min([I_info.Height I_info.Width]);

switch method
    case 'equidistant'
        r = 1946;                                                   % radius of the circular fisheye-lens image if it was 90 degrees (measured from image?)
        r2 = theta * r / 90; %r2 should be negative for azi < 0

        w_im = r2 .* cosd(gamma) + mid(2); %
        h_im = r2 .* sind(gamma) + mid(1); %this seems ok
        
    case {'equisolid', 'default'}
        r = I_info.FocalLength * shortSide / 24;  % theoretical value for 24mm chip with 8mm focal length
        switch lower(I_info.Model{1})
            case 'nikon d3x'
                % measured (imellipse)
                mid = [2023.5 3031.5];
                % r = 1963.7
                
                % theory: mid = [2016.5 3024.5];
                % 1344*2*sind(45) = 1900
                corr = 1.02;    % empirical correction factor for Nikon camera; from lasertest (provides good fit except for last point (90 degrees)
            case 'nikon d800e'
                % mid = [2476.5 3681.0]; measured from function
                % mid = [2487.7 3680.5]; % measured by hand (imellipse) %COMMENTED OUT 25/03/2015
                warning('No spatial calibration available for Nikon D800E. Using an estimated calibration for an equisolid projection.');
                corr = 1.02;
            case {'nikon d810', 'nikon d850'}
                corr = 1;
                
            case 'canon eos-1ds mark ii'
                mid = [1677.9 2510]; % approximately the same for small circle
                % r = 1551; measured for hopkins
                corr = 0.96; % for hopkins
                warning('No calibration available for Canon EOS-1Ds Mark II. Using an estimated calibration for an equisolid projection.');
            case 'nikon d5300'
                warning('No calibration available for this camera (%s) and lens. Using an estimated calibration for an equisolid projection.', I_info.Model{1});
                corr = 1.35;
            otherwise
                warning('No spatial calibration available for this camera (%s) and lens. Assuming perfect equisolid projection on full size chip', I_info.Model{1});
                corr = 1;
        end
       
        r = corr * r;
        % Reminder: Matlab images have their horizontal axis as the SECOND coordinate       
        r2 = 2 * r * sind(theta/2); % equisolid projection

        w_im = r2 .* cosd(gamma) + mid(2); % along w; this is 0 + mid for azimuth 0
        h_im = r2 .* sind(gamma) + mid(1); % along h; this is 0 + mid for elevation 0, and -1 + mid for elevation 90
                       
    case 'orthographic'
        r = 1946; % radius of the circular fisheye-lens image if it was 90 degrees (measured from image?)

        % This assumes a perfect orthographic projection ( R ~ sin(th) )
        % Along the horizon, an azimuth of theta will be imaged on a pixel ~sin(theta)
        
        % Calculate projection of image pixels
        % Algorithm:
        % x = r * cos(ele_deg) * cos(azi_deg); y = r * cos(ele_deg) * sin(azi_deg); z = r * sin(ele_deg)
        % For example, for elevation 0:
        % x = r * cos(azi_deg); y = r * sin(azi_deg); z = 0;
        % Reminder: Matlab images have their horizontal axis as the SECOND coordinate
     
        h_im = Z*r + mid(1); % 1st image coordinate, vertical
        w_im = Y*r + mid(2); % 2nd image coordinate, horizontal
        
    otherwise
        
end

