# Chef Kuma generation prompts

Mode: built-in image generation with transparent backgrounds. The master reference is used for the portrait and all six animation sheets.

Source: `docs/prompts/characters/17-chef-kuma.md`.

## master

```text
Use case: stylized-concept
Asset type: transparent mobile-game character master sprite, 1024x1024.
Japanese anime-style chibi (SD, super-deformed) mobile-game character sprite, cosy slice-of-life anime game. Professional hand-drawn 2D anime illustration: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight natural line-weight variation (thicker silhouette, thinner inner details), one small flat white highlight per shiny surface, limited warm Japanese restaurant palette, chibi proportions (head about half of total height). Animals are anime mascots with expressive matching eyes, flat iris with darker band at top and two white catch-lights; for this bear keep eyes small and kind. Tiny simple nose and small expressive mouth, soft pink oval cheek blush with fine diagonal lines. Simple clean separated bear paws, few deliberate details.
Character: Chef Kuma, a chubby brown bear (#8B5A2B), tall white chef hat and white apron, small kind eyes, round belly. Feared food critic with a soft heart and weakness for honey.
Single full-body character, front three-quarter view facing slightly left, arms crossed, stern critic, centered with about 10% empty margin on every side. Clean readable silhouette and feet.
Constraints: Fully transparent background, no white silhouette halo, no ground shadow. Flat cel shading only. No text, logos, watermarks, glow, aura, texture noise, gradients, 3D sheen, random sparkles, extra props, extra limbs, fused fingers or blurry edges. Outline weight like a cartoon salmon-nigiri game icon.
```

## portrait

```text
Japanese anime-style chibi (SD, super-deformed) mobile-game character sprite, like a cosy slice-of-life anime game. Drawn by hand by a professional 2D anime game illustrator: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight natural line-weight variation (thicker on the outer silhouette and under shapes, thinner on inner details), one small flat white highlight per shiny surface, limited warm Japanese-restaurant palette, chibi proportions (head about half of total height). Big expressive anime eyes with a flat-colour iris, one darker band at the top and two white catch-lights, both eyes matching in size and shape (unless the eyes are described otherwise below), tiny simple nose, small expressive mouth, anime blush on the cheeks (soft pink ovals with fine diagonal lines). Hair drawn as a few clean anime locks with one flat shine band. Simple chibi hands with clearly separated fingers. Animals are anime mascot characters with the same eyes and blush. Use anime emotion symbols (sweat drops, sparkles, anger marks, ^^ eyes) only where a frame asks for them. Few, deliberate details: every prop and accessory clearly shaped and readable, nothing extra beyond the description. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no over-smoothed skin, no random extra sparkles or particles, no melted or merged details, no extra or fused fingers, no blurry edges. No texture noise, no text, no logo, no watermark, no ground shadow, no glow, no aura, fully transparent background. Outline weight matches a cartoon salmon-nigiri game icon.

Character: Chef Kuma, a chubby brown bear (#8B5A2B) wearing a tall white chef hat and white apron, small kind eyes, round belly.

Head-and-shoulders bust portrait, front view, centered, fits inside a circle with a small margin. Big readable shapes that still read clearly at 48 pixels.
Use the master reference for exact bear identity, chef hat, white apron, palette and art style. Transparent bust only. Fits inside a circle describes composition: do not draw any circle, disk, badge, border or backdrop.
```

## idle

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Idle breathing loop, front three-quarter view:
f1 (top-left): neutral, arms crossed, stern critic, gentle expression.
f2 (top-right): body rises very slightly, shoulders up a little.
f3 (bottom-left): same as f1.
f4 (bottom-right): same as f1 but eyes blinking, fully closed.
 Keep exact brown fur (#8B5A2B), dark-brown outline (#4A2A1A), tall white chef hat, white apron, round belly and face of master reference. Crisp flat two-tone cel shading, clean anime mascot bear paws. No gradients, airbrush, ground shadow, white halo, text, watermark or extra limbs. All four figures fully inside their cells, hat and feet never clipped, at least 8% clear cell margin.
```

## talk

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Talking loop, front three-quarter view:
f1 (top-left): mouth closed in a soft expression, arms crossed, stern critic.
f2 (top-right): mouth small and open in an "o" shape.
f3 (bottom-left): mouth open wider, wagging a tasting spoon.
f4 (bottom-right): mouth half open, returning to the rest pose.
 Keep exact brown fur (#8B5A2B), dark-brown outline (#4A2A1A), tall white chef hat, white apron, round belly and face of master reference. Crisp flat two-tone cel shading, clean anime mascot bear paws. No gradients, airbrush, ground shadow, white halo, text, watermark or extra limbs. All four figures fully inside their cells, hat and feet never clipped, at least 8% clear cell margin.
```

## happy

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally; the ground line may change only for hops and leaps. Only the pose changes between frames.

Happy reaction, front three-quarter view:
f1 (top-left): "hmph" turning into a smile.
f2 (top-right): small hop.
f3 (bottom-left): hugs a honey pot, hearts.
f4 (bottom-right): landed, content.
 Keep exact brown fur (#8B5A2B), dark-brown outline (#4A2A1A), tall white chef hat, white apron, round belly and face of master reference. Crisp flat two-tone cel shading, clean anime mascot bear paws. No gradients, airbrush, ground shadow, white halo, text, watermark or extra limbs. All four figures fully inside their cells, hat and feet never clipped, at least 8% clear cell margin.
```

## sad

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Sad reaction, front three-quarter view, still cute and gentle (disappointed, not crying hard):
f1 (top-left): grumpy.
f2 (top-right): turns away.
f3 (bottom-left): arms crossed, "hmph".
f4 (bottom-right): sulking, hat drooping.
 Keep exact brown fur (#8B5A2B), dark-brown outline (#4A2A1A), tall white chef hat, white apron, round belly and face of master reference. Crisp flat two-tone cel shading, clean anime mascot bear paws. No gradients, airbrush, ground shadow, white halo, text, watermark or extra limbs. All four figures fully inside their cells, hat and feet never clipped, at least 8% clear cell margin.
```

## walk

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Side-view walk cycle facing left, heavy waddle, belly bouncing.:
f1 (top-left): contact pose, left foot forward.
f2 (top-right): passing pose, feet together, body slightly higher.
f3 (bottom-left): contact pose, right foot forward.
f4 (bottom-right): passing pose, feet together, body slightly higher.
 Keep exact brown fur (#8B5A2B), dark-brown outline (#4A2A1A), tall white chef hat, white apron, round belly and face of master reference. Crisp flat two-tone cel shading, clean anime mascot bear paws. No gradients, airbrush, ground shadow, white halo, text, watermark or extra limbs. All four figures fully inside their cells, hat and feet never clipped, at least 8% clear cell margin.
```

## taste

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Tasting critique, front three-quarter view, boss presence:
f1 (top-left): lifts a tasting spoon.
f2 (top-right): tastes, eyes closed.
f3 (bottom-left): ponders, one paw on the chin.
f4 (bottom-right): small approving smile: "hmph, not bad".
 Keep exact brown fur (#8B5A2B), dark-brown outline (#4A2A1A), tall white chef hat, white apron, round belly and face of master reference. Crisp flat two-tone cel shading, clean anime mascot bear paws. No gradients, airbrush, ground shadow, white halo, text, watermark or extra limbs. All four figures fully inside their cells, hat and feet never clipped, at least 8% clear cell margin.
```
