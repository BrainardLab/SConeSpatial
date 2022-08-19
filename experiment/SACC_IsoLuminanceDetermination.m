% SACC_IsoLuminanceDetermination
%
% This is for iso-luminance determination for SACC project. Here we display
% simple flicker (red-green) stimuli for observers to adjust the intensity
% of red until the flicker disappears.

% History:
%    08/11/22   smo        - Started on it.
%    08/17/22   smo        - Added a control part to update the intensity of
%                            red light while making red-green flicker.
%    08/18/22   dhb, smo   - Now code is working fine.
%    08/19/22   smo        - Added Gaussian noise on the white background.

%% Initialize.
clear; close all;

%% Open the projector.
initialScreenSettings = [0 0 0]';
projectorMode = true;
[window windowRect] = OpenPlainScreen(initialScreenSettings, 'projectorMode', projectorMode);

%% Set the projector LED channel settings.
%
% Make channel settings.
nPrimaries = 3;
nChannels = 16;
nInputLevels = 256;

% Set which channel to use per each primary. We will use only two
% primaries.
%
% Peak wavelength in order of channel number. Note that it is not ascending
% order.
% [422,448,476,474,506,402,532,552,558,592,610,618,632,418,658,632]
whichChannelPrimary1 = 15;
whichChannelPrimary2 = 5;
whichChannelPrimary3 = [1:16];

channelIntensityPrimary1 = 1;
channelIntensityPrimary2 = 1;
channelIntensityPrimary3 = 1;

channelSettings = zeros(nChannels, nPrimaries);
channelSettings(whichChannelPrimary1, 1) = channelIntensityPrimary1;
channelSettings(whichChannelPrimary2, 2) = channelIntensityPrimary2;
channelSettings(whichChannelPrimary3, 3) = channelIntensityPrimary3;

% Set channel setting here.
SetChannelSettings(channelSettings);

%% Set parameters of the flicker.
%
% Set projector frame rate.
frameRate = 120;
ifi = 1/frameRate;

% Set the flicker frequency .
frequecnyFlicker = 40;
framesPerStim = round((1/frequecnyFlicker)/ifi);

%% Make Gaussian window and normalize its max to one.
%
% Set the window parameters. ScreenPixelsPerDeg is based on the Maxwellian
% view settings for SACC project.
stimulusN = 996;
centerN = stimulusN/2;
gaborSdDeg = 0.75;
screenPixelsPerDeg = 142.1230;
gaborSdPixels = gaborSdDeg * screenPixelsPerDeg;

% Make a gaussian window here.
gaussianWindowBase = zeros(stimulusN, stimulusN, 3);
gaussianWindow = normpdf(MakeRadiusMat(stimulusN,stimulusN,centerN,centerN),0,gaborSdPixels);
gaussianWindowBGBlack = gaussianWindow/max(gaussianWindow(:));
gaussianWindowBGWhite = 1 - gaussianWindowBGBlack;

% Make plain red/green images here.
plainImageBase = zeros(stimulusN, stimulusN, 3);

% Red plain image.
plainImageRed = plainImageBase;
intensityPrimary1 = nInputLevels-1;
plainImageRed(:,:,1) = intensityPrimary1;

% Green plain image.
plainImageGreen = plainImageBase;
intensityPrimary2 = nInputLevels/2;
plainImageGreen(:,:,2) = intensityPrimary2;

% Set primary index to update to make a flicker.
fillColors = {plainImageRed plainImageGreen};
fillColorIndexs = [1 2];
fillColorIndex = 1;

%% Set gamepad settings.
%
% Get the gamepad index for getting response.
gamepadIndex = Gamepad('GetNumGamepads');

% Set parameters for gamepad.
stateButtonUp = false;
stateButtonDown = false;
stateButtonRight = false;
actedUp = false;
actedDown = false;

numButtonUp = 4;
numButtonDown = 2;
numButtonRight = 3;

primaryControlInterval = 1;

%% Start the flicker loop here.
frameCounter = 0;

% Get image windowRect.
centerScreen = [windowRect(3) windowRect(4)] * 0.5;
imageSizeHalf = [size(image,1) size(image,2)] * 0.5;
imageWindowRect = [centerScreen(1)-imageSizeHalf(1) centerScreen(2)-imageSizeHalf(2) ...
    centerScreen(1)+imageSizeHalf(1) centerScreen(2)+imageSizeHalf(2)];

while 1
    
    % End the session if the right button was pressed.
    if (stateButtonRight == false)
        stateButtonRight = Gamepad('GetButton', gamepadIndex, numButtonRight);
        if (stateButtonRight == true)
            fprintf('Finishing up the session... \n');
            break;
        end
    end
    
    % Get a gamepad response here.
    stateButtonUp = Gamepad('GetButton', gamepadIndex, numButtonUp);
    stateButtonDown = Gamepad('GetButton', gamepadIndex, numButtonDown);
    
    % Reset acted on state when button comes back up.
    if (actedUp && ~stateButtonUp)
        actedUp = false;
    end
    if (actedDown && ~stateButtonDown)
        actedDown = false;
    end
    
    % Update the intensity of red light based on the key press above.
    if (stateButtonUp && ~actedUp)
        % Increase the intensity of red light.
        if (intensityPrimary1 < nInputLevels-1)
            intensityPrimary1 = intensityPrimary1 + primaryControlInterval;
        end
        actedUp = true;
        fprintf('Button pressed: (UP)   / Red = (%d), Green = (%d) \n', intensityPrimary1, intensityPrimary2);
        
    elseif (stateButtonDown && ~actedDown)
        % Decrease the intensity of red light.
        if (intensityPrimary1 > 0)
            intensityPrimary1 = intensityPrimary1 - primaryControlInterval;
        end
        actedDown = true;
        fprintf('Button pressed: (DOWN) / Red = (%d), Green = (%d) \n', intensityPrimary1, intensityPrimary2);
    end
    
    % Update the intensity of the red light here.
    fillColors{1}(:,:,1) = intensityPrimary1./(nInputLevels-1);
    
    % Update the fill color at desired frame time.
    if ~mod(frameCounter, framesPerStim)
        fillColorIndex = setdiff(fillColorIndexs, fillColorIndex);
        fillColor = fillColors{fillColorIndex};
    end
    
    % Make and draw image texture.
    fillColor = fillColor + gaussianWindowBGWhite;
    imageTexture = Screen('MakeTexture', window, fillColor);
    Screen('DrawTexture', window, imageTexture, [], imageWindowRect);
    
    % Make a flip.
    Screen('Flip', window);
    
    % Increase frame counter.
    frameCounter = frameCounter + 1;
end

%% Close the screen.
CloseScreen;
