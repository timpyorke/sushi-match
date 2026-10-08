# Joker the Boss Cat

Generated from `docs/prompts/characters/18-boss-cat-joker.md` with built-in image generation and transparent backgrounds.

- Master reference, bust portrait, and five 2×2 animation sheets in `source/`.
- 20 extracted 256×256 RGBA frames, ordered left-to-right, then top-to-bottom.
- Animations: idle (4 fps), prowl (8 fps), eat (10 fps), hit (12 fps), flee (10 fps).
- Exact generation prompts are saved in `source/generation-prompts.md`.
- The frame folder is bundled in `pubspec.yaml` for board-obstacle use.

Re-cut the source sheets:

```bash
dart tool/cut_sprites.dart --obstacles 18-boss-cat-joker
```

Joker is a board obstacle rather than a diner. The current `CatComponent` still renders its vector placeholder; these assets provide the five states for a future board-animation hookup.

> The `source/` folder (generated sheets, master and portrait) was removed from the working tree; it is still in git history (commit `7864de2` and earlier) if you need to re-cut or re-export.
