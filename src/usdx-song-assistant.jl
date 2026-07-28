module UsdxSongAssistant

# USDX Song Assistant
# 
# USDX Song Assistant is a small julia script that 
# assists when adding songs to UltraStar Deluxe.
#
# repository: https://github.com/paspf/usdx-song-assistant

using Base.Filesystem
using ArgParse
using Logging
using Downloads

app_name::String = "USDX Song Assistant"

# Filter all filenames in the given vector for file extensions in the vector allowed_extensions.
function filter_filenames(filenames::Vector{String}, allowed_extensions::Vector{String})::Vector{String}
    # Convert all extensions to lowercase for case-insensitive comparison.
    lower_allowed_extensions = map(ext -> lowercase(ext), allowed_extensions)
    
    filtered_filenames = String[]
    
    for filename in filenames
        # Extract the extension from the filename.
        ext = splitext(filename)[2]
        
        # Check if the extension exists and is in the allowed list (case-insensitive).
        if ext != "" && any(lowercase(ext) == lowercase(ext_allowed) for ext_allowed in lower_allowed_extensions)
            push!(filtered_filenames, filename)
        end
    end
    return filtered_filenames
end

# Read the given text file, search for specific lines and
# replace the contents of these lines.
function update_text_file(txt_file::String, video_file::Union{String, Nothing}=nothing)
	if !isfile(txt_file)
		return
	end
	
	# Open the input file.
	lines = readlines(txt_file)

	# Define the patterns for lines starting with "#VIDEO:" and "#MP3:"
	video_pattern = Regex("^#VIDEO:")
	mp3_pattern = Regex("^#MP3:")
	
	if video_file === nothing
		video_file = "video.mp4"
	end

	# Modify the lines.
	modified_lines = []
	for line in lines
		if occursin(video_pattern, line)
			push!(modified_lines, "#VIDEO:$video_file")
		elseif occursin(mp3_pattern, line)
			push!(modified_lines, "#MP3:audio.mp3")
		else
			push!(modified_lines, line)
		end
	end

	# Open the output file and write the (modified) lines back to the file.
	open(txt_file, "w") do output
		foreach(line -> println(output, line), modified_lines)
	end
end

function check_internet_connection(timeout_seconds=3)::Bool
    try
        Downloads.download("https://api.ipify.org", IOBuffer(); timeout=timeout_seconds)
        return true
    catch
        return false
    end
end

# Convert video to mp3 using ffmpeg.
function convert_video_to_mp3(input_file::String)::String
    # Get the path.
    dir_name = dirname(input_file)
    
    # Construct output filename.
    output_file = joinpath(dir_name, "audio.mp3")
    
    # Run ffmpeg command.
    run(`ffmpeg -i $input_file -vn -acodec libmp3lame -b:a 192k $output_file -hide_banner -loglevel error`)
    
    return output_file
end

function convert_video_to_mp4(input_file::String; output_file::Union{String, Nothing}=nothing)::String
    # Check if input file exists
    if !isfile(input_file)
        throw(ErrorException("Input file does not exist: $input_file"))
    end

    # Set default output file if not provided
    if output_file === nothing
        dir_name = dirname(input_file)
        base_name = splitext(basename(input_file))[1]
        output_file = joinpath(dir_name, "$base_name.mp4")
    end

    # Run ffmpeg command
    try
        run(`ffmpeg -i $input_file -c:v libx264 -c:a aac -strict experimental -y $output_file`)
    catch e
        throw(ErrorException("Failed to convert video: $(e.msg)"))
    end

    # Check if output file was created
    if !isfile(output_file)
        throw(ErrorException("Output file was not created: $output_file"))
    end

    return output_file
end

function invoke_ytdl_to_dl_video(relative_subdir::String, url::String)::Bool
    video_file = joinpath(relative_subdir, "video")
	run(`yt-dlp.exe $url --quiet --progress -o $video_file --cookies-from-browser firefox`)
	# Check if output file exists, if not return false
	files = readdir(relative_subdir)
	if length(filter_filenames(files, [".mp4", ".mkv", ".flv", ".webm"])) > 0
		return true
	end
	return false
end

function invoke_ytdl_to_dl_video_and_audio(relative_subdir::String, url::String)::Bool
	# The yt-dlp option to extract audio seems buggy
	# Prefere downloading containers with video + audio without splitting the container
    video_file = joinpath(relative_subdir, "video")
	run(`yt-dlp.exe $url --quiet --progress -t mp3 -k -o $video_file`)
	# Check if output file exists, if not return false
	files = readdir(relative_subdir)
	if length(filter_filenames(files, [".mp4", ".mkv", ".flv", ".webm"])) > 0
		return true
	end
	return false
end

