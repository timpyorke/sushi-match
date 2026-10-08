#!/usr/bin/env bash
# Converts the bundled PNGs under assets/ to WebP and deletes the PNGs.
#
#   tool/to_webp.sh [file-or-dir …]   # default: everything below
#
# Needs `cwebp` (brew install webp). Run it after tool/cut_sprites.dart, which
# still writes PNG frames. `source/` folders (the generated sheets) stay PNG:
# they are not bundled. Run `dart run build_runner build` afterwards so
# lib/gen/ points at the .webp files.
#
# Lossless (crisp edges, nine-patches, board tiles): assets/ui/{panel,plank,
# button_round,coin,star,heart,shopping}.png and assets/sprites/tiles/.
# Everything else is lossy, quality 90 with sharp chroma and lossless alpha:
# visually the same at display size for roughly a third of the bytes.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v cwebp >/dev/null || { echo "cwebp not found (brew install webp)"; exit 1; }

lossless() {
  case "$1" in
    assets/ui/panel.png | assets/ui/plank.png | assets/ui/button_round.png | \
      assets/ui/coin.png | assets/ui/star.png | assets/ui/heart.png | \
      assets/ui/shopping.png | assets/sprites/tiles/*) return 0 ;;
    *) return 1 ;;
  esac
}

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(assets/ui assets/sprites assets/backgrounds)

while IFS= read -r png; do
  out="${png%.png}.webp"
  if lossless "$png"; then
    cwebp -quiet -lossless -z 9 "$png" -o "$out"
  else
    cwebp -quiet -q 90 -sharp_yuv -alpha_q 100 -m 6 "$png" -o "$out"
  fi
  rm "$png"
  echo "$png -> $(basename "$out") ($(du -k "$out" | cut -f1)K)"
done < <(find "${targets[@]}" -name '*.png' -not -path '*/source/*')
