# Yomipv (Mac-Compatible Edition)

Yomipv is a script that combines Yomitan with MPV to create anki cards from Japanese media without leaving the player.
There's no need to do alt tabs to switch between MPV, texthooker and Yomitan while mining or doing word lookups. 
It was made designed to be used with [Senren Note Type v5.0.0](https://github.com/BrenoAqua/Senren), but it should work with any note type.

https://github.com/user-attachments/assets/8ff6f71a-c961-4da1-bf9f-b1b2c00143f8

## Requirements

- **[MPV](https://mpv.io/)** (0.33.0 or higher)
- **[FFmpeg](https://ffmpeg.org/)** (Required for media extraction, but fallbacks to mpv's internal encoder if not found)
- **[Anki](https://apps.ankiweb.net/)** with **[AnkiConnect](https://ankiweb.net/shared/info/2055492159)**
- **[Yomitan](https://yomitan.wiki/)** and **[Yomitan Api](https://github.com/yomidevs/yomitan-api)**
- **[Node.js](https://nodejs.org/)** (Required for the lookup app)
- **curl** (Usually pre-installed on Windows, used for API requests)
- **[Hianime Plugin](https://github.com/yaaacha/yt-dlp-hianime)** for mpv

Yomipv combines Yomitan with MPV to create Anki cards directly from Japanese media. This version is specifically optimized for **MacOS** and **HiAnime streaming stability**.

## 🚀 Quick Setup (MacOS/Linux)

1. **Clone and Run Setup**:
   ```bash
   git clone [https://github.com/yaaacha/Yomipv](https://github.com/yaaacha/Yomipv) ~/.config/mpv/yomipv-temp
   cp -rn ~/.config/mpv/yomipv-temp/* ~/.config/mpv/
   rm -rf ~/.config/mpv/yomipv-temp
   cd ~/.config/mpv && chmod +x setup.sh && ./setup.sh
   ```
2. Refresh Terminal: source ~/.zshrc (or restart your terminal).
3. Start Mining: Just type yomipv.

✨ New Features in this Branch
- Streaming Stability: Uses internal screenshot mode to bypass connection resets on sites like HiAnime.
- Audio Padding: No more cut-off audio! Configurable start/end padding via yomipv.conf.
- Easy Launch: Integrated lookup app launch via a single terminal command.

## **Configure Settings**:
   - Open `script-opts/yomipv.conf` and update your Anki deck/note type names and field mappings.
   
### Audio Padding
    If your audio clips feel too short, change this configuration:
```
audio_padding_start=0.2
audio_padding_end=0.3
```

## **External Services**:
   - Ensure Anki is running with AnkiConnect enabled.
   - Ensure Yomitan Api is running and the browser where the Yomitan extension is installed is open, and you have dictionaries installed.

## Usage

### Basic Workflow

1. Type yomipv in terminal.
2. Press Ctrl+V to paste a HiAnime link or drop a local file.
3. c: Open word selector.
4. Enter: Export to Anki.
5. a: Toggle History panel.
6. Ctrl+c: Real-time dictionary lookup.

### Advanced Features

- **Append Mode (`Shift+C`)**: Select multiple subtitle lines before exporting
  - Press `Shift+C` to enter append mode, `c` to start the word selector, or `Shift+C` again to cancel

- **Selection Expansion**:
  - **Alt + Left/Right (Mac: ⌥ Option)**: Expand selection to adjacent words.
  - **`Shift + Left/Right`**: Expand to previous/next subtitle line

- **Word Splitting (`s` or right-click)**: Split compound words into smaller segments

- **Dictionary Lookup (`Ctrl+c`)**: Open real-time dictionary definitions window that uses your yomitan glossary

- **History Panel (`a`)**: Toggle subtitle history panel
  - Click on previous/next lines to select them to expand the subtitle lines (when selector is open) or seek to that timestamp (when selector is closed)

There are demos for all features [here](https://github.com/yaaacha/Yomipv/tree/main/features)

## Troubleshooting

### Windows
- Ensure PowerShell execution policy allows scripts
- Check that curl is available at `C:\Windows\System32\curl.exe`

> [!WARNING]
> **Linux and Windows Support Not Tested for this version**
> This script has primarily been developed and tested on Windows and modified on MacOS. While cross-platform support is intended, Linux and Windows users may encounter issues. Please report any bugs or compatibility problems.
