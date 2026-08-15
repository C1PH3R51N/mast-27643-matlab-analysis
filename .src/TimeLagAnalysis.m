clear;
clc;
close all;

%% MAST Shot 27643 - Time-Lag / Cross-Correlation Analysis

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - TIME-LAG ANALYSIS\n');
fprintf('========================================\n\n');

%% -------------------------------------------------
% 1. SELECT FILES
% --------------------------------------------------

[amcName, amcPath] = uigetfile('*.nc','Select amc27643.nc');
if isequal(amcName,0)
    error('AMC file not selected.');
end
amcFile = fullfile(amcPath,amcName);

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
% 2. LOAD RAW SIGNALS
% --------------------------------------------------

timeAMC = double(ncread(amcFile,'/time'));
plasmaCurrent = double(ncread( ...
    amcFile,'/amc/plasma_current/data'));

timeANB = double(ncread(anbFile,'/time'));
nbiPower = double(ncread( ...
    anbFile,'/anb/tot_sum_power/data'));

timeANU = double(ncread(anuFile,'/anu/neutrons/time'));
neutronRate = double(ncread( ...
    anuFile,'/anu/neutrons/data'));

fprintf('Raw signals loaded successfully.\n\n');

%% -------------------------------------------------
% 3. CREATE COMMON TIME GRID
% --------------------------------------------------

analysisStart = 0.00;
analysisEnd   = 0.50;
commonStep    = 0.0002;

commonTime = (analysisStart:commonStep:analysisEnd)';

%% -------------------------------------------------
% 4. ALIGN SIGNALS
% --------------------------------------------------

plasmaAligned = interp1( ...
    timeAMC, plasmaCurrent, commonTime, 'linear');

nbiAligned = interp1( ...
    timeANB, nbiPower, commonTime, 'linear');

neutronAligned = interp1( ...
    timeANU, neutronRate, commonTime, 'linear');

T = table( ...
    commonTime, ...
    plasmaAligned, ...
    nbiAligned, ...
    neutronAligned, ...
    'VariableNames', { ...
    'Time', ...
    'PlasmaCurrent', ...
    'NBIPower', ...
    'NeutronRate'});

T = rmmissing(T);

fprintf('Aligned observations: %d\n\n',height(T));

%% -------------------------------------------------
% 5. NORMALISE SIGNALS
% --------------------------------------------------
% Removes differences in physical scale before
% cross-correlation.

nbiNorm = (T.NBIPower - mean(T.NBIPower)) ...
          / std(T.NBIPower);

neutronNorm = (T.NeutronRate - mean(T.NeutronRate)) ...
              / std(T.NeutronRate);

plasmaNorm = (T.PlasmaCurrent - mean(T.PlasmaCurrent)) ...
             / std(T.PlasmaCurrent);

%% -------------------------------------------------
% 6. NBI vs NEUTRON CROSS-CORRELATION
% --------------------------------------------------
% Search +/- 100 ms.
% At 0.2 ms/sample:
% 100 ms = 500 samples.

maxLagSeconds = 0.100;
maxLagSamples = round(maxLagSeconds/commonStep);

[xcNBI,lagNBI] = xcorr( ...
    neutronNorm, ...
    nbiNorm, ...
    maxLagSamples, ...
    'coeff');

[peakNBI,indexNBI] = max(xcNBI);

bestLagSamplesNBI = lagNBI(indexNBI);
bestLagSecondsNBI = bestLagSamplesNBI * commonStep;
bestLagMsNBI = bestLagSecondsNBI * 1000;

fprintf('----- NBI vs NEUTRON RATE -----\n');
fprintf('Maximum cross-correlation : %.4f\n',peakNBI);
fprintf('Best lag                  : %d samples\n', ...
    bestLagSamplesNBI);
fprintf('Best lag                  : %.3f ms\n\n', ...
    bestLagMsNBI);

%% -------------------------------------------------
% 7. PLASMA CURRENT vs NEUTRON CROSS-CORRELATION
% --------------------------------------------------

[xcPlasma,lagPlasma] = xcorr( ...
    neutronNorm, ...
    plasmaNorm, ...
    maxLagSamples, ...
    'coeff');

[peakPlasma,indexPlasma] = max(xcPlasma);

bestLagSamplesPlasma = lagPlasma(indexPlasma);
bestLagSecondsPlasma = bestLagSamplesPlasma * commonStep;
bestLagMsPlasma = bestLagSecondsPlasma * 1000;

fprintf('----- PLASMA CURRENT vs NEUTRON RATE -----\n');
fprintf('Maximum cross-correlation : %.4f\n',peakPlasma);
fprintf('Best lag                  : %d samples\n', ...
    bestLagSamplesPlasma);
fprintf('Best lag                  : %.3f ms\n\n', ...
    bestLagMsPlasma);

%% -------------------------------------------------
% 8. PLOT NBI CROSS-CORRELATION
% --------------------------------------------------

lagTimeNBI = lagNBI * commonStep * 1000;

figure;

plot(lagTimeNBI,xcNBI,'LineWidth',1.5);
hold on;

plot(bestLagMsNBI,peakNBI,'o', ...
    'MarkerSize',8, ...
    'LineWidth',1.5);

xline(0,'--');

xlabel('Lag (ms)');
ylabel('Normalised Cross-Correlation');
title('NBI Power vs Neutron Rate - Cross-Correlation');

grid on;

%% -------------------------------------------------
% 9. PLOT PLASMA CROSS-CORRELATION
% --------------------------------------------------

lagTimePlasma = lagPlasma * commonStep * 1000;

figure;

plot(lagTimePlasma,xcPlasma,'LineWidth',1.5);
hold on;

plot(bestLagMsPlasma,peakPlasma,'o', ...
    'MarkerSize',8, ...
    'LineWidth',1.5);

xline(0,'--');

xlabel('Lag (ms)');
ylabel('Normalised Cross-Correlation');
title('Plasma Current vs Neutron Rate - Cross-Correlation');

grid on;

%% -------------------------------------------------
% 10. VISUALISE NORMALISED TIME SERIES
% --------------------------------------------------

figure;

plot(T.Time,nbiNorm,'LineWidth',1);
hold on;

plot(T.Time,neutronNorm,'LineWidth',1);

xlabel('Time (s)');
ylabel('Normalised Signal');
title('NBI Power and Neutron Rate - Normalised Comparison');

legend('NBI Power','Neutron Rate','Location','best');
grid on;

fprintf('Time-lag analysis complete.\n');