#!/usr/bin/env bash
# Converts the WAVs in assets/audio/ to AAC .m4a and deletes the WAVs.
#
#   tool/to_m4a.sh [file.wav …]   # default: every WAV in assets/audio/
#
# Needs `ffmpeg`. tool/gen_sounds.dart writes the placeholder WAVs; run this
# after it (the game only refers to the .m4a names, see lib/services/audio.dart).
# 44.1 kHz mono, 64 kbit/s for effects and 96 kbit/s for the BGM loops.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v ffmpeg >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)"; exit 1; }

files=("$@")
[ ${#files[@]} -eq 0 ] && files=(assets/audio/*.wav)

for wav in "${files[@]}"; do
  out="${wav%.wav}.m4a"
  case "$(basename "$wav")" in bgm_*) rate=96k ;; *) rate=64k ;; esac
  ffmpeg -v error -y -i "$wav" -c:a aac -b:a "$rate" -movflags +faststart "$out"
  rm "$wav"
  echo "$wav -> $(basename "$out") ($(du -k "$out" | cut -f1)K)"
done
