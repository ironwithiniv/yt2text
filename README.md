# yt2text

A simple Bash script that downloads audio from a YouTube video using `yt-dlp` and automatically transcribes it to text with Whisper.cpp (with automatic language detection). Output files are named after the video and channel.

## Features

- Downloads audio from YouTube videos
- Automatic language detection using Whisper.cpp
- Clean filename generation based on video title and channel name
- Automatic cleanup of temporary audio files
- Organized output in `transcripts/` folder

## Requirements

- `bash` (version 4.0 or higher)
- `yt-dlp` - YouTube video downloader ([installation guide](https://github.com/yt-dlp/yt-dlp#installation))
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

# The binary will be at ./whisper
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

3. Ensure `whisper.cpp` binary is in your PATH, or update the `WHISPER_BIN` variable in the script to point to your binary location.

## Usage

Basic usage:
```bash
./yt2text.sh <youtube-url>
```

Example:
```bash
./yt2text.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

The script will:
1. Download the audio from the YouTube video
2. Extract video title and channel name
3. Transcribe the audio using Whisper.cpp with automatic language detection
4. Save the transcript as `<channel>-<title>.txt` in the `transcripts/` folder
5. Clean up temporary audio files

## Output Format

Transcripts are saved in the `transcripts/` folder with the following naming convention:
```
<channel-name>-<video-title>.txt
```

**Example output filename:**
```
TechChannel-How to Use Whisper.cpp Tutorial.txt
```

The transcript file contains the plain text transcription of the video audio.

## Configuration

You can modify the following variables in `yt2text.sh`:

- `WHISPER_BIN`: Path to the whisper.cpp binary (default: `whisper`)
- `TRANSCRIPTS_DIR`: Directory to save transcripts (default: `transcripts/`)
- `TEMP_DIR`: Directory for temporary audio files (default: `transcripts/temp/`)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Disclaimer

This tool is for personal and educational use only. Please respect YouTube's Terms of Service and copyright laws when using this tool.
