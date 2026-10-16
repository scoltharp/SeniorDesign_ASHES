%%%%%%%%%%%%%%%%%%% ASHES Data Processing: Read .bil Function %%%%%%%%%%%%%%%%% 

% REV1: 10/14/2026
% Madelyn Sloan Berry (msb686)
% Created script

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

function [cube, wavelengths] = readPIKAXC2(bilFile)

% readPIKAXC2 Reads a complete Resonon PIKA-XC2 ENVI BIL file.
%
% INPUT:
%   bilFile     - Path to the .bil file
%
% OUTPUTS:
%   cube        - Full hyperspectral cube:
%                 lines x samples x bands
%   wavelengths - Wavelength of every band, in nm
%
% Uses base MATLAB only. No toolbox required.
%
% Example:
%   [cube, wavelengths] = readPIKAXC2('Fire8.bil');

    %% 1. Locate files

    if nargin < 1 || isempty(bilFile)
        error('Provide the path to a .bil file.');
    end

    if ~isfile(bilFile)
        error('BIL file not found: %s', bilFile);
    end

    [folder, baseName, ~] = fileparts(bilFile);
    hdrFile = fullfile(folder, [baseName, '.hdr']);

    if ~isfile(hdrFile)
        error('Matching HDR file not found: %s', hdrFile);
    end

    %% 2. Read header metadata

    hdrText = fileread(hdrFile);

    nSamples = readNumber(hdrText, 'samples');
    nLines = readNumber(hdrText, 'lines');
    nBands = readNumber(hdrText, 'bands');
    dataType = readNumber(hdrText, 'data type');
    headerOffset = readNumber(hdrText, 'header offset');
    byteOrder = readNumber(hdrText, 'byte order');

    token = regexp(hdrText, ...
        '(?im)^\s*interleave\s*=\s*(\w+)', ...
        'tokens', 'once');

    if isempty(token)
        error('Interleave field missing from HDR file.');
    end

    if ~strcmpi(token{1}, 'bil')
        error('Expected BIL data; found %s.', token{1});
    end

    %% 3. Read all wavelengths

    startIdx = regexpi(hdrText, ...
        'wavelength\s*=\s*\{', 'once');

    if isempty(startIdx)
        error('Could not locate wavelength list in HDR file.');
    end

    openBrace = find(hdrText(startIdx:end) == '{', ...
        1, 'first') + startIdx - 1;

    closeRelative = find(hdrText(openBrace+1:end) == '}', ...
        1, 'first');

    if isempty(closeRelative)
        error('Wavelength list is missing its closing brace.');
    end

    closeBrace = openBrace + closeRelative;
    wavelengthText = hdrText(openBrace+1:closeBrace-1);

    wavelengths = sscanf( ...
        strrep(wavelengthText, ',', ' '), '%f');

    wavelengths = wavelengths(:);

    % Convert to nm if header specifies micrometers
    unitsToken = regexp(hdrText, ...
        '(?im)^\s*wavelength units\s*=\s*([^\r\n]+)', ...
        'tokens', 'once');

    if ~isempty(unitsToken)
        units = lower(strtrim(unitsToken{1}));
        units = strrep(units, '"', '');
        units = strrep(units, '''', '');

        if contains(units, 'microm')
            wavelengths = wavelengths * 1000;
        end
    end

    if numel(wavelengths) ~= nBands
        error('Found %d wavelengths but expected %d.', ...
            numel(wavelengths), nBands);
    end

    %% 4. Determine data type and byte order

    switch dataType
        case 1
            precision = 'uint8';
            bytesPerValue = 1;
        case 2
            precision = 'int16';
            bytesPerValue = 2;
        case 3
            precision = 'int32';
            bytesPerValue = 4;
        case 4
            precision = 'single';
            bytesPerValue = 4;
        case 5
            precision = 'double';
            bytesPerValue = 8;
        case 12
            precision = 'uint16';
            bytesPerValue = 2;
        case 13
            precision = 'uint32';
            bytesPerValue = 4;
        case 14
            precision = 'int64';
            bytesPerValue = 8;
        case 15
            precision = 'uint64';
            bytesPerValue = 8;
        otherwise
            error('Unsupported ENVI data type: %d', dataType);
    end

    if byteOrder == 0
        machineFormat = 'ieee-le';
    elseif byteOrder == 1
        machineFormat = 'ieee-be';
    else
        error('Unsupported byte order: %d', byteOrder);
    end

    %% 5. Check file size

    expectedBytes = headerOffset + ...
        nLines * nSamples * nBands * bytesPerValue;

    fileInfo = dir(bilFile);

    if fileInfo.bytes < expectedBytes
        error('BIL file is smaller than expected.');
    end

    %% 6. Read the complete hyperspectral cube

    fid = fopen(bilFile, 'r', machineFormat);

    if fid == -1
        error('Could not open BIL file.');
    end

    cleanupObj = onCleanup(@() fclose(fid));

    if fseek(fid, headerOffset, 'bof') ~= 0
        error('Could not seek to image data.');
    end

    % ENVI BIL storage order:
    % line -> band -> sample.
    %
    % Read one line at a time to limit temporary memory use.
    cube = zeros(nLines, nSamples, nBands, precision);

    for line = 1:nLines

        % fread fills columns, so transpose to obtain
        % samples x bands for the current line.
        rawLine = fread(fid, [nSamples, nBands], ...
            ['*' precision]);

        if numel(rawLine) ~= nSamples * nBands
            error('Incomplete data at image line %d.', line);
        end

        cube(line, :, :) = reshape( ...
            rawLine, [1, nSamples, nBands]);
    end

    %% 7. Report results

    fprintf('PIKA-XC2 cube loaded successfully.\n');
    fprintf('Dimensions: %d lines x %d samples x %d bands\n', ...
        nLines, nSamples, nBands);
    fprintf('Wavelength range: %.2f to %.2f nm\n', ...
        min(wavelengths), max(wavelengths));

end


%% Local helper: extract numeric header values
function value = readNumber(hdrText, fieldName)

    pattern = ['(?im)^\s*' ...
        regexptranslate('escape', fieldName) ...
        '\s*=\s*(\d+)'];

    token = regexp(hdrText, pattern, 'tokens', 'once');

    if isempty(token)
        error('Header field "%s" not found.', fieldName);
    end

    value = str2double(token{1});

end
