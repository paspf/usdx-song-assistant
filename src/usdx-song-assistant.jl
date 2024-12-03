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
function update_text_file(txt_file::String)
	if !isfile(txt_file)
		return
	end
	
	# Open the input file.
	lines = readlines(txt_file)

	# Define the patterns for lines starting with "#VIDEO:" and "#MP3:"
	video_pattern = Regex("^#VIDEO:")
	mp3_pattern = Regex("^#MP3:")

	# Modify the lines.
	modified_lines = []
	for line in lines
		if occursin(video_pattern, line)
			push!(modified_lines, "#VIDEO:video.mp4")
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

# Iterate though all subdirectories, find all video, audio and text files
# Link audio and video files to text file.
function process_subdirectories(directory::String)
    subdirs = readdir(directory)
    for subdir in subdirs
		relsubdir = joinpath(directory, subdir)
        if isdir(relsubdir)
            @info ("Processing directory: $subdir")
            files = readdir(relsubdir)
            # Filter for video files
            video_files = filter_filenames(files, [".mp4", ".mkv", ".flv"])
			audio_files = filter_filenames(files, [".mp3", ".aac", ".ogg"])
			text_files = filter_filenames(files, [".txt"])
			
			# Check if only a video file exists -> extract audio.
			if (length(video_files) == 1) && (length(audio_files) == 0)
				try
					input_file = joinpath(relsubdir, video_files[1])
					output_file = convert_video_to_mp3(input_file)
					@debug ("Extracted audio from $input_file to $output_file")
				catch e
					@warn ("Error processing $input_file: $(e.message)")
				end
            elseif length(audio_files) == 1
                audio_file = audio_files[1]
                new_name = joinpath(relsubdir, "audio" * splitext(audio_file)[2])
                rename(joinpath(relsubdir, audio_file), new_name)
            end
			
            # Check if exactly one video file exists -> try to rename video file.
            if length(video_files) == 1
                video_file = video_files[1]
                new_name = joinpath(relsubdir, "video" * splitext(video_file)[2])
                rename(joinpath(relsubdir, video_file), new_name)
			end

			if length(text_files) == 1
				update_text_file(joinpath(relsubdir, text_files[1]))
			end
        end
    end
end

# Parse command-line arguments.
function parse_commandline()
    s = ArgParseSettings(
        description = "Rename video and audio file, reference files in txt file.",
        version = "1.0"
    )

    @add_arg_table s begin
        "--directory", "-d"
            help = "Directory containing directories with songs."
            arg_type = String
            default = "."
    end

    return parse_args(ARGS, s)
end

# Main entry point as required by PackageCompiler.
function julia_main()::Cint
    parsed_args = parse_commandline()

    global_logger(ConsoleLogger(stdout, Logging.Info))

    if haskey(parsed_args, "directory")
        directory = parsed_args["directory"]
        process_subdirectories(directory)
    else
        println("No directory specified. Using current directory.")
        process_subdirectories(".")
    end
    return 0
  end



end #  module UsdxSongAssistant

# Call the main function of the UsdxSongAssistant module.
UsdxSongAssistant.julia_main()