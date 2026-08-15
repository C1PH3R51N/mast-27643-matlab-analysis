clear;
clc;
close all;

%% MAST Shot 27643 - ANU Error Metadata Inspection

fprintf('========================================\n');
fprintf(' MAST SHOT 27643 - ANU ERROR METADATA\n');
fprintf('========================================\n\n');

%% 1. SELECT ANU FILE

[anuName, anuPath] = uigetfile('*.nc','Select anu27643.nc');

if isequal(anuName,0)
    error('ANU file not selected.');
end

anuFile = fullfile(anuPath,anuName);

fprintf('File selected: %s\n\n',anuName);

%% 2. INSPECT ERROR VARIABLE

errorInfo = ncinfo(anuFile,'/anu/errors/data');

fprintf('----- ANU ERRORS VARIABLE -----\n\n');

fprintf('Variable name : %s\n',errorInfo.Name);
fprintf('Datatype      : %s\n',errorInfo.Datatype);

fprintf('Size          : ');
fprintf('%d ',errorInfo.Size);
fprintf('\n\n');

%% 3. DISPLAY ALL ERROR ATTRIBUTES

fprintf('----- ATTRIBUTES -----\n\n');

for i = 1:length(errorInfo.Attributes)

    attributeName = errorInfo.Attributes(i).Name;
    attributeValue = errorInfo.Attributes(i).Value;

    fprintf('%s : ',attributeName);

    if ischar(attributeValue) || isstring(attributeValue)

        fprintf('%s\n',string(attributeValue));

    elseif isnumeric(attributeValue) && isscalar(attributeValue)

        fprintf('%g\n',attributeValue);

    elseif isnumeric(attributeValue)

        fprintf('[');
        fprintf('%g ',attributeValue);
        fprintf(']\n');

    else

        fprintf('[Unable to display directly]\n');

    end

end

%% 4. INSPECT ERROR GROUP

fprintf('\n----- FULL ERROR GROUP STRUCTURE -----\n\n');

ncdisp(anuFile,'/anu/errors');

%% 5. INSPECT MAIN NEUTRON VARIABLE FOR COMPARISON

fprintf('\n----- MAIN NEUTRON VARIABLE -----\n\n');

neutronInfo = ncinfo(anuFile,'/anu/neutrons/data');

fprintf('Variable name : %s\n',neutronInfo.Name);
fprintf('Datatype      : %s\n',neutronInfo.Datatype);

fprintf('\nAttributes:\n');

for i = 1:length(neutronInfo.Attributes)

    attributeName = neutronInfo.Attributes(i).Name;
    attributeValue = neutronInfo.Attributes(i).Value;

    fprintf('%s : ',attributeName);

    if ischar(attributeValue) || isstring(attributeValue)

        fprintf('%s\n',string(attributeValue));

    elseif isnumeric(attributeValue) && isscalar(attributeValue)

        fprintf('%g\n',attributeValue);

    else

        fprintf('[complex value]\n');

    end

end

fprintf('\nMetadata inspection complete.\n');