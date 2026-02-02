#!/bin/bash

usage() {
    echo "Usage: ./create-submission.sh [project_number] [team_number]"
    echo "  project_number: 0 to 4"
    echo "  team_number:    1 to 99"
    echo ""
    echo "Example:  ./create-submission.sh 2 15"
    exit 1
}

warn() {
  tput bold; tput setaf 1
  echo "=========================  ERROR  ==========================" >&2
  echo "$*" >&2
  echo "============================================================" >&2
  tput sgr0
}

info() {
  tput bold; tput setaf 2
  echo "$*" >&2
  tput sgr0
}

if [ "$#" -eq 0 ]; then
    : # Interactive
elif [ "$#" -eq 2 ]; then
    PRJ_NUM=$1
    TEAM_NUM=$2
else
    # Invalid Usage
    echo "Error: Invalid number of arguments."
    usage
fi

if [ "$#" -eq 0 ]; then
    read -p "Enter Project Number (0-4): " PRJ_NUM

    if [[ ! "$PRJ_NUM" =~ ^[0-4]$ ]]; then
        echo "Error: Project Number must be an integer between 0 and 4."
        exit 1
    fi

    read -p "Enter Team Number: " TEAM_NUM

    if [[ ! "$TEAM_NUM" =~ ^[0-9]+$ ]] || [ "$TEAM_NUM" -lt 1 ] || [ "$TEAM_NUM" -gt 99 ]; then
        echo "Error: Team Number must be an integer."
        exit 1
    fi
fi

PATCH_FILE="prj${PRJ_NUM}.patch"
ZIP_FILE="prj${PRJ_NUM}_team_${TEAM_NUM}.zip"

if [ ! -d "original" ] || [ ! -d "project" ]; then
    echo "Error: Run this from the 'pintos' directory containing 'original' and 'project'."
    exit 1
fi

echo "Creating $PATCH_FILE..."
diff -ruN \
    -x "build" \
    -x ".git*" \
    -x ".DS_Store" \
    -x ".vscode" \
    original project > "$PATCH_FILE"

echo "Creating $ZIP_FILE..."
TMP_ZIP="$(mktemp "prj${PRJ_NUM}_team_${TEAM_NUM}.zip.XXXXXX")"
rm -f "$TMP_ZIP"
if (! zip -j -o "$TMP_ZIP" "$PATCH_FILE" >/dev/null); then
    warn "Failed to create zip file."
    exit 1
fi
mv -f "$TMP_ZIP" "$ZIP_FILE"

if [ -f "$ZIP_FILE" ]; then
    MAX_BYTES=$((100 * 1024))
    ZIP_BYTES=$(wc --bytes < "$ZIP_FILE")
    if [ "$ZIP_BYTES" -gt "$MAX_BYTES" ]; then
        warn $'The zip file size ('"$ZIP_BYTES"$' bytes) exceeds the 100 KB limit.\n\n'"\
"$'Please review '"$PATCH_FILE"$' for potential issues such as\n'"\
"$'duplicate/extra folders or files.'
        exit 1
    else
        rm "$PATCH_FILE" 
        info "Please upload $ZIP_FILE to Canvas."
    fi
else
    warn "Failed to create zip file."
    exit 1
fi

