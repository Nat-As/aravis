gst-launch-1.0 aravissrc num-buffers=1 ! videoconvert ! jpegenc ! filesink location=test.jpg
