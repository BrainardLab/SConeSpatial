% SpectralCalCompute
%
% Explore spectral fits with swubprimaries, this
% version using the calibration structures.
%

% History:
%    4/22/2020  Started on it

%% Clear
clear; close all;

%% Verbose?
%
% Set to true to get more output
VERBOSE = false;

% Set wavelength support.
%
% This needs to match what's in the calibration files, but
% we need it before we read those files.  A mismatch will
% throw an error below.
S = [380 2 201];

%% Set key stimulus parameters
%
%
% Condition Name
conditionName = 'LminusMSmooth';
switch (conditionName)
    case 'LminusMSmooth'
        % Background xy.
        %
        % Specify the chromaticity, but we'll chose the luminance based
        % on the range available in the device.
        targetBgxy = [0.3127 0.3290]';

        % Target color direction and max contrasts.
        %
        % This is the basic desired modulation direction positive excursion. We go
        % equally in positive and negative directions.  Make this unit vector
        % length, as that is good convention for contrast.
        targetStimulusContrastDir = [1 -1 0]'; targetStimulusContrastDir = targetStimulusContrastDir/norm(targetStimulusContrastDir);

        % Specify desired primary properties.
        %
        % These are the target contrasts for the three primaries. We want these to
        % span a triangle around the line specified above. Here we define that
        % triangle by hand.  May need a little fussing for other directions, and
        % might be able to autocompute good choices.
        targetProjectorPrimaryContrastDir(:,1) = [-1 1 0]'; targetProjectorPrimaryContrastDir(:,1) = targetProjectorPrimaryContrastDir(:,1)/norm(targetProjectorPrimaryContrastDir(:,1));
        targetProjectorPrimaryContrastDir(:,2) = [1 -1 0.5]'; targetProjectorPrimaryContrastDir(:,2) = targetProjectorPrimaryContrastDir(:,2)/norm(targetProjectorPrimaryContrastDir(:,2));
        targetProjectorPrimaryContrastDir(:,3) = [1 -1 -0.5]'; targetProjectorPrimaryContrastDir(:,3) = targetProjectorPrimaryContrastDir(:,3)/norm(targetProjectorPrimaryContrastDir(:,3));

        % Set parameters for getting desired target primaries.
        targetProjectorPrimaryContrasts = [0.05 0.05 0.05];
        targetPrimaryHeadroom = 1.05;
        primaryHeadroom = 0;
        targetLambda = 3;

        % We may not need the whole direction contrast excursion. Specify max
        % contrast we want relative to that direction vector.
        % The first number is
        % the amount we want to use, the second has a little headroom so we don't
        % run into numerical error at the edges. The second number is used when
        % defining the three primaries, the first when computing desired weights on
        % the primaries.
        spatialGaborTargetContrast = 0.04;
        plotAxisLimit = 100*spatialGaborTargetContrast;

        % Set up basis to try to keep spectra close to.
        %
        % This is how we enforce a smoothness or other constraint
        % on the spectra.  What happens in the routine that finds
        % primaries is that there is a weighted error term that tries to
        % maximize the projection onto a passed basis set.
        basisType = 'fourier';
        nFourierBases = 7;
        switch (basisType)
            case 'cieday'
                load B_cieday
                B_naturalRaw = SplineSpd(S_cieday,B_cieday,S);
            case 'fourier'
                B_naturalRaw = MakeFourierBasis(S,nFourierBases);
            otherwise
                error('Unknown basis set specified');
        end
        B_natural{1} = B_naturalRaw;
        B_natural{2} = B_naturalRaw;
        B_natural{3} = B_naturalRaw;

    case 'ConeIsolating'
        % Background xy.
        %
        % Specify the chromaticity, but we'll chose the luminance based
        % on the range available in the device.
        targetBgxy = [0.3127 0.3290]';

        % Target color direction and max contrasts.
        %
        % This is the basic desired modulation direction positive excursion. We go
        % equally in positive and negative directions.  Make this unit vector
        % length, as that is good convention for contrast.
        targetStimulusContrastDir = [1 -1 0]'; targetStimulusContrastDir = targetStimulusContrastDir/norm(targetStimulusContrastDir);

        % Specify desired primary properties.
        %
        % These are the target contrasts for the three primaries. We want these to
        % span a triangle around the line specified above. Here we define that
        % triangle by hand.  May need a little fussing for other directions, and
        % might be able to autocompute good choices.
        targetProjectorPrimaryContrastDir(:,1) = [1 0 0]'; targetProjectorPrimaryContrastDir(:,1) = targetProjectorPrimaryContrastDir(:,1)/norm(targetProjectorPrimaryContrastDir(:,1));
        targetProjectorPrimaryContrastDir(:,2) = [0 1 0]'; targetProjectorPrimaryContrastDir(:,2) = targetProjectorPrimaryContrastDir(:,2)/norm(targetProjectorPrimaryContrastDir(:,2));
        targetProjectorPrimaryContrastDir(:,3) = [0 0 1]'; targetProjectorPrimaryContrastDir(:,3) = targetProjectorPrimaryContrastDir(:,3)/norm(targetProjectorPrimaryContrastDir(:,3));

        % Set parameters for getting desired target primaries.
        targetProjectorPrimaryContrasts = [0.03 0.03 0.03];
        targetPrimaryHeadroom = 1;
        primaryHeadroom = 0.01;
        targetLambda = 3;

        % We may not need the whole direction contrast excursion. Specify max
        % contrast we want relative to that direction vector.
        % The first number is
        % the amount we want to use, the second has a little headroom so we don't
        % run into numerical error at the edges. The second number is used when
        % defining the three primaries, the first when computing desired weights on
        % the primaries.
        spatialGaborTargetContrast = 0.04;
        plotAxisLimit = 100*spatialGaborTargetContrast;

        % Set up basis to try to keep spectra close to.
        %
        % This is how we enforce a smoothness or other constraint
        % on the spectra.  What happens in the routine that finds
        % primaries is that there is a weighted error term that tries to
        % maximize the projection onto a passed basis set.
        basisType = 'fourier';
        nFourierBases = 7;
        switch (basisType)
            case 'cieday'
                load B_cieday
                B_naturalRaw = SplineSpd(S_cieday,B_cieday,S);
            case 'fourier'
                B_naturalRaw = MakeFourierBasis(S,nFourierBases);
            otherwise
                error('Unknown basis set specified');
        end
        B_natural{1} = B_naturalRaw;
        B_natural{2} = B_naturalRaw;
        B_natural{3} = B_naturalRaw;

