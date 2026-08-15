clear;
clc;
close all;

%% =========================================================
% MAST SHOT 27643
% STAGE 10 - FINAL ANALYSIS AND ROBUST EXPORT
% ==========================================================

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - FINAL ANALYSIS\n');
fprintf('========================================\n\n');

%% ---------------------------------------------------------
% 1. SELECT FILES
% ----------------------------------------------------------

[amcName,amcPath] = uigetfile('*.nc','Select amc27643.nc');

if isequal(amcName,0)
    error('AMC file not selected.');
end

amcFile = fullfile(amcPath,amcName);


[anbName,anbPath] = uigetfile('*.nc','Select anb27643.nc');

if isequal(anbName,0)
    error('ANB file not selected.');
end

anbFile = fullfile(anbPath,anbName);


[anuName,anuPath] = uigetfile('*.nc','Select anu27643.nc');

if isequal(anuName,0)
    error('ANU file not selected.');
end

anuFile = fullfile(anuPath,anuName);

fprintf('Files successfully selected.\n\n');

%% ---------------------------------------------------------
% 2. LOAD RAW DATA
% ----------------------------------------------------------

timeAMC = double(ncread(amcFile,'/time'));

plasmaCurrent = double(ncread( ...
    amcFile,'/amc/plasma_current/data'));


timeANB = double(ncread(anbFile,'/time'));

nbiPower = double(ncread( ...
    anbFile,'/anb/tot_sum_power/data'));


timeANU = double(ncread( ...
    anuFile,'/anu/neutrons/time'));

neutronRate = double(ncread( ...
    anuFile,'/anu/neutrons/data'));


timeANUErr = double(ncread( ...
    anuFile,'/anu/errors/time'));

neutronError = double(ncread( ...
    anuFile,'/anu/errors/data'));

fprintf('Raw data loaded successfully.\n\n');

%% ---------------------------------------------------------
% 3. ALIGN DATA
% ----------------------------------------------------------

analysisStart = 0.00;
analysisEnd   = 0.50;

commonStep = 0.0002;

commonTime = ...
    (analysisStart:commonStep:analysisEnd)';

plasma = interp1( ...
    timeAMC, ...
    plasmaCurrent, ...
    commonTime, ...
    'linear');

nbi = interp1( ...
    timeANB, ...
    nbiPower, ...
    commonTime, ...
    'linear');

neutrons = interp1( ...
    timeANU, ...
    neutronRate, ...
    commonTime, ...
    'linear');

neutronErr = interp1( ...
    timeANUErr, ...
    neutronError, ...
    commonTime, ...
    'linear');

valid = ...
    isfinite(plasma) & ...
    isfinite(nbi) & ...
    isfinite(neutrons) & ...
    isfinite(neutronErr);

time = commonTime(valid);

plasma = plasma(valid);
nbi = nbi(valid);
neutrons = neutrons(valid);
neutronErr = neutronErr(valid);

fprintf('Aligned observations : %d\n\n',length(time));

%% ---------------------------------------------------------
% 4. CORRELATION ANALYSIS
% ----------------------------------------------------------

R = corrcoef([ ...
    plasma, ...
    nbi, ...
    neutrons]);

plasmaNeutronCorrelation = R(1,3);
nbiNeutronCorrelation = R(2,3);

%% ---------------------------------------------------------
% 5. NBI OPERATING PHASES
% ----------------------------------------------------------

phase1 = ...
    nbi >= 1.5 & ...
    nbi < 2.3;

phase2 = ...
    nbi >= 2.8 & ...
    nbi <= 3.6;

phase1Neutron = ...
    mean(neutrons(phase1));

phase2Neutron = ...
    mean(neutrons(phase2));

phaseIncreaseMeasured = ...
    100 * ...
    (phase2Neutron-phase1Neutron) ...
    / phase1Neutron;

%% ---------------------------------------------------------
% 6. MEASURED PEAK
% ----------------------------------------------------------

