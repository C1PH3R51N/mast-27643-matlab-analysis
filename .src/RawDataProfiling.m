clear;
clc;
close all;

%% MAST Shot 27643 - Raw Data Profiling
% Extract and assess diagnostic data before cleaning

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - RAW DATA PROFILING\n');
fprintf('========================================\n\n');

%% -------------------------------------------------
% 1. SELECT DATA FILES
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

fprintf('Files successfully selected.\n\n');

%% -------------------------------------------------
% 2. EXTRACT RAW SIGNALS
% --------------------------------------------------

% AMC - Plasma Current
timeAMC = ncread(amcFile,'/time');
plasmaCurrent = ncread(amcFile,'/amc/plasma_current/data');

% ANB - Total Neutral Beam Power
timeANB = ncread(anbFile,'/time');
nbiPower = ncread(anbFile,'/anb/tot_sum_power/data');

% ANU - Neutron Rate
timeANU = ncread(anuFile,'/anu/neutrons/time');
neutronRate = ncread(anuFile,'/anu/neutrons/data');

% ANU - Neutron Error
neutronError = ncread(anuFile,'/anu/errors/data');

fprintf('Raw diagnostic signals extracted successfully.\n\n');

%% -------------------------------------------------
% 3. DATASET SIZE
% --------------------------------------------------

fprintf('----- DATASET SIZE -----\n');

fprintf('AMC Plasma Current : %d observations\n',length(plasmaCurrent));
fprintf('ANB NBI Power      : %d observations\n',length(nbiPower));
fprintf('ANU Neutron Rate   : %d observations\n\n',length(neutronRate));

%% -------------------------------------------------
% 4. RAW DATA QUALITY PROFILE
% --------------------------------------------------

signalNames = ["Plasma Current"; "NBI Power"; "Neutron Rate"];

signals = {
    double(plasmaCurrent)
    double(nbiPower)
    double(neutronRate)
};

fprintf('----- RAW DATA QUALITY -----\n\n');

for i = 1:length(signals)

    x = signals{i};

    fprintf('%s\n',signalNames(i));
    fprintf('Observations : %d\n',length(x));
    fprintf('NaN          : %d\n',sum(isnan(x)));
    fprintf('Inf          : %d\n',sum(isinf(x)));
    fprintf('Zero         : %d\n',sum(x == 0));
    fprintf('Negative     : %d\n',sum(x < 0));

    valid = x(isfinite(x));

    fprintf('Minimum      : %.4g\n',min(valid));
    fprintf('Maximum      : %.4g\n',max(valid));
    fprintf('Mean         : %.4g\n',mean(valid));
    fprintf('Median       : %.4g\n',median(valid));
    fprintf('Std Dev      : %.4g\n\n',std(valid));

end

%% -------------------------------------------------
% 5. SAMPLING INFORMATION
% --------------------------------------------------

fprintf('----- SAMPLING -----\n');

fprintf('AMC median timestep : %.8f s\n',median(diff(timeAMC)));
fprintf('ANB median timestep : %.8f s\n',median(diff(timeANB)));
fprintf('ANU median timestep : %.8f s\n',median(diff(timeANU)));

fprintf('\nRaw data profiling complete.\n');