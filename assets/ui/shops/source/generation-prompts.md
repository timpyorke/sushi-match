# Restaurant badge generation

Generated 2026-10-08 with the built-in imagegen tool from `docs/prompts/icons/shops.md`. Sheet A uses the chopsticks style reference and a cleanup edit. Sheets B–D use the same written style specification without a reference image; sheet D has a final edit to remove an unrequested chef's hat.

Source sheets normalized to 1024×1024. Final icons extract each complete connected white-rimmed silhouette, excluding detached background fragments while preserving edge antialiasing, then scale proportionally and centre on 192×192 transparent canvases.

## Sheet A

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Use the reference image (assets/sprites/boosters/chopsticks.png) only for style and palette: same outline weight, cel shading, highlights and level of detail. Draw the new items described below.

Setting: the restaurant badges of a sushi-restaurant puzzle game, one per region of Japan. Every icon gets a thin white outer rim outside its dark-brown outline so it reads on a coloured banner.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each icon a standalone emblem in a slight three-quarter front view, filling its cell about evenly so the set looks the same size. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Tsukiji to Hokkaido:
f1 (top-left) tsukiji: Tsukiji Fish Market (banner blue #4FA3D1): a plump glossy tuna, dark blue back and silver-white belly, lying on a small wooden crate of crushed ice; the fish in warm silver so it stands out from the blue banner.
f2 (top-right) osaka: Osaka Street Stall (banner orange #F08A3C): three golden-brown kushikatsu skewers fanned out, the crumbed balls with a glossy dark sauce drip and pale bamboo sticks.
f3 (bottom-left) kyoto: Kyoto Ryokan (banner pink #E56B8F): a small vermilion #D9412B torii gate with black top beams, two pink cherry blossoms on one post.
f4 (bottom-right) hokkaido: Hokkaido Crab Hut (banner teal #6FC3C9): a chubby red king crab with raised claws and a little cap of white snow on its shell.
Output a square 1024x1024 PNG sprite sheet with genuine alpha transparency. Keep the complete white outer rim inside each quadrant with clear transparent separation between icons.
```

### Sheet A cleanup

```text
Edit this restaurant badge sprite sheet. Preserve the four exact subjects, colours, bold dark-brown outlines, flat cel shading, and thin continuous white outer rims: top-left tuna on an ice-filled wooden crate, top-right three kushikatsu skewers, bottom-left torii with two cherry blossoms, bottom-right snowy red crab. Remove ALL detached speckles, coloured fragments, flecks, white dust, stray strokes and pixels around and between the emblems. The area outside each complete white-rimmed silhouette must be entirely clean true alpha transparency. Do not replace it with a checkerboard or opaque colour. Arrange in a square 2x2 equal grid. Slightly reduce and recenter each complete emblem so it fits entirely inside its own quadrant with 10 percent transparent margin on every side, no touching cell boundaries, no overlap. No other changes, no text, no new objects, no particles.
```

## Sheet B

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Setting: the restaurant badges of a sushi-restaurant puzzle game, one per region of Japan. Every icon gets a thin white outer rim outside its dark-brown outline so it reads on a coloured banner.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each icon a standalone emblem in a slight three-quarter front view, filling its cell about evenly so the set looks the same size. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Fukuoka to Nagoya:
f1 (top-left) fukuoka: Fukuoka Night Stall (banner indigo #5B5FC7): a red-and-black ramen bowl of creamy tonkotsu broth with noodles, a chashu slice, half a soft egg and a pair of chopsticks resting on the rim.
f2 (top-right) okinawa: Okinawa Beach Shack (banner turquoise #2EC4B6): a big red hibiscus flower with a yellow stamen and two glossy green leaves.
f3 (bottom-left) omakase: Omakase Counter (banner gold #D4A537): a small chef's crown in deep red lacquer with a gold rim and one white pearl, so it stands out from the gold banner.
f4 (bottom-right) nagoya: Nagoya Tempura Bar (banner amber #E0A030): a long ebi tempura prawn in crisp pale-gold batter with a red tail, lying on a small white paper.
Production constraint: Clean isolated game sprites, not distressed stickers. Use smooth, continuous dark-brown outlines and a thin solid white outer rim. Absolutely no isolated speckles, dust, red/yellow scraps, paint splatters or fragments outside the icons. Keep each entire icon within its own quadrant, with ample genuinely transparent empty space around it. Square 1024x1024 PNG with true alpha transparency.
```

## Sheet C

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Setting: the restaurant badges of a sushi-restaurant puzzle game, one per region of Japan. Every icon gets a thin white outer rim outside its dark-brown outline so it reads on a coloured banner.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each icon a standalone emblem in a slight three-quarter front view, filling its cell about evenly so the set looks the same size. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Everything outside the icons is fully transparent.

Hiroshima to Kobe:
f1 (top-left) hiroshima: Hiroshima Oyster Boat (banner blue #3F8FB5): an open rough grey oyster shell with a plump cream oyster and a lemon wedge.
f2 (top-right) kanazawa: Kanazawa Gold Bento (banner gold #C9A227): a black lacquer bento box seen from above at an angle, four compartments of sushi, egg and pickles, with a few flakes of gold leaf; black and red so it stands out from the gold banner.
f3 (bottom-left) sendai: Sendai Night Grill (banner purple #7A4FA8): a skewer of thick grilled beef-tongue slices with dark grill marks and a small green negi leek on the side.
f4 (bottom-right) kobe: Kobe Harbour Bistro (banner navy #2F6DB5): a chunky gold #E0A84A ship anchor wrapped with a cream rope.
Production constraint: Clean isolated game sprites, not distressed stickers. Use smooth, continuous dark-brown outlines and a thin solid white outer rim. Absolutely no isolated speckles, dust, red/yellow scraps, paint splatters or fragments outside the icons. Keep each entire icon within its own quadrant, with ample genuinely transparent empty space around it. Square 1024x1024 PNG with true alpha transparency.
```

## Sheet D

```text
Japanese anime-style chibi mobile-game icon, like the item icons of a cosy slice-of-life anime puzzle game. Drawn by hand by a professional 2D game icon artist: flat cel colours with one crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with slight natural line-weight variation (thicker outside, thinner on inner details), one or two small flat white highlights on shiny surfaces, chunky rounded toy-like shapes, bold simple silhouette, limited warm Japanese palette, light from the top-left. Few, deliberate details: every icon reads at 24 pixels from its silhouette and main colour alone. Avoid the typical AI-art look: no airbrushed or soft gradient shading, no plastic or 3D-render sheen, no photographic texture, no texture noise, no random extra sparkles or particles, no melted or merged details, no blurry edges. No people unless asked, no text, no letters, no numbers, no logo, no watermark, no ground shadow, no glow, no aura. Outline weight matches a cartoon salmon-nigiri game icon.

Setting: the restaurant badges of a sushi-restaurant puzzle game, one per region of Japan. Every icon gets a thin white outer rim outside its dark-brown outline so it reads on a coloured banner.

Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no borders, no grid lines, no gutters, no labels, no numbers. Each icon a standalone emblem in a slight three-quarter front view, filling its cell about evenly so the set looks the same size. Every icon at the same scale with the same outline weight, centred with about 10% empty margin. Only the first 2 cells hold an icon; the other cells stay empty. Everything outside the icons is fully transparent.

Nara and Ginza:
f1 (top-left) nara: Nara Deer Park Teahouse (banner green #6FA84F): the head of a cute chibi sika deer, light brown with white spots and small antlers, nibbling a round shika-senbei cracker.
f2 (top-right) ginza: Ginza Master Chef (banner silver #B0B7C3): a gold master-chef medal: a five-pointed gold star on a round gold disc, hung on a red-and-white ribbon; different from a plain rating star.
Production constraint: Clean isolated game sprites, not distressed stickers. Use smooth, continuous dark-brown outlines and a thin solid white outer rim. Absolutely no isolated speckles, dust, red/yellow scraps, paint splatters or fragments outside the icons. Keep each entire icon within its own quadrant, with ample genuinely transparent empty space around it. Square 1024x1024 PNG with true alpha transparency.
```

### Sheet D correction

```text
Edit only the top-right Ginza medal in this 2x2 restaurant badge sheet. Remove the white chef's hat and its gold band entirely. The finished Ginza icon must be just a round gold medal disc with a large five-point gold star in its centre, hung on the existing red-and-white V-shaped ribbon. The ribbon meets the gold disc directly, with no hat or other object between. Preserve the gold medal details, colours, dark-brown outline and thin white outer rim. Keep the Nara deer eating a cracker in the top-left exactly as it is. Both lower quadrants remain fully transparent and empty. Outside the two icon silhouettes is true clean alpha transparency. No text or lettering, no other changes.
```

