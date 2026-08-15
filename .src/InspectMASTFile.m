clear;
clc;
close all;

%% MAST Diagnostic File Inspector

[fileName,filePath] = uigetfile('*.nc', ...
    'Select MAST NetCDF file');

if isequal(fileName,0)
    error('No file selected.');
end

file = fullfile(filePath,fileName);

fprintf('\n====================================\n');
fprintf(' MAST DIAGNOSTIC FILE INSPECTION\n');
fprintf('====================================\n');

fprintf('\nFile: %s\n\n',fileName);

%% Read file information

info = ncinfo(file);

fprintf('Root variables:   %d\n',length(info.Variables));
fprintf('Root dimensions:  %d\n',length(info.Dimensions));
fprintf('Root groups:      %d\n\n',length(info.Groups));

%% Display complete hierarchy

ncdisp(file);

fprintf('\n====================================\n');
fprintf(' INSPECTION COMPLETE\n');
fprintf('====================================\n');