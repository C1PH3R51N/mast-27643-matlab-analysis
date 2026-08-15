clear;
clc;
close all;

%% MAST Shot 27643 - Neutron Uncertainty Analysis

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - UNCERTAINTY ANALYSIS\n');
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

fprintf('NBI, neutron and neutron-error data loaded.\n\n');

%% -------------------------------------------------
% 3. ALIGN DATA
% --------------------------------------------------

analysisStart = 0.00;
analysisEnd = 0.50;
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

time = commonTime(valid);
nbi = nbi(valid);
neutrons = neutrons(valid);
neutronErr = neutronErr(valid);

fprintf('Aligned observations: %d\n\n',length(time));

%% -------------------------------------------------
% 4. CALCULATE RELATIVE UNCERTAINTY
% --------------------------------------------------

relativeUncertainty = ...
    100 * neutronErr ./ abs(neutrons);

% Avoid division problems where neutron rate is zero.

relativeUncertainty(neutrons == 0) = NaN;

%% -------------------------------------------------
% 5. UNCERTAINTY SUMMARY
% --------------------------------------------------

validRelative = relativeUncertainty( ...
    isfinite(relativeUncertainty));

fprintf('----- NEUTRON UNCERTAINTY SUMMARY -----\n\n');

fprintf('Mean absolute uncertainty   : %.4e n/s\n', ...
    mean(neutronErr));

fprintf('Median absolute uncertainty : %.4e n/s\n', ...
    median(neutronErr));

fprintf('Minimum absolute uncertainty: %.4e n/s\n', ...
    min(neutronErr));

fprintf('Maximum absolute uncertainty: %.4e n/s\n\n', ...
    max(neutronErr));

fprintf('Mean relative uncertainty   : %.3f %%\n', ...
    mean(validRelative));

fprintf('Median relative uncertainty : %.3f %%\n', ...
    median(validRelative));

fprintf('Minimum relative uncertainty: %.3f %%\n', ...
    min(validRelative));

fprintf('Maximum relative uncertainty: %.3f %%\n\n', ...
    max(validRelative));

%% -------------------------------------------------
% 6. NBI PHASE UNCERTAINTY
% --------------------------------------------------

phase1 = nbi >= 1.5 & nbi < 2.3;

phase2 = nbi >= 2.8 & nbi <= 3.6;

phase1Rel = relativeUncertainty(phase1);
phase2Rel = relativeUncertainty(phase2);

phase1Rel = phase1Rel(isfinite(phase1Rel));
phase2Rel = phase2Rel(isfinite(phase2Rel));

fprintf('----- UNCERTAINTY BY NBI PHASE -----\n\n');

fprintf('Phase 1 observations            : %d\n', ...
    sum(phase1));

fprintf('Phase 1 mean relative uncertainty: %.3f %%\n\n', ...
    mean(phase1Rel));

fprintf('Phase 2 observations            : %d\n', ...
    sum(phase2));

fprintf('Phase 2 mean relative uncertainty: %.3f %%\n\n', ...
    mean(phase2Rel));

%% -------------------------------------------------
% 7. UNCERTAINTY AT PEAK NEUTRON RATE
% --------------------------------------------------

[peakNeutron,peakIndex] = max(neutrons);

peakTime = time(peakIndex);
peakError = neutronErr(peakIndex);

peakRelative = ...
    100 * peakError / peakNeutron;

fprintf('----- PEAK NEUTRON MEASUREMENT -----\n\n');

fprintf('Peak neutron rate       : %.4e n/s\n', ...
    peakNeutron);

fprintf('Peak time               : %.6f s\n', ...
    peakTime);

fprintf('Absolute uncertainty    : %.4e n/s\n', ...
    peakError);

fprintf('Relative uncertainty    : %.3f %%\n\n', ...
    peakRelative);

%% -------------------------------------------------
% 8. UNCERTAINTY AROUND NBI STEP
% --------------------------------------------------

stepTime = 0.2980;

[~,stepIndex] = min(abs(time-stepTime));

fprintf('----- NBI STEP MEASUREMENT -----\n\n');

fprintf('Nearest time            : %.6f s\n', ...
    time(stepIndex));

fprintf('Neutron rate            : %.4e n/s\n', ...
    neutrons(stepIndex));

fprintf('Absolute uncertainty    : %.4e n/s\n', ...
    neutronErr(stepIndex));

fprintf('Relative uncertainty    : %.3f %%\n\n', ...
    relativeUncertainty(stepIndex));

%% -------------------------------------------------
% 9. PLOT RELATIVE UNCERTAINTY
% --------------------------------------------------

figure;

plot(time,relativeUncertainty,'LineWidth',1);

xlabel('Time (s)');
ylabel('Relative Uncertainty (%)');

title('Neutron Rate Relative Uncertainty');

grid on;

%% -------------------------------------------------
% 10. NEUTRON RATE WITH UNCERTAINTY ENVELOPE
% --------------------------------------------------

upperBound = neutrons + neutronErr;
lowerBound = neutrons - neutronErr;

figure;

fill( ...
    [time; flipud(time)], ...
    [upperBound; flipud(lowerBound)], ...
    [0.85 0.85 0.85], ...
    'EdgeColor','none');

hold on;

plot(time,neutrons,'LineWidth',1.2);

xlabel('Time (s)');
ylabel('Neutron Rate (neutrons/s)');

title('Neutron Rate with Measurement Uncertainty');

legend('Uncertainty Envelope','Neutron Rate', ...
    'Location','best');

grid on;

%% -------------------------------------------------
% 11. NBI POWER + RELATIVE UNCERTAINTY
% --------------------------------------------------

figure;

yyaxis left

plot(time,nbi,'LineWidth',1.2);

ylabel('NBI Power (MW)');

yyaxis right

plot(time,relativeUncertainty,'LineWidth',1);

ylabel('Relative Neutron Uncertainty (%)');

xlabel('Time (s)');

title('NBI Power and Neutron Measurement Uncertainty');

grid on;

fprintf('Uncertainty analysis complete.\n');