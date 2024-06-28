#!/bin/bash
set -eux

timestamp_line=$(ffmpeg -i "$1" -vf "select='gt(scene,0.03)',showinfo" -f null - 2>&1 | grep -e 'showinfo.*pts_time:' | head -n 1)
pts_time=$(echo "$timestamp_line" | grep -o "pts_time:[^ ]*" | awk -F: '{print $2}')
echo "The pts_time is: $pts_time"

FILE_DIR=$(python3 -c "import pathlib; print(pathlib.Path('$1').parent);")
FILE_STEM=$(python3 -c "import pathlib; print(pathlib.Path('$1').stem);")
FILE_TYPE=$(python3 -c "import pathlib; print(pathlib.Path('$1').suffix);")

ffmpeg -y -i "$1" -ss "$pts_time" -c copy "$FILE_DIR/${FILE_STEM}_trimmed$FILE_TYPE"
