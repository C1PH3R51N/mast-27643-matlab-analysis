clear;
clc;
close all;

%% MAST Shot 27643 - Full Time-Series Monte Carlo Analysis

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - FULL MONTE CARLO\n');
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

fprintf('Source data loaded.\n\n');

%% -------------------------------------------------
% 3. ALIGN DATA
% --------------------------------------------------

analysisStart = 0.00;
analysisEnd   = 0.50;
commonStep    = 0.0002;

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

fprintf('Aligned time points : %d\n\n',length(time));

%% -------------------------------------------------
% 4. MONTE CARLO SETTINGS
% --------------------------------------------------

numSimulations = 10000;

rng(27643);

fprintf('Monte Carlo simulations : %d\n',numSimulations);
fprintf('Total simulated values  : %d\n\n', ...
    numSimulations * length(time));

%% -------------------------------------------------
% 5. GENERATE FULL TIME-SERIES SIMULATIONS
% -------------------------------------------------
% Assumption:
% ANU_ERRORS treated as 1-sigma Gaussian uncertainty
% for sensitivity analysis.

randomNoise = randn(length(time),numSimulations);

simulatedRates = ...
    neutrons + neutronErr .* randomNoise;

%% -------------------------------------------------
% 6. POINT-BY-POINT MONTE CARLO STATISTICS
% --------------------------------------------------

mcMean = mean(simulatedRates,2);
mcMedian = median(simulatedRates,2);
mcStd = std(simulatedRates,0,2);

mcLower95 = prctile(simulatedRates,2.5,2);
mcUpper95 = prctile(simulatedRates,97.5,2);

fprintf('Point-by-point Monte Carlo statistics calculated.\n\n');

%% -------------------------------------------------
% 7. PEAK NEUTRON RATE DISTRIBUTION
% --------------------------------------------------

[simulationPeaks,simulationPeakIndex] = ...
    max(simulatedRates,[],1);

simulationPeakTimes = ...
    time(simulationPeakIndex);

peakMean = mean(simulationPeaks);
peakMedian = median(simulationPeaks);
peakStd = std(simulationPeaks);

peakCI = prctile(simulationPeaks,[2.5 97.5]);

fprintf('----- PEAK NEUTRON RATE -----\n\n');

fprintf('Mean simulated peak   : %.4e n/s\n',peakMean);
fprintf('Median simulated peak : %.4e n/s\n',peakMedian);
fprintf('Peak SD               : %.4e n/s\n',peakStd);

fprintf('95%% peak interval      : %.4e to %.4e n/s\n\n', ...
    peakCI(1),peakCI(2));

%% -------------------------------------------------
% 8. PEAK TIMING DISTRIBUTION
% --------------------------------------------------

peakTimeMean = mean(simulationPeakTimes);
peakTimeMedian = median(simulationPeakTimes);
peakTimeStd = std(simulationPeakTimes);

peakTimeCI = prctile(simulationPeakTimes,[2.5 97.5]);

fprintf('----- PEAK TIMING -----\n\n');

fprintf('Mean peak time        : %.6f s\n',peakTimeMean);
fprintf('Median peak time      : %.6f s\n',peakTimeMedian);
fprintf('Peak timing SD        : %.6f s\n',peakTimeStd);

fprintf('95%% peak-time interval : %.6f to %.6f s\n\n', ...
    peakTimeCI(1),peakTimeCI(2));

%% -------------------------------------------------
% 9. DEFINE NBI PHASES
% --------------------------------------------------

phase1Mask = nbi >= 1.5 & nbi < 2.3;
phase2Mask = nbi >= 2.8 & nbi <= 3.6;

%% -------------------------------------------------
% 10. SIMULATED MEAN NEUTRON RATE BY PHASE
% --------------------------------------------------

phase1SimulationMeans = ...
    mean(simulatedRates(phase1Mask,:),1);

phase2SimulationMeans = ...
    mean(simulatedRates(phase2Mask,:),1);

phase1MCMean = mean(phase1SimulationMeans);
phase2MCMean = mean(phase2SimulationMeans);

phase1CI = prctile(phase1SimulationMeans,[2.5 97.5]);
phase2CI = prctile(phase2SimulationMeans,[2.5 97.5]);

fprintf('----- NBI PHASE MONTE CARLO RESULTS -----\n\n');

fprintf('Phase 1 mean neutron rate : %.4e n/s\n', ...
    phase1MCMean);