function check_for_dependency(dependency::String, verbose::Bool=true)::Bool
    s = false
    @info ("Checking for dependency: $dependency...")
    try
        cmd = Cmd(`$dependency --help`)
        s = success(cmd)
        
        if verbose
            println("Dependency: $dependency found in PATH")
        end
        
    catch e
            @warn("Dependency: $dependency not found.")
			println("HINT: Is the dependency installed and in the PATH?")
    end
    
    return s
end

function extract_video_entry(text_file_path::String)::String
if !isfile(text_file_path)
		return
	end
	
	# Open the input file.
	lines = readlines(text_file_path)

	# Define the patterns for lines starting with "#VIDEO:"
	video_pattern = Regex("^#VIDEO:")

	# Search for the line starting with "#VIDEO:" and extract the string.
    video_entry = ""
	for line in lines
		if occursin(video_pattern, line)
            video_entry = split(line, ":")[2]
			break
        end
	end

    if video_entry == ""
        @warn ("No video entry found in $text_file_path. Skipping video download.")
    end

    return video_entry
end

function extract_artist_and_title(text_file_path::String)::Tuple{Integer, String, String}
if !isfile(text_file_path)
		return
	end
	lines = readlines(text_file_path)
    artist_entry = ""
	title_entry = ""
	for line in lines
		if occursin(Regex("^#ARTIST:"), line)
            artist_entry = split(line, ":")[2]
        end
		if occursin(Regex("^#TITLE:"), line)
            title_entry = split(line, ":")[2]
        end
	end

    if artist_entry == ""
        @warn ("No video entry found in $text_file_path. Skipping video download.")
		return 1, "", ""
	elseif title_entry == ""
		return 1, "", ""
    end
	
	artist_entry = replace(artist_entry, r"[^ -~]" => "")
	title_entry = replace(title_entry, r"[^ -~]" => "")

    return 0, artist_entry, title_entry
end

function build_video_url(video_entry::String)::String
    entry = strip(video_entry)
    if isempty(entry)
        return ""
    end

    youtube_watch = r"^(?:https?://)?(?:www\.)?youtube\.com/watch\?(?:.*&)?v=([A-Za-z0-9_-]{11})"
    youtu_be = r"^(?:https?://)?(?:www\.)?youtu\.be/([A-Za-z0-9_-]{11})"
    v_param = r"\bv=([A-Za-z0-9_-]{11})\b"
    plain_id = r"^([A-Za-z0-9_-]{11})$"

    function extract_id(pattern)
        m = match(pattern, entry)
        return m === nothing ? "" : m.captures[1]
    end

    video_id = extract_id(youtube_watch)
    if video_id == ""
        video_id = extract_id(youtu_be)
    end
    if video_id == ""
        video_id = extract_id(v_param)
    end
    if video_id == ""
        video_id = extract_id(plain_id)
    end

    if video_id == ""
        return ""
    end
    video_url = "https://www.youtube.com/watch?v=$video_id"
    println("Extracted video url: $video_url")
    return video_url
end

function read_files_in_directory(directory::String)::Tuple{Vector{String}, Vector{String}, Vector{String}}
    files = readdir(directory)
    video_files = filter_filenames(files, [".mp4", ".mkv", ".flv", ".webm"])
    audio_files = filter_filenames(files, [".mp3", ".aac", ".ogg"])
    text_files = filter_filenames(files, [".txt"])
    return video_files, audio_files, text_files
end

# Iterate though all subdirectories, find all video, audio and text files
# Link audio and video files to text file.
function process_subdirectories(directory::String, yt_dl_available::Bool, ffmpeg_available::Bool)
    subdirs = readdir(directory)
    len_subdirs = length(subdirs)
    for (i, subdir) in enumerate(subdirs)
		@info ("Processing directory [$i/$len_subdirs]: $subdir")
		process_song_directory(directory, subdir, yt_dl_available, ffmpeg_available)
    end
end

