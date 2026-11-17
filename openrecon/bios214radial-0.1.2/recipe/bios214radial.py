"""Starter MRD bridge adapted for the bundled, fixed 2D radial Pulseq sequence."""
import ctypes
import logging
import subprocess
import tempfile
from pathlib import Path

import ismrmrd
import numpy as np


def reconstruct_group(acquisitions, image_index):
    for acq in acquisitions:
        if acq.number_of_samples != 128 or acq.discard_pre or acq.discard_post:
            raise ValueError("The fixed sequence requires 128 untrimmed samples per spoke.")
        if acq.encoding_space_ref or acq.idx.kspace_encode_step_2:
            raise ValueError("The fixed sequence supports one 2D encoding without partitions.")
        if acq.sample_time_us != 0 and not np.isclose(acq.sample_time_us, 4.0, atol=0.001):
            raise ValueError("The fixed sequence requires a 4 microsecond ADC dwell.")
    if any(acq.sample_time_us == 0 for acq in acquisitions):
        logging.getLogger(__name__).info("MRD dwell is unset; using 4 microseconds from the bundled sequence.")
    with tempfile.TemporaryDirectory(prefix="radial-") as directory:
        source, target = Path(directory) / "input.npz", Path(directory) / "output.npz"
        np.savez(source, kspace=np.stack([acq.data for acq in acquisitions], axis=1),
                 lines=np.array([acq.idx.kspace_encode_step_1 for acq in acquisitions]))
        subprocess.run([
            "julia", "--startup-file=no", "--threads=1,0", "--gcthreads=1,0",
            "--project=/opt/recon/julia", "/opt/recon/julia/run.jl", str(source), str(target),
        ], check=True)
        with np.load(target) as result:
            pixels = np.ascontiguousarray(result["image"], dtype=np.float32)
            fov = result["fov_mm"].copy()
    if pixels.shape != (128, 128) or not np.isfinite(pixels).all():
        raise ValueError("Expected a finite 128 x 128 magnitude image from Julia.")
    peak = float(pixels.max())
    if peak > 0:
        pixels *= np.float32(4095 / peak)
        logging.getLogger(__name__).info("Scaled magnitude peak %.9g to 4095 for scanner injection.", peak)
    np.clip(pixels, 0, 4095, out=pixels)
    image = ismrmrd.Image.from_array(pixels, acquisition=acquisitions[0], transpose=False)
    image.image_type = ismrmrd.IMTYPE_MAGNITUDE
    image.image_index = image_index
    image.image_series_index = 1
    image.field_of_view = tuple(ctypes.c_float(value) for value in fov)
    head = image.getHead()
    image.attribute_string = ismrmrd.Meta({
        "DataRole": "Image",
        "ImageProcessingHistory": ["OPENRECON", "JULIA", "BART", "NUFFT"],
        "SequenceDescriptionAdditional": "radial_bssfp",
        "Keep_image_geometry": 1,
        "ImageRowDir": [str(value) for value in head.read_dir],
        "ImageColumnDir": [str(value) for value in head.phase_dir],
    }).serialize()
    return image


def process(connection, config, metadata):
    groups = {}
    image_index = 0
    excluded = (ismrmrd.ACQ_IS_NOISE_MEASUREMENT, ismrmrd.ACQ_IS_PARALLEL_CALIBRATION,
                ismrmrd.ACQ_IS_PHASECORR_DATA, ismrmrd.ACQ_IS_NAVIGATION_DATA,
                ismrmrd.ACQ_IS_DUMMYSCAN_DATA)
    logging.getLogger(__name__).info("Reconstructing fixed radial_bssfp.seq with Julia / BartIO 0.4")
    try:
        for item in connection:
            if item is None:
                break
            if not isinstance(item, ismrmrd.Acquisition) or any(item.is_flag_set(flag) for flag in excluded):
                continue
            key = tuple(getattr(item.idx, field) for field in
                        ("average", "slice", "contrast", "phase", "repetition", "set"))
            groups.setdefault(key, []).append(item)
            if item.is_flag_set(ismrmrd.ACQ_LAST_IN_SLICE):
                image_index += 1
                connection.send_image(reconstruct_group(groups.pop(key), image_index))
        for group in groups.values():
            image_index += 1
            connection.send_image(reconstruct_group(group, image_index))
    finally:
        connection.send_close()
