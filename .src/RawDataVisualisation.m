clear;
clc;
close all;

%% MAST Shot 27643 - Raw Data Visualisation

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - RAW VISUALISATION\n');
fprintf('========================================\n\n');

%% Select files

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

%% Extract raw signals

timeAMC = ncread(amcFile,'/time');
plasmaCurrent = double(ncread(amcFile,'/amc/plasma_current/data'));

timeANB = ncread(anbFile,'/time');
nbiPower = double(ncread(anbFile,'/anb/tot_sum_power/data'));

timeANU = ncread(anuFile,'/anu/neutrons/time');
neutronRate = double(ncread(anuFile,'/anu/neutrons/data'));

fprintf('Raw signals loaded successfully.\n\n');

%% Plot 1 - Plasma Current

figure;

plot(timeAMC,plasmaCurrent,'LineWidth',1);

xlabel('Time (s)');
ylabel('Plasma Current (kA)');
title('MAST Shot 27643 - Raw Plasma Current');

grid on;

%% Plot 2 - NBI Power

figure;

plot(timeANB,nbiPower,'LineWidth',1);

xlabel('Time (s)');
ylabel('NBI Power (MW)');
title('MAST Shot 27643 - Raw Neutral Beam Injection Power');

grid on;

%% Plot 3 - Neutron Rate

figure;

plot(timeANU,neutronRate,'LineWidth',1);

xlabel('Time (s)');
ylabel('Neutron Rate (neutrons/s)');
title('MAST Shot 27643 - Raw Neutron Rate');

grid on;

%% Plot 4 - Combined overview

figure;

tiledlayout(3,1);

nexttile;
plot(timeAMC,plasmaCurrent,'LineWidth',1);
ylabel('Current (kA)');
title('Plasma Current');
grid on;

nexttile;
plot(timeANB,nbiPower,'LineWidth',1);
ylabel('Power (MW)');
title('NBI Power');
grid on;

nexttile;
plot(timeANU,neutronRate,'LineWidth',1);
xlabel('Time (s)');
ylabel('Neutrons/s');
title('Neutron Rate');
grid on;

sgtitle('MAST Shot 27643 - Raw Diagnostic Signals');

fprintf('Raw data visualisation complete.\n');