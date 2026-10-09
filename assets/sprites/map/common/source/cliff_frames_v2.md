# Cliff frames v2

Generated with built-in imagegen, referencing cliff.webp. Applied to the map painter; superseded cliff assets and standalone source images have been removed.

Atlas: cliff_frames_v2.png. Left half = outer coastline (surf outside), right half = inner coastline (surf inside). Each half normalized to 768 x 768 and sliced on a 3 x 3 grid. Eight 256 x 256 lossless WebP tiles per frame; transparent center omitted. Exact filenames and grid coordinates: cliff_frames_v2_manifest.json. Reassembled previews provided. The painter places outer slices in a 3x3 subgrid on land tiles. Inner slices are anchored at sea-cell corners surrounded by three land neighbours, with rock shoulders overlapping the adjoining straight cliffs.

Rows:

    top_left     top       top_right
    left         empty     right
    bottom_left  bottom    bottom_right

Final prompt: Production transparent 2:1 sprite atlas with two continuous square cliff frames side by side, no gaps, labels or gridlines. Left frame: convex outer coastline, rocks inward, white foam and cyan surf outside. Right frame: concave inner bay coastline, rocks outward, foam and surf inside. Match reference warm brown chunky rocks, dark outlines, flat cartoon rendering. Uniform scale, thickness, palette and lighting; straight middle edges for 3x3 slicing; large transparent centers. No land fill, background fill, scenery, perspective, glow or shadow.
