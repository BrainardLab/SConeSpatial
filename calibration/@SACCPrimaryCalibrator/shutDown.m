% Method to shutdown the device
function obj = shutDown(obj)
if (obj.options.verbosity > 9)
    fprintf('In SACCPrimary.shutDown() method\n');
end

%% Here put all the subprimaries back into a fairly normal state.
% Normal mode, and some reasonable R, G, and B subprimary values.
%
% Make a matrix for setting up the subprimary settings.
subprimaryClosingSettings = zeros(obj.nSubprimaries,obj.nPrimaries); % Base matrix for subprimary settings. 
idxSubprimaryTurnOnDefault = [13 14 15 ; 5 6 7; 1 2 3]; % Default settings when turning on the projector (0 is for matching size of the matrix).
for pp = 1:obj.nPrimaries
    for ii = 1:size(idxSubprimaryTurnOnDefault,2)
        subprimaryClosingSettings(idxSubprimaryTurnOnDefault(pp,ii),pp) = 1;
    end
end

% Set subprimary settings here.
SetSubprimarySettings(subprimaryClosingSettings,'projectorMode',true);

% Close everything.
CloseProjectorScreen;

end