[measuredPeak,measuredPeakIndex] = ...
    max(neutrons);

measuredPeakTime = ...
    time(measuredPeakIndex);

%% ---------------------------------------------------------
% 7. MONTE CARLO ANALYSIS
% ----------------------------------------------------------

numSimulations = 10000;

rng(27643);

fprintf('Running Monte Carlo analysis...\n');

fprintf('Simulations          : %d\n', ...
    numSimulations);

fprintf('Simulated values     : %d\n\n', ...
    numSimulations * length(time));

%% Assumptions:
%
% ANU_ERRORS treated as assumed 1-sigma
% Gaussian measurement uncertainty.
%
% Errors assumed independent between
% individual time samples.

randomNoise = ...
    randn(length(time),numSimulations);

simulatedRates = ...
    neutrons + ...
    neutronErr .* randomNoise;

%% ---------------------------------------------------------
% 8. POINTWISE MONTE CARLO RESULTS
% ----------------------------------------------------------

mcMean = ...
    mean(simulatedRates,2);

mcLower95 = ...
    prctile(simulatedRates,2.5,2);

mcUpper95 = ...
    prctile(simulatedRates,97.5,2);

%% ---------------------------------------------------------
% 9. MONTE CARLO PHASE ANALYSIS
% ----------------------------------------------------------

phase1SimulationMeans = ...
    mean(simulatedRates(phase1,:),1);

phase2SimulationMeans = ...
    mean(simulatedRates(phase2,:),1);

phaseIncrease = ...
    100 * ...
    (phase2SimulationMeans - ...
    phase1SimulationMeans) ...
    ./ phase1SimulationMeans;

phaseIncreaseMean = ...
    mean(phaseIncrease);

phaseIncreaseMedian = ...
    median(phaseIncrease);

phaseIncreaseCI = ...
    prctile(phaseIncrease,[2.5 97.5]);

%% ---------------------------------------------------------
% 10. MONTE CARLO PEAK ANALYSIS
% ----------------------------------------------------------

[simulationPeaks,peakIndices] = ...
    max(simulatedRates,[],1);

simulationPeakTimes = ...
    time(peakIndices);

peakRateMean = ...
    mean(simulationPeaks);

peakRateCI = ...
    prctile(simulationPeaks,[2.5 97.5]);

peakTimeMean = ...
    mean(simulationPeakTimes);

peakTimeMedian = ...
    median(simulationPeakTimes);

peakTimeCI = ...
    prctile(simulationPeakTimes,[2.5 97.5]);

%% ---------------------------------------------------------
% 11. DISPLAY FINAL RESULTS
% ----------------------------------------------------------

fprintf('========================================\n');
fprintf(' FINAL ANALYSIS RESULTS\n');
fprintf('========================================\n\n');

fprintf('Aligned observations\n');
fprintf('--------------------\n');
fprintf('%d\n\n',length(time));

fprintf('Correlation Analysis\n');
fprintf('--------------------\n');
fprintf('Plasma-Neutron r : %.4f\n', ...
    plasmaNeutronCorrelation);

fprintf('NBI-Neutron r    : %.4f\n\n', ...
    nbiNeutronCorrelation);

fprintf('Measured Peak\n');
fprintf('-------------\n');

fprintf('Peak neutron rate : %.4e n/s\n', ...
    measuredPeak);

fprintf('Peak time         : %.6f s\n\n', ...
    measuredPeakTime);

fprintf('NBI Phase Analysis\n');
fprintf('------------------\n');

fprintf('Phase 1 mean : %.4e n/s\n', ...
    phase1Neutron);

fprintf('Phase 2 mean : %.4e n/s\n', ...
    phase2Neutron);

fprintf('Measured increase : %.3f %%\n\n', ...
    phaseIncreaseMeasured);

fprintf('Monte Carlo Phase Analysis\n');
fprintf('--------------------------\n');

fprintf('Mean increase   : %.3f %%\n', ...
    phaseIncreaseMean);

