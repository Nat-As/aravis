gst-inspect-1.0 aravissrc
mkdir -p kinetic_test
gst-launch-1.0 -e \
  aravissrc num-buffers=100 \
    features="OutputDepth=Mono8 PixelFormat=Mono8 TestPattern=Off SensorTestPattern=On AGC=AGCON" \
  ! video/x-raw,format=GRAY8 \
  ! pngenc \
  ! multifilesink location="kinetic_test/frame_%05d.png"