end

%% Define calibration filenames/params.
%
% This is a standard calibration file for the DLP projector,
% with the subprimaries set to something.  As we'll see below,
% we're going to rewrite those.nPrimaries
projectorCalName = 'SACC';
projectorNInputLevels = 256;

% These are the calibration files for each of the primaries, which
% then entails measuring the spectra of all the subprimaries for that
% primary.
subprimaryCalNames = {'SACCPrimary1' 'SACCPrimary2' 'SACCPrimary3'};
subprimaryNInputLevels = 253;

%% Load projector calibration and refit its gamma
projectorCal = LoadCalFile(projectorCalName);
projectorCalObj = ObjectToHandleCalOrCalStruct(projectorCal);
gammaMethod = 'identity';
projectorCalObj.set('gamma.fitType',gammaMethod);
CalibrateFitGamma(projectorCalObj, projectorNInputLevels);

%% Load subprimary calibrations.
nPrimaries = 3;
subprimaryCals = cell(nPrimaries ,1);
subprimaryCalObjs = cell(nPrimaries ,1);
for cc = 1:length(subprimaryCalNames)
    subprimaryCals{cc} = LoadCalFile(subprimaryCalNames{cc});
    subprimaryCalObjs{cc} = ObjectToHandleCalOrCalStruct(subprimaryCals{cc});
    CalibrateFitGamma(subprimaryCalObjs{cc}, subprimaryNInputLevels);
end

%% Get out some data to work with.
%
% This is from the subprimary calibration file.
Scheck = subprimaryCalObjs{1}.get('S');
if (any(S ~= Scheck))
    error('Mismatch between calibration file S and that specified at top');
end
wls = SToWls(S);
nSubprimaries = subprimaryCalObjs{1}.get('nDevices');

%% Cone fundamentals and XYZ CMFs.
psiParamsStruct.coneParams = DefaultConeParams('cie_asano');
psiParamsStruct.coneParams.fieldSizeDegrees = 2;
T_cones = ComputeObserverFundamentals(psiParamsStruct.coneParams,S);
load T_xyzJuddVos % Judd-Vos XYZ Color matching function
T_xyz = SplineCmf(S_xyzJuddVos,683*T_xyzJuddVos,S);

%% Let's look at little at the subprimary calibration.
%
% Eventually this will be handled by the analyze program,
% when it is generalized for more than three primaries.  But
% we are impatient people so we will hack something up here.
PLOT_SUBPRIMARYINVARIANCE = false;
if (PLOT_SUBPRIMARYINVARIANCE)
    gammaMeasurements = subprimaryCals{1}.rawData.gammaCurveMeanMeasurements;
    [~,nMeas,~] = size(gammaMeasurements);
    for pp = 1:nSubprimaries
        maxSpd = squeeze(gammaMeasurements(pp,end,:));
        figure;
        subplot(1,2,1); hold on;
        plot(wls,maxSpd,'r','LineWidth',3);
        for mm = 1:nMeas-1
            temp = squeeze(gammaMeasurements(pp,mm,:));
            plot(wls,temp,'k','LineWidth',1);
        end
        subplot(1,2,2); hold on
        plot(wls,maxSpd,'r','LineWidth',3);
        for mm = 1:nMeas-1
            temp = squeeze(gammaMeasurements(pp,mm,:));
            scaleFactor = temp\maxSpd;
            plot(wls,scaleFactor*temp,'k','LineWidth',1);
        end
    end
end

