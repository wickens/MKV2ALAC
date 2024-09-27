#!/bin/bash

# Install ffmpeg first using:
# brew install ffmpeg
# or equivalent for your system

# Clean the album name for a valid directory
sanitize_directory_name() {
    echo "$1" | tr -cd '[:alnum:]_-'  # Keeps alphanumeric characters, underscores, and hyphens
}

# Here you can input file from the first argument or use a default
# I recommend you rename your file to 'input.mkv' rather than edit this script.
INPUT_FILE="${1:-input.mkv}"

# Edit Artist, Album, and Year Variables
ALBUM="Oranges And Lemons"
ARTIST="XTC"
YEAR="1989"  

# Track names (make sure this matches what's on the disk exacly)
track_names=(
    "Garden Of Earthly Delights"
    "The Mayor Of Simpleton"
    "King For A Day"
    "Here Comes President Kill Again"
    "The Loving"
    "Poor Skeleton Steps Out"
    "One Of The Millions"
    "Scarecrow People"
    "Merely A Man"
    "Cynical Days"
    "Across This Antheap"
    "Hold Me My Daddy"
    "Pink Thing"
    "Miniature Sun"
    "Chalkhills And Children"
)

###
# No need to edit anything else #
###

# Sanitize the album name for the output directory
OUTPUT_DIR="${2:-$(sanitize_directory_name "$ALBUM")}"

# Output files for audio and chapters
AUDIO_OUTPUT_FILE="output_audio.m4a"
CHAPTER_OUTPUT_FILE="chapters.txt"



# Extract the chapter information and save it to a file
ffmpeg -i "$INPUT_FILE" -f ffmetadata "$CHAPTER_OUTPUT_FILE"

# Convert the MKV file to Apple Lossless while keeping multi-channel Dolby surround sound
ffmpeg -i "$INPUT_FILE" -map 0:a -c:a alac "$AUDIO_OUTPUT_FILE"

# Create output directory for split tracks
mkdir -p "$OUTPUT_DIR"

echo "Conversion to Apple Lossless completed. Temp file saved to $AUDIO_OUTPUT_FILE and chapters saved to $CHAPTER_OUTPUT_FILE."

# Read the chapters from the file
CHAPTERS=($(grep -E 'START=|END=' "$CHAPTER_OUTPUT_FILE" | cut -d= -f2))

# Get the number of tracks (will use this in metadta)
NUM_TRACKS=${#track_names[@]}

# Ensure the chapters.txt file and the track_names array are aligned
if [ $((${#CHAPTERS[@]}/2)) -ne "$NUM_TRACKS" ]; then
    echo "Error: Number of chapters and number of track names do not match."
    exit 1
fi

# Loop through each track and split to a new output file
for ((i=0; i<$NUM_TRACKS; i++)); do
    START_TIME=$(echo "scale=3; ${CHAPTERS[$((i*2))]}/1000000000" | bc)
    END_TIME=$(echo "scale=3; ${CHAPTERS[$((i*2+1))]}/1000000000" | bc)
    TRACK_NUM=$(printf "%02d" $((i+1)))
    TRACK_NAME=${track_names[$i]}
    
    OUTPUT_FILE="${OUTPUT_DIR}/${TRACK_NUM} - ${TRACK_NAME}.m4a"
    
    # Extract the track using ffmpeg *without* re-encoding
    ffmpeg -i "$AUDIO_OUTPUT_FILE" -ss "$START_TIME" -to "$END_TIME" -c copy "$OUTPUT_FILE"

    # Add ID3 tags including the year and total tracks without re-compressing
    ffmpeg -i "$OUTPUT_FILE" \
           -metadata artist="$ARTIST" \
           -metadata album="$ALBUM" \
           -metadata title="$TRACK_NAME" \
           -metadata album_artist="$ARTIST" \
           -metadata track="$TRACK_NUM" \
           -metadata total_tracks="$NUM_TRACKS" \
           -metadata year="$YEAR" \
           -write_id3v1 1 \
           -c copy "${OUTPUT_FILE%.m4a}_tagged.m4a"

    echo "Extracted and tagged: $OUTPUT_FILE (Start: $START_TIME, End: $END_TIME)"
done

# Remove original non-tagged files and rename tagged files
for file in "$OUTPUT_DIR"/*.m4a; do
    # Check if the file has _tagged suffix
    if [[ "$file" == *_tagged.m4a ]]; then
        # Rename the tagged file to remove the _tagged suffix
        mv "$file" "${file/_tagged/}"
    else
        # Remove the original non-tagged file
        rm "$file"
    fi
done

# Remove the temporary audio & chapters file
rm "$AUDIO_OUTPUT_FILE"
rm "$CHAPTER_OUTPUT_FILE"

##  we're done
echo "Track splitting and tagging completed. Temporary file $AUDIO_OUTPUT_FILE has been deleted."
