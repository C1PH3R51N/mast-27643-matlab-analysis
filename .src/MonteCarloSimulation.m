clear;
clc;
close all;

%% MAST Shot 27643 - Monte Carlo Uncertainty Simulation

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - MONTE CARLO ANALYSIS\n');
fprintf('========================================\n\n');

%% -------------------------------------------------
% 1. INPUT MEASUREMENT
% --------------------------------------------------

measuredNeutronRate = 1.0610e14;   % neutrons/s
assumedSigma        = 8.9091e12;   % assumed 1-sigma error
numSimulations      = 100000;

fprintf('Measured neutron rate : %.4e n/s\n',measuredNeutronRate);
fprintf('Assumed 1-sigma error : %.4e n/s\n',assumedSigma);
fprintf('Simulations           : %d\n\n',numSimulations);

%% -------------------------------------------------
% 2. SET RANDOM SEED
% -------------------------------------------------
% Makes the simulation reproducible.

rng(27643);

%% -------------------------------------------------
% 3. RUN MONTE CARLO SIMULATION
% -------------------------------------------------

simulatedNeutronRates = ...
    measuredNeutronRate + assumedSigma .* randn(numSimulations,1);

%% -------------------------------------------------
% 4. BASIC SIMULATION STATISTICS
% --------------------------------------------------

simMean   = mean(simulatedNeutronRates);
simMedian = median(simulatedNeutronRates);
simStd    = std(simulatedNeutronRates);

CI95 = prctile(simulatedNeutronRates,[2.5 97.5]);

lower95 = CI95(1);
upper95 = CI95(2);

fprintf('----- MONTE CARLO RESULTS -----\n\n');

fprintf('Simulation mean        : %.4e n/s\n',simMean);
fprintf('Simulation median      : %.4e n/s\n',simMedian);
fprintf('Simulation SD          : %.4e n/s\n\n',simStd);

fprintf('95%% simulation interval\n');
fprintf('Lower bound            : %.4e n/s\n',lower95);
fprintf('Upper bound            : %.4e n/s\n\n',upper95);

%% -------------------------------------------------
% 5. RELATIVE SIMULATION UNCERTAINTY
% --------------------------------------------------

relativeSD = 100 * simStd / simMean;

fprintf('Relative simulation SD : %.3f %%\n\n',relativeSD);

%% -------------------------------------------------
% 6. EXCEEDANCE PROBABILITIES
% -------------------------------------------------

threshold1 = 1.00e14;
threshold2 = 1.10e14;
threshold3 = 1.20e14;

prob1 = mean(simulatedNeutronRates > threshold1) * 100;
prob2 = mean(simulatedNeutronRates > threshold2) * 100;
prob3 = mean(simulatedNeutronRates > threshold3) * 100;

fprintf('----- EXCEEDANCE PROBABILITIES -----\n\n');

fprintf('P(rate > 1.00e14 n/s) : %.2f %%\n',prob1);
fprintf('P(rate > 1.10e14 n/s) : %.2f %%\n',prob2);
fprintf('P(rate > 1.20e14 n/s) : %.2f %%\n\n',prob3);

%% -------------------------------------------------
% 7. HISTOGRAM
% --------------------------------------------------

figure;

histogram(simulatedNeutronRates,100, ...
    'Normalization','pdf');

hold on;

xline(measuredNeutronRate, ...
    'LineWidth',1.5);

xline(lower95,'--', ...
    'LineWidth',1.2);

xline(upper95,'--', ...
    'LineWidth',1.2);

xlabel('Neutron Rate (neutrons/s)');
ylabel('Probability Density');

title('Monte Carlo Distribution of Peak Neutron Rate');

legend( ...
    'Simulated Distribution', ...
    'Measured Value', ...
    '95% Lower Bound', ...
    '95% Upper Bound', ...
    'Location','best');

grid on;

%% -------------------------------------------------
% 8. CONVERGENCE ANALYSIS
% -------------------------------------------------

sampleSizes = [100 500 1000 5000 10000 50000 100000];

runningMeans = zeros(size(sampleSizes));
runningStd   = zeros(size(sampleSizes));

for i = 1:length(sampleSizes)

    n = sampleSizes(i);

    runningMeans(i) = mean(simulatedNeutronRates(1:n));
    runningStd(i)   = std(simulatedNeutronRates(1:n));

end

figure;

plot(sampleSizes,runningMeans,'-o','LineWidth',1.2);

yline(measuredNeutronRate,'--');

set(gca,'XScale','log');

xlabel('Number of Simulations');
ylabel('Estimated Mean Neutron Rate (n/s)');

title('Monte Carlo Mean Convergence');

grid on;

figure;

plot(sampleSizes,runningStd,'-o','LineWidth',1.2);

yline(assumedSigma,'--');

set(gca,'XScale','log');

xlabel('Number of Simulations');
ylabel('Estimated Standard Deviation (n/s)');

title('Monte Carlo Standard Deviation Convergence');

grid on;

fprintf('Monte Carlo simulation complete.\n');