%% Plot subprimary gamma functions.
PLOT_SUBPRIMARYGAMMA = false;
if (PLOT_SUBPRIMARYGAMMA)
    for pp = 1:nSubprimaries
        figure; hold on;
        plot(subprimaryCals{1}.rawData.gammaInput,subprimaryCals{1}.rawData.gammaTable(:,pp),'ko','MarkerSize',12,'MarkerFaceColor','k');
        plot(gammaInput,gammaTable(:,pp),'k','LineWidth',2);
    end
end

%% Plot x,y if desired.
PLOT_SUBPRIMARYCHROMATICITY = false;
if (PLOT_SUBPRIMARYCHROMATICITY)
    figure; hold on;
    for pp = 1:nSubprimaries
        for mm = 1:nMeas
            % XYZ calculation for each measurement
            spd_temp = squeeze(gammaMeasurements(pp,mm,:));
            XYZ_temp = T_xyz*spd_temp;
            xyY_temp = XYZToxyY(XYZ_temp);

            plot(xyY_temp(1,:),xyY_temp(2,:),'r.','Markersize',10); % Coordinates of the subprimary
            xlabel('CIE x');
            ylabel('CIE y');
        end
    end

    % Add spectrum locus to plot, connected end to end
    colorgamut=XYZToxyY(T_xyz);
    colorgamut(:,end+1)=colorgamut(:,1);
    plot(colorgamut(1,:),colorgamut(2,:),'k-');
end

%% Image spatial parameters.
sineFreqCyclesPerImage = 6;
gaborSdImageFraction = 0.1;

% Image size in pixels
imageN = 512;

%% Get half on spectrum.
%
% This is useful for scaling things reasonably - we start with half of the
% available range of the primaries.
halfOnSubprimaries = 0.5*ones(nSubprimaries,1);
halfOnSpd = PrimaryToSpd(subprimaryCalObjs{1},halfOnSubprimaries);

%% Make sure gamma correction behaves well with unquantized conversion.
%
% This is just a check, not a computational step we need.
SetGammaMethod(subprimaryCalObjs{1},0);
halfOnSettings = PrimaryToSettings(subprimaryCalObjs{1},halfOnSubprimaries);
halfOnPrimariesChk = SettingsToPrimary(subprimaryCalObjs{1},halfOnSettings);
if (max(abs(halfOnSubprimaries-halfOnPrimariesChk)) > 1e-8)
    error('Gamma self-inversion not sufficiently precise');
end

%% Use quantized conversion from here on.
%
% Comment in the line that refits the gamma to see
% effects of extreme quantization one what follows.
%
% CalibrateFitGamma(subprimaryCalObjs{1},10);
subprimaryGammaMethod = 2;
SetGammaMethod(subprimaryCalObjs{1},subprimaryGammaMethod);
SetGammaMethod(subprimaryCalObjs{2},subprimaryGammaMethod);
SetGammaMethod(subprimaryCalObjs{3},subprimaryGammaMethod);

%% Use extant machinery to get primaries from spectrum.
%
% This isn't used in our calculations.  Any difference in the
% two lines here reflects a bug in the SpdToPrimary/PrimaryToSpd pair.
if (VERBOSE)
    halfOnPrimariesChk = SpdToPrimary(subprimaryCalObjs{1},halfOnSpd);
    halfOnSpdChk = PrimaryToSpd(subprimaryCalObjs{1},halfOnPrimariesChk);
    figure; hold on;
    plot(wls,halfOnSpd,'r','LineWidth',3);
    plot(wls,halfOnSpdChk,'k','LineWidth',1);

    % Show effect of quantization.
    %
    % It's very small at the nominal 253 levels of the subprimaries, but will
    % increase if you refit the gamma functios to a small number of levels.
    halfOnPrimariesChk = SpdToPrimary(subprimaryCalObjs{1},halfOnSpd);
    halfOnSettingsChk = PrimaryToSettings(subprimaryCalObjs{1},halfOnPrimariesChk);
    halfOnPrimariesChk1 = SettingsToPrimary(subprimaryCalObjs{1},halfOnSettingsChk);
    halfOnSpdChk1 = PrimaryToSpd(subprimaryCalObjs{1},halfOnPrimariesChk1);
    plot(wls,halfOnSpdChk1,'g','LineWidth',1);
end

% Define wavelength range that will be used to enforce the smoothnes
% through the projection onto an underlying basis set.  We don't the whole
% visible spectrum as putting weights on the extrema where people are not
% sensitive costs us smoothness in the spectral region we care most about.
lowProjectWl = 400;
highProjectWl = 700;
projectIndices = find(wls > lowProjectWl & wls < highProjectWl);

%% Find background primaries to acheive desired xy at intensity scale of display.
%
% Set parameters for getting desired background primaries.
primaryHeadRoom = 0;
targetLambda = 3;
targetBgXYZ = xyYToXYZ([targetBgxy ; 1]);

% Adjust these to keep background in gamut
primaryBackgroundScaleFactor = 0.5;
projectorBackgroundScaleFactor = 0.5;

