#!/bin/bash
set -eu

# Handle unsigned binaries
# cd '/Users/runner/hostedtoolcache/setup-chrome/chromium/126.0.6478.126/x64/Google Chrome for Testing.app/Contents/MacOS/'
# ls -al
# codesign --detached './Google Chrome for Testing.sig' -s - './Google Chrome for Testing'
# codesign -d -r- --detached './Google Chrome for Testing.sig' './Google Chrome for Testing'

CHROME_PATH='/Applications/Google Chrome.app'

# See https://entonos.com/2023/06/23/how-to-modify-tcc-on-macos/
# and https://stackoverflow.com/questions/52706542/how-to-get-csreq-of-macos-application-on-command-line/57259004#57259004
codesign -dr - "$CHROME_PATH" 2>&1 | awk -F ' => ' '/designated/{print $2}' | csreq -r- -b /tmp/csreq.bin 
CSREQ=$(xxd -p /tmp/csreq.bin  | tr -d '\n')

SYSTEM_DB_PATH="/Library/Application Support/com.apple.TCC/TCC.db"
USER_DB_PATH="/Users/$USER/Library/Application Support/com.apple.TCC/TCC.db"
DB_COLUMNS="service, client, client_type, auth_value, auth_reason, auth_version, csreq, flags"

CLIENT='com.google.Chrome'
CLIENT_TYPE=0  # CLIENT is a bundle identifier
AUTH_VALUE=2  # allowed
AUTH_REASON=3  # user set
AUTH_VERSION=1  # always 1

MICROPHONE='kTCCServiceMicrophone'
CAMERA='kTCCServiceCamera'
SCREEN_CAPTURE='kTCCServiceScreenCapture'

# See https://circleci.com/developer/orbs/orb/circleci/macos#commands-add-uitest-permissions
tcc_service_accessibility="INSERT or REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags) values (\"kTCCServiceAccessibility\",\"com.apple.dt.Xcode-Helper\",0,2,1,1,\"UNUSED\",0);"
tcc_service_developer_tool="INSERT or REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags) values (\"kTCCServiceDeveloperTool\",\"com.apple.Terminal\",0,2,1,1,\"UNUSED\",0);"

for DB_PATH in "$SYSTEM_DB_PATH" "$USER_DB_PATH"; do
  echo Adding permissions $DB_PATH

  sudo sqlite3 "$DB_PATH" "$tcc_service_accessibility"
  sudo sqlite3 "$DB_PATH" "$tcc_service_developer_tool"

  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$MICROPHONE', '$CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$CAMERA', '$CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$SCREEN_CAPTURE', '$CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "SELECT * FROM access WHERE client = '$CLIENT'"
done
