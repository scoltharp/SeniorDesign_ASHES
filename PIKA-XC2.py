#adapted from the "Getting started" code snippet found at https://github.com/basler/pypylon

from pypylon import pylon
import numpy as np

# Pika L Parameters, from table on the Camera Setup and Windowing Page
ROI_WIDTH = 1600
ROI_HEIGHT = 924
Y_BINNING = 2

# Device-specific parameters obtained from Resonon Camera Configuration Report (ALREADY DONE - Steven)
X_OFFSET = 184
Y_OFFSET = 192
A = 1.4100000043981709e-05
B = 0.6551039814949036
C = 319.2640075683594
SERIAL_NUMBER = "22658054"

EXPOSURE = 31360 # Microseconds
GAIN = 12

# Establish traspont layer and get list of available devices
factory = pylon.TlFactory.GetInstance()
device_info_list = factory.EnumerateDevices()

# See if avaliable camera matches serial number. If not, just use first avaliable. 
for device_info in device_info_list:
        if device_info.GetSerialNumber() == SERIAL_NUMBER:
            camera_instance = pylon.InstantCamera(factory.CreateDevice(device_info))
            camera_instance.Open()
            break
else: 
    camera_instance = pylon.InstantCamera(pylon.TlFactory.GetInstance().CreateFirstDevice())
    camera_instance.Open()
    print(f"Serial number match not found. Using first avaliable camera.")
    

# Configure the camera window
# We make sure the camera is not binned before configuring the window, then add our desired binning
camera_instance.BinningHorizontal.SetValue(1)
camera_instance.BinningVertical.SetValue(1)
camera_instance.Width.SetValue(ROI_WIDTH)
camera_instance.Height.SetValue(ROI_HEIGHT)
camera_instance.OffsetX.SetValue(X_OFFSET)
camera_instance.OffsetY.SetValue(Y_OFFSET)
camera_instance.BinningVertical.SetValue(Y_BINNING)

camera_instance.ExposureAuto.Value = "Off"
camera_instance.ExposureTime.Value = EXPOSURE

camera_instance.GainAuto.Value = "Off"
camera_instance.Gain.Value = GAIN


def get_wavelength_for_channel(band_number: int) -> float:
    # The wavelength calibration equation is defined in terms of un-binned and un-windowed sensor coordinates.
    # here, we convert the band number of the binned and windowed region to its equivalent un-binned location
    # and apply the calibration equation.
    #
    # The term Y_BINNING / 2.0 - 0.5 is a correction to ensure the wavelength is calculated from the center of the
    # binned region, instead of the edge (using 0-based, C style indexing)
    camera_pixel = Y_OFFSET + band_number * Y_BINNING + Y_BINNING / 2.0 - 0.5
    return A * camera_pixel**2 + B * camera_pixel + C


# print('Wavelengths:')
# wavelengths = [get_wavelength_for_channel(pixel) for pixel in range(camera_instance.Height.GetValue())]
# print(', '.join(str(round(w, 2)) for w in wavelengths))


# Currently, I do not know how the Pika XC2 stores data, so I am worried about taking multiple frames.
# Because of this, there are two different pipelines below to capture frames. 
# One captures a single frame and saves it as  "pika_xc2_test.txt". 
# The second captures 5 frames, saves it in a multidimensional array, and then saves it as SOMETHING ELSE. 

# Old code! Save for when file configuration has been figured out. 
# Capture frames
# FRAME_COUNT = 50
# camera_instance.StartGrabbingMax(FRAME_COUNT)
# frame_number = 0
# while camera_instance.IsGrabbing():
#     grab_result = camera_instance.RetrieveResult(5000, pylon.TimeoutHandling_ThrowException)
#     if grab_result.GrabSucceeded():
#         print (f'Frame {frame_number}')
#         frame_number += 1
#         if frame_number == FRAME_COUNT:
#             # Access the image data for the last frame, as an example
#             print("Frame size X (spatial samples): ", grab_result.Width)
#             print("Frame size Y (spectral bands): ", grab_result.Height)
#             frame = grab_result.Array[::-1, :]  # Flip the frame in the spectral dimension for Pika XC2
            

#     grab_result.Release()

# Capture single frame
camera_instance.StartGrabbingMax(1)
while camera_instance.IsGrabbing():
    grab_result = camera_instance.RetrieveResult(5000, pylon.TimeoutHandling_ThrowException)
    if grab_result.GrabSucceeded():
        print("Frame size X (spatial samples): ", grab_result.Width)
        print("Frame size Y (spectral bands): ", grab_result.Height)
        print("Single frame captured successfully.")
        single_frame = grab_result.Array[::-1, :]  # Flip the frame in the spectral dimension for Pika XC2
        np.savetxt("pika_xc2_single.txt", single_frame)
    else:
        print("Frame capture failed.")

    grab_result.Release()

# Capture multiple (5) frames
multiframe_array = []
FRAME_COUNT = 5
camera_instance.StartGrabbingMax(FRAME_COUNT)
while camera_instance.IsGrabbing():
    grab_result = camera_instance.RetrieveResult(5000, pylon.TimeoutHandling_ThrowException)
    if grab_result.GrabSucceeded():
        frame_number += 1
        print("Multiframe number ", frame_number, "captured successfully.")
        frame = grab_result.Array[::-1, :]  # Flip the frame in the spectral dimension for Pika XC2
        multiframe_array.append(frame)
    grab_result.Release()

np.save("pika_xc2_multiframe.npy", multiframe_array)

camera_instance.Close()
