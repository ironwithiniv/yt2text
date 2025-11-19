#!/bin/bash

# yt2text - YouTube to Text Transcription Tool
# Downloads audio from YouTube videos and transcribes them using Whisper.cpp

set -e  # Exit on error

# Configuration
WHISPER_BIN="${WHISPER_BIN:-$HOME/whisper.cpp/build/bin/whisper-cli}"  # Path to whisper.cpp binary
MODELS_DIR="${MODELS_DIR:-$HOME/whisper.cpp/models}"
TRANSCRIPTS_DIR="${TRANSCRIPTS_DIR:-transcripts}"
TEMP_DIR="${TRANSCRIPTS_DIR}/temp"

# Default model name
MODEL_NAME="${2:-base.en}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[+] $1${NC}"
}

# Check if URL is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <youtube-url> [model-name]"
    echo "Example: $0 https://www.youtube.com/watch?v=VIDEO_ID base.en"
    exit 1
fi

YOUTUBE_URL="$1"

# Check if required tools are available
if ! command -v yt-dlp &> /dev/null; then
    print_error "yt-dlp is not installed. Please install it first."
    exit 1
fi

if ! command -v wget &> /dev/null; then
    print_error "wget is not installed. Please install it first."
    exit 1
fi

if [ ! -f "$WHISPER_BIN" ]; then
    print_error "whisper.cpp binary not found at '$WHISPER_BIN'. Please install whisper.cpp or set WHISPER_BIN environment variable."
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$TRANSCRIPTS_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p "$MODELS_DIR"

# Model file path (absolute)
MODEL_FILE="${MODELS_DIR}/ggml-${MODEL_NAME}.bin"

# Check if model exists, download if not
if [ ! -f "$MODEL_FILE" ]; then
    print_info "Downloading model..."
    MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL_NAME}.bin"
    
    if wget -q --show-progress -O "$MODEL_FILE" "$MODEL_URL"; then
        print_success "Model downloaded successfully: ${MODEL_NAME}"
    else
        print_error "Failed to download model. Check your internet connection or verify the model name."
        rm -f "$MODEL_FILE"  # Remove partial download if any
        exit 1
    fi
else
    print_info "Using existing model: ${MODEL_NAME}"
fi

print_info "Fetching video information..."

# Get video title and channel name using separate commands
TITLE=$(yt-dlp --get-title "$YOUTUBE_URL" 2>/dev/null)
CHANNEL=$(yt-dlp --get-uploader "$YOUTUBE_URL" 2>/dev/null)

if [ -z "$TITLE" ] || [ -z "$CHANNEL" ]; then
    print_error "Failed to fetch video information. Check URL or yt-dlp."
    exit 1
fi

# Sanitize filenames: remove/replace invalid characters
sanitize_filename() {
    local filename="$1"
    # Remove or replace invalid characters for filenames
    filename=$(echo "$filename" | sed 's/[\/\\:*?"<>|]//g')
    # Replace multiple spaces with single space
    filename=$(echo "$filename" | tr -s ' ')
    # Trim leading/trailing spaces
    filename=$(echo "$filename" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Limit length to 200 characters
    filename=$(echo "$filename" | cut -c1-200)
    echo "$filename"
}

TITLE_CLEAN=$(sanitize_filename "$TITLE")
CHANNEL_CLEAN=$(sanitize_filename "$CHANNEL")

# Generate output filename: <Title> - <Channel>.txt
OUTPUT_FILE="${TRANSCRIPTS_DIR}/${TITLE_CLEAN} - ${CHANNEL_CLEAN}.txt"
TEMP_AUDIO="${TEMP_DIR}/${TITLE_CLEAN}-${CHANNEL_CLEAN}.wav"

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
if ! yt-dlp -x --audio-format wav -o "$TEMP_AUDIO" "$YOUTUBE_URL" --quiet --no-warnings; then
    print_error "Audio file not downloaded. Check URL or yt-dlp."
    exit 1
fi

# Find the actual downloaded file (yt-dlp may add extension)
if [ ! -f "$TEMP_AUDIO" ]; then
    # Try to find the file with .wav extension
    TEMP_AUDIO="${TEMP_AUDIO%.*}.wav"
    if [ ! -f "$TEMP_AUDIO" ]; then
        # Try to find any audio file in temp directory
        TEMP_AUDIO=$(find "$TEMP_DIR" -name "${TITLE_CLEAN}-${CHANNEL_CLEAN}.*" -type f | head -n 1)
        if [ -z "$TEMP_AUDIO" ] || [ ! -f "$TEMP_AUDIO" ]; then
            print_error "Audio file not downloaded. Check URL or yt-dlp."
            exit 1
        fi
    fi
fi

print_info "Transcribing..."

# Run Whisper.cpp with the model file
if ! "$WHISPER_BIN" -m "$MODEL_FILE" -f "$TEMP_AUDIO" -of "${OUTPUT_FILE%.txt}" -nt; then
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

print_success "Done! Transcript saved as: $OUTPUT_FILE"
