<h1 align="center">
  <img src="viewer/icons/gnome/128x128/apps/aravis-0.8.png" alt="Aravis" width="128" height="128"/><br>
  Aravis
</h1>

[![Aravis-Linux](https://github.com/AravisProject/aravis/actions/workflows/aravis-linux.yml/badge.svg)](https://github.com/AravisProject/aravis/actions/workflows/aravis-linux.yml)
[![Aravis-macOS](https://github.com/AravisProject/aravis/actions/workflows/aravis-macos.yml/badge.svg)](https://github.com/AravisProject/aravis/actions/workflows/aravis-macos.yml)
[![Aravis-MinGW](https://github.com/AravisProject/aravis/actions/workflows/aravis-mingw.yml/badge.svg)](https://github.com/AravisProject/aravis/actions/workflows/aravis-mingw.yml)
[![Aravis-MSVC](https://github.com/AravisProject/aravis/actions/workflows/aravis-msvc.yml/badge.svg)](https://github.com/AravisProject/aravis/actions/workflows/aravis-msvc.yml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/eaa741156c2041f19b35c336aedf426c)](https://www.codacy.com/gh/AravisProject/aravis/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=AravisProject/aravis&amp;utm_campaign=Badge_Grade)

### What is Aravis ?

Aravis is a glib/gobject based library for video acquisition using Genicam
cameras. It currently implements the gigabit ethernet and USB3 protocols used by
industrial cameras. It also provides a basic ethernet camera simulator and a
simple video viewer.

Aravis is released under [LGPL-2.1-or-later](https://spdx.org/licenses/LGPL-2.1-or-later.html).

# Installation

These instructions cover cloning this fork, installing build dependencies, and compiling/installing Aravis on Linux (tested on kernel 4.9, Amlogic-based SoC board). They also cover the tools included in this fork for capturing frames from the iNocturn USB3 Vision camera.

## 1. Clone the repo

```bash
git clone https://github.com/Nat-As/aravis.git
cd aravis
```

## 2. Install build dependencies

Aravis uses Meson (>= 0.57.0) as its build system, along with GLib2, libxml2, zlib, and optionally libusb1 (USB3 Vision), GTK+3, and GStreamer (viewer + `aravissrc` plugin).

```bash
sudo apt update
sudo apt install -y build-essential pkg-config ninja-build \
    libglib2.0-dev libxml2-dev zlib1g-dev libusb-1.0-0-dev \
    gobject-introspection libgirepository1.0-dev \
    libgtk-3-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

## 3. Install Meson via pip3

Ubuntu's packaged Meson is typically older than the `>= 0.57.0` this project requires (you'll see an error like `unknown method "project_source_root"` if you try to build with an older version). Install a current Meson via pip instead of `apt`:

```bash
# Remove the distro package if installed, to avoid PATH conflicts
sudo apt remove -y meson

# Install a current Meson + Ninja locally
pip3 install --user --upgrade meson ninja

# Make sure ~/.local/bin is on your PATH
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

meson --version   # should report 0.57.0 or newer
```

## 4. Build

```bash
meson setup build --prefix=/usr/local
ninja -C build
```

If you only need the core library (skip the viewer and GStreamer plugin to reduce dependencies):

```bash
meson setup build --prefix=/usr/local -Dviewer=disabled -Dgst-plugin=disabled
ninja -C build
```

## 5. Install

```bash
sudo ninja -C build install
sudo ldconfig
```

## 6. Verify

```bash
pkg-config --modversion aravis-0.10
```

## 7. Install ImageMagick (used by `snapshot.sh` to convert raw camera buffers into TIFF)

```bash
sudo apt install -y imagemagick
convert -version
```

## Usage

Capturing a frame from the iNocturn camera uses three pieces together: a camera-configuration script, a small C program built as part of the normal meson test suite, and a wrapper script that ties capture and conversion together.

### iNocturn Image acquisition

**`setup-iNocturn.sh`**
Sends the camera's required settings (pixel format `Mono10`, resolution `1280x1024`, etc.) to the device via `arv-tool`/GenICam features. Run this once per session before capturing, and any time the camera has been power-cycled or reconnected.

**`tests/arvsnapshot.c` → `build/tests/arv-snapshot`**
A small program built alongside the other Aravis test/example binaries (see `tests/meson.build`, right next to `arv-acquisition-test`). It talks to the camera directly through the Aravis API to capture a RAW image `arv_camera_acquisition()` call as `arv-acquisition-test`.

Run directly if you just want a raw image with no conversion:
```bash
./build/tests/arv-snapshot frame.raw
```

**`snapshot.sh`**
Wraps `arv-snapshot` and `convert` with ImageMagick to a tiff file. It:
1. Runs `build/tests/arv-snapshot` to produce a raw capture and checks the reported `DataSize` against the expected `1280 × 1024 × 2` bytes for Mono10 (16-bit container, 10 bits significant)
2. converts the raw buffer into **two** TIFFs — see below — auto-incrementing both filenames together if `frame.tiff` already exists (`frame.tiff`/`frame_view.tiff` → `frame_1.tiff`/`frame_1_view.tiff` → ...).

### Typical usage

```bash
./setup-iNocturn.sh
./snapshot.sh
```

### RAW to TIFF conversion

Mono10 pixel values range `0–1023`, but the camera delivers them in a 16-bit-per-pixel container without scaling them up. `snapshot.sh` produces both a pixel-accurate copy and a version normalized for human viewing:

```bash
# Pixel-accurate: preserves the raw 10-bit values exactly (0-1023), for
# measurement/analysis. Looks very dark to the eye, since real values only
# span a small fraction of the 16-bit container's 0-65535 range.
convert -size 1280x1024 -depth 16 -endian LSB GRAY:frame.raw frame.tiff

# Viewable: same data, linearly stretched from 0-1023 up to 0-65535 so it
# looks normally bright.
convert -size 1280x1024 -depth 16 -endian LSB GRAY:frame.raw -level 0,1023 frame_view.tiff
```

`-endian LSB` matters: the camera's Mono10 data is little-endian, and ImageMagick's raw `GRAY:` reader doesn't assume that by default — getting this wrong produces a distinctive alternating black/white column artifact (each 16-bit sample's near-zero high byte and varying low byte get read as two separate 8-bit pixels).

### Known issues (resolved)

- ~~**Pixel format mapping**: Mono10 output showed visible column artifacts.~~ Resolved — caused by a combination of (1) GStreamer caps not specifying `format=GRAY16_LE`, letting the camera silently fall back to Mono8, and (2) ImageMagick defaulting to big-endian when reading the raw buffer. Fixed by capturing via the direct Aravis API (which reports the camera's actual pixel format with certainty) and specifying `-endian LSB` during conversion.
- ~~**Pipeline EOF/termination**: `aravissrc` did not reliably send EOS after `num-buffers` was reached.~~ Resolved by dropping the GStreamer capture path entirely in favor of `arv-snapshot`, which uses a single blocking `arv_camera_acquisition()` call with no pipeline/EOS semantics involved.

---

### Documentation

The latest documentation is available
[here](https://aravisproject.github.io/aravis/aravis-stable). You will find how to install
Aravis on Linux, macOS and Windows, how to tweak your system in order to get the
best performances, and the API documentation.

### Dependencies

The Aravis library depends on zlib, libxml2 and glib2, with an optional USB
support depending on libusb1.

The GStreamer plugin depends on GStreamer1 in addition to the Aravis library
dependencies.

The simple viewer depends on GStreamer1, Gtk+3 and the Aravis library
dependencies.

The required versions are specified in the
[meson.build](https://github.com/AravisProject/aravis/blob/main/meson.build)
file in Aravis sources.

It is perfectly possible to only build the library, reducing the dependencies to
the bare minimum.

### Contributions

As an open source and free software project, we welcome any contributions to the
aravis project: code, bug reports, testing...

However, contributions to both Gigabit Ethernet and USB3 protocol code (files
`src/arvuv*.[ch]` `src/arvgv*.[ch]`) must not be based on the corresponding
specification documents published by the [A3](https://www.automate.org/vision), as
this organization forbids the use of their documents for the development of an
open source implementation of the specifications. So, if you want to contribute
to this part of Aravis, don't use the A3 documents and state clearly in the
pull request your work is not based on them.

### Links

* Forum: https://aravis-project.discourse.group
* Github repository: https://github.com/AravisProject/aravis
* Releases: https://github.com/AravisProject/aravis/releases
* Release notes: https://github.com/AravisProject/aravis/blob/main/NEWS.md
* Genicam standard : http://www.genicam.org