% Make a loop for getting background for all primaries.
% Passing true for key 'Scale' causes these to be scaled reasonably
% relative to gamut, which is why we can set the target luminance
% arbitrarily to 1 just above. The scale factor determines where in the
% approximate subprimary gamut we aim the background at.
for pp = 1:nPrimaries
    [subprimaryBackgroundPrimaries(:,pp),subprimaryBackgroundSpd(:,pp),subprimaryBackgroundXYZ(:,pp)] = FindBgChannelPrimaries(targetBgXYZ,T_xyz,subprimaryCalObjs{pp}, ...
        B_natural{pp},projectIndices,primaryHeadRoom,targetLambda,'scaleFactor',0.6,'Scale',true,'Verbose',true);
end
if (any(subprimaryBackgroundPrimaries < 0) | any(subprimaryBackgroundPrimaries > 1))
    error('Oops - primaries should always be between 0 and 1');
end
fprintf('Background primary min: %0.2f, max: %0.2f, mean: %0.2f\n', ...
    min(subprimaryBackgroundPrimaries(:)),max(subprimaryBackgroundPrimaries(:)),mean(subprimaryBackgroundPrimaries(:)));

%% Find primaries with desired LMS contrast.
%
% Get isolating primaries for all primaries.
for pp = 1:nPrimaries
    % The ambient with respect to which we compute contrast is from all
    % three primaries, which we handle via the extraAmbientSpd key-value
    % pair in the call.  The extra is for the primaries not being found in
    % the current call - the contribution from the current primary is known
    % because we pass the primaries for the background.
    otherPrimaries = setdiff(1:nPrimaries,pp);
    extraAmbientSpd = 0;
    for oo = 1:length(otherPrimaries)
        extraAmbientSpd = extraAmbientSpd + subprimaryBackgroundSpd(:,otherPrimaries(oo));
    end

    % Get isolating primaries.
    [projectorPrimaryPrimaries(:,pp),projectorPrimaryPrimariesQuantized(:,pp),projectorPrimarySpd(:,pp),projectorPrimaryContrast(:,pp),projectorPrimaryModulationPrimaries(:,pp)] ... 
        = FindChannelPrimaries(targetProjectorPrimaryContrastDir(:,pp), ...
        targetPrimaryHeadroom,targetProjectorPrimaryContrasts(pp),subprimaryBackgroundPrimaries(:,pp), ...
        T_cones,subprimaryCalObjs{pp},B_natural{pp},projectIndices,primaryHeadroom,targetLambda,'ExtraAmbientSpd',extraAmbientSpd);
    
    % We can wonder about how close to gamut our primaries are.  Compute
    % that here.
    primaryGamutScaleFactor(pp) = MaximizeGamutContrast(projectorPrimaryModulationPrimaries(:,pp),subprimaryBackgroundPrimaries(:,pp));
    fprintf('\tPrimary %d, gamut scale factor is %0.3f\n',pp,primaryGamutScaleFactor(pp));
    
    % Find the subprimary settings that correspond to the desired primaries
    projectorPrimarySettings(:,pp) = PrimaryToSettings(subprimaryCalObjs{pp},projectorPrimaryPrimaries(:,pp));
end

%% How close are spectra to subspace defined by basis?
isolatingNaturalApproxSpd1 = B_natural{1}*(B_natural{1}(projectIndices,:)\projectorPrimarySpd(projectIndices,1));
isolatingNaturalApproxSpd2 = B_natural{2}*(B_natural{2}(projectIndices,:)\projectorPrimarySpd(projectIndices,2));
isolatingNaturalApproxSpd3 = B_natural{3}*(B_natural{3}(projectIndices,:)\projectorPrimarySpd(projectIndices,3));

% Plot of the primary spectra
subplot(2,2,1); hold on
plot(wls,projectorPrimarySpd(:,1),'b','LineWidth',2);
plot(wls,isolatingNaturalApproxSpd1,'r:','LineWidth',1);
plot(wls(projectIndices),projectorPrimarySpd(projectIndices,1),'b','LineWidth',4);
plot(wls(projectIndices),isolatingNaturalApproxSpd1(projectIndices),'r:','LineWidth',3);
xlabel('Wavelength (nm)'); ylabel('Power (arb units)');
title('Primary 1');

subplot(2,2,2); hold on
plot(wls,projectorPrimarySpd(:,2),'b','LineWidth',2);
plot(wls,isolatingNaturalApproxSpd2,'r:','LineWidth',1);
plot(wls(projectIndices),projectorPrimarySpd(projectIndices,2),'b','LineWidth',4);
plot(wls(projectIndices),isolatingNaturalApproxSpd2(projectIndices),'r:','LineWidth',3);
xlabel('Wavelength (nm)'); ylabel('Power (arb units)');
title('Primary 2');

subplot(2,2,3); hold on
plot(wls,projectorPrimarySpd(:,3),'b','LineWidth',2);
plot(wls,isolatingNaturalApproxSpd3,'r:','LineWidth',1);
plot(wls(projectIndices),projectorPrimarySpd(projectIndices,3),'b','LineWidth',4);
plot(wls(projectIndices),isolatingNaturalApproxSpd3(projectIndices),'r:','LineWidth',3);
xlabel('Wavelength (nm)'); ylabel('Power (arb units)');
title('Primary 3');

