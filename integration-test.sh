#!/bin/bash
set -eux

SYSTEM_FLUTTER_PATH="$(which flutter)"
FLUTTER_PATH="${FLUTTER_PATH:-$SYSTEM_FLUTTER_PATH}"
FLUTTER_PATH_DIR="$(dirname $(dirname $FLUTTER_PATH))"
FLUTTER_TOOLS_PATH="$FLUTTER_PATH_DIR/packages/flutter_tools/bin/flutter_tools.dart"

dart $FLUTTER_TOOLS_PATH pub get

cleanup() {
  status=$?
  kill 0
  exit $status
}

is_on_github_actions() {
    if [ -z "${CI:-}" ] || [ -z "${GITHUB_RUN_ID:-}" ]; then
        return 1  # False
    else
        return 0  # True
    fi
}

test_1() {
  chromedriver \
    --port=4444 \
    --remote-debugging-pipe \
    --remote-debugging-port=9222 \
    --enable-chrome-logs \
    --binary='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
    --incognito \
    &

  dart $FLUTTER_TOOLS_PATH drive \
    --target=integration_test/main_test.dart \
    --device-id web-server \
    --browser-dimension=960,1080 \
    --driver-port=4444 \
    --web-browser-flag=--remote-debugging-port=9222 \
    --driver-environment "{\"REMOTE_DEBUGGING_PORT\": 9222}" \
    --no-pub \
    --no-headless
}

test_2() {
  sleep 5

  chromedriver \
    --port=4445 \
    --remote-debugging-pipe \
    --remote-debugging-port=9223 \
    --enable-chrome-logs \
    --binary='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
    &

  dart $FLUTTER_TOOLS_PATH drive \
    --target=integration_test/main_test.dart \
    --device-id web-server \
    --browser-dimension=960,1080 \
    --browser-location=960,0 \
    --driver-port=4445 \
    --web-browser-flag=--remote-debugging-port=9223 \
    --driver-environment "{\"REMOTE_DEBUGGING_PORT\": 9223}" \
    --no-pub \
    --no-headless
}

if ! is_on_github_actions; then
  trap cleanup EXIT
fi

declare FFMPEG_PID

stop_ffmpeg() {
  status=$?
  # See https://stackoverflow.com/a/21032143/11343166
  echo 'q' > stop
  rm ./stop
  wait $FFMPEG_PID

  if ! is_on_github_actions; then
    kill 0
  fi

  exit $status
}

OS_NAME=$(uname)

mkdir -p ./screenshots
touch ./stop

if [ "$OS_NAME" == "Darwin" ]; then
  SCREEN_CAPTURE_INTERFACE_ID=$(ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep 'Capture screen' | grep -o '\[[0-9]\]' | sed 's/\[//; s/\]//')
  echo "SCREEN_CAPTURE_INTERFACE_ID=$SCREEN_CAPTURE_INTERFACE_ID"

  <stop ffmpeg \
    -loglevel warning \
    -y \
    -video_size 1920x1080 \
    -f avfoundation \
    -pixel_format uyvy422 \
    -framerate 25 \
    -i "$SCREEN_CAPTURE_INTERFACE_ID" \
    -c:v libx264 \
    -c:a aac \
    -f flv \
    ./screenshots/recording.flv \
    2>&1 \
    &
  FFMPEG_PID=$!
  trap stop_ffmpeg EXIT
elif [ "$OS_NAME" == "Linux" ]; then
  <stop ffmpeg \
    -loglevel warning \
    -y \
    -video_size 1920x1080 \
    -f x11grab \
    -framerate 25 \
    -i :99 \
    -c:v libx264 \
    -c:a aac \
    -f flv \
    ./screenshots/recording.flv \
    &
  FFMPEG_PID=$!
  trap stop_ffmpeg EXIT
fi

declare -a pids

test_1 &
pids[0]=$!

test_2 &
pids[1]=$!

for pid in "${pids[@]}"; do
    wait "$pid"
    status=$?
    if [ $status -ne 0 ]; then
        echo "Process $pid exited with status $status"
        exit $status
    fi
done

exit 0
