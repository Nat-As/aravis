#!/bin/bash
#
# snapshot.sh - Grab a single 1280x1024 Mono10 frame from the iNocturn camera
# using the arv-snapshot binary (direct Aravis API, no GStreamer), then
# convert the raw buffer into two TIFFs:
#
#   frame.tiff       - pixel-accurate: raw 10-bit values preserved exactly,
#                       suitable for measurement/analysis. Will look very
#                       dark to the eye since real values only span 0-1023
#                       out of the 16-bit container's 0-65535 range.
#   frame_view.tiff   - same data, linearly stretched (0-1023 -> 0-65535)
#                       for normal viewing/brightness.
#
# Both filenames auto-increment together if frame.tiff already exists:
#   frame.tiff / frame_view.tiff
#   frame_1.tiff / frame_1_view.tiff
#   frame_2.tiff / frame_2_view.tiff
#   ...
#
# Requires:
#   - arv-snapshot built via meson (build/tests/arv-snapshot)
#   - ImageMagick (`sudo apt install imagemagick`)
#   - setup-iNocturn.sh already run this session so the camera is configured
#     for Mono10 at 1280x1024

WIDTH=1280
HEIGHT=1024
BASENAME="frame"
EXT="tiff"

# Path to the arv-snapshot binary produced by the meson build.
# Adjust this if your build directory lives somewhere else.
ARV_SNAPSHOT_BIN="build/tests/arv-snapshot"

if [ ! -x "${ARV_SNAPSHOT_BIN}" ]; then
    echo "Error: ${ARV_SNAPSHOT_BIN} not found or not executable." >&2
    echo "       Build it first with:  ninja -C build" >&2
    exit 1
fi

# Work in temp files first so we never leave a half-written/corrupt file
# behind if capture or conversion fails partway through.
RAWFILE="$(mktemp --suffix=".raw")"
TMP_ACCURATE="$(mktemp --suffix=".${EXT}")"
TMP_VIEW="$(mktemp --suffix=".${EXT}")"
trap 'rm -f "$RAWFILE" "$TMP_ACCURATE" "$TMP_VIEW"' EXIT

echo "Capturing ${WIDTH}x${HEIGHT} frame via arv-snapshot..."

# arv-snapshot prints a line like:
#   Width=1280 Height=1024 PixelFormat=0x01100003 DataSize=2621440 bytes
# Capture that output so we can sanity-check the size before converting.
SNAPSHOT_OUTPUT="$("${ARV_SNAPSHOT_BIN}" "${RAWFILE}")"
echo "${SNAPSHOT_OUTPUT}"

DATA_SIZE="$(echo "${SNAPSHOT_OUTPUT}" | grep -oP 'DataSize=\K[0-9]+' || true)"
EXPECTED_BYTES=$((WIDTH * HEIGHT * 2))   # Mono10 -> 16-bit container, 2 bytes/pixel

if [ -z "${DATA_SIZE}" ] || [ "${DATA_SIZE}" -ne "${EXPECTED_BYTES}" ]; then
    echo "Error: unexpected data size (got '${DATA_SIZE:-none}', expected ${EXPECTED_BYTES})." >&2
    echo "       Check camera PixelFormat/resolution with setup-iNocturn.sh." >&2
    exit 1
fi

# Pixel-accurate conversion: preserve raw 10-bit values exactly.
convert -size "${WIDTH}x${HEIGHT}" -depth 16 -endian LSB GRAY:"${RAWFILE}" "${TMP_ACCURATE}"

# Viewable conversion: stretch 0-1023 -> 0-65535 for normal-looking brightness.
convert -size "${WIDTH}x${HEIGHT}" -depth 16 -endian LSB GRAY:"${RAWFILE}" -level 0,1023 "${TMP_VIEW}"

if [ ! -s "${TMP_ACCURATE}" ] || [ ! -s "${TMP_VIEW}" ]; then
    echo "Error: TIFF conversion failed or produced an empty file." >&2
    exit 1
fi

# Figure out the next available filename pair: frame.tiff/frame_view.tiff,
# frame_1.tiff/frame_1_view.tiff, ...
suffix=""
if [ -e "${BASENAME}.${EXT}" ]; then
    n=1
    while [ -e "${BASENAME}_${n}.${EXT}" ]; do
        n=$((n + 1))
    done
    suffix="_${n}"
fi

target_accurate="${BASENAME}${suffix}.${EXT}"
target_view="${BASENAME}${suffix}_view.${EXT}"

mv "${TMP_ACCURATE}" "${target_accurate}"
mv "${TMP_VIEW}" "${target_view}"
trap 'rm -f "$RAWFILE"' EXIT   # tiffs were moved; still clean up the raw temp file

echo "Saved pixel-accurate TIFF to: ${target_accurate}"
echo "Saved viewable TIFF to:       ${target_view}"
