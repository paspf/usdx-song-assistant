# USDX Song Assistant

USDX Song Assistant is a small julia script that assists when adding songs to [UltraStar Deluxe](https://github.com/UltraStar-Deluxe/USDX). It parses a songs text file and analyzes the songs directory. 

 - The video file is renamed to `video.mp4` and linked to the songs text file (no manual editing of the text file required)
 - If the songs directory only contains a video file, and no MP3 file, the audio is extracted out of the video file, and linked to the songs text file.
 - If existent, the audio file is renamed to `audio.mp3` and linked to the songs text file
 - USDX Assistant searches for files ending with `.txt`, so your songs text file can have any name you like
 - USDX Assistant can be used to processes a directory of songs

## Setup and Dependencies

 - Install [FFmpeg](https://ffmpeg.org/)
 - Install [Julia](https://julialang.org/) 1.11 or newer
 - Install required Julia dependencies: `import Pkg; Pkg.add("ArgParse")`

## Adding songs using USDX Assistant

Depending on the source of your song files, the first three steps are not necessary.

1. Download the `.txt` files containing timings and lyrics
2. Prepare a directory for each song in the schema `artist - title`
3. Place the `.txt` file (as well as cover in the directory of the song)
4. Download the songs video (for example from youtube)
5. Place the downloaded video in your songs directory
6. Repeat steps for all new songs
7. Run the script to link video files with the songs text file, as well as generating MP3 files

```
julia src/usdx-song-assistant.jl -d <PATH TO YOUR NEW SONGS DIRECTORY>
```

### Required directory structure when using USDX Song Assistant

```
- NewSongDir/ <- Song root directory, pass this directory to USDX Assistant
    - Artist_1-Song_1 <- Can by any directory name
        - *.txt <- the songs text file, USDX searches for a *txt files
        - *.mp4 <- downloaded video, mkv containers are also supported
    - Artist_2-Song_2 <- Can by any directory name
        - *.txt <- the songs text file, USDX searches for a *txt files
        - *.mp4 <- downloaded video, mkv containers are also supported
    ...
```

After running USDX Song Assistant the directories look like this:
```
- NewSongDir/ <- Song root directory, pass this directory to USDX Assistant
    - Artist_1-Song_1 <- Can by any directory name
        - *.txt <- Edited text file
        - *.mp4 <- Renamed video
        - audio.mp3 <- Extracted audio
    - Artist_2-Song_2 <- Can by any directory name
        - *.txt <- Edited text file
        - video.mp4 <- Renamed video
        - audio.mp3 <- Extracted audio
    ...
```

When always using USDX Song Assistant the script can be run on the full songs directory within UltraStar Deluxe.
