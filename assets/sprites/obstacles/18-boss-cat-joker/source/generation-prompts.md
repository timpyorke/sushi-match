# Joker generation prompts

Mode: built-in image generation with transparent backgrounds. Master reference is used for the portrait and all five sheets.

Source: `docs/prompts/characters/18-boss-cat-joker.md`.

## master

```text
Japanese anime-style chibi (SD, super-deformed) mobile-game character sprite, like a cosy slice-of-life anime game. Drawn by hand by a professional 2D anime game illustrator: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight natural line-weight variation (thicker on the outer silhouette and under shapes, thinner on inner details), one small flat white highlight per shiny surface, limited warm Japanese-restaurant palette, chibi proportions (head about half of total height). Big expressive anime eyes with a flat-colour iris, one darker band at the top and two white catch-lights, both eyes matching in size and shape (unless the eyes are described otherwise below), tiny simple nose, small expressive mouth, anime blush on the cheeks (soft pink ovals with fine diagonal lines). Hair drawn as a few clean anime locks with one flat shine band. Simple chibi hands with clearly separated fingers. Animals are anime mascot characters with the same eyes and blush. Use anime emotion symbols (sweat drops, sparkles, anger marks, ^^ eyes) only where a frame asks for them. Few, deliberate details: every prop and accessory clearly shaped and readable, nothing extra beyond the description. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no over-smoothed skin, no random extra sparkles or particles, no melted or merged details, no extra or fused fingers, no blurry edges. No texture noise, no text, no logo, no watermark, no ground shadow, no glow, no aura, fully transparent background. Outline weight matches a cartoon salmon-nigiri game icon.

Character: Joker the Boss Cat, a big chubby black stray cat (#2B2B33). One torn ear, squarish yellow eyes (#F5D33B), a cross-shaped scar on the nose, a silver spiked collar (#C0C4CC), a fish bone held in the mouth. Cocky, sneaky leader of the stray cat gang; steals customers' fish but is scared of loud noises and explosions. Mischievous rather than scary, still kawaii.

Single full-body character, front three-quarter view facing slightly left, sitting with a smug grin, fish bone in the mouth, centered with about 10% empty margin on every side.
Production asset: exact brown outline and charcoal fur, crisp flat cel shading. One cat only. Keep torn ear, yellow eyes, nose scar, silver collar and fish bone clear at board-cell size. Actual transparent background, no white outline around the silhouette.
```

## portrait

```text
Japanese anime-style chibi (SD, super-deformed) mobile-game character sprite, like a cosy slice-of-life anime game. Drawn by hand by a professional 2D anime game illustrator: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight natural line-weight variation (thicker on the outer silhouette and under shapes, thinner on inner details), one small flat white highlight per shiny surface, limited warm Japanese-restaurant palette, chibi proportions (head about half of total height). Big expressive anime eyes with a flat-colour iris, one darker band at the top and two white catch-lights, both eyes matching in size and shape (unless the eyes are described otherwise below), tiny simple nose, small expressive mouth, anime blush on the cheeks (soft pink ovals with fine diagonal lines). Hair drawn as a few clean anime locks with one flat shine band. Simple chibi hands with clearly separated fingers. Animals are anime mascot characters with the same eyes and blush. Use anime emotion symbols (sweat drops, sparkles, anger marks, ^^ eyes) only where a frame asks for them. Few, deliberate details: every prop and accessory clearly shaped and readable, nothing extra beyond the description. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no over-smoothed skin, no random extra sparkles or particles, no melted or merged details, no extra or fused fingers, no blurry edges. No texture noise, no text, no logo, no watermark, no ground shadow, no glow, no aura, fully transparent background. Outline weight matches a cartoon salmon-nigiri game icon.

Character: Joker the Boss Cat, a big chubby black stray cat (#2B2B33). One torn ear, squarish yellow eyes (#F5D33B), a cross-shaped scar on the nose, a silver spiked collar (#C0C4CC), a fish bone held in the mouth.

Head-and-shoulders bust portrait, front view, centered, fits inside a circle with a small margin. Big readable shapes that still read clearly at 48 pixels.
Use the master as identity reference. Transparent bust only; fits inside a circle describes composition only. Do not draw a circle, badge, disk, border or backdrop.
```

