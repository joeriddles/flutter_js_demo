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
  --ignore-certificate-errors \
  --allow-insecure-localhost \
  --webdriver-loglevel=DEBUG \
  &

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

# Use headless in GitHub, headed locally
if is_on_github_actions; then
  dart $FLUTTER_TOOLS_PATH drive \
    --web-launch-url='https://localhost:5555/' \
    --target=integration_test/main_test.dart \
    --device-id web-server \
    --browser-dimension=1280,1024
else
  trap cleanup EXIT

  dart $FLUTTER_TOOLS_PATH drive \
    --web-launch-url='https://localhost:5555/' \
    --target=integration_test/main_test.dart \
    --device-id web-server \
    --browser-dimension=1280,1024 \
    --no-pub \
    --no-headless \
    --verbose
fi
