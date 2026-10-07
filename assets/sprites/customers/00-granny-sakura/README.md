# Granny Sakura sprite sources

Generated from `docs/prompts/00-granny-sakura.md` with the built-in GPT Image tool.

- `source/00-granny-sakura_master.png`: character identity reference.
- `source/*_sheet.png`: 2x2 source sheets, frames ordered left-to-right then top-to-bottom.
- `<animation>_0.png` through `<animation>_3.png`: 24 frames at 256x256 with alpha, cut from the sheets by `dart run tool/cut_sprites.dart 00-granny-sakura`.

Only the frames ship with the app: `pubspec.yaml` lists this folder, which doesn't include `source/`. The `idle`, `happy`, `sad` and `bow` sheets have a soft semi-transparent brown aura that the cutter drops. The walk sheet faces left in frames 0–1 and right in frames 2–3.
