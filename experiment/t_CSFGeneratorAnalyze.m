% t_CSFGeneratorAnalyze.
%
% Syntax:
%    t_CSFGeneratorAnalyze
%
% Description:
%    This is for fitting PF to the data acquired from the experiments.
%
% Inputs:
%    None.
%
% Outputs:
%    None.
%
% Optional key/value pairs:
%    None.
%
% See Also:
%    t_CSFGeneratorExperiment.

% History:
%    02/28/22  smo          - Started on it.
%    03/14/22  smo          - Added a plotting option to make different
%                             marker size over different number of trials.
%    03/16/22  smo          - Added an option to check if Adaptive mode
%                             works fine.
%    06/26/22  smo          - Added a part plotting CSF curves.
%    10/03/22  smo          - Now fitting all spatial frequency at once and
%                             give CSF curve at the same time.

%% Start over.
clear; close all;

%% Set parameters here.
VERBOSE = true;
CHECKADAPTIVEMODE = false;
PF = 'weibull';

subjectName = 'Semin';

%% Load the data and PF fitting.
%
% Set startData to 0 if you want to read the data from the most recent.
sineFreqCyclesPerDeg = [3 6 9 12 18];
nSineFreqCyclesPerDeg = length(sineFreqCyclesPerDeg);

olderDate = 0;
SUBPLOT = true;
sizeSubplot = [2 3];
axisLog = true;

figure; clf; hold on;
for ss = 1:nSineFreqCyclesPerDeg
    
    % Set target spatial frequency.
    sineFreqCyclesPerDegTemp = sineFreqCyclesPerDeg(ss);
    
    % Load the experiment data.
    if (ispref('SpatioSpectralStimulator','TestDataFolder'))
        testFiledir = fullfile(getpref('SpatioSpectralStimulator','TestDataFolder'),...
            subjectName,append(num2str(sineFreqCyclesPerDegTemp),'_cpd'));
        testFilename = GetMostRecentFileName(testFiledir,...
            'CS','olderDate',olderDate);
        theData = load(testFilename);
    else
        error('Cannot find data file');
    end
    
    nDataContrastRange = 1;
    for cc = 1:nDataContrastRange
        % Load the contrast range data.
        if (ispref('SpatioSpectralStimulator','TestDataFolder'))
            testFiledir = fullfile(getpref('SpatioSpectralStimulator','TestDataFolder'),subjectName);
            testFilename = GetMostRecentFileName(testFiledir,...
                sprintf('ContrastRange_%s_%d',subjectName,sineFreqCyclesPerDegTemp), 'olderDate',cc-1);
            theContrastData = load(testFilename);
        else
            error('Cannot find data file');
        end
        
        % Extract the threshold from the initial measurements.
        thresholdInitial(cc,:) = theContrastData.preExpDataStruct.thresholdFoundRawLinear;
    end
    
    % Pull out the data here.
    nTrials = theData.estimator.nRepeat;
    [stimVec, responseVec, structVec] = combineData(theData.estimator);
    
    % Here we will plot the PF fitting graph.
    %
    % Set marker size here. We will use this number to plot the results to
    % have different marker size according to the number of trials. Here
    % we used the same method to decide the size of each marker as
    % 'thresholdMLE' does.
    stimVal = unique(stimVec);
    pCorrect = zeros(1,length(stimVal));
    for idx = 1:length(stimVal)
        prop = responseVec(stimVec == stimVal(idx));
        pCorrect(idx) = sum(prop) / length(prop);
        pointSize(idx) = 10 * 100 / length(stimVec) * length(prop);
    end
    
    thresholdCriterion = 0.81606;
    [threshold, para, dataOut] = theData.estimator.thresholdMLE(...
        'thresholdCriterion', thresholdCriterion, 'returnData', true);
    thresholdsQuest(ss) = threshold;
    
    % Set the contrast levels in linear unit.
    examinedContrastsLinear = 10.^dataOut.examinedContrasts;
    
    % PF fitting here.
    if (SUBPLOT)
        subplot(sizeSubplot(1),sizeSubplot(2),ss); hold on;
    end
    [paramsFitted(:,ss)] = FitPFToData(examinedContrastsLinear, dataOut.pCorrect, ...
        'PF', PF, 'nTrials', nTrials, 'verbose', VERBOSE,...
        'figureWindow', ~SUBPLOT, 'pointSize', pointSize, 'axisLog', axisLog, 'questPara', para);
    subtitle(sprintf('%d cpd',sineFreqCyclesPerDegTemp),'fontsize', 15);

    % Add initial threhold to the plot.
    for cc = 1:nDataContrastRange
        % Plot it on log space if you want.
        if(axisLog)
            thresholdInitial(cc,:) = log10(thresholdInitial(cc,:));
        end
        
        % Plot it here.
        plot([thresholdInitial(cc,1) thresholdInitial(cc,1)], [0 1], 'b-', 'linewidth',3);
        plot([thresholdInitial(cc,2) thresholdInitial(cc,2)], [0 1], 'g--', 'linewidth',3);
    end
    
    % Set xlim differently according to the axis on linear and log space.
    xlim([-3.3 -1]);
    
    % Clear the pointsize for next plot.
    clear pointSize;
