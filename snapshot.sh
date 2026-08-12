#!/bin/bash
#
# snapshot.sh - Grab a single 1280x1024 frame from an Aravis (GenICam) camera
# and save it as image.jpeg, auto-incrementing the filename if it already
# exists (image_1.jpeg, image_2.jpeg, ...).

set -euo pipefail

WIDTH=1280
HEIGHT=1024
TIMEOUT_SECS=7
BASENAME="image"
EXT="jpeg"

# Work in a temp file first so we never leave a half-written/corrupt file
# behind if the capture fails or times out badly.
TMPFILE="$(mktemp --suffix=".${EXT}")"
trap 'rm -f "$TMPFILE"' EXIT

echo "Capturing ${WIDTH}x${HEIGHT} frame..."

timeout "${TIMEOUT_SECS}" gst-launch-1.0 aravissrc num-buffers=1 \
    ! video/x-raw,width="${WIDTH}",height="${HEIGHT}" \
    ! videoconvert \
    ! jpegenc \
    ! filesink location="${TMPFILE}" \
    >/dev/null 2>&1 || true   # timeout kills the hung pipeline; ignore its exit code

# Make sure we actually got a non-empty file before treating it as success.
if [ ! -s "${TMPFILE}" ]; then
    echo "Error: capture failed or produced an empty file." >&2
    exit 1
fi

# Figure out the next available filename: image.jpeg, image_1.jpeg, image_2.jpeg, ...
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