fprintf('Median increase : %.3f %%\n', ...
    phaseIncreaseMedian);

fprintf('95%% interval    : %.3f %% to %.3f %%\n\n', ...
    phaseIncreaseCI(1), ...
    phaseIncreaseCI(2));

fprintf('Monte Carlo Peak Timing\n');
fprintf('-----------------------\n');

fprintf('Mean peak time   : %.6f s\n', ...
    peakTimeMean);

fprintf('Median peak time : %.6f s\n', ...
    peakTimeMedian);

fprintf('95%% interval     : %.6f to %.6f s\n\n', ...
    peakTimeCI(1), ...
    peakTimeCI(2));

%% ---------------------------------------------------------
% 12. CREATE CLEANED DATA TABLE
% ----------------------------------------------------------

CleanedData = table( ...
    time, ...
    plasma, ...
    nbi, ...
    neutrons, ...
    neutronErr, ...
    mcMean, ...
    mcLower95, ...
    mcUpper95, ...
    'VariableNames',{ ...
    'Time_s', ...
    'PlasmaCurrent_kA', ...
    'NBIPower_MW', ...
    'NeutronRate_n_s', ...
    'NeutronError', ...
    'MonteCarloMean', ...
    'MonteCarloLower95', ...
    'MonteCarloUpper95'});

%% ---------------------------------------------------------
% 13. CREATE FINAL SUMMARY TABLE
% ----------------------------------------------------------

Metric = { ...
    'Aligned observations'; ...
    'Plasma-Neutron correlation'; ...
    'NBI-Neutron correlation'; ...
    'Measured peak neutron rate'; ...
    'Measured peak time'; ...
    'Phase 1 mean neutron rate'; ...
    'Phase 2 mean neutron rate'; ...
    'Measured phase increase percent'; ...
    'MC mean phase increase percent'; ...
    'MC phase increase lower 95 percent'; ...
    'MC phase increase upper 95 percent'; ...
    'MC mean peak time'; ...
    'MC peak time lower 95'; ...
    'MC peak time upper 95'; ...
    'MC mean simulated maximum'; ...
    'MC maximum lower 95'; ...
    'MC maximum upper 95'};

Value = [ ...
    length(time); ...
    plasmaNeutronCorrelation; ...
    nbiNeutronCorrelation; ...
    measuredPeak; ...
    measuredPeakTime; ...
    phase1Neutron; ...
    phase2Neutron; ...
    phaseIncreaseMeasured; ...
    phaseIncreaseMean; ...
    phaseIncreaseCI(1); ...
    phaseIncreaseCI(2); ...
    peakTimeMean; ...
    peakTimeCI(1); ...
    peakTimeCI(2); ...
    peakRateMean; ...
    peakRateCI(1); ...
    peakRateCI(2)];

ResultsSummary = table( ...
    Metric, ...
    Value);

%% ---------------------------------------------------------
% 14. EXPORT NUMERICAL RESULTS FIRST
% ----------------------------------------------------------

fprintf('Exporting numerical results...\n');

writetable( ...
    CleanedData, ...
    'MAST27643_CleanedData.csv');

writetable( ...
    ResultsSummary, ...
    'MAST27643_ResultsSummary.csv');

save( ...
    'MAST27643_FinalAnalysis.mat', ...
    'CleanedData', ...
    'ResultsSummary', ...
    'phaseIncrease', ...
    'simulationPeakTimes', ...
    'simulationPeaks');

fprintf('Numerical results exported successfully.\n\n');

%% ---------------------------------------------------------
% 15. CLEAR LARGE MONTE CARLO MATRIX
% ----------------------------------------------------------
%
% We no longer need the complete 25-million-value
% matrix for plotting.
%

clear randomNoise;
clear simulatedRates;

fprintf('Large Monte Carlo matrices cleared from memory.\n\n');

%% =========================================================
% ROBUST INDIVIDUAL FIGURE EXPORT
% ==========================================================

