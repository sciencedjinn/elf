function info = elf_info_load(fullfilename)
% ELF_INFO_LOAD loads EXIF information for an image file and returns it as a struct.
% If information for a particular filetype is in a different spot than in a DNG, it should be copied over in this function. 
%
% info = elf_info_load(fullfilename)

temp = warning('off', 'MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero'); % happens with cr2
warning('off', 'imageio:tifftagsread:expectedTagDataFormat');
info = imfinfo(fullfilename); % get exif info
warning(temp); % turn warnings back on

[~,~,ext] = fileparts(fullfilename); % using info.Format does not work for raw files, as they are usually tif format

switch lower(ext(2:end))
    case {'tif', 'tiff'}
        info = info(1);
        info.ColorMatrix2       = 0;
    case {'jpg', 'jpeg'}
        info.BitsPerSample      = ones(1, info.NumberOfSamples) * info.BitDepth / info.NumberOfSamples;
        info.SamplesPerPixel    = info.NumberOfSamples;
        info.ColorMatrix2       = 0;
    case 'dng'
        % DNGs have only thumbnail info in the main info structure.
        % Copy all fields from info.SubIFDs to info.
        fieldstocopy = fieldnames(info.SubIFDs{1});
        for i = 1:length(fieldstocopy)
            info.(fieldstocopy{i}) = info.SubIFDs{1}.(fieldstocopy{i});
        end
        % get correct size and channel number
        info.Width              = info.DefaultCropSize(1);
        info.Height             = info.DefaultCropSize(2);
        info.SamplesPerPixel    = 3;
    case 'nef'
        %same as dng, but the info seems to be in SubIFDs{2}
        fieldstocopy = fieldnames(info.SubIFDs{2});
        for i = 1:length(fieldstocopy)
            info.(fieldstocopy{i}) = info.SubIFDs{2}.(fieldstocopy{i});
        end
    case 'cr2'
        %same as dng, but the info seems to be in SubIFDs{2}
        info = info(1); %FIXME
%         fieldstocopy = fieldnames(info.SubIFDs{2});
%         for i = 1:length(fieldstocopy)
%             info.(fieldstocopy{i}) = info.SubIFDs{2}.(fieldstocopy{i});
%         end
    otherwise
        warning('Unknown format: If fields in the EXIF data are different from TIF, errors will occur. In that case, please create an entry in elf_info_load.m for this image format.');
end

% Examine bit depth
if length(unique(info.BitsPerSample)) > 1
    error(['Channels have different bit depths: ' num2str(info.BitsPerSample)]);
else
    info.bpc = info.BitsPerSample(1); %just one number for bits per channel
end
     
% set variable type depending on bit depth
switch info.bpc
    case 8
        info.class='uint8';
    case {12, 14, 16}
        info.class='uint16';
    case 32
        info.class='uint32';
    otherwise
        error(['ELF currently does not know how to process ' num2str(info.bpc) '-bit images']);
end



%% Example jpg
% Filename: 'J:\Data and Documents\data\2014 VEPS test data\Kostallar_vintern_2013\D3X_1189.jpg'
%          FileModDate: '04-Jun-2013 08:56:26'
%             FileSize: 6636795
%               Format: 'jpg'
%        FormatVersion: ''
%                Width: 6048
%               Height: 4032
%             BitDepth: 24
%            ColorType: 'truecolor'
%      FormatSignature: ''
%      NumberOfSamples: 3
%         CodingMethod: 'Huffman'
%        CodingProcess: 'Sequential'
%              Comment: {'AppleMark'}
%                 Make: 'NIKON CORPORATION'
%                Model: 'NIKON D3X'
%          Orientation: 1
%          XResolution: 72
%          YResolution: 72
%       ResolutionUnit: 'Inch'
%             Software: 'QuickTime 7.7.1'
%             DateTime: '2013:06:04 08:56:26'
%         HostComputer: 'Mac OS X 10.7.5'
%     YCbCrPositioning: 'Centered'
%        DigitalCamera: [1x1 struct]
%        ExifThumbnail: [1x1 struct]
        
%% Example tif (can be very different)
%         Filename: 'J:\Data and Documents\data\2014 VEPS test data\Kohagar_mam_29augkl1530\_D3X0930.tif'
%                   FileModDate: '13-Mar-2014 09:48:44'
%                      FileSize: 146337214
%                        Format: 'tif'
%                 FormatVersion: []
%                         Width: 6048
%                        Height: 4032
%                      BitDepth: 48
%                     ColorType: 'truecolor'
%               FormatSignature: [73 73 42 0]
%                     ByteOrder: 'little-endian'
%                NewSubFileType: 0
%                 BitsPerSample: [16 16 16]
%                   Compression: 'Uncompressed'
%     PhotometricInterpretation: 'RGB'
%                  StripOffsets: 23998
%               SamplesPerPixel: 3
%                  RowsPerStrip: 4032
%               StripByteCounts: 146313216
%                   XResolution: 300
%                   YResolution: 300
%                ResolutionUnit: 'Inch'
%                      Colormap: []
%           PlanarConfiguration: 'Chunky'
%                     TileWidth: []
%                    TileLength: []
%                   TileOffsets: []
%                TileByteCounts: []
%                   Orientation: 1
%                     FillOrder: 1
%              GrayResponseUnit: 0.0100
%                MaxSampleValue: [65535 65535 65535]
%                MinSampleValue: [0 0 0]
%                  Thresholding: 1
%                        Offset: 8
%                          Make: 'NIKON CORPORATION'
%                         Model: 'NIKON D3X'
%                      Software: 'Adobe Photoshop Camera Raw 8.3 (Macintosh)'
%                      DateTime: '2014:03:13 10:48:43'
%                           XMP: '<?xpacket begin="???" id="W5M0MpCehiHzreSzNTczkc9d"?>
% <x:xmpmeta xmlns:x="adobe:ns:meta/...'
%                          ITPC: [1x16 double]
%                     Photoshop: [1x12190 double]
%                 DigitalCamera: [1x1 struct]
%              ICCProfileOffset: 22846