end

%% Here we check if the Adaptive mode works fine if you want.
if (CHECKADAPTIVEMODE)
    figure; clf; hold on;
    for ss = 1:nSineFreqCyclesPerDeg
        
        % Set target spatial frequency.
        sineFreqCyclesPerDegTemp = sineFreqCyclesPerDeg(ss);
        
        % Load the data.
        if (ispref('SpatioSpectralStimulator','TestDataFolder'))
            testFiledir = fullfile(getpref('SpatioSpectralStimulator','TestDataFolder'),...
                subjectName,append(num2str(sineFreqCyclesPerDegTemp),'_cpd'));
            testFilename = GetMostRecentFileName(testFiledir,...
                'CS','olderDate',olderDate);
            theData = load(testFilename);
        else
            error('Cannot find data file');
        end
        
        % Set variables here.
        nTrial = theData.estimator.nTrial;
        testTrials = linspace(1,nTrial,nTrial);
        testContrasts = 10.^stimVec;
        testPerformances = {structVec.outcome};
        
        % Set the color of the data point according to the subject's
        % performance. We will differenciate the marker point based on
        % each response either correct of incorrect.
        %
        % In testPerformances, correct response is allocated to 2 and
        % incorrect to 1. We will differenciate the marekr color based on
        % these.
        responseCorrect   = 2;
        responseIncorrect = 1;
        markerColorCorrect   = 5;
        markerColorIncorrect = 10;
        
        for tt = 1:nTrial
            markerFaceColor(1,tt) = testPerformances{tt};
            markerFaceColor(find(markerFaceColor == responseCorrect)) = markerColorCorrect;
            markerFaceColor(find(markerFaceColor == responseIncorrect)) = markerColorIncorrect;
        end
        
        if (SUBPLOT)
            subplot(sizeSubplot(1),sizeSubplot(2),ss); hold on;
        end
        
        % Plot it.
        markerSize = 40;
        scatter(testTrials, testContrasts, markerSize, markerFaceColor, 'filled', 'MarkerEdgeColor', zeros(1,3));
        xlabel('Number of Trials', 'fontsize', 15);
        ylabel('Contrast', 'fontsize', 15);
        title(sprintf('%d cpd',sineFreqCyclesPerDegTemp),'fontsize', 15);
        legend('Blue = correct / Yellow = incorrect','location','northeast','fontsize',15);
        
        clear markerFaceColor;
    end
end

%% Plot the CSF curve here.
CSFCURVE = true;
SUBPLOTCSF = true;

if (CSFCURVE)
    % Export the threshold data.
    thresholds = paramsFitted(1,:);
    
    % Convert NaN to 0 here.
    for tt = 1:length(thresholds)
        if isnan(thresholds(tt))
            thresholds(tt) = 0;
        end
    end
    
    % Calculate sensitivity.
    sensitivityLinear = 1./thresholds;
    sensitivityLog = log10(sensitivityLinear);
    sineFreqCyclesPerDegLog = log10(sineFreqCyclesPerDeg);
    
    sensitivityQuestLinear = 1./(10.^thresholdsQuest);
    sensitivityQuestLog = log10(sensitivityQuestLinear);
    
    % Decide the plot on either subplot or separate figure.
    if (SUBPLOTCSF)
        subplot(sizeSubplot(1), sizeSubplot(2), 6); hold on;
    else
        figure; clf; hold on;
    end
    
    % Plot PF fit CSF curve.
    plot(sineFreqCyclesPerDegLog, sensitivityLog, 'r.-','markersize',20,'linewidth',2);
    % Add Quest fit CSF curve.
    plot(sineFreqCyclesPerDegLog, sensitivityQuestLog, 'k.--','markersize',20,'linewidth',2);
    xlabel('Spatial Frequency (cpd)','fontsize',15);
    ylabel('Contrast Sensitivity','fontsize',15);
    xticks(sineFreqCyclesPerDegLog);
    xticklabels(sineFreqCyclesPerDeg);
    yticks(sort(sensitivityLog));
    yticklabels(sort(round(sensitivityLinear)));
    title('CSF curve','fontsize',15);
    legend(append(subjectName,'-PF'),append(subjectName,'-Quest'),'fontsize',15);
end
