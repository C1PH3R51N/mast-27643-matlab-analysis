clear;
clc;
close all;

%% MAST Shot 27643 - Exploratory Data Analysis

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - EXPLORATORY ANALYSIS\n');
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
% 2. LOAD SIGNALS
% --------------------------------------------------

timeAMC = double(ncread(amcFile,'/time'));
plasmaCurrent = double(ncread(amcFile,'/amc/plasma_current/data'));

timeANB = double(ncread(anbFile,'/time'));
nbiPower = double(ncread(anbFile,'/anb/tot_sum_power/data'));

timeANU = double(ncread(anuFile,'/anu/neutrons/time'));
neutronRate = double(ncread(anuFile,'/anu/neutrons/data'));

timeANUErr = double(ncread(anuFile,'/anu/errors/time'));
neutronError = double(ncread(anuFile,'/anu/errors/data'));

%% -------------------------------------------------
% 3. COMMON TIME WINDOW
% --------------------------------------------------

analysisStart = 0.00;
analysisEnd   = 0.50;
commonStep    = 0.0002;

commonTime = (analysisStart:commonStep:analysisEnd)';

%% -------------------------------------------------
% 4. ALIGN SIGNALS
% --------------------------------------------------

plasmaCurrentAligned = interp1( ...
    timeAMC, plasmaCurrent, commonTime, 'linear');

nbiPowerAligned = interp1( ...
    timeANB, nbiPower, commonTime, 'linear');

neutronRateAligned = interp1( ...
    timeANU, neutronRate, commonTime, 'linear');

neutronErrorAligned = interp1( ...
    timeANUErr, neutronError, commonTime, 'linear');

AlignedData = table( ...
    commonTime, ...
    plasmaCurrentAligned, ...
    nbiPowerAligned, ...
    neutronRateAligned, ...
    neutronErrorAligned, ...
    'VariableNames', { ...
    'Time_s', ...
    'PlasmaCurrent_kA', ...
    'NBIPower_MW', ...
    'NeutronRate_n_s', ...
    'NeutronError'});

AlignedData = rmmissing(AlignedData);

fprintf('Aligned observations available: %d\n\n',height(AlignedData));

%% -------------------------------------------------
% 5. DESCRIPTIVE STATISTICS
% --------------------------------------------------

fprintf('----- DESCRIPTIVE STATISTICS -----\n\n');

variables = { ...
    AlignedData.PlasmaCurrent_kA, ...
    AlignedData.NBIPower_MW, ...
    AlignedData.NeutronRate_n_s};

names = ["Plasma Current","NBI Power","Neutron Rate"];

for i = 1:length(variables)

    x = variables{i};

    fprintf('%s\n',names(i));
    fprintf('Mean   : %.4g\n',mean(x));
    fprintf('Median : %.4g\n',median(x));
    fprintf('Std    : %.4g\n',std(x));
    fprintf('Min    : %.4g\n',min(x));
    fprintf('Max    : %.4g\n\n',max(x));

end

%% -------------------------------------------------
% 6. CORRELATION MATRIX
% --------------------------------------------------

X = [ ...
    AlignedData.PlasmaCurrent_kA, ...
    AlignedData.NBIPower_MW, ...
    AlignedData.NeutronRate_n_s];

R = corrcoef(X);

fprintf('----- CORRELATION MATRIX -----\n\n');

disp(array2table(R, ...
    'VariableNames',{'PlasmaCurrent','NBIPower','NeutronRate'}, ...
    'RowNames',{'PlasmaCurrent','NBIPower','NeutronRate'}));

%% -------------------------------------------------
% 7. SCATTER PLOTS
% --------------------------------------------------

figure;

scatter( ...
    AlignedData.NBIPower_MW, ...
    AlignedData.NeutronRate_n_s, ...
    10,'filled');

xlabel('NBI Power (MW)');
ylabel('Neutron Rate (neutrons/s)');
title('NBI Power vs Neutron Rate');
grid on;

figure;

scatter( ...
    AlignedData.PlasmaCurrent_kA, ...
    AlignedData.NeutronRate_n_s, ...
    10,'filled');

xlabel('Plasma Current (kA)');
ylabel('Neutron Rate (neutrons/s)');
title('Plasma Current vs Neutron Rate');
grid on;

%% -------------------------------------------------
% 8. DEFINE NBI OPERATING PHASES
% --------------------------------------------------

phase1Mask = ...
    AlignedData.NBIPower_MW >= 1.5 & ...
    AlignedData.NBIPower_MW < 2.3;

phase2Mask = ...
    AlignedData.NBIPower_MW >= 2.8 & ...
    AlignedData.NBIPower_MW <= 3.6;

fprintf('\n----- NBI OPERATING PHASES -----\n\n');

fprintf('Phase 1 observations: %d\n',sum(phase1Mask));
fprintf('Phase 2 observations: %d\n\n',sum(phase2Mask));

phase1MeanNBI = mean(AlignedData.NBIPower_MW(phase1Mask));
phase2MeanNBI = mean(AlignedData.NBIPower_MW(phase2Mask));

phase1MeanNeutrons = mean(AlignedData.NeutronRate_n_s(phase1Mask));
phase2MeanNeutrons = mean(AlignedData.NeutronRate_n_s(phase2Mask));

fprintf('Phase 1 mean NBI power     : %.3f MW\n',phase1MeanNBI);
fprintf('Phase 1 mean neutron rate  : %.4e n/s\n\n',phase1MeanNeutrons);

fprintf('Phase 2 mean NBI power     : %.3f MW\n',phase2MeanNBI);
fprintf('Phase 2 mean neutron rate  : %.4e n/s\n\n',phase2MeanNeutrons);

neutronIncrease = ...
    100 * (phase2MeanNeutrons - phase1MeanNeutrons) ...
    / phase1MeanNeutrons;

fprintf('Mean neutron-rate increase from Phase 1 to Phase 2: %.2f %%\n\n', ...
    neutronIncrease);

%% -------------------------------------------------
% 9. PHASE COMPARISON VISUALISATION
% --------------------------------------------------

figure;

phaseLabels = categorical({'Phase 1','Phase 2'});

meanNeutronValues = [ ...
    phase1MeanNeutrons, ...
    phase2MeanNeutrons];

bar(phaseLabels,meanNeutronValues);

ylabel('Mean Neutron Rate (neutrons/s)');
title('Neutron Production by NBI Operating Phase');
grid on;

%% -------------------------------------------------
% 10. CORRELATION HEATMAP
% --------------------------------------------------

figure;

h = heatmap( ...
    {'Plasma Current','NBI Power','Neutron Rate'}, ...
    {'Plasma Current','NBI Power','Neutron Rate'}, ...
    R);

h.Title = 'Diagnostic Correlation Matrix';

fprintf('Exploratory analysis complete.\n');