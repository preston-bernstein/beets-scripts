#!/bin/bash

# Define paths
MUSIC_DIR="/music"
CONFIG_DIR="/config/logs"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="$CONFIG_DIR/remove_duplicates_$TIMESTAMP.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    log_message "ERROR: $1"
    exit 1
}

# Function to count and log files and folders
log_counts() {
    local file_count=$(find "$MUSIC_DIR" -type f | wc -l)
    local folder_count=$(find "$MUSIC_DIR" -type d | wc -l)
    log_message "Current file count: $file_count"
    log_message "Current folder count: $folder_count"
}

# Function to normalize names for comparison
normalize_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' '
}

# Function to compare and remove duplicates
remove_duplicates() {
    declare -A name_map
    local duplicate_count=0

    while IFS= read -r -d '' item; do
        local base_name
        base_name=$(basename "$item")
        norm_name=$(normalize_name "$base_name")

        if [[ -n "${name_map[$norm_name]}" ]]; then
            log_message "Removing duplicate: $item"
            rm -rf "$item"
            ((duplicate_count++))
        else
            log_message "Keeping: $item"
            name_map["$norm_name"]="$item"
        fi
    done < <(find "$MUSIC_DIR" -mindepth 1 -print0 | sort -z -f)

    log_message "Total duplicates removed: $duplicate_count"
}

# Check if music directory exists
if [ ! -d "$MUSIC_DIR" ]; then
    handle_error "Music directory '$MUSIC_DIR' not found."
fi

# Check if config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    handle_error "Config directory '$CONFIG_DIR' not found."
fi

log_message "Starting duplicate removal process."

# Log initial counts
log_counts

# Remove duplicates
remove_duplicates

log_message "Duplicate removal process completed."
log_counts  # Log counts after removing duplicates

# Remove empty directories and log their names, excluding @eaDir directories
declare -i empty_folders_removed=0
find "$MUSIC_DIR" -type d -empty ! -path "*/@eaDir/*" -print -delete | while read -r dir; do
    log_message "Removed empty folder: $dir"
    empty_folders_removed+=1
done

log_message "Empty folder removal process completed. Total empty folders removed: $empty_folders_removed"
log_counts  # Log counts after removing empty folders

log_message "All tasks completed successfully."
