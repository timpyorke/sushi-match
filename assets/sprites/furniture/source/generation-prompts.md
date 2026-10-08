# Furniture sprite generation

Generated 2026-10-08 with the built-in imagegen tool. Prompts adapted from `docs/prompts/icons/furniture.md`. Sheet A uses `assets/sprites/boosters/chopsticks.png` as a style reference; sheets B and C use sheet A. All calls requested transparent backgrounds.

Source sheets normalized to 1024×1024. Individual icons use transparent separators between objects rather than fixed grid boundaries, then are trimmed, scaled proportionally, and centred on 256×256 transparent canvases.

## Sheet A

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Use the reference image (assets/sprites/boosters/chopsticks.png) only for style and palette: same outline weight, cel shading, highlights and level of detail. Draw the new items described below.

Setting: furniture and decorations for a cosy anime sushi bar with warm wooden floors, bought one piece at a time by the player. Each piece stands on its own on the floor.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each piece a standalone object in a slight three-quarter front view, standing upright with a flat base at the bottom of its cell. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Starter pieces:
f1 (top-left) lantern: a round red #C8372D paper chochin lantern with black top and bottom caps, a few curved rib lines and a short hanging cord; no lettering.
f2 (top-right) stool: a round wooden counter stool in honey wood #C98B4E with four short legs, a cross brace and a red cushion on the seat.
f3 (bottom-left) noren: a short split doorway curtain (noren) of three indigo #2C3E73 cloth panels with a white wave pattern along the bottom, hung from a bamboo rod.
f4 (bottom-right) sign: a wooden shop sign board (kanban) under a tiny tiled roof, standing on two posts: a cream plaque painted with a red fish shape; no letters.
Output a square 1024x1024 PNG sprite sheet with genuine alpha transparency.
```

## Sheet B

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Use the reference image (assets/sprites/furniture/source/furniture_a_sheet.png) only for style and palette: same outline weight, cel shading, highlights and level of detail. Draw the new items described below.

Setting: furniture and decorations for a cosy anime sushi bar with warm wooden floors, bought one piece at a time by the player. Each piece stands on its own on the floor.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each piece a standalone object in a slight three-quarter front view, standing upright with a flat base at the bottom of its cell. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Mid-game pieces:
f1 (top-left) plant: a small bonsai pine with rounded cloud-shaped green foliage in a shallow indigo glazed pot.
f2 (top-right) luckycat: a maneki-neko figurine: white ceramic cat sitting upright with one paw raised, red collar with a gold bell, holding a gold oval koban coin; a figurine, not a living cat.
f3 (bottom-left) aquarium: a small rectangular glass fish tank on a wooden stand, pale blue water, two orange fish, green water weed and a few bubbles.
f4 (bottom-right) conveyor: a short curved piece of sushi conveyor belt on a wooden counter base with two coloured plates riding it: salmon nigiri on a blue plate and tuna nigiri on a red plate.
Output a square 1024x1024 PNG sprite sheet with genuine alpha transparency.
```

## Sheet C

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Use the reference image (assets/sprites/furniture/source/furniture_a_sheet.png) only for style and palette: same outline weight, cel shading, highlights and level of detail. Draw the new items described below.

Setting: furniture and decorations for a cosy anime sushi bar with warm wooden floors, bought one piece at a time by the player. Each piece stands on its own on the floor.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each piece a standalone object in a slight three-quarter front view, standing upright with a flat base at the bottom of its cell. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Late-game pieces:
f1 (top-left) kadomatsu: a kadomatsu: three diagonally cut green bamboo stalks of different heights with pine sprigs and small red plum blossoms, in a straw-wrapped base tied with rope.
f2 (top-right) taiko: a barrel taiko drum on a low wooden stand: brown wooden body, cream drumheads with a ring of metal studs, two bachi sticks crossed in front.
f3 (bottom-left) sake: a komodaru sake barrel wrapped in white woven straw with a bold red circle crest and blue bands instead of lettering, a wooden lid and a wooden ladle resting on top.
f4 (bottom-right) trophy: a gold #E0A84A trophy cup with two handles on a black lacquer base, a red ribbon tied round the stem and a tiny salmon nigiri on the lid.
Output a square 1024x1024 PNG sprite sheet with genuine alpha transparency. Keep each object fully inside its quadrant, with 10 percent empty margin to all quadrant edges.
```

