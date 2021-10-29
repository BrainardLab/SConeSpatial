function [] = OpenProjectorPlainScreen(projectorDisplayColor,options)
% This displays a plain screen on the projector using Psychtoolbox.
%
% Syntax: [] = OpenProjectorPlainScreen(setProjectorDisplayColor)
%
% Description:
%    This displays a plain screen with a desired color on the projector
%    screen. This function should be used wherever it needs to display and
%    measure the projector including calibration, additivity check, etc.
%
% Inputs:
%    projectorDisplayColor -      Desired color to display on the
%                                 projector. This should be in format of
%                                 3x1 matrix, and each column should be in
%                                 the range from 0 (black) to 1 (white).
%                                 Each column respectively matches 
%                                 red, green, and blue channels.
%
% Outputs:
%    N/A
%
% Optional key/value pairs:
%    'projectorToolboxPath' -     Path to the Vpixx control toolbox.  We
%                                 add this to the Matlab path if it isn't
%                                 already there.  This doesn't need to be
%                                 right if the toolbox is already on the
%                                 path.
%    'verbose' -                  Boolean. Default true.  Controls the printout.
%
% History:
%    10/28/21  smo                Started on it

%% Set parameters.
arguments
    projectorDisplayColor (3,1) {mustBeInRange(projectorDisplayColor,0,1,"inclusive")}
    options.verbose (1,1) = true
    options.projectorToolboxPath = '/home/colorlab/Documents/MATLAB/toolboxes/VPixx';
end

%% Set the default PTB setting. 
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);

% Set white as the default background. The screen will be flipped with the
% desired color with the following command.
white = WhiteIndex(screenNumber);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);

%% Set the color of plain screen on the projector.
Screen('FillRect',window,projectorDisplayColor,windowRect);
Screen('Flip', window);
if (options.verbose)
    fprintf('Projector primary is set to [%.2f, %.2f, %.2f] \n',projectorDisplayColor(1),projectorDisplayColor(2),projectorDisplayColor(3));
end


%% Also make sure we can talk to the subprimaries.
%
% Make sure Vpixx toolbox is on the path and do our best to add it if not.
thePath = path;
isThere = findstr(thePath,[filesep 'VPixx']);
if (isempty(isThere))
    addpath(genpath(options.projectorToolboxPath));
    isThere = findstr(thePath,[filesep 'VPixx']);
    if (isempty(isThere))
        error('Unable to add VPixx toolbox to path. Figure out why not and fix.');
    end
end

% Connect to the Vpixx projector.
isReady = Datapixx('open');
if (~isReady)
    error('Datapixx call returns error');
end
isReady = Datapixx('IsReady');
if (~isReady)
    error('Datapixx call returns error');
end

end