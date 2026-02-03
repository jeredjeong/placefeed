#!/bin/bash
set -e

# Path to the problematic file
FILE="./node_modules/event-target-shim/index.d.ts"

# Check if the file exists
if [ ! -f "$FILE" ]; then
    echo "Error: $FILE not found. Cannot apply patch."
    exit 1
fi

# Apply the patch using sed
# Change 'export const EventTarget' to 'export declare const EventTarget'
sed -i 's/export const EventTarget:/export declare const EventTarget:/g' "$FILE"

echo "Successfully patched $FILE"
