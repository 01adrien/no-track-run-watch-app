xhost +local:docker
docker run --rm \
  --name garmin-sdk \
  -e DISPLAY="$DISPLAY" \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/Bureau/garmin:/workspace \
  --network host \
  garmin-dev
