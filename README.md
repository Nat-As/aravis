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

These instructions cover cloning this fork, installing build dependencies, and compiling/installing Aravis on Linux (tested on kernel 4.9, Amlogic-based SoC board). They also cover two helper scripts included in this fork for working with the iNocturn USB3 Vision camera.

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
    gstreamer1.0-libav libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

> `gstreamer1.0-libav` is required for the `avenc_tiff` element used by `snapshot.sh` below — without it, TIFF encoding in the capture pipeline will fail to find a matching element.

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

## 7. Install ImageMagick (used by `snapshot.sh` for raw → TIFF conversion)

```bash
sudo apt install -y imagemagick
convert -version
```

## Helper scripts

This fork includes two shell scripts for working with the iNocturn USB3 Vision camera:

- **`setup-iNocturn.sh`** — sends the camera's configured settings (pixel format, resolution, etc.) to the device via `arv-tool`/GenICam features before capture.
- **`snapshot.sh`** — captures a single frame via `aravissrc`/GStreamer and saves it as a TIFF (`frame.tiff`, auto-incrementing to `frame_1.tiff`, `frame_2.tiff`, etc. if the file already exists).

Typical usage:

```bash
./setup-iNocturn.sh
./snapshot.sh
```

### Known issues (in progress)

- **Pixel format mapping**: Mono10 output currently shows visible artifacts (alternating blank columns), likely caused by a caps/pixel-format mismatch between the requested GStreamer caps and the camera's native Mono10 output. Not yet resolved — tracking down the correct `GRAY16_LE` caps negotiation.
- **Pipeline EOF/termination**: `aravissrc` does not reliably send EOS after `num-buffers` is reached (a known quirk with GStreamer live sources), which can cause the capture pipeline to hang rather than exit cleanly. Currently mitigated with `timeout` around the capture command in `snapshot.sh`; a cleaner fix using `identity eos-after=1` is being evaluated.

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
