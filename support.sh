arv-tool-0.10 control PixelFormat=Mono8 # Mono8
arv-tool-0.10 control SensorTestPattern=On # Send test pattern
arv-tool-0.10 control  # confirm camera is detected
arv-tool-0.10 stream --filename=frame  # writes raw frames to disk, no video sink involved
