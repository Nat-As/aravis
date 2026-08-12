sudo apt update
#installs to /home/alakai_user/.local/bin/meson
pip3 install --user meson ninja
#move local install to path to compile with meson
export PATH="$HOME/.local/bin:$PATH"
sudo apt install -y build-essential ninja-build pkg-config \
    libglib2.0-dev libxml2-dev zlib1g-dev libusb-1.0-0-dev \
    gobject-introspection libgirepository1.0-dev \
    libgtk-3-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
