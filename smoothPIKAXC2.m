
function smoothedCube = smoothPIKAXC2(trimmedCube, polynomialOrder, frameLength)
% smoothPIKAXC2 Smooth hyperspectral data across wavelength bands.
%
% INPUTS:
%   trimmedCube      - lines x samples x bands hyperspectral cube
%   polynomialOrder  - Savitzky-Golay polynomial order (e.g., 2)
%   frameLength      - odd number of bands in the window (e.g., 5)
%
% OUTPUT:
%   smoothedCube     - smoothed cube, same dimensions as input
%
% Requires Signal Processing Toolbox for sgolayfilt.

    if nargin < 2
        polynomialOrder = 2;
    end

    if nargin < 3
        frameLength = 5;
    end

    if frameLength <= polynomialOrder || ...
            mod(frameLength, 2) == 0
        error(['frameLength must be odd and greater than ', ...
               'polynomialOrder.']);
    end

    nBands = size(trimmedCube, 3);

    if frameLength > nBands
        error('frameLength cannot exceed the number of bands.');
    end

    % Convert to double for numerical processing
    data = double(trimmedCube);

    % Reshape so each row contains one pixel's spectrum
    [nLines, nSamples, ~] = size(data);
    spectra = reshape(data, [], nBands);

    % Smooth each spectrum along the wavelength dimension
    smoothedSpectra = sgolayfilt( ...
        spectra, polynomialOrder, frameLength, [], 2);

    % Restore original hyperspectral cube dimensions
    smoothedCube = reshape( ...
        smoothedSpectra, nLines, nSamples, nBands);

end

