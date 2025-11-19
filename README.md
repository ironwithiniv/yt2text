# yt2text

A simple Bash script that downloads audio from a YouTube video using `yt-dlp` and automatically transcribes it to text with Whisper.cpp. Output files are named after the video title and channel name.

## Features

- Downloads audio from YouTube videos
- Automatic model download from HuggingFace
- Clean filename generation based on video title and channel name
- Automatic cleanup of temporary audio files
- Organized output in `transcripts/` folder
- Optional model selection (defaults to `base.en`)

## Requirements

- `bash` (version 4.0 or higher)
- `yt-dlp` - YouTube video downloader ([installation guide](https://github.com/yt-dlp/yt-dlp#installation))
- `wget` - For downloading Whisper models
- `whisper.cpp` compiled binary - Speech recognition ([installation guide](https://github.com/ggerganov/whisper.cpp#usage))

### Installing Requirements

**yt-dlp:**
```bash
# Using pip
pip install yt-dlp

# Or using homebrew (macOS)
brew install yt-dlp
```

**whisper.cpp:**
```bash
# Clone the repository
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp

# Build the project (see whisper.cpp README for detailed instructions)
make

# The binary will be at ./main
# Copy it to the expected location (or update WHISPER_BIN in the script)
cp main ~/whisper.cpp/main
```

**wget:**
```bash
# macOS
brew install wget

# Linux (Debian/Ubuntu)
sudo apt-get install wget
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/yt2text.git
cd yt2text
```

2. Make the script executable:
```bash
chmod +x yt2text.sh
```

3. Ensure `whisper.cpp` binary is located at `$HOME/whisper.cpp/main`, or set the `WHISPER_BIN` environment variable to point to your binary location.

## Usage

Basic usage:
```bash
./yt2text.sh <youtube-url> [model-name]
```

Examples:
```bash
# Use default model (base.en)
./yt2text.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Specify a different model
./yt2text.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ base
./yt2text.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ small
./yt2text.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ medium
```

The script will:
1. Check if the Whisper model exists, download it automatically if not
2. Download the audio from the YouTube video
3. Extract video title and channel name
4. Transcribe the audio using Whisper.cpp with the specified model
5. Save the transcript as `<Title> - <Channel>.txt` in the `transcripts/` folder
6. Clean up temporary audio files

## Output Format

Transcripts are saved in the `transcripts/` folder with the following naming convention:
```
<Title> - <Channel>.txt
```

**Example output filename:**
```
How to Use Whisper.cpp Tutorial - TechChannel.txt
```

The transcript file contains the plain text transcription of the video audio.

## Available Models

The script supports all Whisper.cpp models available on HuggingFace. Common models include:

- `tiny.en` - English only, smallest model
- `base.en` - English only, default model
- `tiny` - Multilingual, smallest model
- `base` - Multilingual, small model
- `small` - Multilingual, medium model
- `medium` - Multilingual, larger model
- `large-v2` - Multilingual, largest model (best quality)

Models are automatically downloaded to `$HOME/whisper.cpp/models/` on first use.

## Configuration

You can modify the following variables in `yt2text.sh` or set them as environment variables:

- `WHISPER_BIN`: Path to the whisper.cpp binary (default: `$HOME/whisper.cpp/main`)
- `MODELS_DIR`: Directory to store Whisper models (default: `$HOME/whisper.cpp/models`)
- `TRANSCRIPTS_DIR`: Directory to save transcripts (default: `transcripts/`)
- `TEMP_DIR`: Directory for temporary audio files (default: `transcripts/temp/`)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Disclaimer

This tool is for personal and educational use only. Please respect YouTube's Terms of Service and copyright laws when using this tool.