fprintf('Creating individual analysis figures...\n\n');

%% ---------------------------------------------------------
% FIGURE 1 - PLASMA CURRENT
% ----------------------------------------------------------

try

    f1 = figure( ...
        'Visible','off', ...
        'Color','w');

    plot( ...
        time, ...
        plasma, ...
        'LineWidth',1.2);

    xlabel('Time (s)');
    ylabel('Plasma Current (kA)');

    title('MAST Shot 27643 - Plasma Current');

    grid on;
    box on;

    drawnow;

    print( ...
        f1, ...
        '01_PlasmaCurrent.png', ...
        '-dpng', ...
        '-r200');

    close(f1);

    fprintf('Figure 1 exported.\n');

catch ME

    fprintf('Figure 1 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 2 - NBI POWER
% ----------------------------------------------------------

try

    f2 = figure( ...
        'Visible','off', ...
        'Color','w');

    plot( ...
        time, ...
        nbi, ...
        'LineWidth',1.2);

    xlabel('Time (s)');
    ylabel('NBI Power (MW)');

    title('MAST Shot 27643 - NBI Power');

    grid on;
    box on;

    drawnow;

    print( ...
        f2, ...
        '02_NBIPower.png', ...
        '-dpng', ...
        '-r200');

    close(f2);

    fprintf('Figure 2 exported.\n');

catch ME

    fprintf('Figure 2 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 3 - NEUTRON RATE
% ----------------------------------------------------------

try

    f3 = figure( ...
        'Visible','off', ...
        'Color','w');

    plot( ...
        time, ...
        neutrons, ...
        'LineWidth',1.2);

    xlabel('Time (s)');
    ylabel('Neutron Rate (neutrons/s)');

    title('MAST Shot 27643 - Neutron Production');

    grid on;
    box on;

    drawnow;

    print( ...
        f3, ...
        '03_NeutronRate.png', ...
        '-dpng', ...
        '-r200');

    close(f3);

    fprintf('Figure 3 exported.\n');

catch ME

    fprintf('Figure 3 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 4 - NBI VS NEUTRON RATE
% ----------------------------------------------------------

try

    f4 = figure( ...
        'Visible','off', ...
        'Color','w');

    scatter( ...
        nbi, ...
        neutrons, ...
        8, ...
        'filled');

    xlabel('NBI Power (MW)');
    ylabel('Neutron Rate (neutrons/s)');

    title(sprintf( ...
        'NBI Power vs Neutron Rate (r = %.3f)', ...
        nbiNeutronCorrelation));

    grid on;
    box on;

    drawnow;

    print( ...
        f4, ...
        '04_NBI_vs_Neutron.png', ...
        '-dpng', ...
        '-r200');

    close(f4);

    fprintf('Figure 4 exported.\n');

catch ME

    fprintf('Figure 4 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 5 - PLASMA CURRENT VS NEUTRON RATE
% ----------------------------------------------------------

try

    f5 = figure( ...
        'Visible','off', ...
        'Color','w');

    scatter( ...
        plasma, ...
        neutrons, ...
        8, ...
        'filled');

    xlabel('Plasma Current (kA)');
    ylabel('Neutron Rate (neutrons/s)');

    title(sprintf( ...
        'Plasma Current vs Neutron Rate (r = %.3f)', ...
        plasmaNeutronCorrelation));

    grid on;
    box on;

    drawnow;

    print( ...
        f5, ...
        '05_Plasma_vs_Neutron.png', ...
        '-dpng', ...
        '-r200');

    close(f5);

    fprintf('Figure 5 exported.\n');

catch ME

    fprintf('Figure 5 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 6 - NBI PHASE COMPARISON
% ----------------------------------------------------------

try

    f6 = figure( ...
        'Visible','off', ...
        'Color','w');

    phaseValues = [ ...
        phase1Neutron ...
        phase2Neutron];

    bar( ...
        categorical({'Phase 1','Phase 2'}), ...
        phaseValues);

    ylabel('Mean Neutron Rate (neutrons/s)');

    title(sprintf( ...
        'Neutron Production by NBI Phase (+%.2f%%)', ...
        phaseIncreaseMeasured));

    grid on;
    box on;

    drawnow;

    print( ...
        f6, ...
        '06_NBI_PhaseComparison.png', ...
        '-dpng', ...
        '-r200');

    close(f6);

    fprintf('Figure 6 exported.\n');

catch ME

    fprintf('Figure 6 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 7 - MONTE CARLO ENVELOPE
% ----------------------------------------------------------

try

    f7 = figure( ...
        'Visible','off', ...
        'Color','w');

    fill( ...
        [time; flipud(time)], ...
        [mcUpper95; flipud(mcLower95)], ...
        [0.85 0.85 0.85], ...
        'EdgeColor','none');

    hold on;

    plot( ...
        time, ...
        neutrons, ...
        'LineWidth',1.2);

    plot( ...
        time, ...
        mcMean, ...
        '--', ...
        'LineWidth',1);

    xlabel('Time (s)');
    ylabel('Neutron Rate (neutrons/s)');

    title( ...
        'Full Time-Series Monte Carlo Uncertainty');

    legend( ...
        '95% Monte Carlo Envelope', ...
        'Measured Neutron Rate', ...
        'Monte Carlo Mean', ...
        'Location','best');

    grid on;
    box on;

    drawnow;

    print( ...
        f7, ...
        '07_MonteCarlo_UncertaintyEnvelope.png', ...
        '-dpng', ...
        '-r200');

    close(f7);

    fprintf('Figure 7 exported.\n');

catch ME

    fprintf('Figure 7 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 8 - PHASE INCREASE DISTRIBUTION
% ----------------------------------------------------------

try

    f8 = figure( ...
        'Visible','off', ...
        'Color','w');

    histogram( ...
        phaseIncrease, ...
        60);

    hold on;

    xline( ...
        phaseIncreaseMean, ...
        '--', ...
        'LineWidth',1.5);

    xline( ...
        phaseIncreaseCI(1), ...
        ':', ...
        'LineWidth',1.2);

    xline( ...
        phaseIncreaseCI(2), ...
        ':', ...
        'LineWidth',1.2);

    xlabel( ...
        'Phase 1 to Phase 2 Increase (%)');

    ylabel('Frequency');

    title( ...
        'Monte Carlo Distribution of NBI Phase Increase');

    grid on;
    box on;

    drawnow;

    print( ...
        f8, ...
        '08_MC_PhaseIncrease.png', ...
        '-dpng', ...
        '-r200');

    close(f8);

    fprintf('Figure 8 exported.\n');

catch ME

    fprintf('Figure 8 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 9 - PEAK TIMING DISTRIBUTION
% ----------------------------------------------------------

try

    f9 = figure( ...
        'Visible','off', ...
        'Color','w');

    histogram( ...
        simulationPeakTimes, ...
        50);

    xlabel('Peak Time (s)');
    ylabel('Frequency');

    title( ...
        'Monte Carlo Distribution of Peak Timing');

    grid on;
    box on;

    drawnow;

    print( ...
        f9, ...
        '09_MC_PeakTiming.png', ...
        '-dpng', ...
        '-r200');

    close(f9);

    fprintf('Figure 9 exported.\n');

catch ME

    fprintf('Figure 9 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% FIGURE 10 - SIMULATED MAXIMUM DISTRIBUTION
% ----------------------------------------------------------

try

    f10 = figure( ...
        'Visible','off', ...
        'Color','w');

    histogram( ...
        simulationPeaks, ...
        60);

    xlabel( ...
        'Simulated Maximum Neutron Rate (neutrons/s)');

    ylabel('Frequency');

    title( ...
        'Monte Carlo Distribution of Time-Series Maximum');

    grid on;
    box on;

    drawnow;

    print( ...
        f10, ...
        '10_MC_MaximumDistribution.png', ...
        '-dpng', ...
        '-r200');

    close(f10);

    fprintf('Figure 10 exported.\n');

catch ME

    fprintf('Figure 10 export failed: %s\n', ...
        ME.message);

    close all;

end

%% ---------------------------------------------------------
% 16. CREATE TEXT SUMMARY FILE
% ----------------------------------------------------------

fid = fopen( ...
    'MAST27643_FinalSummary.txt', ...
    'w');

if fid ~= -1

    fprintf(fid, ...
        'MAST SHOT 27643 - FINAL ANALYSIS SUMMARY\n');

    fprintf(fid, ...
        '=======================================\n\n');

    fprintf(fid, ...
        'Aligned observations: %d\n\n', ...
        length(time));

    fprintf(fid, ...
        'Plasma-Neutron correlation: %.4f\n', ...
        plasmaNeutronCorrelation);

    fprintf(fid, ...
        'NBI-Neutron correlation: %.4f\n\n', ...
        nbiNeutronCorrelation);

    fprintf(fid, ...
        'Measured peak neutron rate: %.4e n/s\n', ...
        measuredPeak);

    fprintf(fid, ...
        'Measured peak time: %.6f s\n\n', ...
        measuredPeakTime);

    fprintf(fid, ...
        'Phase 1 mean neutron rate: %.4e n/s\n', ...
        phase1Neutron);

    fprintf(fid, ...
        'Phase 2 mean neutron rate: %.4e n/s\n', ...
        phase2Neutron);

    fprintf(fid, ...
        'Measured Phase 1 to Phase 2 increase: %.3f %%\n\n', ...
        phaseIncreaseMeasured);

    fprintf(fid, ...
        'Monte Carlo mean phase increase: %.3f %%\n', ...
        phaseIncreaseMean);

    fprintf(fid, ...
        'Monte Carlo 95%% phase interval: %.3f %% to %.3f %%\n\n', ...
        phaseIncreaseCI(1), ...
        phaseIncreaseCI(2));

    fprintf(fid, ...
        'Monte Carlo peak timing 95%% interval: %.6f to %.6f s\n\n', ...
        peakTimeCI(1), ...
        peakTimeCI(2));

    fprintf(fid, ...
        'Monte Carlo modelling assumptions:\n');

    fprintf(fid, ...
        '1. ANU_ERRORS treated as assumed 1-sigma Gaussian uncertainty.\n');

    fprintf(fid, ...
        '2. Measurement errors assumed independent between time samples.\n');

    fprintf(fid, ...
        '3. Simulated raw maxima are interpreted as sensitivity to uncertainty, not corrected physical peak estimates.\n');

    fclose(fid);

end

%% ---------------------------------------------------------
% 17. FINISH
% ----------------------------------------------------------

fprintf('\n========================================\n');
fprintf(' STAGE 10 COMPLETE\n');
fprintf('========================================\n\n');

fprintf('Numerical outputs:\n');
fprintf('  MAST27643_CleanedData.csv\n');
fprintf('  MAST27643_ResultsSummary.csv\n');
fprintf('  MAST27643_FinalAnalysis.mat\n');
fprintf('  MAST27643_FinalSummary.txt\n\n');

fprintf('Individual figure exports attempted:\n');
fprintf('  01_PlasmaCurrent.png\n');
fprintf('  02_NBIPower.png\n');
fprintf('  03_NeutronRate.png\n');
fprintf('  04_NBI_vs_Neutron.png\n');
fprintf('  05_Plasma_vs_Neutron.png\n');
fprintf('  06_NBI_PhaseComparison.png\n');
fprintf('  07_MonteCarlo_UncertaintyEnvelope.png\n');
fprintf('  08_MC_PhaseIncrease.png\n');
fprintf('  09_MC_PeakTiming.png\n');
fprintf('  10_MC_MaximumDistribution.png\n\n');

fprintf('Final analysis complete.\n');