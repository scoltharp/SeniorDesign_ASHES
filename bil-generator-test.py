from pypylon import pylon
import numpy as np
from spectral import envi

# Load test data, replace file path with your own if necessary
test_data = np.transpose(np.load("test-data/pika_xc2_multiframe.npy"), (0, 2, 1))

# Generate bands array, next time actually generate this to be exact bands
wavelengths = np.linspace(385.24, 1003.85, num=462)

# Variables for metadata
lines, samples, bands = test_data.shape

metadata = {
    'lines': lines,
    'samples': samples,
    'bands': bands,
    'interleave': 'bil',
    'data type': 1,  # ENVI code, 1 = uint8
    'wavelength units': 'Nanometers',
    'wavelength': wavelengths, 
}

name = input("Enter the name of the output file (without extension): ") + ".hdr"

envi.save_image(name, test_data, metadata=metadata, force=True, interleave='bil', ext='bil')