%% Set the projector primaries
%
% We want these to match those we set up with the
% subprimary calculations above.  Need to reset
% sensor color space after we do this, so that the
% conversion matrix is properly recomputed.
projectorCalObj.set('P_device',projectorPrimarySpd);
SetSensorColorSpace(projectorCalObj,T_cones,S);

%% Set projector gamma method
%
% If we set to 0, there is no quantization and the result is excellent.
% If we set to 2, this is quantized at 256 levels and the result is more
% of a mess.  The choice of 2 represents what we think will actually happen
% since the real device is quantized.
%
% The point cloud method below reduces this problem.
projectorGammaMethod = 2;
SetGammaMethod(projectorCalObj,projectorGammaMethod);

%% Set up desired background.
%
% We aim for the background that we said we wanted when we built the projector primaries.
desiredBgExcitations = projectorBackgroundScaleFactor*T_cones*sum(subprimaryBackgroundSpd,2);
projectorBgSettings = SensorToSettings(projectorCalObj,desiredBgExcitations);
projectorBgExcitations = SettingsToSensor(projectorCalObj,projectorBgSettings);
figure; clf; hold on;
plot(desiredBgExcitations,projectorBgExcitations,'ro','MarkerFaceColor','r','MarkerSize',12);
axis('square');
xlim([min([desiredBgExcitations ; projectorBgExcitations]),max([desiredBgExcitations ; projectorBgExcitations])]);
ylim([min([desiredBgExcitations ; projectorBgExcitations]),max([desiredBgExcitations ; projectorBgExcitations])]);
xlabel('Desired bg excitations'); ylabel('Obtained bg excitations');
title('Check that we obtrain desired background excitations');
fprintf('Projector settings to obtain background: %0.2f, %0.2f, %0.2f\n', ...
    projectorBgSettings(1),projectorBgSettings(2),projectorBgSettings(3));

%% Make monochrome Gabor patch in range -1 to 1.
%
% This is our monochrome contrast modulation image.  Multiply
% by the max contrast vector to get the LMS contrast image.
fprintf('Making Gabor contrast image\n');
centerN = imageN/2;
gaborSdPixels = gaborSdImageFraction*imageN;
rawMonochromeSineImage = MakeSineImage(0,sineFreqCyclesPerImage,imageN);
gaussianWindow = normpdf(MakeRadiusMat(imageN,imageN,centerN,centerN),0,gaborSdPixels);
gaussianWindow = gaussianWindow/max(gaussianWindow(:));
rawMonochromeUnquantizedContrastGaborImage = rawMonochromeSineImage.*gaussianWindow;

% Put it into cal format.  Each pixel in cal format is one column.  Here
% there is just one row since it is a monochrome image at this point.
rawMonochromeUnquantizedContrastGaborCal = ImageToCalFormat(rawMonochromeUnquantizedContrastGaborImage);

%% Quantize the contrast image to a (large) fixed number of levels
%
% This allows us to speed up the image conversion without any meaningful
% loss of precision. If you don't like it, increase number of quantization
% bits until you are happy again.
nQuantizeBits = 14;
nQuantizeLevels = 2^nQuantizeBits;
rawMonochromeContrastGaborCal = 2*(PrimariesToIntegerPrimaries((rawMonochromeUnquantizedContrastGaborCal+1)/2,nQuantizeLevels)/(nQuantizeLevels-1))-1;

% Plot of how well point cloud method does in obtaining desired contrats
figure; clf;
plot(rawMonochromeUnquantizedContrastGaborCal(:),rawMonochromeContrastGaborCal(:),'r+');
axis('square');
xlim([0 1]); ylim([0 1]);
xlabel('Unquantized Gabor contrasts');
ylabel('Quantized Gabor contrasts');
title('Effect of contrast quantization');

%% Get cone contrast/excitation gabor image
%
% Scale target cone contrast vector at max excursion by contrast modulation
% at each pixel.  This is done by a single matrix multiply plus a lead
% factor.  We work cal format here as that makes color transforms
% efficient.
theDesiredContrastGaborCal = spatialGaborTargetContrast*targetStimulusContrastDir*rawMonochromeContrastGaborCal;

% Convert cone contrast to excitations
theDesiredExcitationsGaborCal = ContrastToExcitation(theDesiredContrastGaborCal,projectorBgExcitations);

% Get primaries using standard calibration code, and desired spd without
% quantizing.
theStandardPrimariesGaborCal = SensorToPrimary(projectorCalObj,theDesiredExcitationsGaborCal);
theDesiredSpdGaborCal = PrimaryToSpd(projectorCalObj,theStandardPrimariesGaborCal);

% Gamma correct and quantize (if gamma method set to 2 above; with gamma
% method set to zero there is no quantization).  Then convert back from
% the gamma corrected settings.
theStandardSettingsGaborCal = PrimaryToSettings(projectorCalObj,theStandardPrimariesGaborCal);
theStandardPredictedPrimariesGaborCal = SettingsToPrimary(projectorCalObj,theStandardSettingsGaborCal);
theStandardPredictedExcitationsGaborCal = PrimaryToSensor(projectorCalObj,theStandardPredictedPrimariesGaborCal);
theStandardPredictedContrastGaborCal = ExcitationsToContrast(theStandardPredictedExcitationsGaborCal,projectorBgExcitations);

