%%%%%%%%%%%%%%%%%%% ASHES Data Processing: Trim Function %%%%%%%%%%%%%%%%% 

% REV1: 10/10/2026
% Madelyn Sloan Berry (msb686)
% Created script
% Trims .bil file to 765-785nm 
% Need matching .hdr file 

% REV2: 10/10/2026
% Madelyn Sloan Berry (msb686)
% fixed 750 
% Trims .bil file to 744-786nm 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

function [trimmedCube, trimmedWavelengths, bandIdx] = ...
    trimPIKAXC2(bilFile, outputFile)

% trimPIKAXC2 Reads a Resonon PIKA-XC2 ENVI BIL file and
% trims the hyperspectral data to 744-786 nm.
%
% INPUTS:
%   bilFile   - Full path to the .bil file
%   outputFile - (Optional) Full path for saving the .mat file.
%                If omitted or empty, data is not saved.
%
% OUTPUTS:
%   trimmedCube        - Image cube: lines x samples x selected bands
%   trimmedWavelengths - Wavelengths retained, in nm
%   bandIdx            - Original spectral band indices retained
%
% Uses base MATLAB only. No graphing.
%
% Example:
%   [cube, wavelengths, bands] = trimPIKAXC2('Fire8.bil');
%   [cube, wavelengths, bands] = trimPIKAXC2( ...
%       'Fire8.bil', 'Fire8_744_786nm.mat');

    %% 1. Validate input and locate header

    if nargin < 1 || isempty(bilFile)
        error('Provide the path to a .bil file.');
    end

    if nargin < 2
        outputFile = '';
    end

    if ~isfile(bilFile)
        error('BIL file not found: %s', bilFile);
    end

    [folder, baseName, ~] = fileparts(bilFile);
    hdrFile = fullfile(folder, [baseName, '.bil.hdr']);

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

    interleave = lower(token{1});

    if ~strcmp(interleave, 'bil')
        error('Expected BIL interleave; found %s.', interleave);
    end

   
%% 3. Extract wavelength calibration

% Find the start of the wavelength list
startIdx = regexpi(hdrText, 'wavelength\s*=\s*\{', 'once');

if isempty(startIdx)
    error('Could not locate wavelength list in HDR file.');
end

% Find the opening brace
openBrace = find(hdrText(startIdx:end) == '{', 1, 'first') ...
    + startIdx - 1;

% Find the closing brace
closeRelative = find(hdrText(openBrace+1:end) == '}', ...
    1, 'first');

if isempty(closeRelative)
    error('Wavelength list is missing its closing brace.');
end

closeBrace = openBrace + closeRelative;

% Extract and parse the wavelength values
wavelengthText = hdrText(openBrace+1:closeBrace-1);

wavelengths = sscanf( ...
    strrep(wavelengthText, ',', ' '), '%f');

wavelengths = wavelengths(:);

% Convert to nanometers if necessary
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

% Verify wavelength calibration
if numel(wavelengths) ~= nBands
    error('Found %d wavelengths but header specifies %d bands.', ...
        numel(wavelengths), nBands);
end


    %% 4. Identify bands between 744 and 786 nm

    lambdaMin = 744;
    lambdaMax = 786;

    bandIdx = find(wavelengths >= lambdaMin & ...
                   wavelengths <= lambdaMax);

    if isempty(bandIdx)
        error('No spectral bands found between %g and %g nm.', ...
            lambdaMin, lambdaMax);
    end

    trimmedWavelengths = wavelengths(bandIdx);

    %% 5. Determine data precision and byte order

    % ENVI data type 12 = unsigned 16-bit integer
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

    %% 6. Check BIL file size

    expectedBytes = headerOffset + ...
        nLines * nSamples * nBands * bytesPerValue;

    fileInfo = dir(bilFile);

    if fileInfo.bytes < expectedBytes
        error(['BIL file is smaller than expected. Expected at least ' ...
            '%d bytes; found %d bytes.'], ...
            expectedBytes, fileInfo.bytes);
    end

    %% 7. Read and trim the BIL cube

    fid = fopen(bilFile, 'r', machineFormat);

    if fid == -1
        error('Could not open BIL file.');
    end

    cleanupObj = onCleanup(@() fclose(fid));

    if fseek(fid, headerOffset, 'bof') ~= 0
        error('Could not seek to image data.');
    end

    nSelectedBands = numel(bandIdx);

    trimmedCube = zeros(nLines, nSamples, ...
        nSelectedBands, precision);

    for line = 1:nLines

        % Read one BIL line into a samples x bands matrix.
        % fread fills columns, so transpose to match BIL ordering.
        rawLine = fread(fid, [nSamples, nBands], ...
            ['*' precision]);

        if numel(rawLine) ~= nSamples * nBands
            error('Incomplete data at line %d.', line);
        end

        % Select requested wavelengths and reshape for assignment
        selectedLine = rawLine(:, bandIdx);

        trimmedCube(line, :, :) = reshape(selectedLine, ...
            [1, nSamples, nSelectedBands]);
    end

    %% 8. Optionally save results

    if ~isempty(outputFile)
        save(outputFile, 'trimmedCube', ...
            'trimmedWavelengths', 'bandIdx', ...
            'lambdaMin', 'lambdaMax', '-v7.3');
    end

    fprintf('PIKA-XC2 data successfully trimmed.\n');
    fprintf('Original dimensions: %d x %d x %d\n', ...
        nLines, nSamples, nBands);
    fprintf('Trimmed dimensions: %d x %d x %d\n', ...
        nLines, nSamples, nSelectedBands);
    fprintf('Wavelength range: %.2f to %.2f nm\n', ...
        min(trimmedWavelengths), max(trimmedWavelengths));

end


%% Local helper: extract a numeric field from the ENVI header
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
