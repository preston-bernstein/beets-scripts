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

# Function to normalize filenames for comparison
normalize_name() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' '
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

# Find duplicate files based on normalized names, excluding @eaDir directories
declare -A file_map
declare -i duplicates_removed=0

while IFS= read -r -d '' file; do
    if [[ "$file" != */@eaDir/* ]]; then
        norm_name=$(normalize_name "$(basename "$file")")
        if [[ -n "${file_map[$norm_name]}" ]]; then
            current_file="${file_map[$norm_name]}"
            if [[ "$file" =~ [[:space:]] ]]; then
                log_message "Removing duplicate file: $current_file"
                rm "$current_file"
                file_map["$norm_name"]="$file"
            else
                log_message "Removing duplicate file: $file"
                rm "$file"
            fi
            duplicates_removed+=1
        else
            file_map["$norm_name"]="$file"
        fi
    fi
done < <(find "$MUSIC_DIR" -type f -print0)

log_message "Duplicate removal process completed. Total duplicates removed: $duplicates_removed"
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