%% Set up point cloud of contrasts for all possible settings
%
% The method above is subject to imperfect quantization because each primary is
% quantized individually. Here we'll quantize jointly across the three
% primaries, using an exhaustive search process.  Amazingly, it is feasible
% to search all possible quantized settings for each image pixel, and choose
% the settings that best approximate the desired LMS excitations at that pixel.
%
% Compute an array with all possible triplets of projector settings,
% quantized on the interval [0,1].
%
% This method takes all possible projector settings and creates a
% point cloud of the corresponding cone contrasts. It then finds
% the settings that come as close as possible to producing the
% desired cone contrast at each point in the image. It's a little
% slow but conceptually simple and fast enough to be feasible.
tic;
fprintf('Point cloud exhaustive method, setting up cone contrast cloud, this takes a while\n')

% Compute all possible settings as integers.  
allProjectorIntegersCal = zeros(3,projectorNInputLevels^3);
idx = 1;
for ii = 0:(projectorNInputLevels-1)
    for jj = 0:(projectorNInputLevels-1)
        for kk = 0:(projectorNInputLevels-1)
            allProjectorIntegersCal(:,idx) = [ii jj kk]';
            idx = idx+1;
        end
    end
end

% Convert integers to 0-1 reals, quantized
allProjectorSettingsCal = IntegersToSettings(allProjectorIntegersCal,'nInputLevels',projectorNInputLevels);

