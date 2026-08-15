clear;
clc;
close all;

%% MAST Shot 27643 - Data Cleaning
% Preserve raw data and create cleaned analysis subsets

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - DATA CLEANING\n');
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
% 2. LOAD RAW DATA
% --------------------------------------------------

timeAMC_raw = ncread(amcFile,'/time');
plasmaCurrent_raw = double(ncread(amcFile,'/amc/plasma_current/data'));

timeANB_raw = ncread(anbFile,'/time');
nbiPower_raw = double(ncread(anbFile,'/anb/tot_sum_power/data'));

timeANU_raw = ncread(anuFile,'/anu/neutrons/time');
neutronRate_raw = double(ncread(anuFile,'/anu/neutrons/data'));

neutronError_raw = double(ncread(anuFile,'/anu/errors/data'));

fprintf('Raw data loaded successfully.\n\n');

%% -------------------------------------------------
% 3. DEFINE ANALYSIS WINDOW
% --------------------------------------------------

analysisStart = 0.00;
analysisEnd   = 0.50;

fprintf('Analysis window: %.2f s to %.2f s\n\n', ...
    analysisStart,analysisEnd);

%% -------------------------------------------------
% 4. CREATE WINDOW MASKS
% --------------------------------------------------

maskAMC = timeAMC_raw >= analysisStart & timeAMC_raw <= analysisEnd;
maskANB = timeANB_raw >= analysisStart & timeANB_raw <= analysisEnd;
maskANU = timeANU_raw >= analysisStart & timeANU_raw <= analysisEnd;

%% -------------------------------------------------
% 5. CREATE CLEANED SUBSETS
% --------------------------------------------------

timeAMC = timeAMC_raw(maskAMC);
plasmaCurrent = plasmaCurrent_raw(maskAMC);

timeANB = timeANB_raw(maskANB);
nbiPower = nbiPower_raw(maskANB);

timeANU = timeANU_raw(maskANU);
neutronRate = neutronRate_raw(maskANU);
neutronError = neutronError_raw(maskANU);

%% -------------------------------------------------
% 6. REPORT RETAINED DATA
% --------------------------------------------------

fprintf('----- DATA RETENTION -----\n');

fprintf('AMC retained : %d of %d observations (%.1f%%)\n', ...
    length(plasmaCurrent), ...
    length(plasmaCurrent_raw), ...
    100*length(plasmaCurrent)/length(plasmaCurrent_raw));

fprintf('ANB retained : %d of %d observations (%.1f%%)\n', ...
    length(nbiPower), ...
    length(nbiPower_raw), ...
    100*length(nbiPower)/length(nbiPower_raw));

fprintf('ANU retained : %d of %d observations (%.1f%%)\n\n', ...
    length(neutronRate), ...
    length(neutronRate_raw), ...
    100*length(neutronRate)/length(neutronRate_raw));

%% -------------------------------------------------
% 7. CHECK CLEANED DATA
% --------------------------------------------------

fprintf('----- CLEANED WINDOW QUALITY -----\n');

fprintf('\nPlasma Current\n');
fprintf('Min      : %.3f kA\n',min(plasmaCurrent));
fprintf('Max      : %.3f kA\n',max(plasmaCurrent));
fprintf('Negative : %d\n',sum(plasmaCurrent < 0));

fprintf('\nNBI Power\n');
fprintf('Min      : %.5f MW\n',min(nbiPower));
fprintf('Max      : %.5f MW\n',max(nbiPower));
fprintf('Negative : %d\n',sum(nbiPower < 0));

fprintf('\nNeutron Rate\n');
fprintf('Min      : %.4e neutrons/s\n',min(neutronRate));
fprintf('Max      : %.4e neutrons/s\n',max(neutronRate));
fprintf('Zero     : %d\n\n',sum(neutronRate == 0));

%% -------------------------------------------------
% 8. FLAG POSSIBLE PLASMA-CURRENT SPIKES
% --------------------------------------------------

plasmaMedian = median(plasmaCurrent);
plasmaMAD = mad(plasmaCurrent,1);

spikeThreshold = plasmaMedian + 6*plasmaMAD;

spikeMask = plasmaCurrent > spikeThreshold;

fprintf('----- PLASMA CURRENT SPIKE CHECK -----\n');
fprintf('Median current     : %.3f kA\n',plasmaMedian);
fprintf('MAD                 : %.3f kA\n',plasmaMAD);
fprintf('Spike threshold     : %.3f kA\n',spikeThreshold);
fprintf('Flagged observations: %d\n\n',sum(spikeMask));

%% -------------------------------------------------
% 9. VISUALISE CLEANED WINDOW
% --------------------------------------------------

figure;

tiledlayout(3,1);

nexttile;
plot(timeAMC,plasmaCurrent,'LineWidth',1);
hold on;
plot(timeAMC(spikeMask),plasmaCurrent(spikeMask),'o');
ylabel('Current (kA)');
title('Plasma Current - Analysis Window');
grid on;

nexttile;
plot(timeANB,nbiPower,'LineWidth',1);
ylabel('Power (MW)');
title('NBI Power - Analysis Window');
grid on;

nexttile;
plot(timeANU,neutronRate,'LineWidth',1);
xlabel('Time (s)');
ylabel('Neutrons/s');
title('Neutron Rate - Analysis Window');
grid on;

sgtitle('MAST Shot 27643 - Cleaned Analysis Window');

fprintf('Cleaning stage complete.\n');