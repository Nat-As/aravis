#!/bin/bash
#
# snapshot.sh - Grab a single 1280x1024 frame from an Aravis (GenICam) camera
# and save it directly as frame.tiff (no jpeg intermediate), auto-incrementing
# the filename if it already exists (frame_1.tiff, frame_2.tiff, ...).
#
# Requires the gst-libav plugin set for the avenc_tiff element:
#   sudo apt install gstreamer1.0-libav      (Debian/Ubuntu)
#   sudo yum install gstreamer1-libav        (RHEL/Fedora)
# Verify with: gst-inspect-1.0 avenc_tiff

WIDTH=1280
HEIGHT=1024
TIMEOUT_SECS=7
BASENAME="frame"
EXT="tiff"

# Grabs a tiff file and closes after timeout because iNocturn doesn't send an EOF
timeout "${TIMEOUT_SECS}" gst-launch-1.0 aravissrc num-buffers=1 \
    ! video/x-raw,width="${WIDTH}",height="${HEIGHT}" \
    ! videoconvert \
    ! avenc_tiff \
    ! filesink location="frame.tiff"
