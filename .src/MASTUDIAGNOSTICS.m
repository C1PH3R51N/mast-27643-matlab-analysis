clear;
clc;
close all;

%% MAST Shot 27643 - Neutron Diagnostic
% Stage 1: Inspect the raw ANT NetCDF dataset

%% Select ANT file

[fileName, filePath] = uigetfile('*.nc', ...
    'Select ant27643.nc');

if isequal(fileName,0)
    error('No file selected.');
end

file = fullfile(filePath,fileName);

fprintf('\n========================================\n');
fprintf(' MAST NEUTRON DIAGNOSTIC DATA INSPECTION\n');
fprintf('========================================\n\n');

fprintf('File selected: %s\n\n',fileName);

%% Read NetCDF information

info = ncinfo(file);

%% Root-level information

fprintf('----- ROOT LEVEL -----\n');
fprintf('Variables: %d\n',length(info.Variables));
fprintf('Dimensions: %d\n',length(info.Dimensions));
fprintf('Attributes: %d\n',length(info.Attributes));
fprintf('Groups: %d\n\n',length(info.Groups));

%% Display global attributes

fprintf('----- GLOBAL ATTRIBUTES -----\n');

for i = 1:length(info.Attributes)

    fprintf('%s : ',info.Attributes(i).Name);

    value = info.Attributes(i).Value;

    if ischar(value) || isstring(value)
        fprintf('%s\n',string(value));
    elseif isnumeric(value) && isscalar(value)
        fprintf('%g\n',value);
    else
        fprintf('[complex value]\n');
    end

end

%% Display groups

fprintf('\n----- GROUP STRUCTURE -----\n');

for i = 1:length(info.Groups)

    group = info.Groups(i);

    fprintf('\nGROUP %02d\n',i);
    fprintf('Name: %s\n',group.Name);
    fprintf('Variables: %d\n',length(group.Variables));
    fprintf('Dimensions: %d\n',length(group.Dimensions));
    fprintf('Subgroups: %d\n',length(group.Groups));

    %% Variables inside group

    if ~isempty(group.Variables)

        fprintf('\nVariables contained in this group:\n');

        for j = 1:length(group.Variables)

            variable = group.Variables(j);

            fprintf('   %02d | %s',j,variable.Name);

            if ~isempty(variable.Size)
                fprintf(' | Size: ');
                fprintf('%d ',variable.Size);
            end

            fprintf('\n');

        end
    end
end

%% Full NetCDF structure

fprintf('\n========================================\n');
fprintf(' FULL NETCDF STRUCTURE\n');
fprintf('========================================\n\n');

ncdisp(file);

fprintf('\nInspection complete.\n');