clear;
clc;
close all;

%% MAST Shot 27643 - Time Alignment and Resampling

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - TIME ALIGNMENT\n');
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

timeAMC_raw = double(ncread(amcFile,'/time'));
plasmaCurrent_raw = double(ncread(amcFile,'/amc/plasma_current/data'));

timeANB_raw = double(ncread(anbFile,'/time'));
nbiPower_raw = double(ncread(anbFile,'/anb/tot_sum_power/data'));

timeANU_raw = double(ncread(anuFile,'/anu/neutrons/time'));
neutronRate_raw = double(ncread(anuFile,'/anu/neutrons/data'));

timeANUErr_raw = double(ncread(anuFile,'/anu/errors/time'));
neutronError_raw = double(ncread(anuFile,'/anu/errors/data'));

fprintf('Raw signals loaded successfully.\n\n');

%% -------------------------------------------------
% 3. DEFINE COMMON ANALYSIS WINDOW
% --------------------------------------------------

analysisStart = 0.00;
analysisEnd   = 0.50;

maskAMC = timeAMC_raw >= analysisStart & timeAMC_raw <= analysisEnd;
maskANB = timeANB_raw >= analysisStart & timeANB_raw <= analysisEnd;
maskANU = timeANU_raw >= analysisStart & timeANU_raw <= analysisEnd;
maskANUErr = timeANUErr_raw >= analysisStart & timeANUErr_raw <= analysisEnd;

timeAMC = timeAMC_raw(maskAMC);
plasmaCurrent = plasmaCurrent_raw(maskAMC);

timeANB = timeANB_raw(maskANB);
nbiPower = nbiPower_raw(maskANB);

timeANU = timeANU_raw(maskANU);
neutronRate = neutronRate_raw(maskANU);

timeANUErr = timeANUErr_raw(maskANUErr);
neutronError = neutronError_raw(maskANUErr);

%% -------------------------------------------------
% 4. CREATE COMMON TIME GRID
% --------------------------------------------------

commonStep = 0.0002;   % 200 microseconds

commonTime = (analysisStart:commonStep:analysisEnd)';

fprintf('Common timestep : %.7f s\n',commonStep);
fprintf('Common points   : %d\n\n',length(commonTime));

%% -------------------------------------------------
% 5. INTERPOLATE SIGNALS
% --------------------------------------------------

plasmaCurrentAligned = interp1( ...
    timeAMC, plasmaCurrent, commonTime, 'linear');

nbiPowerAligned = interp1( ...
    timeANB, nbiPower, commonTime, 'linear');

neutronRateAligned = interp1( ...
    timeANU, neutronRate, commonTime, 'linear');

neutronErrorAligned = interp1( ...
    timeANUErr, neutronError, commonTime, 'linear');

%% -------------------------------------------------
% 6. CHECK FOR MISSING VALUES AFTER ALIGNMENT
% --------------------------------------------------

fprintf('----- ALIGNMENT QUALITY -----\n');

fprintf('Plasma Current NaN : %d\n',sum(isnan(plasmaCurrentAligned)));
fprintf('NBI Power NaN      : %d\n',sum(isnan(nbiPowerAligned)));
fprintf('Neutron Rate NaN   : %d\n',sum(isnan(neutronRateAligned)));
fprintf('Neutron Error NaN  : %d\n\n',sum(isnan(neutronErrorAligned)));

%% -------------------------------------------------
% 7. CREATE ALIGNED TABLE
% --------------------------------------------------

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

disp('First 10 aligned observations:');
disp(AlignedData(1:10,:));

%% -------------------------------------------------
% 8. REMOVE ROWS WITH ANY NaN VALUES
% --------------------------------------------------

rowsBefore = height(AlignedData);

AlignedData = rmmissing(AlignedData);

rowsAfter = height(AlignedData);

fprintf('Rows before NaN removal : %d\n',rowsBefore);
fprintf('Rows after NaN removal  : %d\n',rowsAfter);
fprintf('Rows removed            : %d\n\n',rowsBefore - rowsAfter);

%% -------------------------------------------------
% 9. VISUALISE ALIGNED SIGNALS
% --------------------------------------------------

figure;

tiledlayout(3,1);

nexttile;
plot(AlignedData.Time_s, ...
     AlignedData.PlasmaCurrent_kA, ...
     'LineWidth',1);

ylabel('Current (kA)');
title('Aligned Plasma Current');
grid on;

nexttile;
plot(AlignedData.Time_s, ...
     AlignedData.NBIPower_MW, ...
     'LineWidth',1);

ylabel('Power (MW)');
title('Aligned NBI Power');
grid on;

nexttile;
plot(AlignedData.Time_s, ...
     AlignedData.NeutronRate_n_s, ...
     'LineWidth',1);

xlabel('Time (s)');
ylabel('Neutrons/s');
title('Aligned Neutron Rate');
grid on;

sgtitle('MAST Shot 27643 - Time-Aligned Diagnostic Signals');

fprintf('Time alignment complete.\n');