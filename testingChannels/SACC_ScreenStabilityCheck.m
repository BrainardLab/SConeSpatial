% SACC_ScreenStabilityCheck
%
% This tests screen stability for SACC project. It basically measures
% the plain screen repeatedely and
%
% History:
%    11/24/21 smo   Pulled out this part from the old code. It has been
%                     cleaned up using our SACC measurement functions.
%    01/07/22 smo   Added the option skipping the measurement.

%% Initialize.
clear; close all;

%% Set parameters here.
%
% This code basically measures the spectrum of the plain screen
% automatically in a specific time interval.

% Set measurement time length and interval. The time is set in minute unit,
% which will be converted into second unit later in this code.
totalMeasurementTime_min = 60;
timeDelayBeforeEachMeasurement_min = 0.1;

timeDelayBeforeMeasurement_sec = timeDelayBeforeEachMeasurement_min * 60;

% Measurement range.
S = [380 2 201];

% Verbose.
PLOT = true;
MEASURE = false;

%% Make a bit of time delay before the measurement starts.
% You can go out before it's done.
if (MEASURE)
    timeDelayGoOut_sec = 3;
    fprintf('You have %d seconds to go out the room!',timeDelayGoOut_sec);
    for tt = 1:timeDelayGoOut_sec
        pause(1) % Pause for 1 seconds (unit)
    end
    
    %% Make screen and spectroradiometer ready.
    %
    % Open the plain screen. Simply set it as white here. It won't change
    % during the whole measurements.
    screenSettings = [1 1 1];
    OpenPlainScreen(screenSettings,'projectorMode',true,'verbose',PLOT);
    
    % Set channel settings.
    nChannels = 16;
    nPrimaries = 3;
    channelSettings = ones(nChannels,nPrimaries);
    SetChannelSettings(channelSettings);
    
    % Connect to the spectroradiometer. We will use PR670 here.
    OpenSpectroradiometer;
    
    %% Measurements.
    %
    % The number of measurements are calculated based on the total measurement
    % time and time delay interval which were set from the above.
    %
    % +1 is the measurement at the cold state which is right after the screen turned on.
    nMeasurments = (totalMeasurementTime_min / timeDelayBeforeEachMeasurement_min) + 1;
    allSpdMeasured = zeros(S(3),nMeasurments);
    
    % Measure it.
    for i=1:nMeasurments
        
        % Measurement happens here.
        allSpdMeasured(:,i) = MeasureSpectroradiometer;
        
        % Make a delay before next measurement.
        for tt = 1:timeDelayBeforeMeasurement_sec
            % Pause for 1 second in unit.
            pause(1);
        end
    end
else
    % Load the data if the measurement is skipped.
    if (ispref('SpatioSpectralStimulator','CheckDataFolder'))
        testFiledir = getpref('SpatioSpectralStimulator','CheckDataFolder');
        testFilename = GetMostRecentFileName(testFiledir,sprintf('stabilityCheck'),'olderDate',0);
        load(testFilename);
    end
end
%% XYZ calculations
%
% Match the wavelength range.
load T_xyzJuddVos;
T_xyz = SplineCmf(S_xyzJuddVos, 683*T_xyzJuddVos, S);

% Calculate XYZ values.
XYZ = T_xyz * allSpdMeasured;
xyY = XYZToxyY(XYZ);

% Calculate color gamut too.
colorGamut = XYZToxyY(T_xyz);
colorGamut(:,end+1) = colorGamut(:,1);

%% Plot the data.
if (PLOT)
    % Spds.
    figure; clf; hold on;
    plot(SToWls(S),allSpdMeasured);
    xlabel('Wavelenth (nm)','fontsize',15);
    ylabel('Spectral power distribution','fontsize',15);
    legend('Measurements');

    % Luminance.
    figure; clf;
    subplot(2,2,1);
    measurementTime = linspace(0, totalMeasurementTime_min, nMeasurments);
    plot(measurementTime, XYZ(3,:),'r.','markersize',10);
    xlabel('Measurement time (min)','fontsize',15);
    ylabel('Luminance (cd/m2)','fontsize',15);
    ylim([max(XYZ(3,:))*0.8 max(XYZ(3,:))*1.2]);
    legend('Measurements');
    title('Luminance','fontsize',15);
    
    % xy coordiantes.
    subplot(2,2,2); hold on;
    plot(xyY(1,:), xyY(2,:), 'r.','markersize',10);
    plot(colorGamut(1,:),colorGamut(2,:),'k-');
    xlabel('CIE x','fontsize',15);
    ylabel('CIE y','fontsize',15);
    legend('Measurements','Spectral locus');
    title('CIE xy chromaticity','fontsize',15);
    
    % CIE x over the time.
    subplot(2,2,3); hold on;
    plot(measurementTime,xyY(1,:),'r.','markersize',10);
    xlabel('Measurement time (min)','fontsize',15);
    ylabel('CIE x','fontsize',15);
    legend('Measurements');
    title('CIE x','fontsize',15);
    
    % CIE y over the time.
    subplot(2,2,4); hold on;
    plot(measurementTime,xyY(2,:),'r.','markersize',10);
    xlabel('Measurement time (min)','fontsize',15);
    ylabel('CIE y','fontsize',15);
    legend('Measurements');
    title('CIE y','fontsize',15);
end

%% Save the data.
%
% Close the screen and projector.
if (MEASURE)
    CloseScreen;
    CloseSpectroradiometer;
    
    % Save data with the name containing dayTimestr.
    if (ispref('SpatioSpectralStimulator','CheckDataFolder'))
        testFiledir = getpref('SpatioSpectralStimulator','CheckDataFolder');
        dayTimestr = datestr(now,'yyyy-mm-dd_HH-MM-SS');
        testFilename = fullfile(testFiledir,sprintf('stabilityCheck_%s',dayTimestr));
        save(testFilename,'allSpdMeasured','XYZ','xyY','colorGamut','nMeasurements', ...
            'totalMeasurementTime_min','timeDelayBeforeEachMeasurement_min','S');
    end
end