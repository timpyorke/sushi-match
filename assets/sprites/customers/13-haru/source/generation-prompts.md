# Haru generation prompts

Generated with the built-in image_gen tool; transparent_background: true. Portrait and animation sheets use 13-haru_master.png as their reference.

## master

```text
Japanese anime-style chibi (SD, super-deformed) mobile-game character sprite, like a cosy slice-of-life anime game. Drawn by hand by a professional 2D anime game illustrator: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight natural line-weight variation (thicker on the outer silhouette and under shapes, thinner on inner details), one small flat white highlight per shiny surface, limited warm Japanese-restaurant palette, chibi proportions (head about half of total height). Big expressive anime eyes with a flat-colour iris, one darker band at the top and two white catch-lights, both eyes matching in size and shape (unless the eyes are described otherwise below), tiny simple nose, small expressive mouth, anime blush on the cheeks (soft pink ovals with fine diagonal lines). Hair drawn as a few clean anime locks with one flat shine band. Simple chibi hands with clearly separated fingers. Animals are anime mascot characters with the same eyes and blush. Use anime emotion symbols (sweat drops, sparkles, anger marks, ^^ eyes) only where a frame asks for them. Few, deliberate details: every prop and accessory clearly shaped and readable, nothing extra beyond the description. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no over-smoothed skin, no random extra sparkles or particles, no melted or merged details, no extra or fused fingers, no blurry edges. No texture noise, no text, no logo, no watermark, no ground shadow, no glow, no aura, fully transparent background. Outline weight matches a cartoon salmon-nigiri game icon.

Character: Haru, a shy tea-ceremony student. Lime-green kimono (#B5D96B) with a cream obi (#F2E6C8), dark hair in a low ponytail, holding a tea bowl with both hands. Polite, shy and attentive to detail.

Single full-body character, front three-quarter view facing slightly left, holding the tea bowl in both hands, shy, centered with about 10% empty margin on every side.
```

## portrait

```text
Japanese anime-style chibi (SD, super-deformed) mobile-game character sprite, like a cosy slice-of-life anime game. Drawn by hand by a professional 2D anime game illustrator: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight natural line-weight variation (thicker on the outer silhouette and under shapes, thinner on inner details), one small flat white highlight per shiny surface, limited warm Japanese-restaurant palette, chibi proportions (head about half of total height). Big expressive anime eyes with a flat-colour iris, one darker band at the top and two white catch-lights, both eyes matching in size and shape (unless the eyes are described otherwise below), tiny simple nose, small expressive mouth, anime blush on the cheeks (soft pink ovals with fine diagonal lines). Hair drawn as a few clean anime locks with one flat shine band. Simple chibi hands with clearly separated fingers. Animals are anime mascot characters with the same eyes and blush. Use anime emotion symbols (sweat drops, sparkles, anger marks, ^^ eyes) only where a frame asks for them. Few, deliberate details: every prop and accessory clearly shaped and readable, nothing extra beyond the description. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no over-smoothed skin, no random extra sparkles or particles, no melted or merged details, no extra or fused fingers, no blurry edges. No texture noise, no text, no logo, no watermark, no ground shadow, no glow, no aura, fully transparent background. Outline weight matches a cartoon salmon-nigiri game icon.

Character: Haru, a shy tea-ceremony student. Lime-green kimono (#B5D96B) with a cream obi (#F2E6C8), dark hair in a low ponytail, holding a tea bowl with both hands.

Head-and-shoulders bust portrait, front view, centered, fits inside a circle with a small margin. Big readable shapes that still read clearly at 48 pixels.
Use the reference for exact character identity, outfit and style. Clean transparent cutout bust. No circle, disk, border, badge, pattern, or backdrop. Fits inside a circle describes framing only; do not draw a circle.
```

## idle

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Idle breathing loop, front three-quarter view:
f1 (top-left): neutral, holding the tea bowl in both hands, shy, gentle expression.
f2 (top-right): body rises very slightly, shoulders up a little.
f3 (bottom-left): same as f1.
f4 (bottom-right): same as f1 but eyes blinking, fully closed.
```

## talk

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Talking loop, front three-quarter view:
f1 (top-left): mouth closed in a soft expression, holding the tea bowl in both hands, shy.
f2 (top-right): mouth small and open in an "o" shape.
f3 (bottom-left): mouth open wider, small bow while speaking.
f4 (bottom-right): mouth half open, returning to the rest pose.
```

## happy

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally; the ground line may change only for hops and leaps. Only the pose changes between frames.

Happy reaction, front three-quarter view:
f1 (top-left): blush.
f2 (top-right): small happy hop.
f3 (bottom-left): shy smile, eyes closed.
f4 (bottom-right): landed, small bow.
```

## sad

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Sad reaction, front three-quarter view, still cute and gentle (disappointed, not crying hard):
f1 (top-left): looks down.
f2 (top-right): eyes watery.
f3 (bottom-left): hides the face behind the tea bowl.
f4 (bottom-right): peeks out sadly.
```

## walk

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Side-view walk cycle facing left, tidy small steps.:
f1 (top-left): contact pose, left foot forward.
f2 (top-right): passing pose, feet together, body slightly higher.
f3 (bottom-left): contact pose, right foot forward.
f4 (bottom-right): passing pose, feet together, body slightly higher.
```

## tea

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Offering tea, front three-quarter view:
f1 (top-left): holds the bowl.
f2 (top-right): turns the bowl.
f3 (bottom-left): presents the bowl forward with a bow.
f4 (bottom-right): shy smile.
```

