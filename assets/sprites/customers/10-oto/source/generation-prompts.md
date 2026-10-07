# Oto generation prompts

Generated with the built-in image_gen tool; transparent_background: true. Portrait and animation sheets use 10-oto_master.png as their reference.

## master

```text
Japanese anime-style chibi (SD, super-deformed) mobile-game character sprite, like a cosy slice-of-life anime game. Drawn by hand by a professional 2D anime game illustrator: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight natural line-weight variation (thicker on the outer silhouette and under shapes, thinner on inner details), one small flat white highlight per shiny surface, limited warm Japanese-restaurant palette, chibi proportions (head about half of total height). Big expressive anime eyes with a flat-colour iris, one darker band at the top and two white catch-lights, both eyes matching in size and shape (unless the eyes are described otherwise below), tiny simple nose, small expressive mouth, anime blush on the cheeks (soft pink ovals with fine diagonal lines). Hair drawn as a few clean anime locks with one flat shine band. Simple chibi hands with clearly separated fingers. Animals are anime mascot characters with the same eyes and blush. Use anime emotion symbols (sweat drops, sparkles, anger marks, ^^ eyes) only where a frame asks for them. Few, deliberate details: every prop and accessory clearly shaped and readable, nothing extra beyond the description. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no over-smoothed skin, no random extra sparkles or particles, no melted or merged details, no extra or fused fingers, no blurry edges. No texture noise, no text, no logo, no watermark, no ground shadow, no glow, no aura, fully transparent background. Outline weight matches a cartoon salmon-nigiri game icon.

Character: Oto the Drummer, an energetic teen taiko drummer. Blue wave-pattern headband (#2C6FB7), white happi with red trim (#C8332B), cloth wrist wraps, two wooden bachi drumsticks. Cheerful, loud and fast; always tapping a beat.

Single full-body character, front three-quarter view facing slightly left, drumsticks crossed in front of the chest, centered with about 10% empty margin on every side.
```

## portrait

```text
Japanese anime-style chibi (SD, super-deformed) mobile-game character sprite, like a cosy slice-of-life anime game. Drawn by hand by a professional 2D anime game illustrator: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight natural line-weight variation (thicker on the outer silhouette and under shapes, thinner on inner details), one small flat white highlight per shiny surface, limited warm Japanese-restaurant palette, chibi proportions (head about half of total height). Big expressive anime eyes with a flat-colour iris, one darker band at the top and two white catch-lights, both eyes matching in size and shape (unless the eyes are described otherwise below), tiny simple nose, small expressive mouth, anime blush on the cheeks (soft pink ovals with fine diagonal lines). Hair drawn as a few clean anime locks with one flat shine band. Simple chibi hands with clearly separated fingers. Animals are anime mascot characters with the same eyes and blush. Use anime emotion symbols (sweat drops, sparkles, anger marks, ^^ eyes) only where a frame asks for them. Few, deliberate details: every prop and accessory clearly shaped and readable, nothing extra beyond the description. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no over-smoothed skin, no random extra sparkles or particles, no melted or merged details, no extra or fused fingers, no blurry edges. No texture noise, no text, no logo, no watermark, no ground shadow, no glow, no aura, fully transparent background. Outline weight matches a cartoon salmon-nigiri game icon.

Character: Oto the Drummer, an energetic teen taiko drummer. Blue wave-pattern headband (#2C6FB7), white happi with red trim (#C8332B), cloth wrist wraps, two wooden bachi drumsticks.

Head-and-shoulders bust portrait, front view, centered, fits inside a circle with a small margin. Big readable shapes that still read clearly at 48 pixels.
Use the reference for exact character identity, outfit and style. Clean transparent cutout bust. No circle, disk, border, badge, pattern, or backdrop. Fits inside a circle describes framing only; do not draw a circle.
```

## idle

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Idle breathing loop, front three-quarter view:
f1 (top-left): neutral, drumsticks crossed in front of the chest, gentle expression.
f2 (top-right): body rises very slightly, shoulders up a little.
f3 (bottom-left): same as f1.
f4 (bottom-right): same as f1 but eyes blinking, fully closed.
```

## talk

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Talking loop, front three-quarter view:
f1 (top-left): mouth closed in a soft expression, drumsticks crossed in front of the chest.
f2 (top-right): mouth small and open in an "o" shape.
f3 (bottom-left): mouth open wider, tapping a drumstick in the air to a beat.
f4 (bottom-right): mouth half open, returning to the rest pose.
```

## happy

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally; the ground line may change only for hops and leaps. Only the pose changes between frames.

Happy reaction, front three-quarter view:
f1 (top-left): big grin.
f2 (top-right): jump, both sticks up.
f3 (bottom-left): twirls the sticks, music notes.
f4 (bottom-right): landed, victory pose.
```

## sad

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Sad reaction, front three-quarter view, still cute and gentle (disappointed, not crying hard):
f1 (top-left): sticks lowering.
f2 (top-right): slumped.
f3 (bottom-left): sticks drooping at the sides.
f4 (bottom-right): sitting, head down.
```

## walk

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Side-view walk cycle facing left, rhythmic marching steps tapping sticks.:
f1 (top-left): contact pose, left foot forward.
f2 (top-right): passing pose, feet together, body slightly higher.
f3 (bottom-left): contact pose, right foot forward.
f4 (bottom-right): passing pose, feet together, body slightly higher.
```

## drum

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Drumming on a small taiko, front three-quarter view, boss energy:
f1 (top-left): raises the right stick.
f2 (top-right): hits the drum, impact lines.
f3 (bottom-left): raises the left stick.
f4 (bottom-right): hits the drum, music notes.
```

