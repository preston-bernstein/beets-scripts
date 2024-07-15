#!/bin/bash

# Define paths
MUSIC_DIR="/music"
CONFIG_DIR="/config"
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
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' ' | sed -E 's/ \(.*\)$//' | sed 's/[0-9]* //g'
}

# Function to determine file quality
get_file_quality() {
    local file="$1"
    case "${file##*.}" in
        flac) echo 3 ;;
        mp3) echo 2 ;;
        *) echo 1 ;;  # Default to lowest quality if not recognized
    esac
}

# Function to compare and consolidate tracks within the same album context
consolidate_album_tracks() {
    local album_dir="$1"
    declare -A track_map
    local consolidate_dir="$MUSIC_DIR/consolidated"

    mkdir -p "$consolidate_dir"

    while IFS= read -r -d '' track; do
        local track_name
        track_name=$(basename "$track")
        norm_track_name=$(normalize_name "$track_name")
        track_quality=$(get_file_quality "$track")

        if [[ -n "${track_map[$norm_track_name]}" ]]; then
            existing_track="${track_map[$norm_track_name]}"
            existing_quality=$(get_file_quality "$existing_track")
            if (( track_quality > existing_quality )); then
                log_message "Replacing lower quality track: $existing_track with higher quality track: $track"
                mv "$track" "$consolidate_dir"
                rm -rf "$existing_track"
            else
                log_message "Keeping existing higher quality track: $existing_track, removing lower quality track: $track"
                rm -rf "$track"
            fi
        else
            log_message "Keeping track: $track"
            mv "$track" "$consolidate_dir"
            track_map["$norm_track_name"]="$track"
        fi
    done < <(find "$album_dir" -type f -print0)
}

# Function to compare and consolidate duplicates across albums
consolidate_duplicates() {
    declare -A album_map

    while IFS= read -r -d '' item; do
        local album_name
        album_name=$(basename "$item")
        norm_album_name=$(normalize_name "$album_name")

        if [[ -n "${album_map[$norm_album_name]}" ]]; then
            # Check if the current album is a deluxe edition and should be prioritized
            if [[ "$album_name" == *"Deluxe Edition"* ]]; then
                log_message "Removing non-deluxe album: ${album_map[$norm_album_name]}"
                rm -rf "${album_map[$norm_album_name]}"
                log_message "Consolidating deluxe album: $item"
                consolidate_album_tracks "$item"
            else
                log_message "Consolidating album: $item"
                consolidate_album_tracks "$item"
            fi
        else
            log_message "Consolidating album: $item"
            consolidate_album_tracks "$item"
            album_map["$norm_album_name"]="$item"
        fi
    done < <(find "$MUSIC_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z -f)
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

# Consolidate duplicates
consolidate_duplicates

log_message "Duplicate consolidation process completed."
log_counts  # Log counts after consolidating duplicates

# Remove empty directories and log their names, excluding @eaDir directories
declare -i empty_folders_removed=0
find "$MUSIC_DIR" -type d -empty ! -path "*/@eaDir/*" -print -delete | while read -r dir; do
    log_message "Removed empty folder: $dir"
    empty_folders_removed+=1
done

log_message "Empty folder removal process completed. Total empty folders removed: $empty_folders_removed"
log_counts  # Log counts after removing empty folders

log_message "All tasks completed successfully."
