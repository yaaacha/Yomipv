# Yomipv (Mac-Compatible Edition)

Yomipv is a script that combines Yomitan with MPV to create Anki cards from Japanese media without leaving the player.
This version is specifically optimized for MacOS compatibility, fixing common TLS handshake and header issues found on HiAnime/Megacloud.

There's no need to do alt tabs to switch between MPV, texthooker and Yomitan while mining or doing word lookups. 
It was made designed to be used with [Senren Note Type v5.0.0](https://github.com/BrenoAqua/Senren), but it should work with any note type.

https://github.com/user-attachments/assets/8ff6f71a-c961-4da1-bf9f-b1b2c00143f8

## 📋 Requirements & Dependencies

| Tool | Purpose | Status |
| :--- | :--- | :--- |
| **Anki** | Flashcard storage | Required (+ [AnkiConnect](https://ankiweb.net/shared/info/2055492159)) |
| **Yomitan** | Dictionary & Translation | Required ([Browser Extension](https://yomitan.wiki/)) |
| **Yomitan API** | Bridge between MPV & Yomitan | Required ([Setup Guide](https://github.com/yomidevs/yomitan-api)) |
| **curl** | Handling API requests | Required (Included in macOS) |
| **HiAnime Plugin** | Anime streaming support | Required for Streaming ([Plugin Link](https://github.com/yaaacha/yt-dlp-hianime)) |

## 🛠 MacOS Requirements & Setup
MacOS uses `SecureTransport` which often conflicts with unofficial streams. To ensure smooth playback and image processing (WebP/AVIF):
1. **MPV Configuration**: You **must** disable TLS verification in your `mpv.conf` to prevent `-9806` errors.
2. **Curl**: macOS comes with `curl` pre-installed. Verify by typing `curl --version` in Terminal. If missing, install via `brew install curl`.
3. **Image Support**: To support WebP/AVIF for Anki cards, ensure FFmpeg is installed with proper libraries.

### Installation via Homebrew:
Core dependencies
	```
	brew install ffmpeg mpv node libwebp libavif
	```
   
## Quick Setup (MacOS/Linux)

1. **Clone and Run Setup**:
   Open Terminal
   ```
   # Create mpv directory if it doesn't exist
   mkdir -p ~/.config/mpv

   # Navigate to mpv config directory
   cd ~/.config/mpv

   # Clone the specific mac-compatibility branch directly into the current folder
   git clone -b mac-hianime-compatibility https://github.com/yaaacha/Yomipv.git .

   # Run the setup script
   chmod +x setup.sh
   ./setup.sh
   ```
   Note: Using . at the end of git clone will extract files directly into the current folder instead of creating a subfolder.
   > [!IMPORTANT]
   > We are using the -b mac-hianime-compatibility flag to ensure you get the optimized version for MacOS.
   
## ⚠️ MacOS Compatibility Fixes (Internal Updates)
   If you encounter Status 2 (Audio extraction failed) or TLS Errors, ensure your configuration matches these recent updates:
   1. **Updated mpv.conf**
      Recent updates moved headers directly into the config to stabilize the connection:
	  ```
	  tls-verify=no
	  user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
	  http-header-fields="Referer: https://megacloud.blog/"
	  ```
   2. **[HiAnime Plugin Optimization](https://github.com/yaaacha/yt-dlp-hianime)**
      The included hianime.py extractor has been modified to:
	  - Force sub server for consistent Japanese audio.
	  - Hardcode ja language metadata for Yomitan recognition.
	  - Inject Referer and Origin headers into every M3U8 segment request.
   3. **Stream and Local Profile**
      Different modes require different handling for audio and image extraction to avoid "Status 2" or TLS errors on MacOS.
	  | Profile Name | Usage Scenario | Key Settings
	  | :---: | :---: | :--- |
	  | [streaming-mode] | Watching via HiAnime/Online | Disables local FFmpeg extraction to rely on mpv's internal stream buffer. Bypasses TLS for extraction. |
	  | [local-mode] | Watching downloaded files | "Enables local FFmpeg for faster, high-quality audio/image extraction from your disk." |
	  
	  > [!TIP]
	  > Switching Profiles: default profile is stream Mode. You can change mode with assigned shortcut. You define them yourself in your script-opts so Yomipv knows which extraction method to use. You need to restart mpv to change profile.
	  
## ⌨️ Default Keybindings
   | Shortcut | Action |
   | :---: | :--- |
   | `Ctrl + v` | paste a HiAnime link |
   | `c` | Open word selector |
   | `Arrow Keys or Mouse hover` | Word selection navigating |
   | `Enter/return` | Export to Anki (when selector is open) |
   | `a` | Toggle subtitle history panel |
   | `Ctrl + c` | Dictionary lookup |
   | `Alt/Opt (Mac) + 1` | Stream Mode |
   | `Alt/Opt (Mac) + 2` | Local Mode|
   
### ⌨️ Advanced Features

   <table>
  <tr>
    <th colspan="2" align="center">Append Mode</th>
  </tr>
  <tr>
    <td><code>Shift + c</code></td>
    <td>Enter append mode</td>
  </tr>
  <tr>
    <td><code>c</code></td>
    <td>Start word selector</td>
  </tr>
  <tr>
    <td><code>Shift + c</code></td>
    <td>Cancel word selector</td>
  </tr>
  <tr>
    <th colspan="2" align="center">Selection Expansion</th>
  </tr>
  <tr>
    <td><code>s</code></td>
    <td>Word Splitting (after entering word selector)</td>
  </tr>
  <tr>
    <td><code>Alt/Opt (Mac) + Left/Right</code></td>
    <td>Expand selection to adjacent words</td>
  </tr>
  <tr>
    <td><code>Shift + Left/Right</code></td>
    <td>Expand to previous/next subtitle line</td>
  </tr>
</table>

   
## 🛠 Troubleshooting (MacOS)
   | Error Code | Cause | Solution |
   | :---: | :---: | :---: |
   | Error -9806 / -36 | TLS Handshake failure | Add tls-verify=no to mpv.conf (no --) |
   | Status 2 | Audio Extraction Failed | Check Referer headers in hianime.py |
   | IndentationError | Python Spacing | Ensure 4-space indentation in hianime.py |
   | Image Missing | Missing Libs | Run brew install libwebp libavif |
   
> [!IMPORTANT]
> Active Branch: Always use the mac-hianime-compatibility branch for the latest MacOS fixes.

> [!WARNING]
> **Linux and Windows Support Not Tested for this version**
> This script has primarily been developed and tested on Windows and modified on MacOS. While cross-platform support is intended, Linux and Windows users may encounter issues. Please report any bugs or compatibility problems.
