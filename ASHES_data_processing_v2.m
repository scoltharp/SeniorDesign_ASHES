%%%%%%%%%%%%%%%%%%% ASHES Data Processing %%%%%%%%%%%%%%%%% 

% rev1: 10/10/2026
% Madelyn Sloan Berry (msb686)
% Data processing using "trimPIKAXC2.m" function

% rev2: 10/14/2026
% Madelyn Sloan Berry (msb686)
% Added pixel averaging ability 

% rev3: 10/23/2026
% Madelyn Sloan Berry (msb686)
% Added smoothing function 
% also kill me I didn't get any of the plastic fire
% in frame for this I am so stupid and embarassing 

clear; clc; close all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% ---------- LOAD FILE AND TRIM DATA ------------ %

% Insert name of .bil file (must have corresponding .hdr file) 
bilFile = ['comp_5.bil'];

% Read and trim the hyperspectral cube
[fireCube, wavelengths, bandIdx] = trimPIKAXC2(bilFile);    % fireCube dimensions: lines x samples x selected bands
                                                            % wavelengths contains the actual wavelengths in nm
% ---------- SMOOTH DATA  ------------ %
polynomialOrder = 2;
frameLength = 13;
smoothedCube = smoothPIKAXC2( fireCube, polynomialOrder, frameLength);

% ---------- CALCULATE AVERAGE WAVELENGTH BANDS  ------------ %

%%%%%%% 750 FILTER
% Select wavelengths from 745 to 755 nm
rangeIdx50 = wavelengths >= 745 & wavelengths <= 755.5;
selectedCube50 = smoothedCube(:, :, rangeIdx50);
selectedWavelengths50 = wavelengths(rangeIdx50);

%%%%%%% 770 FILTER
% Select wavelengths from 765 to 775 nm
rangeIdx70 = wavelengths >= 764.5 & wavelengths <= 775.5;
selectedCube70 = smoothedCube(:, :, rangeIdx70);
selectedWavelengths70 = wavelengths(rangeIdx70);

%%%%%%% 780 FILTER
% Select wavelengths from 755 to 785 nm
rangeIdx80 = wavelengths >= 774.5 & wavelengths <= 785.5;
selectedCube80 = smoothedCube(:, :, rangeIdx80);
selectedWavelengths80 = wavelengths(rangeIdx80);

% Create average image across selected wavelengths
averageImage50 = mean(double(selectedCube50), 3);
averageImage70 = mean(double(selectedCube70), 3);
averageImage80 = mean(double(selectedCube80), 3);

% Calculate average pixel intensity over the entire image and range
averagePixelIntensity50 = mean(double(selectedCube50(:)));
averagePixelIntensity70 = mean(double(selectedCube70(:)));
averagePixelIntensity80 = mean(double(selectedCube80(:)));

% Calculate delta 77 
delta77 = averagePixelIntensity70 - ( (1/3)*averagePixelIntensity50 + (2/3)*averagePixelIntensity80);
delta77_image = averageImage70 - ( (1/3)*averageImage50 + (2/3)*averageImage80);

% Seperate positive values 
positiveValues = delta77_image(delta77_image>0);
numPositive = nnz(delta77_image > 0);

% ---------- LIST RESULTS  ------------ %

%%%% List values of images  
fprintf('\nSelected wavelength range: \n %.2f to %.2f nm\n', ...
    min(selectedWavelengths50), max(selectedWavelengths50));
fprintf('\n %.2f to %.2f nm\n', ...
    min(selectedWavelengths70), max(selectedWavelengths70));
fprintf('\n %.2f to %.2f nm\n', ...
    min(selectedWavelengths80), max(selectedWavelengths80));

fprintf('\nNumber of selected bands:\n 750: %d\n 770: %d\n 780: %d\n', ...
    numel(selectedWavelengths50),  numel(selectedWavelengths70), numel(selectedWavelengths80));

% fprintf('\n Average pixel intensity:\n 750: %.4f\n 770: %.4f\n 780: %.4f\n', ...
%     averagePixelIntensity50, averagePixelIntensity70, averagePixelIntensity80);

fprintf('\n Number of Positive Delta 77 Pixels: %.4f\n', ...
    numPositive);

% ---------- PLOT POSITIVE DELTA 77 IMAGES  ------------ %

