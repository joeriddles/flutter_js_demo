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
    --remote-debugging-pipe &

  dart $FLUTTER_TOOLS_PATH drive \
    --target=integration_test/main_test.dart \
    --device-id web-server \
    --browser-dimension=1280,1024 \
    --driver-port=4444 \
    --web-browser-flag='--remote-debugging-port=9222' \
    --driver-environment "{\"REMOTE_DEBUGGING_PORT\": 9222}" \
    --no-pub \
    --no-headless
}

test_2() {
  chromedriver \
    --port=4445 \
    --remote-debugging-pipe \
    --remote-debugging-port=9223 \
    &

  dart $FLUTTER_TOOLS_PATH drive \
    --target=integration_test/main_test.dart \
    --device-id web-server \
    --browser-dimension=1280,1024 \
    --driver-port=4445 \
    --web-browser-flag='--remote-debugging-port=9223' \
    --driver-environment "{\"REMOTE_DEBUGGING_PORT\": 9223}" \
    --no-pub \
    --no-headless
}

if ! is_on_github_actions; then
  trap cleanup EXIT
fi

if is_on_github_actions; then
  ffmpeg \
    -video_size 1280x1024 \
    -f x11grab \
    -framerate 25 \
    -i :99 \
    -c:v libx264 \
    -c:a aac \
    -f flv \
    ./screenshots/recording.flv \
    &
  FFMPEG_ID=$!
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

if is_on_github_actions; then
  kill -TERM $FFMPEG_ID
end

exit 0
