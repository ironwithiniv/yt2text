#!/bin/bash

# yt2text - YouTube to Text Transcription Tool
# Downloads audio from YouTube videos and transcribes them using Whisper.cpp

set -e  # Exit on error

# Configuration
WHISPER_BIN="${WHISPER_BIN:-whisper}"  # Path to whisper.cpp binary
TRANSCRIPTS_DIR="${TRANSCRIPTS_DIR:-transcripts}"
TEMP_DIR="${TRANSCRIPTS_DIR}/temp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if URL is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <youtube-url>"
    exit 1
fi

YOUTUBE_URL="$1"

# Check if required tools are available
if ! command -v yt-dlp &> /dev/null; then
    print_error "yt-dlp is not installed. Please install it first."
    exit 1
fi

if ! command -v "$WHISPER_BIN" &> /dev/null; then
    print_error "whisper.cpp binary not found at '$WHISPER_BIN'. Please install whisper.cpp or set WHISPER_BIN environment variable."
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$TRANSCRIPTS_DIR"
mkdir -p "$TEMP_DIR"

print_info "Fetching video information..."

# Get video title and channel name
VIDEO_INFO=$(yt-dlp --print "%(channel)s|%(title)s" "$YOUTUBE_URL" 2>/dev/null)

if [ $? -ne 0 ]; then
    print_error "Failed to fetch video information. Please check the URL."
    exit 1
fi

# Extract channel and title
CHANNEL=$(echo "$VIDEO_INFO" | cut -d'|' -f1)
TITLE=$(echo "$VIDEO_INFO" | cut -d'|' -f2-)

# Sanitize filenames: remove/replace invalid characters
sanitize_filename() {
    local filename="$1"
    # Replace spaces with hyphens, remove special characters, limit length
    filename=$(echo "$filename" | sed 's/[^a-zA-Z0-9._-]/ /g' | tr -s ' ' | sed 's/ /-/g')
    # Remove leading/trailing hyphens and dots
    filename=$(echo "$filename" | sed 's/^[.-]*//;s/[.-]*$//')
    # Limit length to 200 characters
    filename=$(echo "$filename" | cut -c1-200)
    echo "$filename"
}

CHANNEL_CLEAN=$(sanitize_filename "$CHANNEL")
TITLE_CLEAN=$(sanitize_filename "$TITLE")

# Generate output filename
OUTPUT_FILE="${TRANSCRIPTS_DIR}/${CHANNEL_CLEAN}-${TITLE_CLEAN}.txt"
TEMP_AUDIO="${TEMP_DIR}/${CHANNEL_CLEAN}-${TITLE_CLEAN}.wav"

# Check if transcript already exists
if [ -f "$OUTPUT_FILE" ]; then
    print_info "Transcript already exists: $OUTPUT_FILE"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping..."
        exit 0
    fi
fi

print_info "Channel: $CHANNEL"
print_info "Title: $TITLE"
print_info "Downloading audio..."

# Download audio as WAV format
yt-dlp -x --audio-format wav -o "$TEMP_AUDIO" "$YOUTUBE_URL" --quiet --no-warnings

if [ $? -ne 0 ]; then
    print_error "Failed to download audio."
    exit 1
fi

# Find the actual downloaded file (yt-dlp may add extension)
if [ ! -f "$TEMP_AUDIO" ]; then
    # Try to find the file with .wav extension
    TEMP_AUDIO="${TEMP_AUDIO%.*}.wav"
    if [ ! -f "$TEMP_AUDIO" ]; then
        # Try to find any audio file in temp directory
        TEMP_AUDIO=$(find "$TEMP_DIR" -name "${CHANNEL_CLEAN}-${TITLE_CLEAN}.*" -type f | head -n 1)
        if [ -z "$TEMP_AUDIO" ]; then
            print_error "Could not find downloaded audio file."
            exit 1
        fi
    fi
fi

print_info "Transcribing audio with Whisper.cpp (auto language detection)..."

# Run Whisper.cpp with automatic language detection
"$WHISPER_BIN" -l auto -f "$TEMP_AUDIO" -of "${OUTPUT_FILE%.txt}" -nt

if [ $? -ne 0 ]; then
    print_error "Transcription failed."
    rm -f "$TEMP_AUDIO"
    exit 1
fi

# Whisper.cpp creates .txt file, ensure it has the correct name
if [ -f "${OUTPUT_FILE%.txt}.txt" ] && [ "${OUTPUT_FILE%.txt}.txt" != "$OUTPUT_FILE" ]; then
    mv "${OUTPUT_FILE%.txt}.txt" "$OUTPUT_FILE"
fi

# Clean up temporary audio file
print_info "Cleaning up temporary files..."
rm -f "$TEMP_AUDIO"

print_success "Transcription complete!"
print_success "Output saved to: $OUTPUT_FILE"

