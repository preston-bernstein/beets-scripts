#!/bin/bash

# Define paths
MUSIC_DIR="/music"
CONFIG_DIR="/config/logs"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="$CONFIG_DIR/remove_duplicates_$TIMESTAMP.log"

# ANSI color codes
RESET="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# Function to log messages with color
log_message() {
    local color="$1"
    local message="$2"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${color}${message}${RESET}" >> "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    log_message "$RED" "ERROR: $1"
    exit 1
}

# Function to count and log files and folders
log_counts() {
    local file_count=$(find "$MUSIC_DIR" -type f | wc -l)
    local folder_count=$(find "$MUSIC_DIR" -type d | wc -l)
    log_message "$CYAN" "Current file count: $file_count"
    log_message "$CYAN" "Current folder count: $folder_count"
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

# Function to get the disc number from the track name
get_disc_number() {
    local track_name="$1"
    if [[ "$track_name" =~ [Dd]isc[[:space:]]*([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo 1
    fi
}

# Function to compare and consolidate tracks within the same album context
consolidate_album_tracks() {
    local album_dir="$1"
    declare -A track_map
    declare -A disc_map

    while IFS= read -r -d '' track; do
        local track_name
        track_name=$(basename "$track")
        log_message "$BLUE" "Processing track: $track_name"
        norm_track_name=$(normalize_name "$track_name")
        track_quality=$(get_file_quality "$track")
        disc_number=$(get_disc_number "$track_name")

        target_dir="$album_dir/Disc $disc_number"
        mkdir -p "$target_dir"

        if [[ -n "${track_map[$disc_number,$norm_track_name]}" ]]; then
            existing_track="${track_map[$disc_number,$norm_track_name]}"
            existing_quality=$(get_file_quality "$existing_track")
            if (( track_quality > existing_quality )); then
                log_message "$GREEN" "Replacing lower quality track: $existing_track with higher quality track: $track"
                mv "$track" "$target_dir/"
                rm -rf "$existing_track"
                track_map[$disc_number,$norm_track_name]="$target_dir/$(basename "$track")"
            else
                log_message "$YELLOW" "Keeping existing higher quality track: $existing_track, removing lower quality track: $track"
                rm -rf "$track"
            fi
        else
            log_message "$BLUE" "Keeping track: $track"
            mv "$track" "$target_dir/"
            track_map[$disc_number,$norm_track_name]="$target_dir/$(basename "$track")"
        fi
    done < <(find "$album_dir" -type f -print0)
}

# Function to compare and consolidate duplicates across albums
consolidate_duplicates() {
    declare -A album_map

    while IFS= read -r -d '' item; do
        local album_name
        album_name=$(basename "$item")
        local artist_name
        artist_name=$(basename "$(dirname "$item")")
        norm_album_name=$(normalize_name "$album_name")
        norm_artist_name=$(normalize_name "$artist_name")

        log_message "$MAGENTA" "Processing album: $album_name by $artist_name"

        if [[ -n "${album_map[$norm_artist_name,$norm_album_name]}" ]]; then
            # Check if the current album is a deluxe edition and should be prioritized
            if [[ "$album_name" == *"Deluxe Edition"* ]]; then
                log_message "$MAGENTA" "Removing non-deluxe album: ${album_map[$norm_artist_name,$norm_album_name]}"
                rm -rf "${album_map[$norm_artist_name,$norm_album_name]}"
                album_map[$norm_artist_name,$norm_album_name]="$item"
            else
                log_message "$MAGENTA" "Removing album: $item"
                rm -rf "$item"
            fi
        else
            album_map[$norm_artist_name,$norm_album_name]="$item"
        fi
    done < <(find "$MUSIC_DIR" -mindepth 2 -maxdepth 2 -type d -print0 | sort -z -f)

    for key in "${!album_map[@]}"; do
        consolidate_album_tracks "${album_map[$key]}"
    done
}

# Check if music directory exists
if [ ! -d "$MUSIC_DIR" ]; then
    handle_error "Music directory '$MUSIC_DIR' not found."
fi

# Check if config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    handle_error "Config directory '$CONFIG_DIR' not found."
fi

log_message "$CYAN" "Starting duplicate removal process."

# Log initial counts
log_counts

# Consolidate duplicates
consolidate_duplicates

log_message "$CYAN" "Duplicate consolidation process completed."
log_counts  # Log counts after consolidating duplicates

# Remove empty directories and log their names, excluding @eaDir directories
declare -i empty_folders_removed=0
find "$MUSIC_DIR" -type d -empty ! -path "*/@eaDir/*" -print -delete | while read -r dir; do
    log_message "$RED" "Removed empty folder: $dir"
    empty_folders_removed+=1
done

log_message "$CYAN" "Empty folder removal process completed. Total empty folders removed: $empty_folders_removed"
log_counts  # Log counts after removing empty folders

log_message "$GREEN" "All tasks completed successfully."
