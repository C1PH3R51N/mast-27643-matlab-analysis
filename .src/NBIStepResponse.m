clear;
clc;
close all;

%% MAST Shot 27643 - NBI Step-Response Analysis

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - NBI STEP RESPONSE\n');
fprintf('========================================\n\n');

%% -------------------------------------------------
% 1. SELECT FILES
% --------------------------------------------------

[anbName, anbPath] = uigetfile('*.nc','Select anb27643.nc');
if isequal(anbName,0)
    error('ANB file not selected.');
end
anbFile = fullfile(anbPath,anbName);

[anuName, anuPath] = uigetfile('*.nc','Select anu27643.nc');
if isequal(anuName,0)
    error('ANU file not selected.');
end
anuFile = fullfile(anuPath,anuName);

%% -------------------------------------------------
% 2. LOAD DATA
% --------------------------------------------------

timeANB = double(ncread(anbFile,'/time'));
nbiPower = double(ncread( ...
    anbFile,'/anb/tot_sum_power/data'));

timeANU = double(ncread(anuFile,'/anu/neutrons/time'));
neutronRate = double(ncread( ...
    anuFile,'/anu/neutrons/data'));

timeANUErr = double(ncread(anuFile,'/anu/errors/time'));
neutronError = double(ncread( ...
    anuFile,'/anu/errors/data'));

fprintf('NBI and neutron signals loaded.\n\n');

%% -------------------------------------------------
% 3. CREATE COMMON TIME GRID
% --------------------------------------------------

analysisStart = 0.25;
analysisEnd   = 0.38;

commonStep = 0.0002;

commonTime = (analysisStart:commonStep:analysisEnd)';

nbi = interp1( ...
    timeANB,nbiPower,commonTime,'linear');

neutrons = interp1( ...
    timeANU,neutronRate,commonTime,'linear');

neutronErr = interp1( ...
    timeANUErr,neutronError,commonTime,'linear');

valid = isfinite(nbi) & ...
        isfinite(neutrons) & ...
        isfinite(neutronErr);

commonTime = commonTime(valid);
nbi = nbi(valid);
neutrons = neutrons(valid);
neutronErr = neutronErr(valid);

fprintf('Observations in step-response window: %d\n\n', ...
    length(commonTime));

%% -------------------------------------------------
% 4. DETECT MAIN NBI STEP
% --------------------------------------------------
% Calculate change in NBI power between samples.

dNBI = diff(nbi);

% Search specifically around expected transition.
transitionSearch = ...
    commonTime(1:end-1) >= 0.28 & ...
    commonTime(1:end-1) <= 0.32;

searchIndices = find(transitionSearch);

[~,localIndex] = max(dNBI(transitionSearch));

stepIndex = searchIndices(localIndex) + 1;

stepTime = commonTime(stepIndex);

fprintf('----- NBI STEP DETECTION -----\n');
fprintf('Detected NBI transition : %.6f s\n\n',stepTime);

%% -------------------------------------------------
% 5. DEFINE PRE AND POST WINDOWS
% --------------------------------------------------
% Use 20 ms windows to estimate stable conditions
% immediately before and after the transition.

preStart = stepTime - 0.020;
preEnd   = stepTime - 0.005;

postStart = stepTime + 0.005;
postEnd   = stepTime + 0.020;

preMask = ...
    commonTime >= preStart & ...
    commonTime <= preEnd;

postMask = ...
    commonTime >= postStart & ...
    commonTime <= postEnd;

%% -------------------------------------------------
% 6. CALCULATE PRE/POST STATISTICS
% --------------------------------------------------

preNBI = mean(nbi(preMask));
postNBI = mean(nbi(postMask));

preNeutrons = mean(neutrons(preMask));
postNeutrons = mean(neutrons(postMask));

preNeutronStd = std(neutrons(preMask));
postNeutronStd = std(neutrons(postMask));

nbiChange = ...
    100*(postNBI-preNBI)/preNBI;

neutronChange = ...
    100*(postNeutrons-preNeutrons)/preNeutrons;

fprintf('----- PRE / POST STEP COMPARISON -----\n\n');

