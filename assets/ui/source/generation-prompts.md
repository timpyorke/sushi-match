# Dialog icon generation

Generated 2026-10-08 with the built-in imagegen tool from `docs/prompts/icons/ui.md`, using `assets/ui/heart.png` as the style reference and requesting a transparent background.

Source sheet normalized to 1024×1024. Three icons cut along transparent separators, preserving both broken-heart halves, trimmed, scaled proportionally, and centred on 192×192 transparent canvases. The bottom-right cell is unused.

## Final prompt

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Use the reference image (assets/ui/heart.png) only for style and palette: same outline weight, cel shading, highlights and level of detail. Draw the new items described below.

Setting: the dialog icons of a sushi-restaurant puzzle game, shown next to its glossy red heart and gold coin and star icons.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each icon a standalone object, straight front view. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Only the first 3 cells hold an icon; the other cell stays empty. Everything outside the icons is fully transparent.

Dialog icons:
f1 (top-left) gift: a square gift box in red #D8402E with a gold #E8B13C ribbon and a big bow on top, the lid lifted a little.
f2 (top-right) heart_broken: the same glossy red heart as the reference, cracked down the middle with a zigzag split and the two halves leaning a little apart.
f3 (bottom-left) check: a chunky green #4CAF50 tick mark on a round cream badge with a thin gold rim.
Output a square 1024x1024 PNG sprite sheet with genuine alpha transparency. Keep each complete icon inside its quadrant with clear transparent gaps; leave the bottom-right quadrant fully empty. The broken heart must contain both separated halves. No detached fragments or speckles outside the three icon silhouettes.
```

