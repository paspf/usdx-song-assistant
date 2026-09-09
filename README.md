# USDX Song Assistant

USDX Song Assistant is a small julia script that assists when adding songs to [UltraStar Deluxe](https://github.com/UltraStar-Deluxe/USDX). It parses a songs text file and analyzes the songs directory. 

 - The video file is downloaded, renamed to `video.mp4` and linked to the songs text file (no manual editing of the text file required)
 - If the songs directory only contains a video file, and no MP3 file, the audio is extracted out of the video file, and linked to the songs text file.
 - If existent, the audio file is renamed to `audio.mp3` and linked to the songs text file
 - USDX Assistant searches for files ending with `.txt`, so your songs text file can have any name you like
 - USDX Assistant can be used to processes a directory of songs

## Setup and Dependencies

 - Install [Julia](https://julialang.org/) 1.12 or newer
 - Install required Julia dependencies: `import Pkg; Pkg.add("ArgParse")`

### For Downloading Videos

 - Install [yt-dlp](https://github.com/ytdl-org/youtube-dl) - for downloading videos from youtube (optional)
     - Ensure to also install the dependency [Deno](https://deno.com/)
     - Add yt-dlp to your `PATH`

### For extracting audio

 - Install [FFmpeg](https://ffmpeg.org/)
 - Add FFmpeg to your `PATH`


## Using USDX Assistant

Depending on the source of your song files, steps 2 to 5 are not necessary.

1. Download the `.txt` files (also called song files) containing timings and lyrics
2. (optional) Place the .txt file in a directory with schema `artist - title`
3. (optional) Place the `.txt` file (as well as a cover in the directory of the song)
4. (optional, required if yt-dlp is not installed) Download the songs video (for example from YouTube)
5. (optional, required if yt-dlp is not installed) Place the downloaded video in your songs directory
6. Repeat steps 1-5 for all new songs
7. Run the script to link video files with the songs text file, as well as generating MP3 files

```bash
julia src/usdx-song-assistant.jl -d <PATH TO YOUR NEW SONGS DIRECTORY>
```

Since most USDX song providers offer `.zip` files containing a `.txt` file and a cover image, extracting the `.zip` file and running the script without manual intervention is often sufficient.

### Required directory structure when using USDX Song Assistant with -d flag

```
- NewSongDir/ <- Song database root directory, pass this directory to USDX Assistant
    - Artist_1-Song_1 <- Can be any directory name
        - *.txt <- the songs text file, USDX searches for a *txt files
    - Artist_2-Song_2 <- Can be any directory name
        - *.txt <- the songs text file, USDX searches for a *txt files
    ...
```

### Directory Structure After Running USDX Song Assistant

After running USDX song assistant the directory structure should be compatible with UltraStrar Deluxe. 

```
- NewSongDir/ <- Song root directory, pass this directory to USDX Assistant
    - Artist_1-Song_1 <- Can be any directory name
        - *.txt <- Edited text file
        - video.mp4 <- Renamed video
        - audio.mp3 <- Extracted audio
    - Artist_2-Song_2 <- Can be any directory name
        - *.txt <- Edited text file
        - video.mp4 <- Renamed video
        - audio.mp3 <- Extracted audio
    ...
```

When always using USDX Song Assistant the script can be run on the full songs directory within UltraStar Deluxe.

## Compiling package to executable

This repository also contains a script to compile the package into an executable using PackageCompiler. Since compiled Julia packages are currently very large, this option should only be used if necessary.

```bash
julia compile-package.jl
```
