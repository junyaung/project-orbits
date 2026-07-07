#!/bin/zsh
# Turn any short clip into a SEAMLESS looping Ogg Theora (.ogv) for a Godot
# background. Godot 4 only plays Theora video, so we must end at .ogv.
#
# How it loops with no seam: we take the tail (last X seconds) and crossfade it
# INTO the head over the first X seconds of the output. The loop point then lands
# on the same source frame on both sides, so the jump back is invisible. Motion
# keeps its natural direction (unlike a ping-pong, which reverses it).
#
# Usage:  ./make_seamless_loop.sh input.mp4 output_basename [crossfade_seconds]
# Needs:  brew install ffmpeg ffmpeg2theora
set -e

IN="${1:?usage: make_seamless_loop.sh input.mp4 out_basename [xfade_sec]}"
OUT="${2:?provide an output basename, e.g. tachyon_drift_loop}"
X="${3:-0.8}"                                   # crossfade length in seconds

DIR="$(cd "$(dirname "$IN")" && pwd)"
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")   # source duration
L=$(python3 -c "print($D - $X)")                                        # kept length
R=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$IN" | awk -F/ '{print ($2?$1/$2:$1)}')

echo "duration=$D  crossfade=$X  loop_length=$L  fps=$R"

# 1) crossfade-seamless intermediate (h264 mp4, also handy for previewing)
ffmpeg -y -i "$IN" -filter_complex \
"[0:v]trim=0:$X,setpts=PTS-STARTPTS[head];\
[0:v]trim=$L:$D,setpts=PTS-STARTPTS[tail];\
[0:v]trim=$X:$L,setpts=PTS-STARTPTS[body];\
[tail][head]xfade=transition=fade:duration=$X:offset=0[xf];\
[xf][body]concat=n=2:v=1:a=0[v]" \
-map "[v]" -r "$R" -c:v libx264 -pix_fmt yuv420p -crf 20 -an -movflags +faststart \
"$DIR/${OUT}.mp4"

# 2) Theora .ogv for Godot (videoquality 0-10; 8 = high)
ffmpeg2theora --videoquality 8 --no-skeleton -o "$DIR/${OUT}.ogv" "$DIR/${OUT}.mp4"

echo "wrote $DIR/${OUT}.mp4 (preview) and $DIR/${OUT}.ogv (Godot)"
