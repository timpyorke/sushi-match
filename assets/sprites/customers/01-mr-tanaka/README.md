# Mr. Tanaka sprite sources

Generated from `docs/prompts/01-mr-tanaka.md` with the built-in GPT Image tool.

- `source/01-mr-tanaka_master.png`: character identity reference.
- `source/*_sheet.png`: 2x2 source sheets, frames ordered left-to-right then top-to-bottom.
- `<animation>_0.png` through `<animation>_3.png`: 24 frames at 256x256 with alpha, cut from the sheets by `dart run tool/cut_sprites.dart 01-mr-tanaka`.

Only the frames ship with the app: `pubspec.yaml` lists this folder, which doesn't include `source/`. Most sheets have a soft semi-transparent brown aura that the cutter drops. `watch` is his signature move (checking his wristwatch).