%% Example dng
%                      Filename: 'J:\Data and Documents\data\2014 VEPS test data\f8_45cm_resolution\_D3X2211.dng'
%                   FileModDate: '07-Mar-2014 15:33:46'
%                      FileSize: 18045868
%                        Format: 'tif'
%                 FormatVersion: []
%                         Width: 256
%                        Height: 171
%                      BitDepth: 24
%                     ColorType: 'truecolor'
%               FormatSignature: [73 73 42 0]
%                     ByteOrder: 'little-endian'
%                NewSubFileType: 1
%                 BitsPerSample: [8 8 8]
%                   Compression: 'Uncompressed'
%     PhotometricInterpretation: 'RGB'
%                  StripOffsets: 122840
%               SamplesPerPixel: 3
%                  RowsPerStrip: 171
%               StripByteCounts: 131328
%                   XResolution: []
%                   YResolution: []
%                ResolutionUnit: 'Inch'
%                      Colormap: []
%           PlanarConfiguration: 'Chunky'
%                     TileWidth: []
%                    TileLength: []
%                   TileOffsets: []
%                TileByteCounts: []
%                   Orientation: 1
%                     FillOrder: 1
%              GrayResponseUnit: 0.0100
%                MaxSampleValue: [255 255 255]
%                MinSampleValue: [0 0 0]
%                  Thresholding: 1
%                        Offset: 8
%                          Make: 'NIKON CORPORATION'
%                         Model: 'NIKON D3X'
%                      Software: 'Adobe Photoshop Camera Raw 8.3 (Macintosh)'
%                      DateTime: '2014:03:07 12:23:50'
%                       SubIFDs: {[1x1 struct]  [1x1 struct]}
%                           XMP: '<?xpacket begin="???" id="W5M0MpCehiHzreSzNTczkc9d"?>
% <x:xmpmeta xmlns:x="adobe:ns:meta/...'
%                 DigitalCamera: [1x1 struct]
%                    DNGVersion: [1 4 0 0]
%            DNGBackwardVersion: [1 1 0 0]
%             UniqueCameraModel: 'Nikon D3X'
%                  ColorMatrix1: [0.8213 -0.3151 0.0011 -0.6594 1.3688 0.3236 -0.1101 0.1577 0.7803]
%                  ColorMatrix2: [0.7171 -0.1986 -0.0648 -0.8085 1.5555 0.2718 -0.2170 0.2512 0.7457]
%            CameraCalibration1: [1 0 0 0 1 0 0 0 1]
%            CameraCalibration2: [1 0 0 0 1 0 0 0 1]
%                 AnalogBalance: [1 1 1]
%                 AsShotNeutral: [0.4163 1 0.8050]
%              BaselineExposure: 0.2500
%                 BaselineNoise: 0.9000
%             BaselineSharpness: 1.2000
%            LinearResponseUnit: 1
%            CameraSerialNumber: '5005356'
%                      LensInfo: [8 8 3.5000 3.5000]
%                   ShadowScale: 1
%                DNGPrivateData: [1x52002 double]
%        CalibrationIlluminant1: 17
%        CalibrationIlluminant2: 21
%            AliasLayerMetadata: [84 146 150 73 72 67 93 76 128 236 119 93 80 223 250 186]
%           OriginalRawFileName: '_D3X2211.NEF'
%                   UnknownTags: [17x1 struct]

%% Example CR2 info(1)
%                        Filename: 'J:\Data and Documents\data\2014 VEPS test data\UW Hopkins MS April 06\XB1S3663.CR2'
%                     FileModDate: '30-Apr-2006 22:55:54'
%                        FileSize: 14580806
%                          Format: 'tif'
%                   FormatVersion: []
%                           Width: 1536
%                          Height: 1024
%                        BitDepth: 24
%                       ColorType: -1
%                 FormatSignature: [73 73 42 0]
%                       ByteOrder: 'little-endian'
%                  NewSubFileType: 0
%                   BitsPerSample: [8 8 8]
%                     Compression: 'OJPEG'
%       PhotometricInterpretation: []
%                    StripOffsets: 10084
%                 SamplesPerPixel: 1
%                    RowsPerStrip: 4.2950e+09
%                 StripByteCounts: 371615
%                     XResolution: 72
%                     YResolution: 72
%                  ResolutionUnit: 'Inch'
%                        Colormap: []
%             PlanarConfiguration: 'Chunky'
%                       TileWidth: []
%                      TileLength: []
%                     TileOffsets: []
%                  TileByteCounts: []
%                     Orientation: 1
%                       FillOrder: 1
%                GrayResponseUnit: 0.0100
%                  MaxSampleValue: [255 255 255]
%                  MinSampleValue: [0 0 0]
%                    Thresholding: 1
%                          Offset: 16
%                            Make: 'Canon'
%                           Model: 'Canon EOS-1Ds Mark II'
%                        DateTime: '2006:04:30 15:55:52'
%           JPEGInterchangeFormat: []
%     JPEGInterchangeFormatLength: []
%                   DigitalCamera: [1x1 struct]
%                     UnknownTags: []
