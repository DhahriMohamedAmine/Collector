#!/bin/zsh

# SETTINGS
# Set to true to see what WOULD happen without changing anything.
# Set to false to actually rename the files.
DRY_RUN=false

# The root directory to start the recursive search from.
# Use "." for the current directory, or specify a path like "/Users/me/Documents/Projects"
ROOT_DIR="/Users/mohamedaminedhahri/Desktop/Code/swift/Ex_Files_Swift_6_EssT"

# Enable recursive globbing
setopt extended_glob

echo "Starting search for 'contents.xcplayground.xml' inside '.playground' directories in: $ROOT_DIR"

# Check if the root directory exists
if [[ ! -d "$ROOT_DIR" ]]; then
    echo "Error: Root directory '$ROOT_DIR' does not exist or is not a directory."
    exit 1
fi

# Find files matching the pattern:
# ${ROOT_DIR}/** = recursive search starting from ROOT_DIR
# *.playground = inside folders ending in .playground
# contents.xcplayground.xml = the specific file
# (.)      = ensures we only match regular files, not directories
found_files=(${ROOT_DIR}/**/*.playground/**/contents.xcplayground.xml(.))

if (( ${#found_files} == 0 )); then
    echo "No matching files found."
    exit 0
fi

count=0

for file in $found_files; do
    # ${file%.xml} removes the .xml extension from the end of the string
    new_name="${file%.xml}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would rename: '$file' -> '$new_name'"
    else
        mv "$file" "$new_name"
        echo "Renamed: '$file' -> '$new_name'"
    fi
    ((count++))
done

echo "------------------------------------------------"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "Dry run complete. Found $count files."
    echo "Change 'DRY_RUN=true' to 'DRY_RUN=false' in the script to execute."
else
    echo "Operation complete. Renamed $count files."
fi