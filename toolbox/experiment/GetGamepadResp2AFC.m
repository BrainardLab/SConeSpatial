function [buttonPress] = GetGamepadResp2AFC(options)
% Get button responses from gamepad for 2-AFC task.
%
% Syntax:
%    [bttnPress] = GetGamepadResp2AFC()
%
% Description:
%    This function get responses from 2 buttons from the gamepad and
%    returns a 1 or 2 output response. The buttons can be defined as
%    key/value pairs. Default is set to 1 for (Y) button / 2 for (A) button.
%
% Inputs:
%    N/A
%
% Output:
%    buttonPress -       The recorded button press corresponding to the button
%                        mapping. It either gives 1 or 2.
%
% Optional key/value pairs:
%    numButtonUp -       The button number on the gamepad corresponding to
%                        the first interval. Default "Y" on Longitech F310.
%    numButtonDown -     The button number on the gamepad corresponding to
%                        the second interval. Default "A" on Longitech F310.
%    verbose -           Default to true. Print out more status messages.

% History:
%    01/20/22  MAB       Started.
%    02/08/22  smo       Modified it to use for SACC project.

%% Set parameters.
arguments
    options.numButtonUp (1,1) = 4
    options.numBurronDown (1,1) = 2
    options.pauseTime (1,1) = 0
    options.verbose (1,1) = true
end

%% Get a button response here.
%
% Say hello.
if (options.verbose)
    disp('Waiting for a button to be pressed...');
end

% Get the gamepad info.
gamepadIndex = Gamepad('GetNumGamepads');

% Get a button press here till either Up or Down button is pressed.
buttonStateUp = false;
buttonStateDown = false;
while (buttonStateUp == false && buttonStateDown == false)
    buttonStateUp   = Gamepad('GetButton', gamepadIndex, options.numButtonUp);
    buttonStateDown = Gamepad('GetButton', gamepadIndex, options.numBurronDown);
end

% Convert the logical to number either 1 or 2 based on the button press.
selectImgFirst  = 1;
selectImgSecond = 2;
if (buttonStateUp == true)
    buttonPress = selectImgFirst;
    selectImg = 'First';
elseif (buttonStateDown == true)
    buttonPress = selectImgSecond;
    selectImg = 'Second';
else
    error('Button should be pressed either first (1) or second (2) image!');
end

% Print out which image was selected.
if (options.verbose)
    fprintf('(%s) image has been selected!',selectImg);
    
% Pause if you want.
pause(options.pauseTime);

end
