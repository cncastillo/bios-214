"""Exercise the real Julia/BART bridge over weak, strong and zero raw signals."""
import sys

import ismrmrd
import numpy as np

sys.path.insert(0, "/opt/code/python-ismrmrd-server")
from bios214radial import reconstruct_group

acquisitions = []
for line in range(202):
    acquisition = ismrmrd.Acquisition()
    acquisition.resize(128, 1)
    acquisition.sample_time_us = 4
    acquisition.idx.kspace_encode_step_1 = line
    acquisitions.append(acquisition)

images = []
for amplitude in (1e-6, 1e6, 0):
    for acquisition in acquisitions:
        acquisition.data[:] = amplitude
    image = reconstruct_group(acquisitions, 1).data.copy()
    assert image.shape == (1, 1, 128, 128)
    assert np.isfinite(image).all() and image.min() >= 0
    if amplitude:
        assert 4094.9 <= image.max() <= 4095
        images.append(image)
    else:
        assert np.count_nonzero(image) == 0
np.testing.assert_allclose(images[0] / 4095, images[1] / 4095, rtol=1e-4, atol=1e-4)
print("Scanner display scaling passed")
