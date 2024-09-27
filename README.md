# MKV2ALAC
 Script that takes audio from an MKV file (likely surround sound) and converts to individual M4A files that can be played on Apple devices, keeping the surround sound.

## Input
 - An single MKV file extracted from a bluray.

## Output
 - Individual M4A files that maintain surround sound and can be played on Apple devices. (Sadly they can't be imported into Apple Music)

 ## Instructions for use


1. [Install ffmpeg](https://formulae.brew.sh/formula/ffmpeg)
1. Import your blu-ray track using a tool like [MakeMKV](https://www.makemkv.com/download/). 
2. Edit the script so that the following are set:
   1. `Track listing` (name each track)
   2. The `Artist name`
   3. The `Album name`
   4. The `Album year`
3. Either rename your mkv file to `input.mkv` or edit the input filename in the script.
4. Run `./script.sh` from the same directly
   1. Note you will need to make it executable first, this can be done with the following commmand:
       - `chmod +x script.sh`

