#!/bin/bash
set -eux

# TODO(joeriddles): don't hardcode this
CHROME_PATH='/Users/runner/hostedtoolcache/setup-chrome/chromium/126.0.6478.126/x64/Google Chrome for Testing.app'
if ! [ -f "$CHROME_PATH" ]; then 
  echo "CHROME_PATH not found: $CHROME_PATH"
  exit 1
fi

# See https://entonos.com/2023/06/23/how-to-modify-tcc-on-macos/
# and https://stackoverflow.com/questions/52706542/how-to-get-csreq-of-macos-application-on-command-line/57259004#57259004
codesign -dr - "$CHROME_PATH"  2>&1 | awk -F ' => ' '/designated/{print $2}' | csreq -r- -b /tmp/csreq.bin 
CSREQ=$(xxd -p /tmp/csreq.bin  | tr -d '\n')

DB_PATH="/Library/Application Support/com.apple.TCC/TCC.db"
DB_COLUMNS="service, client, client_type, auth_value, auth_reason, auth_version, csreq, flags"

CLIENT='com.google.chrome.for.testing'
CLIENT_TYPE=0  # CLIENT is a bundle identifier
AUTH_VALUE=2  # allowed
AUTH_REASON=3  # user set
AUTH_VERSION=1  # always 1

MICROPHONE='kTCCServiceMicrophone'
CAMERA='kTCCServiceCamera'
SCREEN_CAPTURE='kTCCServiceScreenCapture'

# echo ".schema access" | sqlite3 "$DB_PATH"
sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$MICROPHONE', '$CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CSREQ', 0)"
sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$CAMERA', '$CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CSREQ', 0)"
sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$SCREEN_CAPTURE', '$CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CSREQ', 0)"
