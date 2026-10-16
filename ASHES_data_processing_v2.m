%%%%%%%%%%%%%%%%%%% ASHES Data Processing %%%%%%%%%%%%%%%%% 

% rev1: 10/10/2026
% Madelyn Sloan Berry (msb686)
% Data processing using "trimPIKAXC2.m" function

% rev2: 10/14/2026
% Madelyn Sloan Berry (msb686)
% Added pixel averaging ability 

clear; clc; close all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% ---------- LOAD FILE AND TRIM DATA ------------ %

% Insert name of .bil file (must have corresponding .hdr file) 
bilFile = 'double15.bil';

% Read and trim the hyperspectral cube
[fireCube, wavelengths, bandIdx] = trimPIKAXC2(bilFile);    % fireCube dimensions: lines x samples x selected bands
                                                            % wavelengths contains the actual wavelengths in nm

% ---------- CALCULATE AVERAGE WAVELENGTH BANDS  ------------ %

%%%%%%% 750 FILTER
% Select wavelengths from 745 to 755 nm
rangeIdx50 = wavelengths >= 745 & wavelengths <= 755.5;
selectedCube50 = fireCube(:, :, rangeIdx50);
selectedWavelengths50 = wavelengths(rangeIdx50);

%%%%%%% 770 FILTER
% Select wavelengths from 765 to 775 nm
rangeIdx70 = wavelengths >= 764.5 & wavelengths <= 775.5;
selectedCube70 = fireCube(:, :, rangeIdx70);
selectedWavelengths70 = wavelengths(rangeIdx70);

%%%%%%% 780 FILTER
% Select wavelengths from 755 to 785 nm
rangeIdx80 = wavelengths >= 774.5 & wavelengths <= 785.5;
selectedCube80 = fireCube(:, :, rangeIdx80);
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

positiveImage = delta77_image; 
positiveImage(positiveImage < 0) = 0;

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

fprintf('\n Average pixel intensity:\n 750: %.4f\n 770: %.4f\n 780: %.4f\n', ...
    averagePixelIntensity50, averagePixelIntensity70, averagePixelIntensity80);

fprintf('\n Number of Positive Delta 77 Pixels: %.4f\n', ...
    numPositive);


% ---------- PLOT RESULTS  ------------ %

%%%% Plot delta77 image
figure;
    imagesc(delta77_image);
    axis image;
    colorbar;
    
    title('Delta 77 Image');
    
    xlabel('Spatial Sample');
    ylabel('Image Line');

%%%% Plot positive pixles only
figure;
    imagesc(positiveImage);
    axis image;

    title('Positive Delta 77 Image');

    xlabel('Spatial Sample');
    ylabel('Image Line');

%%%% Display histograms
% figure; 
%     subplot(3,1,1);     % plot 750 image
%     histogram(averageImage50)
% 
%     subplot(3,1,2);     % plot 770 image
%     histogram(averageImage70)
% 
%     subplot(3,1,3);     % plot 780 image
%     histogram(averageImage80)


%%%% Display average images
% figure;
%     subplot(3,1,1);     % plot 750 image
%     imagesc(averageImage50);
%     axis image;
%     colorbar;
% 
%     title(sprintf('Average Image 750 (%.1f–%.1f nm)', ...
%         min(selectedWavelengths50), max(selectedWavelengths50)));
% 
%     xlabel('Spatial Sample');
%     ylabel('Image Line');
% 
%     subplot(3,1,2);     % plot 770 image 
%     imagesc(averageImage70);
%     axis image;
%     colorbar;
% 
%     title(sprintf('Average Image 770 (%.1f–%.1f nm)', ...
%         min(selectedWavelengths70), max(selectedWavelengths70)));
% 
%     xlabel('Spatial Sample');
%     ylabel('Image Line');
% 
%     subplot(3,1,3);     % plot 780 image 
%     imagesc(averageImage80);
%     axis image;
%     colorbar;
% 
%     title(sprintf('Average Image 780 (%.1f–%.1f nm)', ...
%         min(selectedWavelengths80), max(selectedWavelengths80)));
% 
%     xlabel('Spatial Sample');
%     ylabel('Image Line');


% ---------- Using one bandwidth  ------------ %

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