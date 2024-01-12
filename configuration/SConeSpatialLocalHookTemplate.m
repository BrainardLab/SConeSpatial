function SConeSpatialLocalHook
% SConeSpatialLocalHook
%
% Configure things for working on the SConeSpatial project.
%
% For use with the ToolboxToolbox.  If you copy this into your
% ToolboxToolbox localToolboxHooks directory (by default,
% ~/localToolboxHooks) and delete "LocalHooksTemplate" from the filename,
% this will get run when you execute tbUseProject('SConeSpatial') to set up for
% this project.  You then edit your local copy to match your configuration.
%
% You will need to edit the project location and i/o directory locations
% to match what is true on your computer.

%% Define project
projectName = 'SConeSpatial';

%% Say hello
fprintf('Running %s local hook\n',projectName);

%% Clear out old preferences
if (ispref(projectName))
    rmpref(projectName);
end

%% Specify project location
projectBaseDir = tbLocateProject(projectName);

% If we ever needed some user/machine specific preferences, this is one way
% we could do that.
sysInfo = GetComputerInfo();
switch (sysInfo.localHostName)
    otherwise
        % Some unspecified machine, try user specific customization
        switch(sysInfo.userShortName)
            % Could put user specific things in, but at the moment generic
            % is good enough.
     
            case 'colorlab'
                % SCONSFA desktop (Linux)
                userNameDropbox = 'Mela Nopsin';
                baseDir = fullfile('/home/',sysInfo.userShortName,'Aguirre-Brainard Lab Dropbox',userNameDropbox);
                
            otherwise
                if ismac
                    dbJsonConfigFile = '~/.dropbox/info.json';
                    fid = fopen(dbJsonConfigFile);
                    raw = fread(fid,inf);
                    str = char(raw');
                    fclose(fid);
                    val = jsondecode(str);
                    baseDir = val.business.path;
                end
        end
end

%% Project prefs
setpref(projectName,'LEDSpectraDir',fullfile(baseDir,'SCON_materials','JandJProjector','LEDSpectrumMeasurements'));

% Calibration
setpref('BrainardLabToolbox','CalDataFolder',fullfile(baseDir,'SCON_materials','Calibration'));

% Data dir
setpref(projectName,'TestDataFolder',fullfile(baseDir,'SCON_datadev','TestData'));

% Main experiment data dir (as of 10/14/22)
setpref(projectName,'SCONData',fullfile(baseDir,'SCON_data'));

% Experiment analysis data dir (as of 10/19/22)
setpref(projectName,'SCONAnalysis',fullfile(baseDir,'SCON_analysis'));

% Check data dir (This is for screen stability and channel additivity data)
setpref(projectName,'CheckDataFolder',fullfile(baseDir,'SCON_materials','JandJProjector','CheckData'));
setpref(projectName,'CheckDataFolderSACC',fullfile(baseDir,'SCON_materials','FromSACCMeasurements','JandJProjector','CheckData'));

% SCON materials.
setpref(projectName,'SCONMaterials',fullfile(baseDir,'SCON_materials'));

% David's melanopsion work
setpref(projectName,'SCONMelanopsin',fullfile(baseDir,'SCON_melanopsin'));

% New experiment analysis data dir (as of 10/03/23).
setpref(projectName,'SCONAnalysisRefit',fullfile(baseDir,'SCON_analysis_refit'));

% We will save the final results in this directory (as of 10/13/23).
setpref(projectName,'SCONAnalysisFinal',fullfile(baseDir,'SCON_analysis_final'));

