% CameraContrastRealtime.
%
% This captures the real time camera image and calculate the contrast from
% the targeted area of the image.

% History:
%    06/13/23    smo     - Cleaned up from the old script.
%    08/31/23    smo     - Moved to project repository as Trombone laptop
%                          is now able to use git.
%    11/29/23    smo     - Parts were subsituted with function.

%% Initialize.
clear; close all; clc;

%% Open camera.
vid = OpenCamera;

%% Capture image and calculate contrast.
%
% Repeat this part to update the contrast calculation results on the camera
% preview screen. It is not 100% real-time measurements, but works pretty
% fast.
%
% Clear text on the camera preview. This would make sort of real-time
% measurement by updating the numbers.
fig = gcf;
textObjects = findall(fig,'Type','text');
delete(textObjects);

% Control exposure time. 
% Default = 10000. Set it higher number for brighter
% image.
src = getselectedsource(vid);

% Set it differently over the channel. This value was found when we turn on
% a single channel of combi-LED in input setting of 0.5 intensity (0-1).
% numChannel = 5;
switch numChannel
    case 1
    src.ExposureTime = 27000;
    case 2
        src.ExposureTime = 45000;
        case 3
        src.ExposureTime = 40000;
        case 4
        src.ExposureTime = 58000;
        case 5
        src.ExposureTime = 21000;
        case 6
        src.ExposureTime = 210000;
        case 7
        src.ExposureTime = 47000;
        case 8
        src.ExposureTime = 47000;    
        otherwise
        % Default = 10000.
        src.ExposureTime = 10000;     
end

% Save a camera image. We will calculate the contrast from still image.
start(vid);
image = getdata(vid);
imagesize = size(image);
pixelHeight = imagesize(1);
pixelWidth = imagesize(2);

% Save the raw image here for saving it later.
imageRaw = image(1:pixelHeight,1:pixelWidth);

% Get the targeted area of the image. 
a = (0.5-ratioHeight/2)*pixelHeight;
b = (0.5+ratioHeight/2)*pixelHeight;
c = (0.5-ratioWidth/2)*pixelWidth;
d = (0.5+ratioWidth/2)*pixelWidth;
imageCrop = image(a:b,c:d);
[Ypixel_crop Xpixel_crop] = size(imageCrop);

% Crop the targeted area in the image.
imagecrop_25 = imageCrop(round(0.25*Ypixel_crop),:);
imagecrop_50 = imageCrop(round(0.50*Ypixel_crop),:);
imagecrop_75 = imageCrop(round(0.75*Ypixel_crop),:);
imagecrop_avg = mean([imagecrop_25;imagecrop_50;imagecrop_75]);

% Calculate contrast.
white = max(imagecrop_avg);
black = min(imagecrop_avg);
contrast = (white-black)/(white+black);
fprintf('Contrast = (%.2f) \n', contrast);

% Show contrast on the camera preview.
textContrast = append('Contrast:  ',num2str(round(contrast,2)));
text(1.05*imWidth*markerindex, 1*imHeight*markerindex, textContrast, 'Color','w');

% Show spatial frequency.
%
% Set minimum peak distance here for not having multiple peaks at one peak
% point. Followings are recommendation over different spatial frequency.
% 
% minPeakDistance = 5 (9, 12 ,18 cpd), 17 (6 cpd), 40 (3 cpd).
minPeakDistance = 40;

% Show the peaks found. Visually check.
figPeak = figure; findpeaks(double(imagecrop_50),'MinPeakDistance',minPeakDistance)

% Calculate the spatial frequency here.
[~,peakIndex] = findpeaks(double(imagecrop_50),'MinPeakDistance',minPeakDistance);
numCycles = length(peakIndex);

% Get the horizontal size of cropped image in degrees.
pixelToInchHorizontal = 0.0367;
pixelToInchVertical = 0.0362;
physicalDistnaceRefInch = 370;
cropImageHalfInch = pixelToInchHorizontal * (Xpixel_crop/2);
sizeDegHorizontal = 2*(rad2deg(atan(cropImageHalfInch/physicalDistnaceRefInch)));

% When the cropped image was 309 x 166 pixels.
% sizeDegHorizontal = 1.7570;

% Calculate the cpd here.
cyclesPerDeg = numCycles/sizeDegHorizontal;
fprintf('Spatial frequency = (%.1f) \n', cyclesPerDeg);

% Add spatial frequency on the camera preview.
textCyclesPerDeg = append('Spatial frequency:  ',num2str(round(cyclesPerDeg,0)));
text(1.05*imWidth*markerindex, 1.1*imHeight*markerindex, textCyclesPerDeg,'Color','w');

% Save the image if you want.
SAVEIMAGE = false;
if (SAVEIMAGE)
    testfileDir = 'C:\Users\brainardlab\Desktop\0905';
    testfileDir = fullfile(testfileDir,append('Ch',num2str(numChannel)));
    cyclesPerDegStr = 'single_focused_';
    fileNameRawImage = fullfile(testfileDir,append(cyclesPerDegStr,'raw_'));
    fileNameCropImage = fullfile(testfileDir,append(cyclesPerDegStr,'crop_'));
    dayTimeStr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
    imwrite(imageCrop,append(fileNameCropImage,dayTimeStr,'.tiff'));
    imwrite(imageRaw,append(fileNameRawImage,dayTimeStr,'.tiff'));
    disp('Image has been saved successfully!');
end