% Get LMS excitations for each triplet of projector settings, and build a
% point cloud object from these.
allProjectorExcitations = SettingsToSensor(projectorCalObj,allProjectorSettingsCal);
allProjectorContrast = ExcitationsToContrast(allProjectorExcitations,projectorBgExcitations);
allSensorPtCloud = pointCloud(allProjectorContrast');

% Force point cloud setup by finding one nearest neighbor. This is slow,
% but once it is done subsequent calls are considerably faster.
findNearestNeighbors(allSensorPtCloud,[0 0 0],1);
toc

%% Find settings by exhaustive search of point cloud for each pixel
%
% Go through the gabor image, and for each pixel find the settings that
% come as close as possible to producing the desired excitations.
% Conceptually straightforward, but a bit slow.
SLOWMETHODCHECK = false;
if (SLOWMETHODCHECK)
    tic;
    fprintf('Point cloud exhaustive method, finding image settings\n')
    printIter = 10000;
    thePointCloudSettingsGaborCal = zeros(3,size(theDesiredContrastGaborCal,2));
    minIndex = zeros(1,size(theDesiredContrastGaborCal,2));
    for ll = 1:size(theDesiredContrastGaborCal,2)
        if (rem(ll,printIter) == 0)
            fprintf('Finding settings for iteration %d of %d\n',ll,size(theDesiredContrastGaborCal,2));
        end
        minIndex = findNearestNeighbors(allSensorPtCloud,theDesiredContrastGaborCal(:,ll)',1);
        thePointCloudSettingsGaborCal(:,ll) = allProjectorSettingsCal(:,minIndex);
    end
    toc

    % Get contrasts we think we have obtained.
    thePointCloudExcitationsGaborCal = SettingsToSensor(projectorCalObj,thePointCloudSettingsGaborCal);
    thePointCloudContrastGaborCal = ExcitationsToContrast(thePointCloudExcitationsGaborCal,projectorBgExcitations);

    % Plot of how well pixelwise point cloud method does in obtaining desired contrats
    figure; clf;
    plot(theDesiredContrastGaborCal(:),thePointCloudContrastGaborCal(:),'r+');
    axis('square');
    xlabel('Desired L, M or S contrast');
    ylabel('Predicted L, M, or S contrast');
    title('Pixelwise point cloud image method');
end

%% Get image settings, fast way
%
% Only look up each unique cone contrast once, and then fill into the
% settings image. Slick!
%
% Find the unique cone contrasts in the image
tic;
fprintf('Point cloud unique contrast method, finding image settings\n')
[uniqueDesiredContrastGaborCal,~,uniqueIC] = unique(theDesiredContrastGaborCal','rows','stable');
uniqueDesiredContrastGaborCal = uniqueDesiredContrastGaborCal';

% For each unique contrast, find the right settings and then plug into
% output image.
theUniqueQuantizedSettingsGaborCal = zeros(3,size(theDesiredContrastGaborCal,2));
minIndex = zeros(1,size(theDesiredContrastGaborCal,2));
for ll = 1:size(uniqueDesiredContrastGaborCal,2)
    minIndex = findNearestNeighbors(allSensorPtCloud,uniqueDesiredContrastGaborCal(:,ll)',1);
    theUniqueQuantizedSettingsGaborCal(:,ll) = allProjectorSettingsCal(:,minIndex);
end
theUniqueQuantizedSettingsGaborCal = theUniqueQuantizedSettingsGaborCal(:,uniqueIC);
toc

% Print out min/max of settings
fprintf('Gabor image min/max settings: %0.3f, %0.3f\n',min(theUniqueQuantizedSettingsGaborCal(:)), max(theUniqueQuantizedSettingsGaborCal(:)));

% Get contrasts we think we have obtianed
theUniqueQuantizedExcitationsGaborCal = SettingsToSensor(projectorCalObj,theUniqueQuantizedSettingsGaborCal);
theUniqueQuantizedContrastGaborCal = ExcitationsToContrast(theUniqueQuantizedExcitationsGaborCal,projectorBgExcitations);

% Plot of how well point cloud method does in obtaining desired contrats
figure; clf;
plot(theDesiredContrastGaborCal(:),theUniqueQuantizedContrastGaborCal(:),'r+');
axis('square');
xlabel('Desired L, M or S contrast');
ylabel('Predicted L, M, or S contrast');
title('Quantized unique point cloud image method');

% Check that we get the same answer
if (SLOWMETHODCHECK)
    if (max(abs(theUniqueQuantizedContrastGaborCal(:)-theUniqueQuantizedContrastGaborCal(:))) > 0)
        fprintf('Point cloud and unique method methods do not agree\n');
    end
end

%% Convert representations we want to take forward to image format
theDesiredContrastGaborImage = CalFormatToImage(theDesiredContrastGaborCal,imageN,imageN);
theStandardPredictedContrastImage = CalFormatToImage(theStandardPredictedContrastGaborCal,imageN,imageN);
theStandardSettingsGaborImage = CalFormatToImage(theStandardSettingsGaborCal,imageN,imageN);
theUniqueQuantizedContrastGaborImage = CalFormatToImage(theUniqueQuantizedContrastGaborCal,imageN,imageN);

%% SRGB image via XYZ, scaled to display
thePredictedXYZCal = T_xyz*theDesiredSpdGaborCal;
theSRGBPrimaryCal = XYZToSRGBPrimary(thePredictedXYZCal);
scaleFactor = max(theSRGBPrimaryCal(:));
theSRGBCal = SRGBGammaCorrect(theSRGBPrimaryCal/(2*scaleFactor),0);
theSRGBImage = uint8(CalFormatToImage(theSRGBCal,imageN,imageN));

% Show the SRGB image
figure; imshow(theSRGBImage);
title('SRGB Gabor Image');

%% Show the settings image
figure; clf;
imshow(theStandardSettingsGaborImage);
title('Image of settings');

%% Plot slice through predicted LMS contrast image.
%
% Note that the y-axis in this plot is individual cone contrast, which is
% not the same as the vector length contrast of the modulation.
figure; hold on
plot(1:imageN,100*theStandardPredictedContrastImage(centerN,:,1),'r+','MarkerFaceColor','r','MarkerSize',4);
plot(1:imageN,100*theDesiredContrastGaborImage(centerN,:,1),'r','LineWidth',0.5);

plot(1:imageN,100*theStandardPredictedContrastImage(centerN,:,2),'g+','MarkerFaceColor','g','MarkerSize',4);
plot(1:imageN,100*theDesiredContrastGaborImage(centerN,:,2),'g','LineWidth',0.5);

plot(1:imageN,100*theStandardPredictedContrastImage(centerN,:,3),'b+','MarkerFaceColor','b','MarkerSize',4);
plot(1:imageN,100*theDesiredContrastGaborImage(centerN,:,3),'b','LineWidth',0.5);
if (projectorGammaMethod == 2)
    title('Image Slice, SensorToSettings Method, Quantized Gamma, LMS Cone Contrast');
else
    title('Image Slice, SensorToSettings Method, No Quantization, LMS Cone Contrast');
end
xlabel('x position (pixels)')
ylabel('LMS Cone Contrast (%)');
ylim([-plotAxisLimit plotAxisLimit]);

%% Plot slice through point cloud LMS contrast image.
%
% Note that the y-axis in this plot is individual cone contrast, which is
% not the same as the vector length contrast of the modulation.
figure; hold on
plot(1:imageN,100*theUniqueQuantizedContrastGaborImage(centerN,:,1),'r+','MarkerFaceColor','r','MarkerSize',4);
plot(1:imageN,100*theDesiredContrastGaborImage(centerN,:,1),'r','LineWidth',0.5);

plot(1:imageN,100*theUniqueQuantizedContrastGaborImage(centerN,:,2),'g+','MarkerFaceColor','g','MarkerSize',4);
plot(1:imageN,100*theDesiredContrastGaborImage(centerN,:,2),'g','LineWidth',0.5);

plot(1:imageN,100*theUniqueQuantizedContrastGaborImage(centerN,:,3),'b+','MarkerFaceColor','b','MarkerSize',4);
plot(1:imageN,100*theDesiredContrastGaborImage(centerN,:,3),'b','LineWidth',0.5);
title('Image Slice, Point Cloud Method, LMS Cone Contrast');
xlabel('x position (pixels)')
ylabel('LMS Cone Contrast (%)');
ylim([-plotAxisLimit plotAxisLimit]);

%% Generate some settings values corresponding to known contrasts % (THIS PART MAY BE GOING TO BE IN A FUNCTION LATER ON - SEMIN)
%
% The reason for this is to measure and check these.  This logic follows
% how we handled an actual gabor image above. We don't actually need to
% quantize to 14 bits here on the contrast, but nor does it hurt.
rawMonochromeUnquantizedContrastCheckCal = [0 0.25 -0.25 0.5 -0.5 1 -1];
rawMonochromeContrastCheckCal = 2*(PrimariesToIntegerPrimaries((rawMonochromeUnquantizedContrastCheckCal+1)/2,nQuantizeLevels)/(nQuantizeLevels-1))-1;
theDesiredContrastCheckCal = spatialGaborTargetContrast*targetStimulusContrastDir*rawMonochromeContrastCheckCal;
theDesiredExcitationsCheckCal = ContrastToExcitation(theDesiredContrastCheckCal,projectorBgExcitations);

% For each check calibration find the settings that
% come as close as possible to producing the desired excitations.
%
% If we measure for a uniform field the spectra corresopnding to each of
% the settings in the columns of thePointCloudSettingsCheckCal, then
% compute the cone contrasts with respect to the backgound (0 contrast
% measurement, first settings), we should approximate the cone contrasts in
% theDesiredContrastCheckCal.
fprintf('Point cloud exhaustive method, finding settings\n')
thePointCloudSettingsCheckCal = zeros(3,size(theDesiredContrastCheckCal,2));
for ll = 1:size(theDesiredContrastCheckCal,2)
    minIndex = findNearestNeighbors(allSensorPtCloud,theDesiredContrastCheckCal(:,ll)',1);
    thePointCloudSettingsCheckCal(:,ll) = allProjectorSettingsCal(:,minIndex);
end
thePointCloudPrimariesCheckCal = SettingsToPrimary(projectorCalObj,thePointCloudSettingsCheckCal);
thePointCloudSpdCheckCal = PrimaryToSpd(projectorCalObj,thePointCloudPrimariesCheckCal);
thePointCloudExcitationsCheckCal = SettingsToSensor(projectorCalObj,thePointCloudSettingsCheckCal);
thePointCloudContrastCheckCal = ExcitationsToContrast(thePointCloudExcitationsCheckCal,projectorBgExcitations);
figure; clf; hold on;
plot(theDesiredContrastCheckCal(:),thePointCloudContrastCheckCal(:),'ro','MarkerSize',10,'MarkerFaceColor','r');
xlim([0 plotAxisLimit/100]); ylim([0 plotAxisLimit/100]); axis('square');
xlabel('Desired'); ylabel('Obtained');
title('Check of desired versus obtained check contrasts');

% Check that we can recover the settings from the spectral power
% distributions, etc.  This won't necessarily work perfectly, but should be
% OK.
for tt = 1:size(thePointCloudSettingsCheckCal,2)
    thePointCloudPrimariesFromSpdCheckCal(:,tt) = SpdToPrimary(projectorCalObj,thePointCloudSpdCheckCal(:,tt),'lambda',0);
    thePointCloudSettingsFromSpdCheckCal(:,tt) = PrimaryToSettings(projectorCalObj,thePointCloudSettingsCheckCal(:,tt));
end
figure; clf; hold on
plot(thePointCloudSettingsCheckCal(:),thePointCloudSettingsFromSpdCheckCal(:),'+','MarkerSize',12);
xlim([0 1]); ylim([0 1]);
xlabel('Computed primaries'); ylabel('Check primaries from spd'); axis('square');

% Make sure that projectorPrimarySettings leads to projectorPrimarySpd
clear projectorPrimarySpdCheck
for pp = 1:length(subprimaryCalObjs)
    projectorPrimarySpdCheck(:,pp) = PrimaryToSpd(subprimaryCalObjs{pp},SettingsToPrimary(subprimaryCalObjs{pp},projectorPrimarySettings(:,pp)));
end
figure; clf; hold on
plot(SToWls(S),projectorPrimarySpdCheck,'k','LineWidth',4);
plot(SToWls(S),projectorPrimarySpd,'r','LineWidth',2);
xlabel('Wavelength'); ylabel('Radiance');
title('Check of consistency between projector primaries and projector primary spds');

%% Save out what we need to check things on the DLP
projectorSettingsImage = theStandardSettingsGaborImage;
if (ispref('SpatioSpectralStimulator','TestDataFolder'))
    testFiledir = getpref('SpatioSpectralStimulator','TestDataFolder');
    testFilename = fullfile(testFiledir,sprintf('testImageData_%s',conditionName));
    save(testFilename,'S','T_cones','projectorCalObj','subprimaryCalObjs','projectorSettingsImage', ...
        'projectorPrimaryPrimaries','projectorPrimarySettings','projectorPrimarySpd',...
        'theDesiredContrastCheckCal', ...
        'thePointCloudSettingsCheckCal','thePointCloudContrastCheckCal','thePointCloudSpdCheckCal', ...
        'nQuantizeLevels','projectorNInputLevels','targetStimulusContrastDir','spatialGaborTargetContrast');
end