%%%% Plot positive pixles only
% Positive pixel mask, locations, and values
mask      = delta77_image > 0;
[rows, cols] = find(mask);
posValues = delta77_image(mask);     % same order as rows/cols from find

% Background as grayscale RGB (so it ignores the colormap)
bg    = mat2gray(delta77_image);     % scale to 0-1
bgRGB = repmat(bg, [1 1 3]);

figure;
    ax1 = subplot(2,1,1);               % Subplot 1: grayscale background, positives in red 
    imagesc(ax1, delta77_image);
    axis(ax1, 'image');
    colormap(ax1, gray);                 % apply gray to THIS axes only
    hold(ax1, 'on');
    plot(ax1, cols, rows, 'r.', 'MarkerSize', 4);
    title(ax1, 'Positive pixels marked in red');

    ax2 = subplot(2,1,2);                % Subplot 2: RGB background, positives colored by value
    image(ax2, bgRGB);                   % truecolor, ignores colormap
    axis(ax2, 'image');
    hold(ax2, 'on');
    impixelinfo;
    scatter(ax2, cols, rows, 12, posValues, 'filled');
    colormap(ax2, hot);                  % apply hot to THIS axes only
    clim(ax2, [min(posValues) max(posValues)]);
    cb = colorbar(ax2);
    cb.Label.String = 'Positive pixel value';
    title(ax2, 'Positive pixels colored by value');

% ---------- EVALUATE SMOOTHING  ------------ %

% Choose a pixel by its image coordinates
lineNumber = 179;       % Image row (1-100)
sampleNumber = 1025;    % Image column (1-1600)

% Extract the pixel's spectral signal
originalSpectrum = double(squeeze(fireCube(lineNumber, sampleNumber, :)));
smoothedSpectrum = double(squeeze(smoothedCube(lineNumber, sampleNumber, :)));

% Plot intensity versus wavelength
figure;
    plot(wavelengths, originalSpectrum, 'DisplayName', 'Original Signal');
    hold on;
    
    plot(wavelengths, smoothedSpectrum, 'DisplayName', 'Smoothed Signal', ...
        'LineWidth', 1.5);
    
    xlabel('Wavelength (nm)');
    ylabel('Pixel Intensity (Digital Numbers)');
    title(sprintf('Pixel Spectrum: Row %d, Column %d', lineNumber, sampleNumber));
    
    legend('Location', 'best');
    grid on;
    hold off;

% Choose the target wavelengths
targetWavelengths = [750, 770, 780];
nTargets = numel(targetWavelengths);
actualWavelengths = zeros(nTargets, 1);
originalValues = zeros(nTargets, 1);
smoothedValues = zeros(nTargets, 1);

for k = 1:nTargets
    [~, idx] = min(abs(wavelengths - targetWavelengths(k)));

    actualWavelengths(k) = wavelengths(idx);
    originalValues(k) = originalSpectrum(idx);
    smoothedValues(k) = smoothedSpectrum(idx);
end

delta77_smoothpixle = smoothedValues(2) - ( (1/3)*smoothedValues(1) + (2/3)*smoothedValues(3));
delta77_originalpixle = originalValues(2) - ( (1/3)*originalValues(1) + (2/3)*originalValues(3));

fprintf('\n Delta 77 smoothed pixle: %.4f\n', delta77_smoothpixle);
fprintf('\n Delta 77 original pixle: %.4f\n', delta77_originalpixle);


% %  Display results in a table
% results = table( ...
%     targetWavelengths(:), actualWavelengths, ...
%     originalValues, smoothedValues, ...
%     'VariableNames', {'Target_nm', 'Actual_nm', ...
%     'Original_DN', 'Smoothed_DN'});
% 
% disp(results);

% ---------- PLOT ONE BANDWIDTH IMAGE  ------------ %

%%%% Retrieve the image band closest to 770 nm
% [~, idx770] = min(abs(wavelengths - 770));
% image770 = fireCube(:, :, idx770);
% 
% 
% 
% % Plot 
    % figure;
    % imagesc(image770);
    % axis image;
    % colorbar;
    % title(sprintf('Image at %.2f nm', wavelengths(idx770)));
    % xlabel('Sample');
    % ylabel('Line');
