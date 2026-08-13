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

# Work in a temp file first so we never leave a half-written/corrupt file
# behind if the capture fails or times out badly.
TMPFILE="$(mktemp --suffix=".${EXT}")"
trap 'rm -f "$TMPFILE"' EXIT

echo "Capturing ${WIDTH}x${HEIGHT} frame..."

timeout "${TIMEOUT_SECS}" gst-launch-1.0 aravissrc num-buffers=1 \
    ! video/x-raw,width="${WIDTH}",height="${HEIGHT}" \
    ! videoconvert \
    ! avenc_tiff \
    ! filesink location="${TMPFILE}" \
    >/dev/null 2>&1 || true   # timeout kills the hung pipeline; ignore its exit code

# Make sure we actually got a non-empty file before treating it as success.
if [ ! -s "${TMPFILE}" ]; then
    echo "Error: capture failed or produced an empty file." >&2
    exit 1
fi

# Figure out the next available filename: frame.tiff, frame_1.tiff, frame_2.tiff, ...
target="${BASENAME}.${EXT}"
if [ -e "${target}" ]; then
    n=1
    while [ -e "${BASENAME}_${n}.${EXT}" ]; do
        n=$((n + 1))
    done
    target="${BASENAME}_${n}.${EXT}"
fi

mv "${TMPFILE}" "${target}"
trap - EXIT   # file was moved, nothing left to clean up

echo "Saved snapshot to: ${target}"
