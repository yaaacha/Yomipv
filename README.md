# Yomipv (Mac-Compatible Edition)

Yomipv is a script that combines Yomitan with MPV to create Anki cards from Japanese media without leaving the player.
This version is specifically optimized for MacOS compatibility and additional Hianime stream feature. Youtube stream also supported because hianime is plugin of yt-dlp.

There's no need to do alt tabs to switch between MPV, texthooker and Yomitan while mining or doing word lookups. 
It was made designed to be used with [Senren Note Type v5.0.0](https://github.com/BrenoAqua/Senren), but it should work with any note type.

https://github.com/user-attachments/assets/8ff6f71a-c961-4da1-bf9f-b1b2c00143f8

---

## 📋 Requirements & Dependencies

| Tool | Purpose | Status |
| :--- | :--- | :--- |
| **MPV** | Media player | Required for [Media Player](https://github.com/mpv-player/mpv) |
| **FFmpeg** | Media Extractor | Required for [Media Extraction](https://ffmpeg.org/) (falls back to MPV's internal encoder if not found) |
| **MPV** | Media player | Required [Media Player](https://github.com/mpv-player/mpv) |
| **Anki** | Flashcard storage | Required (+ [AnkiConnect](https://ankiweb.net/shared/info/2055492159)) |
| **Yomitan** | Dictionary & Translation | Required ([Browser Extension](https://yomitan.wiki/)) |
| **Yomitan API** | Bridge between MPV & Yomitan | Required ([Setup Guide](https://github.com/yomidevs/yomitan-api)) |
| **curl** | Handling API requests | Required (Usually already preinstalled in macOS and Windows, used for API requests) |
| **HiAnime Plugin** | Anime streaming support | Required for Streaming ([Plugin Link](https://github.com/yaaacha/yt-dlp-hianime)) |

### Installation via Homebrew:
Core dependencies

	brew install ffmpeg mpv node libwebp libavif
	
---

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

2. After this setup, you can start Yomipv with just type `yomipv` in terminal

---

## ⚠️ MacOS Compatibility Fixes (Internal Updates)
   1. **[HiAnime Plugin Optimization](https://github.com/yaaacha/yt-dlp-hianime)**
      The included hianime.py extractor has been modified to:
	  - Force sub server for consistent Japanese audio.
	  - Hardcode ja language metadata for Yomitan recognition.
	  - Inject Referer and Origin headers into every M3U8 segment request.
   2. **Stream and Local Profile**
      Different modes require different handling for audio and image extraction to avoid "Status 2" or TLS errors on MacOS.
	  | Profile Name | Usage Scenario | Key Settings |
	  | :---: | :---: | :--- |
	  | [streaming-mode] | Watching via HiAnime/Online | Disables local FFmpeg extraction to rely on mpv's internal stream buffer. Bypasses TLS for extraction. |
	  | [local-mode] | Watching downloaded files | "Enables local FFmpeg for faster, high-quality audio and animated image extraction from your local video." |
	  
> [!TIP]
> Switching Profiles: default profile is **stream mode**.  
> You can change mode with assigned shortcut.  
> Restart MPV after switching profiles.

---
	  
## ⌨️ Default Keybindings
   | Shortcut | Action |
   | :---: | :--- |
   | `Ctrl + v` | Paste a HiAnime link |
   | `c` | Open word selector |
   | `mouse hover` | Open word selector (if `selector_trigger_on_mouse_move` is enabled) |
   | `Arrow Keys or Mouse hover` | Navigate word selection |
   | `Enter/return` | Export to Anki (when selector is open) |
   | `a` | Toggle subtitle history panel |
   | `Ctrl + c` | Dictionary lookup popup |
   | `Alt/Opt (Mac) + 1` | Stream Mode |
   | `Alt/Opt (Mac) + 2` | Local Mode|

More about lookup-app can be found [here](https://github.com/yaaacha/Yomipv/blob/mac-hianime-compatibility/docs/lookup-app.md).
More about field handlebar configuration for mining can be found [here](https://github.com/yaaacha/Yomipv/blob/mac-hianime-compatibility/docs/field_handlebars.md).

---

## 🧭 Basic Workflow

1. Open a video with **Japanese subtitles** in MPV.
2. Press **`c`** or **move your mouse after an idle period** (if `selector_trigger_on_mouse_move` is enabled) to activate the word selector.
3. Navigate using **mouse hover** or **arrow keys** to select a word.
4. Press **`Enter`**, **`c`**, or **left-click** to create an Anki card.

---

## ⌨️ Advanced Features

<table>

<tr>
<th colspan="2" align="center">Append Mode</th>
</tr>

<tr>
<td><code>Shift + c</code></td>
<td>
<strong>Enter append mode</strong><br>
Collect multiple subtitle lines before exporting
</td>
</tr>

<tr>
<td><code>c</code></td>
<td>
Start the <strong>word selector</strong> while in append mode
</td>
</tr>

<tr>
<td><code>Shift + c</code></td>
<td>
Press again to <strong>cancel append mode</strong>
</td>
</tr>


<tr>
<th colspan="2" align="center">Selection Expansion</th>
</tr>

<tr>
<td><code>Ctrl + Left</code><br><code>Ctrl + Right</code></td>
<td>
Expand selection to <strong>adjacent words</strong>
</td>
</tr>

<tr>
<td><code>Shift + Left</code><br><code>Shift + Right</code></td>
<td>
Expand selection to the <strong>previous / next subtitle line</strong>
</td>
</tr>


<tr>
<th colspan="2" align="center">Mora-level Navigation</th>
</tr>

<tr>
<td><code>s</code></td>
<td>
Toggle <strong>mora-level keyboard navigation</strong><br>
<em>Arrow keys move by mora instead of whole word</em>
</td>
</tr>

<tr>
<td><strong>Mouse Hover</strong></td>
<td>
When <code>selector_mora_hover</code> is enabled,<br>
lookup starts from the <strong>mora under the cursor</strong>
instead of the full word
</td>
</tr>


<tr>
<th colspan="2" align="center">Lookup App</th>
</tr>

<tr>
<td><code>Ctrl + c</code></td>
<td>
Open popup dictionary powered by <strong>Yomitan dictionaries</strong><br>
Shows definitions, pitch accents, and frequency data
</td>
</tr>

<tr>
<td><strong>Right-click word</strong></td>
<td>
<strong>Lock lookup</strong> so moving the cursor does not trigger another lookup
</td>
</tr>

<tr>
<td><strong>Click mora in header</strong></td>
<td>
Narrow the lookup to a <strong>sub-word starting at that mora</strong>
</td>
</tr>

<tr>
<td><strong>Right-click header</strong></td>
<td>
Return to the <strong>previous word</strong> in lookup history
</td>
</tr>

<tr>
<td colspan="2" align="center">
<small>
See <code>docs/lookup-app.md</code> for full details
</small>
</td>
</tr>


<tr>
<th colspan="2" align="center">Automation (Mouse Trigger)</th>
</tr>

<tr>
<td><strong>Auto Trigger</strong></td>
<td>
Automatically open the selector when the mouse moves<br>
<strong>after being idle</strong>
</td>
</tr>

<tr>
<td colspan="2" align="center">
<small>
Enable <code>selector_trigger_on_mouse_move</code> and adjust<br>
<code>selector_trigger_mouse_idle_time</code> in <code>yomipv.conf</code>
</small>
</td>
</tr>


<tr>
<th colspan="2" align="center">Manual Timing</th>
</tr>

<tr>
<td><code>q</code></td>
<td>
Set custom <strong>start time</strong> for audio/image extraction
</td>
</tr>

<tr>
<td><code>w</code></td>
<td>
Set custom <strong>end time</strong> for audio/image extraction
</td>
</tr>

<tr>
<td><code>e</code></td>
<td>
<strong>Clear manual timing markers</strong><br>
Unset timings default to subtitle boundaries
</td>
</tr>


<tr>
<th colspan="2" align="center">History Panel</th>
</tr>

<tr>
<td><code>a</code></td>
<td>
Toggle the <strong>subtitle history panel</strong>
</td>
</tr>

<tr>
<td><strong>Click subtitle</strong></td>
<td>
Select lines to expand subtitles <em>(selector open)</em><br>
or <strong>seek to the timestamp</strong> <em>(selector closed)</em>
</td>
</tr>

</table>

For more configuration, you can customize settings in: `script-opts/yomipv.conf`, `mpv/mpv.cong` and `mpv/input.conf`

---

## 🔄 How to Update
If you already have Yomipv installed and want to update to the latest version (including the MacOS compatibility fixes), follow these steps:
1. Navigate to your MPV directory:

   		cd ~/.config/mpv
2. Fetch and Pull the latest changes
   If you are already on the correct branch, pull the latest updates directly:

		git pull origin mac-hianime-compatibility
3. Switching to the Mac Branch (If you are currently on main).
   If you haven't switched to the optimized MacOS branch yet, run the following commands:
   
   		git fetch origin
		git checkout mac-hianime-compatibility
4. Re-run Setup (If necessary).
   If there have been updates to the lookup-app or its dependencies, navigate to the folder and run the setup script:

   		cd Yomipv
		chmod +x setup.sh
		./setup.sh
   
## 🛠 Troubleshooting (MacOS)
   | Error Code | Cause | Solution |
   | :---: | :---: | :---: |
   | Error -9806 / -36 | TLS Handshake failure | Add tls-verify=no to mpv.conf (no --) |
   | Status 2 | Audio Extraction Failed | Check Referer headers in hianime.py |
   | Image Missing | Missing Libs | Run brew install libwebp libavif |
   
> [!IMPORTANT]
> Active Branch: Always use the mac-hianime-compatibility branch for the latest MacOS fixes.

> [!WARNING]
> **Linux and Windows Support Not Tested for this version**
> This script initially developed on Windows and modified for MacOS compatibility. While cross-platform support is intended, Linux and Windows users may encounter issues.

# 🏛 Acknowledgements
Yomipv (Mac-Compatible Edition) was made possible by open source software and the work of its contributors. This project relies on the following components:
	
| Software | License | Role|
| :---: | :---: | :--- |
| [Yomipv](https://github.com/BrenoAqua/Yomipv) | GPL-3.0 | Core mining script |
| [mpv](https://github.com/mpv-player/mpv) | GPL-2.0 | Primary media player |
| [ffmpeg](https://github.com/FFmpeg/FFmpeg) | LGPL-2.1 | Audio and image extraction |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Unlicensed | Video downloader backend |
| [yt-dlp-hianime](https://github.com/pratikpatel8982/yt-dlp-hianime) | Unlicensed | Original HiAnime streaming support |
| [curl](https://curl.se/download.html) | MIT | API request handling |
| [Node.js](https://nodejs.org/en/download/current) | MIT | Lookup app backend |
| [thumbfast](https://github.com/po5/thumbfast) | MPL-2.0 | Thumbnailer script for mpv |
| [uosc](https://github.com/tomasklaen/uosc) | LGPL-2.1 | Feature-rich minimalist proximity-based UI for MPV player |
| [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) | GPL-2.0 | autoload playlist in folder |
| [save playlist](https://github.com/NaiveInvestigator/save-playlist) | Unlicensed | saving playlist compatible with autoload lua |
