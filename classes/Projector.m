classdef Projector
    % PROJECTOR represents a circular fisheye/hemispherical image and contains the image and projection data
    %
    % Call sequence: elf -> elf_main1_HdrAndInt -> FisheyeImage
    %
    % See also: Calibrator, Projector

    properties(SetAccess=immutable)
        Data
        Height
        Width
        SamplesPerChannel
        ProjectionType
        XCorr(1,1) double = 0 % correction for centre in X (width) (obtained from calibration for imperfect lens)
        YCorr(1,1) double = 0 % correction for centre in Y (height) (obtained from calibration for imperfect lens)
        RCorr(1,1) double = 1 % correction multiplier for R (obtained from calibration for imperfect lens)
    end

    properties(Access=protected)
        MidPoint % Image centre in x/y
        PixPerMM
        CorrFocalLength
    end
    
    %%%%%%%%%%%%%%%%%
    %% CONSTRUCTOR %%
    %%%%%%%%%%%%%%%%%
    methods
        function obj = Projector(I_info, projInfo)
            %CALIBRATOR Construct an instance of this class
            %   Detailed explanation goes here
            % Inputs:
            %   camString   - camera model (can be extracted from info.Model or infoSum.Model)
            %   wh          - width and height of images (can be extracted from info.Width and info.Height)
            %   projInfo - needs fields ChipWidth, 
            % ChipHeight, 
            % RCorr, >1: Image circle greater than expected from focal length
            % WCorr, 
            % HCorr

            Logger.log(LogLevel.INFO, 'Creating a Projector object for %s camera\n', I_info.Model{1})

            obj.Height = I_info.Height;
            obj.Width = I_info.Width;
            obj.SamplesPerChannel = I_info.SamplesPerPixel;
            obj.ProjectionType = projInfo.Type;

            shortSide = min([I_info.Height I_info.Width]);
            chipShortSide = min([projInfo.ChipHeight projInfo.ChipWidth]);

            obj.PixPerMM = shortSide / chipShortSide;
            obj.CorrFocalLength = I_info.FocalLength * projInfo.RCorr;   
            obj.MidPoint = [(I_info.Height+1)/2+projInfo.HCorr; (I_info.Width+1)/2+projInfo.WCorr];        % centre of image
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% PROJECTION CORE FUNCTIONS %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function theta_deg = r2theta(obj, R_mm)
            % angle between point in the real world and the optical axis
            switch obj.ProjectionType
                case {"equisolid", "default"}
                    theta_deg = 2 * asind(R_mm / 2 / obj.CorrFocalLength);
                case "equidistant"
                    theta_deg = rad2deg(R_mm / obj.CorrFocalLength);
                case "stereographic"
                    theta_deg = 2 * atand(R_mm / 2 / obj.CorrFocalLength);
                case "orthographic"
                    theta_deg = asind(R_mm / obj.CorrFocalLength);
                otherwise
                    error('Unknown method')
            end
        end

        function R_mm = theta2r(obj, theta_deg)
            switch obj.ProjectionType
                case {"equisolid", "default"}
                    R_mm = 2 * obj.CorrFocalLength * sind(theta_deg / 2);
                case "equidistant"
                    R_mm = obj.CorrFocalLength * deg2rad(theta_deg);
                case "stereographic"
                    R_mm = 2 * obj.CorrFocalLength * tand(theta_deg / 2);
                case "orthographic"
                    R_mm = obj.CorrFocalLength * sind(theta_deg);
                otherwise
                    error('Unknown method')
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% RE-PROJECTION FUNCTIONS %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Input/Outputs for all methods
    % w, h     - x/y image coordinatesin pixels, e.g. defining the desired grid of a projected image along image width and height, respectively
    % X, Y, Z  - cartesian coordinates in arbitrary units, e.g. on a unit sphere surrounding the camera
    % azi, ele - azimuth/elevation in degrees
    % rotation - angle (in degrees) by which the image should be rotated clockwise before processing (Use 90 or -90 for portrait images)
    
    methods
        function [X, Y, Z] = pix2cart(obj, w, h, rotation)
            % PIX2CART translates w/h pixel positions into X,Y,Z on a unit sphere
            %
            % Usage example:
            % [w_grid, h_grid] = meshgrid(1:I_info.Width, 1:I_info.Height);
            % [X, Y, Z] = obj.pix2cart(w_grid, h_grid)

            if nargin<4 || isempty(rotation), rotation=0; end

            h_rel = h-obj.MidPoint(1);
            w_rel = w-obj.MidPoint(2);
            R_pix = sqrt(h_rel.^2 + w_rel.^2); % each point's radial excentricity on the sensor (in pixels)
            R_mm  = R_pix / obj.PixPerMM;      % each point's radial excentricity on the sensor (in mm)
            gamma = atan2d(h_rel, w_rel) - rotation;

            theta_deg = obj.r2theta(R_mm);

            r_yz = sind(theta_deg);
            r_yz(~isreal(r_yz)) = NaN; % set to NaN some points far out of the image circle
            r_yz = real(r_yz);

            X = cosd(theta_deg);
            Y = r_yz .* cosd(gamma);
            Z = r_yz .* -sind(gamma); % This minus makes sure that low image indices are mapped onto high-elevation points 
        end

        function [w, h] = cart2pix(obj, X, Y, Z, rotation, roundIt)
            % CART2PIX translates X/Y/Z positions into w/h pixel positions in the image
            %
            % [w_grid, h_grid] = meshgrid(1:I_info.Width, 1:I_info.Height);
            % [X, Y, Z] = obj.pix2cart(w_grid, h_grid)

            if nargin<6 || isempty(roundIt), roundIt=true; end
            if nargin<5 || isempty(rotation), rotation=0; end

            theta_deg = acosd(X);               % theta is the angle between a viewing direction and the X-axis (X is equal to the scalar dot product of that direction and the X-axis)
            gamma     = atan2d(-Z, Y)-rotation; % gamma is the angle between the Y/Z projection of a viewing direction and the Y axis; the -Z makes sure that high elevation values are mapped onto a low image index
            R_mm      = obj.theta2r(theta_deg);
            R_pix     = R_mm * obj.PixPerMM;
            w         = R_pix .* cosd(gamma) + obj.MidPoint(2); % along w; this is 0 + mid for azimuth 0
            h         = R_pix .* sind(gamma) + obj.MidPoint(1); % along h; this is 0 + mid for elevation 0, and -1 + mid for elevation 90
            if roundIt
                w = round(w);
                h = round(h);
            end
        end

        function [azi, ele] = pix2rect(obj, w, h, rotation)
            % PIX2RECT translates w/h pixel positions in the image into azimuth/elevation
            %
            % Usage example:
            % [w_grid, h_grid]  = meshgrid(1:I_info.Width, 1:I_info.Height);
            % [azi, ele]        = obj.pix2rect(w_grid, h_grid)

            if nargin<4 || isempty(rotation), rotation=0; end
            [X, Y, Z]           = obj.pix2cart(w, h, rotation);
            [azi_rad, ele_rad]  = cart2sph(X, Y, Z);
            azi                 = rad2deg(azi_rad);
            ele                 = rad2deg(ele_rad);
        end

        function [w, h] = rect2pix(obj, azi, ele, rotation)
            % RECT2PIX translates azimuth/elevation into w/h pixel positions
            %
            % Usage example:
            % [azi_grid, ele_grid] = meshgrid(-90:0.1:90, 90:-0.1:-90);
            % [w, h] = obj.rect2pix(azi_grid, ele_grid)

            if nargin<4 || isempty(rotation), rotation=0; end
            [X, Y, Z]    = sph2cart(deg2rad(azi), deg2rad(ele), 1);
            [w, h]       = obj.cart2pix(X, Y, Z, rotation);
        end

        function I_info = getProjectionInfo(obj, I_info, azi, ele, rotation)
            % GETPROJECTIONINFO creates a grids for plotting
            %
            % Inputs:
            % I_info     - Image information structure to write grids to % TODO: Make it a substruct
            % azi, ele   - output angle ranges defining the desired grid of the projected images (default -90:0.1:90, and 90:-0.1:-90)
            %
            % Outputs:
            % I_info          - Image information structure with projection grids added. These can be used in plotting.

            % Uses: elf_project_rect2fisheye, which uses Projector.sub2ind

            if nargin<6 || isempty(rotation), rotation = 0; end
            if nargin<5 || isempty(ele), ele = 90:-0.1:-90; end
            if nargin<4 || isempty(azi), azi = -90:0.1:90; end

            Logger.log(LogLevel.INFO, '\tCalculating projection grids...\n');

            %% parameters
            gridres1 = 10;  % resolution of the displayed grid between lines
            gridres2 = 1;   % resolution of the displayed grid along lines

            %% Calculate grids for plotting
            % a) grid for original projection
            [gazi1, gele1]       = meshgrid(-90:gridres1:90, -90:gridres2:90);
            [gazi2, gele2]       = meshgrid(-90:gridres2:90, -90:gridres1:90);
            gazi2                = gazi2';
            gele2                = gele2';

            %  Link all grid lines into a single NaN clipped vector
            r                    = size(gazi1, 1);
            gazi1(r+1, :)        = NaN;
            gele1(r+1, :)        = NaN;
            r                    = size(gazi2, 1);
            gazi2(r+1, :)        = NaN;
            gele2(r+1, :)        = NaN;
            gazi                 = [gazi1(:); gazi2(:)];
            gele                 = [gele1(:); gele2(:)];

            [I_info.ori_grid_x, I_info.ori_grid_y] = obj.rect2pix(gazi, gele, rotation);

            % b) grid for projected image (assumes that grid points are included in image grid)
            [~, I_info.proj_grid_x] = ismember(gazi, azi);
            [~, I_info.proj_grid_y] = ismember(gele, ele);
            I_info.proj_grid_x(I_info.proj_grid_x==0) = NaN;    % 0 indicates the element was not found
            I_info.proj_grid_y(I_info.proj_grid_y==0) = NaN;

            I_info.proj_azi      = azi;
            I_info.proj_ele      = ele;

            Logger.log(LogLevel.INFO, '\t\tdone.\n')
        end

        function projection_ind = calculateProjection(obj, azi, ele, rotation)
            % CALCULATEPROJECTION creates a projection index vector to transform a fisheye image into a equirectangular (azimuth/elevation) grid
            %
            % Inputs:
            % azi, ele   - output angle ranges defining the desired grid of the projected images (default -90:0.1:90, and 90:-0.1:-90)
            %
            % Outputs:
            % projection_ind  - projections index matrix. The projected image can be calculated as im_proj = im(projection_ind)

            if nargin<4 || isempty(rotation), rotation = 0; end
            if nargin<3 || isempty(ele), ele = 90:-0.1:-90; end
            if nargin<2 || isempty(azi), azi = -90:0.1:90; end

            Logger.log(LogLevel.INFO, '\tCalculating projection constants...\n');
            [azi_grid, ele_grid] = meshgrid(azi, ele);                    % grid of desired angles
            [w_im, h_im]         = obj.rect2pix(azi_grid, ele_grid, rotation);
            projection_ind       = obj.sub2ind([obj.Height obj.Width obj.SamplesPerChannel], w_im, h_im);
            Logger.log(LogLevel.INFO, '\t\tdone.\n');
        end

        function projection_ind = calculateBackProjection(obj, azi, ele, rotation)
            % CALCULATEBACKPROJECTION creates a projection index vector to transform an equirectangular image back to a fisheye image
            %
            % Inputs:
            % azi, ele   - output angle ranges defining the grid of the equirectangular images (default -90:0.1:90, and 90:-0.1:-90)
            %
            % Outputs:
            % projection_ind  - projections index matrix. The projected image can be calculated as im_proj = im(projection_ind)

            if nargin<4 || isempty(rotation), rotation = 0; end
            if nargin<3 || isempty(ele), ele = 90:-0.1:-90; end
            if nargin<2 || isempty(azi), azi = -90:0.1:90; end

            %% Calculate azi/ele sampling
            if length(unique(round(1./diff(azi))))>1, error('azi MUST be evenly sampled.'); else, azires = mean(diff(azi)); end
            if length(unique(round(1./diff(ele))))>1, error('ele MUST be evenly sampled.'); else, eleres = mean(diff(ele)); end
            
            %% Calculate main projections   
            Logger.log(LogLevel.INFO, '\tCalculating projection constants...\n');     
            [w_grid, h_grid]         = meshgrid(1:obj.Width, 1:obj.Height);          % grid of desired output image coordinates
            [target_azi, target_ele] = obj.pix2rect(w_grid, h_grid, rotation);   % TODO: Replace with Projector.pix2rect
            % calculate azi/ele index vectors
            azi_ind                  = (target_azi - azi(1)) / azires + 1;
            ele_ind                  = (target_ele - ele(1)) / eleres + 1;
            % remove out-of-bounds azi and ele pairs
            sel                      = target_azi>max(azi) | target_azi<min(azi) | target_ele>max(ele) | target_ele<min(ele);
            azi_ind(sel)             = NaN; 
            ele_ind(sel)             = NaN;
            % and create linear index vector
            projection_ind           = obj.sub2ind([length(ele) length(azi) obj.SamplesPerChannel], azi_ind, ele_ind);
            Logger.log(LogLevel.INFO, '\t\tdone.\n');
        end

        function im_fisheye = fastBackProjection(obj, im, azi, ele, rotation, method)
            % FASTBACKPROJECTION takes a equirectangular image and project it back to an equisolid fisheye image.
            %
            % Inputs:
            % im             - MxNxC double, the equirectangular image to be transformed
            % azi, ele       - Azimuth/elevation vectors IN DEGREES defining the x and y axes of im, respectively
            % rotation       - Angle (in degrees) by which the image should be rotated before processing (Use 90 or -90 for portrait images)
            % method         - 'interpolate' (default): projects each equirectangular pixel into fisheye space, and then interpolates using griddata
            %                  'nearestneighbour':      projects each fisheye pixel onto equirectangular space, and them samples the nearest pixel
            %
            % Outputs:
            % im_proj        - Output fisheye image

            if nargin < 6 || isempty(method), method = 'default'; end
            if nargin < 5 || isempty(rotation), rotation = 0; end
            if nargin < 4 || isempty(ele), ele = linspace(-90, 90, size(im, 1)); end
            if nargin < 3 || isempty(azi), azi = linspace(-90, 90, size(im, 2)); end

            switch method
                case {'interpolate', 'interp', 'default'}
                    [azi_grid, ele_grid]    = meshgrid(azi, ele);                                   % grid of desired angles
                    [w_im, h_im]            = obj.rect2pix(azi_grid, ele_grid, -rotation);
                    [w_grid, h_grid]        = meshgrid(1:obj.Width, 1:obj.Height);   % grid of desired output pixels

                    im_fisheye              = zeros(obj.Height, obj.Width, obj.SamplesPerChannel); % pre-allocate
                    for ch = 1:obj.SamplesPerChannel % for each channel
                        thisch               = im(:, :, ch);
                        warning('off', 'MATLAB:griddata:DuplicateDataPoints');
                        im_fisheye(:, :, ch) = griddata(h_im(:), w_im(:), thisch(:), h_grid, w_grid, 'cubic'); %#ok<GRIDD>
                        warning('on', 'MATLAB:griddata:DuplicateDataPoints');

                        %% Alternative: scatteredInterpolant version, which is a LOT slower (~10x), but gives the same results
                        %             F = scatteredInterpolant(y_im(:), x_im(:), thisch(:));
                        %             im_fisheye(:, :, ch) = F(y_grid, x_grid);
                    end
                    im_fisheye = obj.blackout(im_fisheye); % set points beyond 90 degrees to 0
                case {'nearestneighbour', 'nn', 'nearestpixel'}
                    projection_ind           = calculateBackProjection(azi, ele, rotation);
                    im_temp                  = Projector.apply(im, projection_ind, [obj.Height, obj.Width, obj.SamplesPerChannel]);
                    im_fisheye               = obj.blackout(im_temp);
            end
        end

        function im = blackout(obj, im, excLimit, zerovalue)
            % BLACKOUT takes a fisheye image and sets all image point beyond a certain excentricity (default 90 degrees) to 0 or NaN
                        
            if nargin<4 || isempty(zerovalue), zerovalue = 0; end
            if nargin<3 || isempty(excLimit), excLimit = 90; end
            
            [w, h]      = meshgrid(1:obj.Width, 1:obj.Height);
            r           = sqrt((h-obj.MidPoint(1)).^2 + (w-obj.MidPoint(2)).^2);
            R_mm        = r / obj.PixPerMM;
            theta_deg   = obj.r2theta(R_mm);
            sel         = theta_deg>excLimit;
            tempim      = cell(obj.SamplesPerChannel, 1);
            for i = 1:obj.SamplesPerChannel
                tempim{i} = im(:, :, i); 
                tempim{i}(sel) = zerovalue;
            end
            im = cat(3, tempim{:});
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% STATIC HELPER FUNCTIONS %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Static)
        function im = apply(im, proj_ind, imsize)
            % PROJECTOR.APPLY applies a linear index vector ind to a three-dimensional matrix (image).
            % Use this for quick reprojection of images.
            %
            % Inputs:
            % im            - image to unwarp
            % ind           - linear index vector into the first two dimensions of im (obtained from Projector.sub2ind)
            % imsize        - 3x1 double, size of the output image
            %
            % Outputs:
            % im            - projections index matrix. The projected image can be calculated as im_proj = im(projection_ind)
            %
            % Example:  % TODO: Replace with Projector-based example
            % imsize_fisheye = [I_info.Height I_info.Width I_info.SamplesPerPixel];
            % [x_im, y_im]   = elf_project_rect2fisheye(az, el, I_info, method);
            % ind            = Projector.sub2ind(imsize_fisheye, x_im, y_im)
            % imsize_rect    = [length(ele) length(azi) I_info.SamplesPerPixel];
            % im             = Projector.apply(im, ind, imsize_rect)

            sel = isnan(proj_ind); 
            proj_ind(sel) = 1; % NaNs in the projection index indicate invalid points. Remove for now, and set to NaN later
            im_temp = im(proj_ind); % index image
            im_temp(sel) = NaN; % now set invalid points to NaN
            im = reshape(im_temp, imsize); % and reshape back into an image
        end

        function ind = sub2ind(imsize, w_im, h_im)
            % PROJECTOR.SUB2IND turns x/y subscript index vectors into a linear index vector ind for a three-dimensional matrix
            % Use this for quick reprojection of images.
            %
            % Inputs:
            % imsize            - 3x1 double, size of the image to be sampled
            % w_im, h_im        - image coordinates obtained from Projector.rect2pix
            %
            % Outputs:
            % projection_ind    - projections index matrix. The projected image can be calculated as im_proj = im(projection_ind)
            %
            % Example:
            % imsize       = [I_info.Height I_info.Width I_info.SamplesPerPixel];
            % [w_im, h_im] = elf_project_rect2fisheye(az, el, I_info, method);
            % ind          = Projector.sub2ind(imsize, x_im, y_im)
            
            %% calculate linear index vector for projection
            ind1    = repmat(round(h_im(:)), imsize(3), 1); % repeat three times to call for each channel
            ind2    = repmat(round(w_im(:)), imsize(3), 1); % repeat three times to call for each channel
            ind3    = reshape(repmat(1:imsize(3), length(w_im(:)), 1), [], 1);
            
            sel = isnan(ind1) | isnan(ind2);
            ind1(sel) = 1;
            ind2(sel) = 1;
            
            ind     = sub2ind(imsize, ind1, ind2, ind3);    % transform into linear indexes

            ind(sel) = NaN;
        end

        function ind = sub2ind4(imsize, w_im, h_im, n_im)
            % PROJECTOR.SUB2IND4 is the 4D version of PROJECTOR.SUB2IND and can be used on a whole image stack
            % n_im              - 4th image coordinate obtained from stitch_5dirs
            
            %% calculate linear index vector for projection
            ind1    = repmat(round(h_im(:)), imsize(3), 1); % repeat three times to call for each channel
            ind2    = repmat(round(w_im(:)), imsize(3), 1); % repeat three times to call for each channel
            ind3    = reshape(repmat(1:imsize(3), length(w_im(:)), 1), [], 1);
            ind4    = repmat(n_im(:), imsize(3), 1);
            
            ind1(ind1>imsize(1)) = NaN;
            ind2(ind2>imsize(2)) = NaN;
            ind1(ind1<1) = NaN;
            ind2(ind2<1) = NaN;
            
            ind     = sub2ind(imsize, ind1, ind2, ind3, ind4);    % transform into linear indexes
        end
    end
end