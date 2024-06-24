#!/bin/bash
set -eux

SYSTEM_FLUTTER_PATH="$(which flutter)"
FLUTTER_PATH="${FLUTTER_PATH:-$SYSTEM_FLUTTER_PATH}"
FLUTTER_PATH_DIR="$(dirname $(dirname $FLUTTER_PATH))"
FLUTTER_TOOLS_PATH="$FLUTTER_PATH_DIR/packages/flutter_tools/bin/flutter_tools.dart"

chromedriver \
  --port=4444 \
  --auto-accept-camera-and-microphone-capture \
  --use-fake-ui-for-media-stream \
  --remote-debugging-pipe \
  --disable-web-security \
  --allowed-ips \
  --allowed-origins=* \
  &

cleanup() {
  status=$?
  kill 0
  exit $status
}

trap cleanup EXIT

dart $FLUTTER_TOOLS_PATH drive \
  --target=integration_test/main_test.dart \
  --device-id web-server \
  --browser-dimension=1280,1024 \
  --no-headless
