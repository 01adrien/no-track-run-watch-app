xhost +local:docker
docker run --rm \
  -e DISPLAY="$DISPLAY" \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ~/Bureau/garmin:/workspace \
  -p 8080:8080 \ 
  garmin-dev
