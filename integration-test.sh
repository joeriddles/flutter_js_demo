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
  --webdriver-loglevel=DEBUG \
  &

# cleanup() {
#   status=$?
#   kill 0
#   exit $status
# }

# trap cleanup EXIT

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
    --no-pub \
    --target=integration_test/main_test.dart \
    --device-id web-server \
    --browser-dimension=1280,1024
else
  dart $FLUTTER_TOOLS_PATH drive \
    --no-pub \
    --target=integration_test/main_test.dart \
    --device-id web-server \
    --browser-dimension=1280,1024 \
    --no-headless
fi
