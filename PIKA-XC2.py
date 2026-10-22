#adapted from the "Getting started" code snippet found at https://github.com/basler/pypylon

from pypylon import pylon
import numpy as np
from spectral import envi

# Pika XC2 Parameters, from table on the Camera Setup and Windowing Page
ROI_WIDTH = 1600
ROI_HEIGHT = 924
Y_BINNING = 1
X_BINNING = 1

BINNING_TRUE = 2 # True desired software binning value for the camera. 

# Obtained from a header file taken from Spectronon. 
WAVELENGTHS = (385.24, 386.56, 387.88, 389.19, 390.51, 391.82, 393.14, 394.46, 395.78, 397.09, 398.41, 399.73, 401.04, 402.36, 403.68, 405.0, 406.31, 407.63, 408.95, 410.27, 411.58, 412.9, 414.22, 415.54, 416.86, 418.18, 419.5, 420.81, 422.13, 423.45, 424.77, 426.09, 427.41, 428.73, 430.05, 431.37, 432.69, 434.01, 435.33, 436.65, 437.97, 439.29, 440.61, 441.93, 443.25, 444.57, 445.89, 447.22, 448.54, 449.86, 451.18, 452.5, 453.82, 455.14, 456.47, 457.79, 459.11, 460.43, 461.76, 463.08, 464.4, 465.72, 467.04, 468.37, 469.69, 471.02, 472.34, 473.66, 474.98, 476.31, 477.63, 478.96, 480.28, 481.6, 482.93, 484.25, 485.58, 486.9, 488.22, 489.55, 490.88, 492.2, 493.52, 494.85, 496.17, 497.5, 498.83, 500.15, 501.48, 502.8, 504.13, 505.46, 506.78, 508.11, 509.44, 510.76, 512.09, 513.42, 514.74, 516.07, 517.4, 518.72, 520.05, 521.38, 522.7, 524.04, 525.36, 526.69, 528.02, 529.34, 530.67, 532.0, 533.33, 534.66, 535.99, 537.32, 538.64, 539.97, 541.31, 542.63, 543.96, 545.29, 546.62, 547.95, 549.28, 550.61, 551.94, 553.27, 554.6, 555.93, 557.26, 558.59, 559.92, 561.26, 562.58, 563.92, 565.24, 566.58, 567.91, 569.24, 570.58, 571.9, 573.24, 574.57, 575.9, 577.24, 578.57, 579.9, 581.23, 582.57, 583.9, 585.22, 586.56, 587.9, 589.22, 590.56, 591.9, 593.22, 594.56, 595.9, 597.22, 598.57, 599.9, 601.23, 602.57, 603.9, 605.24, 606.57, 607.9, 609.24, 610.58, 611.9, 613.24, 614.58, 615.92, 617.25, 618.58, 619.92, 621.26, 622.6, 623.93, 625.26, 626.6, 627.93, 629.28, 630.62, 631.94, 633.29, 634.62, 635.96, 637.3, 638.64, 639.97, 641.31, 642.64, 643.98, 645.33, 646.66, 648.0, 649.34, 650.67, 652.02, 653.36, 654.69, 656.03, 657.36, 658.7, 660.04, 661.38, 662.72, 664.06, 665.4, 666.74, 668.08, 669.42, 670.76, 672.1, 673.44, 674.79, 676.12, 677.46, 678.8, 680.14, 681.48, 682.84, 684.18, 685.52, 686.86, 688.2, 689.54, 690.88, 692.22, 693.56, 694.9, 696.24, 697.59, 698.94, 700.28, 701.62, 702.96, 704.3, 705.64, 706.99, 708.34, 709.68, 711.02, 712.36, 713.7, 715.05, 716.4, 717.74, 719.08, 720.42, 721.78, 723.12, 724.46, 725.8, 727.15, 728.5, 729.84, 731.18, 732.53, 733.88, 735.22, 736.56, 737.92, 739.26, 740.6, 741.95, 743.3, 744.64, 745.99, 747.34, 748.68, 750.03, 751.38, 752.72, 754.07, 755.42, 756.76, 758.11, 759.46, 760.8, 762.16, 763.5, 764.85, 766.2, 767.54, 768.9, 770.24, 771.59, 772.94, 774.29, 775.64, 776.98, 778.34, 779.68, 781.04, 782.38, 783.74, 785.08, 786.44, 787.79, 789.14, 790.48, 791.84, 793.18, 794.54, 795.88, 797.24, 798.58, 799.94, 801.29, 802.64, 803.99, 805.34, 806.7, 808.04, 809.4, 810.75, 812.1, 813.45, 814.8, 816.16, 817.51, 818.86, 820.21, 821.56, 822.92, 824.27, 825.62, 826.98, 828.33, 829.68, 831.04, 832.39, 833.74, 835.1, 836.46, 837.81, 839.16, 840.52, 841.87, 843.22, 844.58, 845.94, 847.29, 848.64, 850.0, 851.36, 852.71, 854.06, 855.42, 856.78, 858.13, 859.49, 860.84, 862.2, 863.56, 864.91, 866.27, 867.62, 868.98, 870.34, 871.7, 873.05, 874.41, 875.77, 877.12, 878.48, 879.84, 881.2, 882.56, 883.91, 885.27, 886.63, 887.99, 889.35, 890.7, 892.06, 893.42, 894.78, 896.14, 897.5, 898.86, 900.22, 901.58, 902.94, 904.3, 905.65, 907.01, 908.37, 909.73, 911.09, 912.45, 913.82, 915.18, 916.54, 917.9, 919.26, 920.62, 921.98, 923.34, 924.7, 926.06, 927.42, 928.79, 930.15, 931.51, 932.87, 934.23, 935.6, 936.96, 938.32, 939.68, 941.05, 942.41, 943.77, 945.14, 946.5, 947.86, 949.22, 950.59, 951.95, 953.32, 954.68, 956.04, 957.41, 958.77, 960.14, 961.5, 962.86, 964.23, 965.59, 966.96, 968.32, 969.69, 971.05, 972.42, 973.78, 975.15, 976.52, 977.88, 979.24, 980.61, 981.98, 983.34, 984.71, 986.08, 987.44, 988.81, 990.18, 991.54, 992.91, 994.28, 995.64, 997.01, 998.38, 999.74, 1001.12, 1002.48, 1003.85)

