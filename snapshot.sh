# Take a single JPEG Image and save it to test.jpg
timeout 3 gst-launch-1.0 aravissrc num-buffers=1 ! video/x-raw,width=1280,height=1024 ! videoconvert ! jpegenc ! filesink location=test.jpg