function process_song_directory(directory::String, subdir::String, yt_dl_available::Bool, ffmpeg_available::Bool)
	rel_subdir = joinpath(directory, subdir)
	if isdir(rel_subdir)
		video_files, audio_files, text_files = read_files_in_directory(rel_subdir)
		
		if (length(video_files) == 0) && (length(text_files) == 1) && yt_dl_available
			# try to extract video link from txt file and download video
			println("Try to extract video link from txt file and download video")
			video_entry = extract_video_entry(joinpath(rel_subdir, text_files[1]))
			if video_entry == ""
				return
			end
			video_url = build_video_url(video_entry)
			if video_url == ""
				@warn ("Could not extract a valid video URL from the video entry: $video_entry. Skipping video download for $rel_subdir.")
				return
			end
			@warn ("VIDEO URL: $video_url. Attempting to download video for $rel_subdir...")
			if invoke_ytdl_to_dl_video(rel_subdir, video_url) == false
				# retry downloading video with yt-dlp
				@warn ("Failed to download video for $rel_subdir from URL: $video_url. Retry...")
				if invoke_ytdl_to_dl_video(rel_subdir, video_url) == false
					@warn ("Retry failed for $rel_subdir. Could not download video. Continue with next song.")
					return
				end
			end
			# Ensure video has correct file format
			
		end
		
		# Check if only a video file exists -> extract audio.
		if (length(video_files) == 1) && (length(audio_files) == 0) && ffmpeg_available
			try
				input_file = joinpath(rel_subdir, video_files[1])
				output_file = convert_video_to_mp3(input_file)
				@debug ("Extracted audio from $input_file to $output_file")
			catch e
				@warn ("Error processing $input_file: $(e.message)")
			end
		elseif length(audio_files) == 1
			audio_file = audio_files[1]
			new_name = joinpath(rel_subdir, "audio" * splitext(audio_file)[2])
			rename(joinpath(rel_subdir, audio_file), new_name)
		end
		
		# Check if exactly one video file exists -> try to rename video file.
		if length(video_files) == 1
			video_file = video_files[1]
			new_name = joinpath(rel_subdir, "video" * splitext(video_file)[2])
			# Only rename video file if its filename is not video.xyz
			if video_file != new_name
				rename(joinpath(rel_subdir, video_file), new_name)
			end
		end
		
		video_files, audio_files, text_files = read_files_in_directory(rel_subdir)
		if length(text_files) == 1 && length(video_files) == 1
			update_text_file(joinpath(rel_subdir, text_files[1]), video_files[1])
		end
	end
end


function process_text_file(text_file::String, yt_dl_available::Bool, ffmpeg_available::Bool)
	directory = dirname(text_file)
	status, artist, title =  extract_artist_and_title(text_file)
	mkdir(subdir)
	
	mv_destination = joinpath(subdir, basename(text_file))
	mv(process_song_directory(directory, subdir, yt_dl_available, ffmpeg_available))
end


# Parse command-line arguments.
function parse_commandline()
    s = ArgParseSettings(
        description = """
					$app_name Is a tool to rename video and audio files and reference
					them in the songs txt file. It uses yt-dl to dowload videos and 
					ffmpeg to extract audio streams.
					""",
        version = "1.1"
    )
    @add_arg_table s begin
        "--directory", "-d"
            help = """
					Directory containing directories with songs. 
					Use this option if you apply $app_name on a existing library or if you already have prepared a directory for each song.
					"""
            arg_type = String
		"--text", "-t"
			help = """
					Directory containing text files (song files). 
					Use this option if you only have text files. When choosing this option
					$app_name will create a directory structure and tries to download all songs.
					"""
			arg_type = String
    end

    return parse_args(ARGS, s)
end

# Main entry point as required by PackageCompiler.
function julia_main()::Cint
    parsed_args = parse_commandline()
    global_logger(ConsoleLogger(stdout, Logging.Info))
	
    @info ("Checking internet connection for automated video download...")
    internet_available = check_internet_connection();
    yt_dl_available = false
    if internet_available
	    yt_dl_available = check_for_dependency("yt-dlp", false)
        if !yt_dl_available
            @warn ("Youtube Downloader not installed. Please install https://github.com/ytdl-org/youtube-dl. Disabling automated video download.")
        end
    else
        @warn ("Internet not available. Disabling automated video download.")
    end
	ffmpeg_available = check_for_dependency("ffmpeg", false)
    if !ffmpeg_available
        @warn ("FFMPEG not installed. Disabling audio extraction.")
    end

    if haskey(parsed_args, "directory") && parsed_args["directory"] != nothing
        directory = parsed_args["directory"]
		if isdir(directory)
			@info ("Directory is: $directory.")
			process_subdirectories(directory, yt_dl_available, ffmpeg_available)
		else
			@warn ("Directory: $directory not found")
			return 1
		end
	elseif haskey(parsed_args, "text") && parsed_args["text"] != nothing
		text_file = parsed_args["text"]
		if isfile(text_file)
			@info ("Processing a directory with many text files is currenty not supported")
		else
			@warn ("File: $text_file not found")
			return 1
		end
    else
        println("No directory or text specified. Using current directory.")
        process_subdirectories(".", yt_dl_available, ffmpeg_available)
    end
    return 0
end

# end #  module UsdxSongAssistant

end
println("Loading UsdxSongAssistant module...")

# Call the main function of the UsdxSongAssistant module.
ret::Cint = UsdxSongAssistant.julia_main()

if ret == 0
    @info ("Successfully prepared all songs for USDX.")
else
    @error ("Failed to prepare songs for USDX.")
end