# Device-specific parameters obtained from Resonon Camera Configuration Report 
X_OFFSET = 184
Y_OFFSET = 192
A = 1.4100000043981709e-05
B = 0.6551039814949036
C = 319.2640075683594
SERIAL_NUMBER = "22658054"

EXPOSURE = 1000 * 1000 # Microseconds. Change value in front of the * 1000 to change exposure time in milliseconds.
GAIN = 12 # dB

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
camera_instance.PixelFormat.SetValue("Mono12")
camera_instance.Width.SetValue(ROI_WIDTH)
camera_instance.Height.SetValue(ROI_HEIGHT)
camera_instance.OffsetX.SetValue(X_OFFSET)
camera_instance.OffsetY.SetValue(Y_OFFSET)
camera_instance.BinningVertical.SetValue(Y_BINNING)
camera_instance.BinningHorizontal.SetValue(X_BINNING)

camera_instance.ExposureAuto.Value = "Off"
camera_instance.ExposureTime.Value = EXPOSURE

camera_instance.GainAuto.Value = "Off"
camera_instance.Gain.Value = GAIN


while True:

    # Set up for capture
    multiframe_array = []
    frame_number = 0

    # Ask user how many frames and to enter when ready
    FRAME_COUNT = int(input("Enter the number of frames to capture: "))
    input("Press Enter to start capturing frames...")

    # * CAMERA MAGIC * #
    camera_instance.StartGrabbingMax(FRAME_COUNT)
    while camera_instance.IsGrabbing():
        grab_result = camera_instance.RetrieveResult(5000, pylon.TimeoutHandling_ThrowException)
        if grab_result.GrabSucceeded():
            frame_number += 1
            frame = grab_result.Array[::-1, :]  # Flip the frame in the spectral dimension for Pika XC2
            frame = frame.reshape(frame.shape[0] // BINNING_TRUE, BINNING_TRUE, -1).sum(axis=1, dtype=np.uint16) # Software binning of spectral dimension. 
            multiframe_array.append(frame)

    # Frame array must be transposed for data
    transposed_data = np.transpose(multiframe_array, (0, 2, 1))  

    # Ask user for output file name
    name = input("Enter the desired name of the output file (without extension): ") + ".hdr"

    # Variables for metadata
    lines, samples, bands = transposed_data.shape

    shutter = EXPOSURE / 1000 # Shutter time in milliseconds
    framerate = 1 / shutter * 1000 # Framerate in frames per second

    # metadata = {
    #     'lines': lines,
    #     'samples': samples,
    #     'bands': bands,
    #     'interleave': 'bil',
    #     'data type': 12,  # ENVI code, 12 = uint16
    #     'wavelength units': 'Nanometers',
    #     'wavelength': wavelengths, 
    # }

    metadata = {
         'interleave': 'bil',
         'data type': 12,  # ENVI code, 12 = uint16
         'lines': lines,
         'samples': samples,
         'bands': bands,
         'ceiling': 8190,
         'sample binning': 1,
         'spectral binning': 2,
         'line binning': 1,
         'shutter': shutter,
         'gain': GAIN,
         'framerate': framerate,
         'temperature': 0,
         'imager serial number': SERIAL_NUMBER,
         'rotation': '[(0, 0), (0, 1), (1, 0), (1, 1)]',
         'byte order': 0,
         'header offset': 0,
         'flip radiometric callibration': 'False',
         'wavelength': WAVELENGTHS,
         'wavelength units': 'nm',
         'label': name
    }

    # Save data
    envi.save_image(name, transposed_data, metadata=metadata, force=True, interleave='bil', ext='bil')

    # Repeat! (or exit)

camera_instance.Close()


