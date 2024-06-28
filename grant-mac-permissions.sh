#!/bin/bash
set -eux

SYSTEM_DB_PATH="/Library/Application Support/com.apple.TCC/TCC.db"
USER_DB_PATH="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
DB_COLUMNS="service, client, client_type, auth_value, auth_reason, auth_version, csreq, flags"

CHROME_CLIENT='com.google.Chrome'
CHROME_TEST_CLIENT='com.google.chrome.for.testing'

CLIENT_TYPE=0  # CLIENT is a bundle identifier
AUTH_VALUE=2  # allowed
AUTH_REASON=3  # user set
AUTH_VERSION=1  # always 1

MICROPHONE='kTCCServiceMicrophone'
CAMERA='kTCCServiceCamera'
SCREEN_CAPTURE='kTCCServiceScreenCapture'

# https://github.com/actions/runner-images/blob/macos-13/20240623.1/images/macos/scripts/helpers/utils.sh#L48C1-L50C2
is_Sonoma() {
    [ "$OSTYPE" = "darwin23" ]
}

# https://github.com/actions/runner-images/blob/macos-13/20240623.1/images/macos/scripts/helpers/utils.sh#L137
configure_tccdb() {
  local dbPath=$1
  local values=$2
  local sqlQuery="INSERT OR REPLACE INTO access VALUES($values);"
  sudo sqlite3 "$dbPath" "$sqlQuery"
}

configure_system_tccdb () {
    configure_tccdb "$SYSTEM_DB_PATH" "$1"
}

configure_user_tccdb () {
    configure_tccdb "$USER_DB_PATH" "$1"
}

# === Existing clients ===
# add microphone, camera, and screen capture for all existing clients in the databases
for DB_PATH in "$SYSTEM_DB_PATH" "$USER_DB_PATH"; do
  echo "DB_PATH=$DB_PATH"
  for CLIENT in $(sudo sqlite3 "$DB_PATH" "SELECT DISTINCT client FROM access;"); do
    echo "CLIENT=$CLIENT"
    row=$(sudo sqlite3 "$DB_PATH" "SELECT * FROM access WHERE client = '$CLIENT' LIMIT 1;")
    echo "row=$row"
    IFS="|" read -ra row_split <<< "$row"
    row_split="${row_split[@]:1}"
    echo "row_split=$row_split"
    for service in $MICROPHONE $CAMERA $SCREEN_CAPTURE; do
      row_for_service="${service}|${row_split[@]}"
      echo "row_for_service=$row_for_service"
      configure_tccdb "$DB_PATH" "$row_for_service"
    done
  done
done

# === Chrome ===
# See https://circleci.com/developer/orbs/orb/circleci/macos#commands-add-uitest-permissions
tcc_service_accessibility="INSERT or REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags) values (\"kTCCServiceAccessibility\",\"com.apple.dt.Xcode-Helper\",0,2,1,1,\"UNUSED\",0);"
tcc_service_developer_tool="INSERT or REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags) values (\"kTCCServiceDeveloperTool\",\"com.apple.Terminal\",0,2,1,1,\"UNUSED\",0);"

# See https://entonos.com/2023/06/23/how-to-modify-tcc-on-macos/
# and https://stackoverflow.com/questions/52706542/how-to-get-csreq-of-macos-application-on-command-line/57259004#57259004
codesign -dr - "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" 2>&1 | awk -F ' => ' '/designated/{print $2}' | csreq -r- -b /tmp/csreq.bin 
CHROME_CSREQ=$(xxd -p /tmp/csreq.bin  | tr -d '\n')
echo CHROME_CSREQ="$CHROME_CSREQ"

codesign -dr - "/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" 2>&1 | awk -F ' => ' '/designated/{print $2}' | csreq -r- -b /tmp/csreq.bin 
CHROME_TEST_CSREQ=$(xxd -p /tmp/csreq.bin  | tr -d '\n')
echo CHROME_TEST_CSREQ="$CHROME_TEST_CSREQ"

for DB_PATH in "$SYSTEM_DB_PATH" "$USER_DB_PATH"; do
  echo Adding permissions $DB_PATH

  sudo sqlite3 "$DB_PATH" "$tcc_service_accessibility"
  sudo sqlite3 "$DB_PATH" "$tcc_service_developer_tool"
  
  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$MICROPHONE', '$CHROME_CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CHROME_CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$CAMERA', '$CHROME_CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CHROME_CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$SCREEN_CAPTURE', '$CHROME_CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CHROME_CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "SELECT * FROM access WHERE client = '$CHROME_CLIENT'"

  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$MICROPHONE', '$CHROME_TEST_CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CHROME_TEST_CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$CAMERA', '$CHROME_TEST_CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CHROME_TEST_CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "INSERT or REPLACE INTO access ($DB_COLUMNS) VALUES ('$SCREEN_CAPTURE', '$CHROME_TEST_CLIENT', $CLIENT_TYPE, $AUTH_VALUE, $AUTH_REASON, $AUTH_VERSION, '$CHROME_TEST_CSREQ', 0)"
  sudo sqlite3 "$DB_PATH" "SELECT * FROM access WHERE client = '$CHROME_TEST_CLIENT'"
done
