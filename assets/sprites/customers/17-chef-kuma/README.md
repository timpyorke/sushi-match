# Chef Kuma

Created from `docs/prompts/characters/17-chef-kuma.md` with built-in image generation and transparent backgrounds.

- Master reference, bust portrait, and six 2×2 animation sheets in `source/`.
- 24 extracted 256×256 RGBA frames, ordered left-to-right, then top-to-bottom.
- Animations: idle, talk, happy, sad, walk, and the signature taste reaction.
- Exact generation prompts are saved in `source/generation-prompts.md`.
- Standard animations are bundled and registered as `cust17`, with English and Thai names. The portrait and taste frames are available for future boss-specific UI.

Chef Kuma is the Hokkaido boss concept for level 60. The current UI uses the shared rotating customer roster; dedicated restaurant/boss selection is not implemented here.

Re-cut the source sheets with `dart tool/cut_sprites.dart 17-chef-kuma`.