fprintf('Pre-step mean NBI power      : %.4f MW\n',preNBI);
fprintf('Post-step mean NBI power     : %.4f MW\n',postNBI);
fprintf('NBI power change             : %.2f %%\n\n',nbiChange);

fprintf('Pre-step mean neutron rate   : %.4e n/s\n',preNeutrons);
fprintf('Post-step mean neutron rate  : %.4e n/s\n',postNeutrons);
fprintf('Neutron-rate change          : %.2f %%\n\n',neutronChange);

fprintf('Pre-step neutron SD          : %.4e n/s\n',preNeutronStd);
fprintf('Post-step neutron SD         : %.4e n/s\n\n',postNeutronStd);

%% -------------------------------------------------
% 7. DETECT NEUTRON RESPONSE
% --------------------------------------------------
% Establish baseline from pre-step neutron data.

baselineMean = mean(neutrons(preMask));
baselineStd = std(neutrons(preMask));

% Exploratory response threshold:
% baseline mean + 3 standard deviations.

responseThreshold = baselineMean + 3*baselineStd;

afterStep = commonTime > stepTime;

responseCandidates = find( ...
    afterStep & neutrons > responseThreshold);

if ~isempty(responseCandidates)

    responseIndex = responseCandidates(1);
    responseTime = commonTime(responseIndex);

    responseDelay = ...
        (responseTime-stepTime)*1000;

else

    responseTime = NaN;
    responseDelay = NaN;

end

fprintf('----- NEUTRON RESPONSE -----\n\n');

fprintf('Baseline neutron rate       : %.4e n/s\n',baselineMean);
fprintf('Baseline SD                 : %.4e n/s\n',baselineStd);
fprintf('3-SD response threshold     : %.4e n/s\n',responseThreshold);

if ~isnan(responseDelay)

    fprintf('Threshold first exceeded    : %.6f s\n',responseTime);
    fprintf('Apparent response delay     : %.3f ms\n\n',responseDelay);

else

    fprintf('No 3-SD response detected in analysis window.\n\n');

end

%% -------------------------------------------------
% 8. FIND POST-STEP PEAK
% --------------------------------------------------

peakSearch = ...
    commonTime >= stepTime & ...
    commonTime <= stepTime + 0.080;

[peakNeutrons,peakLocalIndex] = ...
    max(neutrons(peakSearch));

peakIndices = find(peakSearch);

peakIndex = peakIndices(peakLocalIndex);

peakTime = commonTime(peakIndex);

timeToPeak = ...
    (peakTime-stepTime)*1000;

fprintf('----- POST-STEP PEAK -----\n\n');

fprintf('Peak neutron rate           : %.4e n/s\n',peakNeutrons);
fprintf('Peak time                   : %.6f s\n',peakTime);
fprintf('Time from NBI step to peak  : %.3f ms\n\n',timeToPeak);

%% -------------------------------------------------
% 9. VISUALISE STEP RESPONSE
% --------------------------------------------------

figure;

yyaxis left

plot(commonTime,nbi,'LineWidth',1.5);

ylabel('NBI Power (MW)');

yyaxis right

plot(commonTime,neutrons,'LineWidth',1.5);

ylabel('Neutron Rate (neutrons/s)');

xline(stepTime,'--','NBI Step');

if ~isnan(responseTime)
    xline(responseTime,'--','3-SD Response');
end

xlabel('Time (s)');

title('MAST Shot 27643 - NBI Step and Neutron Response');

grid on;

%% -------------------------------------------------
% 10. NEUTRON RESPONSE ONLY
% --------------------------------------------------

figure;

plot(commonTime,neutrons,'LineWidth',1.5);
hold on;

yline(responseThreshold,'--');

xline(stepTime,'--');

if ~isnan(responseTime)
    plot(responseTime, ...
         neutrons(responseIndex), ...
         'o', ...
         'MarkerSize',8, ...
         'LineWidth',1.5);
end

xlabel('Time (s)');
ylabel('Neutron Rate (neutrons/s)');

title('Neutron Response Following NBI Power Step');

grid on;

fprintf('NBI step-response analysis complete.\n');