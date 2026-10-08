# Obstacle icon generation

Generated 2026-10-08 with the built-in imagegen tool, using `docs/prompts/icons/obstacles.md`. Layers use the chopsticks sprite as the style reference; hazards and rules use the layers sheet. All calls requested transparent backgrounds.

Source sheets normalized to 1024×1024. Icons cut along transparent gaps, trimmed, scaled proportionally, and centred on 192×192 transparent canvases. Very faint alpha below 16 is ignored only when finding separators; source alpha is preserved in the extracted artwork.

## Layers

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Use the reference image (assets/sprites/boosters/chopsticks.png) only for style and palette: same outline weight, cel shading, highlights and level of detail. Draw the new items described below.

Setting: a sushi-restaurant match-3 puzzle game. Each icon stands for one board obstacle or goal and has to read on a small white goal chip as well as on a light wooden panel.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each icon a standalone object in a slight three-quarter front view. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Layer obstacles:
f1 (top-left) nori: two small square sheets of toasted nori seaweed stacked at a slight angle: deep green-black #1F3A24 with a few darker crinkle strokes and a thin lighter green edge so the dark shape still reads on a dark chip.
f2 (top-right) ice: a chunky rounded cube of pale blue ice #AEE1FA with frosted white edges, one small crack and one white glint.
f3 (bottom-left) bag: a small round rice sack of cream burlap #E9D3A8 with a darker #D1B47F fold shadow, tied at the neck with a red #B5472F cord, one brown dot on the front and three white rice grains at its foot.
f4 (bottom-right) mat: a bamboo sushi-rolling mat (makisu) half rolled up: pale bamboo slats #CDB872 with darker slat lines and two thin green cords.
Output a square 1024x1024 PNG sheet with genuine alpha transparency. Keep every complete icon inside its quadrant, with clear transparent space between icons.
```

## Hazards

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Use the reference image (assets/ui/obstacles/source/layers_sheet.png) only for style and palette: same outline weight, cel shading, highlights and level of detail. Draw the new items described below.

Setting: a sushi-restaurant match-3 puzzle game. Each icon stands for one board obstacle or goal and has to read on a small white goal chip as well as on a light wooden panel.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each icon a standalone object in a slight three-quarter front view. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Hazards:
f1 (top-left) fire: a cartoon flame of three rounded tongues: orange #FF8A2A outside, yellow #FFD24A core, one red shadow tone.
f2 (top-right) cat: the head of a mischievous chibi black stray cat #2B2B33 from the thieving cat gang: big yellow #F5D33B eyes, a sly grin, a fish bone held in its mouth, one ear slightly nicked.
f3 (bottom-left) key: a chunky gold #E0A84A key with a round bow, crossed in front of a small white #FFFFFF and light grey #D9D9D9 padlock.
f4 (bottom-right) bomb: a round black #2B211C cartoon bomb with a short fuse and a small orange spark on top and a blank round cream label on its front; no number.
Output a square 1024x1024 PNG sheet with genuine alpha transparency. Keep every complete icon inside its quadrant, with clear transparent space between icons.
```

## Rules

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Use the reference image (assets/ui/obstacles/source/layers_sheet.png) only for style and palette: same outline weight, cel shading, highlights and level of detail. Draw the new items described below.

Setting: a sushi-restaurant match-3 puzzle game. Each icon stands for one board obstacle or goal and has to read on a small white goal chip as well as on a light wooden panel.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each icon a standalone object in a slight three-quarter front view. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Board rules and delivery:
f1 (top-left) portal: a round swirling portal seen slightly from above: spiral arms from light lavender #C9B6F2 on the rim to deep indigo #3B2F7A in the centre, with a thin notched ring round it like a magic circle.
f2 (top-right) conveyor: a short straight piece of sushi conveyor belt: grey-blue belt on a red lacquer #8E2A22 rail with a gold #E0A84A trim, one salmon nigiri plate on it and a chunky cream arrow printed on the belt pointing right.
f3 (bottom-left) gravity: a round cream badge with a big chunky dark-brown #4A2E1B arrow pointing to the right and two short speed lines behind it, a tiny salmon nigiri riding the arrow head.
f4 (bottom-right) deliver: a triangle rice ball (onigiri) with a nori band at the bottom and a tiny cute face (dot eyes, small smile, pink blush), the same onigiri as the board delivery item.
Output a square 1024x1024 PNG sheet with genuine alpha transparency. Keep every complete icon inside its quadrant, with clear transparent space between icons.
```

