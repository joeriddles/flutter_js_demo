#!/bin/bash

# Get the names of all visible processes
app_names=$(osascript -e 'tell application "System Events" to get the name of every process whose visible is true')

# Loop through each app name to find its path
IFS=", " read -r -a apps <<< "$app_names"
for app in "${apps[@]}"; do
  app_path=$(mdfind "kMDItemKind == 'Application' && kMDItemDisplayName == '$app'" | head -n 1)
  echo "$app: $app_path"
done