fprintf('Phase 1 95%% interval      : %.4e to %.4e n/s\n\n', ...
    phase1CI(1),phase1CI(2));

fprintf('Phase 2 mean neutron rate : %.4e n/s\n', ...
    phase2MCMean);

fprintf('Phase 2 95%% interval      : %.4e to %.4e n/s\n\n', ...
    phase2CI(1),phase2CI(2));

%% -------------------------------------------------
% 11. PHASE 1 -> PHASE 2 PERCENTAGE CHANGE
% --------------------------------------------------

phaseIncrease = ...
    100 * ...
    (phase2SimulationMeans-phase1SimulationMeans) ...
    ./ phase1SimulationMeans;

increaseMean = mean(phaseIncrease);
increaseMedian = median(phaseIncrease);
increaseCI = prctile(phaseIncrease,[2.5 97.5]);

fprintf('----- PHASE INCREASE -----\n\n');

fprintf('Mean simulated increase   : %.3f %%\n', ...
    increaseMean);

fprintf('Median simulated increase : %.3f %%\n', ...
    increaseMedian);

fprintf('95%% interval              : %.3f %% to %.3f %%\n\n', ...
    increaseCI(1),increaseCI(2));

%% -------------------------------------------------
% 12. FULL TIME-SERIES UNCERTAINTY ENVELOPE
% --------------------------------------------------

figure;

fill( ...
    [time; flipud(time)], ...
    [mcUpper95; flipud(mcLower95)], ...
    [0.85 0.85 0.85], ...
    'EdgeColor','none');

hold on;

plot(time,neutrons,'LineWidth',1.2);

plot(time,mcMean,'--','LineWidth',1);

xlabel('Time (s)');
ylabel('Neutron Rate (neutrons/s)');

title('Full Time-Series Monte Carlo Uncertainty Envelope');

legend( ...
    '95% Monte Carlo Envelope', ...
    'Measured Neutron Rate', ...
    'Monte Carlo Mean', ...
    'Location','best');

grid on;

%% -------------------------------------------------
% 13. PEAK DISTRIBUTION
% --------------------------------------------------

figure;

histogram(simulationPeaks,80);

xlabel('Peak Neutron Rate (neutrons/s)');
ylabel('Frequency');

title('Monte Carlo Distribution of Peak Neutron Rate');

grid on;

%% -------------------------------------------------
% 14. PEAK TIMING DISTRIBUTION
% --------------------------------------------------

figure;

histogram(simulationPeakTimes,50);

xlabel('Peak Time (s)');
ylabel('Frequency');

title('Monte Carlo Distribution of Peak Timing');

grid on;

%% -------------------------------------------------
% 15. PHASE INCREASE DISTRIBUTION
% --------------------------------------------------

figure;

histogram(phaseIncrease,80);

xlabel('Phase 1 to Phase 2 Neutron Increase (%)');
ylabel('Frequency');

title('Monte Carlo Distribution of NBI Phase Neutron Increase');

grid on;

%% -------------------------------------------------
% 16. SAVE SUMMARY TABLE
% --------------------------------------------------

summaryNames = { ...
    'Simulated Peak Neutron Rate'; ...
    'Peak Timing'; ...
    'Phase 1 Mean Neutron Rate'; ...
    'Phase 2 Mean Neutron Rate'; ...
    'Phase 1 to Phase 2 Increase'};

summaryMeans = [ ...
    peakMean; ...
    peakTimeMean; ...
    phase1MCMean; ...
    phase2MCMean; ...
    increaseMean];

summaryLower95 = [ ...
    peakCI(1); ...
    peakTimeCI(1); ...
    phase1CI(1); ...
    phase2CI(1); ...
    increaseCI(1)];

summaryUpper95 = [ ...
    peakCI(2); ...
    peakTimeCI(2); ...
    phase1CI(2); ...
    phase2CI(2); ...
    increaseCI(2)];

MonteCarloSummary = table( ...
    summaryNames, ...
    summaryMeans, ...
    summaryLower95, ...
    summaryUpper95, ...
    'VariableNames', { ...
    'Metric', ...
    'Mean', ...
    'Lower95', ...
    'Upper95'});

disp('----- MONTE CARLO SUMMARY TABLE -----');
disp(MonteCarloSummary);

fprintf('\nFull time-series Monte Carlo analysis complete.\n');