## idle

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Smug idle loop, front three-quarter view:
f1 (top-left): sitting, smug grin, fish bone in the mouth.
f2 (top-right): tail swishes left.
f3 (bottom-left): same as f1.
f4 (bottom-right): eyes half closed, smug.
Preserve exact master identity: charcoal-black fur #2B2B33, squarish yellow eyes #F5D33B, SAME torn ear, cross-shaped nose scar, silver spiked collar #C0C4CC, dark-brown outlines #4A2A1A, and clean chibi anatomy. Four full-body figures entirely inside separate cells with generous clear margins, no clipped ears, tails or paws. Equal scale and ground line except specified leaps. Flat crisp cel shading only, no gradients, airbrush, 3D sheen, white silhouette halo, ground shadow, backdrop, extra limbs, labels, text or watermark. Fish bone may leave the mouth only as necessary for open-mouth actions.
CRITICAL SPACING CORRECTION: a 2-by-2 sheet with each complete cat SMALL within its cell, occupying only 60% of cell width and 65% of cell height including the tail. Leave broad transparent gutters between figures: each cell has at least 15% empty margin on EVERY side. ALL tail tips and whiskers must be entirely inside their own cell, never touching or overlapping a neighbour. Do not enlarge the figures to fill the page. Clear empty full-width central horizontal gutter and full-height central vertical gutter. Exact same cat size in every cell. The swishing tail stays within the same generous safe area.
```

## prowl

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Sneaky prowl, side view facing left, low to the ground:
f1 (top-left): front-left and back-right paws forward.
f2 (top-right): passing, body slightly higher, shoulders rolling.
f3 (bottom-left): front-right and back-left paws forward.
f4 (bottom-right): passing, sly sideways glance.
Preserve exact master identity: charcoal-black fur #2B2B33, squarish yellow eyes #F5D33B, SAME torn ear, cross-shaped nose scar, silver spiked collar #C0C4CC, dark-brown outlines #4A2A1A, and clean chibi anatomy. Four full-body figures entirely inside separate cells with generous clear margins, no clipped ears, tails or paws. Equal scale and ground line except specified leaps. Flat crisp cel shading only, no gradients, airbrush, 3D sheen, white silhouette halo, ground shadow, backdrop, extra limbs, labels, text or watermark. Fish bone may leave the mouth only as necessary for open-mouth actions.
CRITICAL SPACING CORRECTION: each complete prowling cat must be SMALL within its own cell, including the FULL long body, ALL whiskers and tail. Occupy at most 60% of the cell width and 65% of height. Keep at least 15% completely transparent margin on EVERY side of each cell. Leave broad uninterrupted transparent central vertical and horizontal gutters. No overlap, no contact between neighbouring cats. Exactly four separate complete figures, equal scale. Do not enlarge the cats to fill the sheet.
```

## eat

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally, standing on the same ground line. Only the pose changes between frames.

Eating, front three-quarter view:
f1 (top-left): leans forward, mouth open.
f2 (top-right): chomps.
f3 (bottom-left): chewing, cheeks full.
f4 (bottom-right): licks the lips, satisfied.
Preserve exact master identity: charcoal-black fur #2B2B33, squarish yellow eyes #F5D33B, SAME torn ear, cross-shaped nose scar, silver spiked collar #C0C4CC, dark-brown outlines #4A2A1A, and clean chibi anatomy. Four full-body figures entirely inside separate cells with generous clear margins, no clipped ears, tails or paws. Equal scale and ground line except specified leaps. Flat crisp cel shading only, no gradients, airbrush, 3D sheen, white silhouette halo, ground shadow, backdrop, extra limbs, labels, text or watermark. Fish bone may leave the mouth only as necessary for open-mouth actions.
```

## hit

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally; the ground line may change only for hops and leaps. Only the pose changes between frames.

Hissing in shock, front three-quarter view:
f1 (top-left): startled, eyes wide.
f2 (top-right): fur puffed up, jumps a little.
f3 (bottom-left): hissing "fsst!", arched back.
f4 (bottom-right): lands, glaring.
Preserve exact master identity: charcoal-black fur #2B2B33, squarish yellow eyes #F5D33B, SAME torn ear, cross-shaped nose scar, silver spiked collar #C0C4CC, dark-brown outlines #4A2A1A, and clean chibi anatomy. Four full-body figures entirely inside separate cells with generous clear margins, no clipped ears, tails or paws. Equal scale and ground line except specified leaps. Flat crisp cel shading only, no gradients, airbrush, 3D sheen, white silhouette halo, ground shadow, backdrop, extra limbs, labels, text or watermark. Fish bone may leave the mouth only as necessary for open-mouth actions.
```

## flee

```text
Use the character in the reference image exactly: same face, hair, outfit, props, colours, outline and art style.

Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, no borders, no grid lines, no numbers, no glow or aura around the character, fully transparent background. The character has the exact same size and scale in every cell, centered horizontally; the ground line may change only for hops and leaps. Only the pose changes between frames.

Fleeing, side view facing left:
f1 (top-left): turns away, tail puffed.
f2 (top-right): leaps forward.
f3 (bottom-left): mid-run, legs stretched, dust puff.
f4 (bottom-right): tail flick, dropping a gold coin behind.
Preserve exact master identity: charcoal-black fur #2B2B33, squarish yellow eyes #F5D33B, SAME torn ear, cross-shaped nose scar, silver spiked collar #C0C4CC, dark-brown outlines #4A2A1A, and clean chibi anatomy. Four full-body figures entirely inside separate cells with generous clear margins, no clipped ears, tails or paws. Equal scale and ground line except specified leaps. Flat crisp cel shading only, no gradients, airbrush, 3D sheen, white silhouette halo, ground shadow, backdrop, extra limbs, labels, text or watermark. Fish bone may leave the mouth only as necessary for open-mouth actions.
```
