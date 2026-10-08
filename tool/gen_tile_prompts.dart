// ignore_for_file: avoid_print
// Writes the GPT Image prompt pack for the tilesets to docs/prompts/tiles/:
// the in-level board tiles, the shared level-map parts and one file per map
// region (every restaurant in Restaurant.shops), plus README.md. The markdown
// is generated, so change the style or a tile here and re-run.
//
//   dart run tool/gen_tile_prompts.dart
import 'dart:io';

part 'prompts/tile_board.dart';
part 'prompts/tile_regions.dart';

const _outDir = 'docs/prompts/tiles';

const _style =
    'Japanese anime-style chibi mobile-game environment art, like the tile '
    'set of a cosy slice-of-life anime puzzle game. Drawn by hand by a '
    'professional 2D anime game background artist: flat cel colours with one '
    'crisp hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with '
    'slight natural line-weight variation (thicker on outer silhouettes, '
    'thinner on inner details), one small flat white highlight per shiny '
    'surface, chunky rounded chibi shapes (buildings, trees, rocks and props '
    'squashed and rounded like cute toys), limited warm Japanese palette, '
    'light from the top-left. Few, deliberate details, every shape clearly '
    'readable at 64 pixels. Avoid the typical AI-art look: no airbrushed or '
    'soft gradient shading, no plastic or 3D-render sheen, no photographic '
    'texture, no texture noise, no random extra sparkles or particles, no '
    'melted or merged details, no blurry edges. No characters or people '
    'unless asked, no text, no letters, no numbers, no logo, no watermark. '
    'Outline weight matches a cartoon salmon-nigiri game icon.';

String _sameAsRef(String ref) =>
    'Use the reference image ($ref) only for style and palette: same outline '
    'weight, cel shading, colours and level of detail. Draw the new items '
    'described below.';

/// How a cell of a sheet is cut out and how the prompt describes it.
enum Fit {
  /// Opaque ground that repeats seamlessly in every direction.
  ground,

  /// Fills its square cell and must stay lined up with the grid (no trim).
  cell,

  /// A standalone object: trimmed to its outline, then scaled to fit.
  prop,
}

class Cell {
  const Cell(this.file, this.desc, {this.fit = Fit.prop});
  final String file;
  final String desc;
  final Fit fit;
}

/// A 2x2 sheet of four 512px cells, cut into [out]-pixel files.
class Sheet {
  const Sheet({
    required this.name,
    required this.title,
    required this.use,
    required this.cells,
    this.view = 'Straight top-down view, flat, no perspective.',
    this.ref,
    this.extra,
  });

  /// Saved as `source/<name>_sheet.png`.
  final String name;
  final String title;
  final String use;
  final List<Cell> cells;
  final String view;

  /// Image passed to the Edit endpoint; null means text → image.
  final String? ref;
  final String? extra;

  bool get ground => cells.every((c) => c.fit == Fit.ground);
}

/// One whole image (no grid).
class Single {
  const Single({
    required this.name,
    required this.title,
    required this.use,
    required this.size,
    required this.desc,
    required this.out,
    required this.resize,
    this.transparent = true,
    this.ref,
  });
  final String name;
  final String title;
  final String use;

  /// GPT Image size: 1024x1024, 1536x1024 or 1024x1536.
  final String size;
  final String desc;

  /// Final asset path.
  final String out;

  /// ImageMagick geometry for the final size, or null to keep it as is.
  final String? resize;
  final bool transparent;
  final String? ref;
}

class Doc {
  const Doc({
    required this.file,
    required this.title,
    required this.intro,
    required this.folder,
    required this.theme,
    required this.out,
    required this.sheets,
    this.singles = const [],
    this.palette = const {},
  });

  /// Markdown file name without extension.
  final String file;
  final String title;
  final String intro;

  /// Asset folder the cut tiles go to; sheets go to `<folder>/source/`.
  final String folder;

  /// Setting line shared by every prompt of this file.
  final String theme;

  /// Final tile size in pixels.
  final int out;
  final List<Sheet> sheets;
  final List<Single> singles;
  final Map<String, String> palette;
}

const _decoNames = {'m': 'mountain', 'f': 'forest', 'c': 'city'};

Doc _regionDoc(int i, Region r) {
  final n = (i + 1).toString().padLeft(2, '0');
  final shown = [for (final ch in r.used) _decoNames[ch]!];
  String deco(String key, String desc) {
    final on = shown.contains(key) ? '' : ' (not on this band today)';
    return '$desc$on.';
  }

  return Doc(
    file: 'map-$n-${r.id}',
    title: 'level map, ${r.en}',
    intro: '**${r.th} / ${r.en}** (${r.kanji}) · levels ${r.levels} · shop id '
        '`${r.id}`. Map band colours come from `kMapRegions` in '
        '`lib/ui/map/japan_map.dart`. This band shows the '
        '${shown.join(' and ')} deco tile${shown.length == 1 ? '' : 's'}; '
        'the others are drawn anyway so the set stays complete.',
    folder: 'assets/sprites/map/${r.id}',
    theme: 'Setting: the ${r.en} region of the map, ${r.setting} Region '
        'colours: banner ${r.top} to ${r.bottom}, land ${r.land}.',
    out: 256,
    palette: {'banner top': r.top, 'banner bottom': r.bottom, 'land': r.land},
    sheets: [
      Sheet(
        name: 'land',
        title: 'Land',
        use: 'Land tiles (`L`), alternating as a checkerboard like '
            '`region.land` in `tile_map.dart`. land_c/land_d are rare '
            'variants.',
        cells: [
          Cell('land_a', '${r.ground} in ${r.land}.', fit: Fit.ground),
          const Cell(
              'land_b',
              'the same ground about 12% lighter, details in other places, '
                  'so it alternates with land_a.',
              fit: Fit.ground),
          Cell('land_c', 'land_a with ${r.detail}.', fit: Fit.ground),
          Cell('land_d', 'land_b with ${r.detail}.', fit: Fit.ground),
        ],
      ),
      Sheet(
        name: 'deco',
        title: 'Deco tiles',
        use: 'The `m`/`f`/`c` tiles of the band template (`_deco` in '
            '`tile_map.dart`), drawn over a land tile, plus one extra prop '
            'for this region.',
        view: 'Top-down three-quarter view, seen from above at about 45 '
            'degrees, each object sitting on an invisible ground with its '
            'base near the bottom of its cell.',
        ref: 'land_sheet.png',
        cells: [
          Cell('mountain', deco('mountain', r.mountain)),
          Cell('forest', deco('forest', r.forest)),
          Cell('city', deco('city', r.city)),
          Cell('special', '${r.special}.'),
        ],
      ),
    ],
    singles: [
      Single(
        name: 'landmark',
        title: 'Landmark emblem',
        use: 'Region emblem for the banner (`RegionBanner`), replacing the '
            'shop emoji.',
        size: '1024x1024',
        desc: 'Region emblem: ${r.landmark}. A single object, front '
            'three-quarter view, chunky and glossy like a sushi game icon, '
            'centred with about 10% empty margin, fully transparent '
            'background.',
        out: 'assets/sprites/map/${r.id}/landmark.png',
        resize: '512x512',
        ref: 'land_sheet.png',
      ),
      Single(
        name: 'level_bg',
        title: 'Level backdrop',
        use: 'Backdrop behind the board for this region\'s levels (today '
            'every screen uses `assets/backgrounds/bg.png`).',
        size: '1024x1536',
        desc: 'Portrait background for the puzzle screen, opaque, no '
            'characters: ${r.backdrop}. The game board covers the middle '
            '(about 90% of the width, from 25% to 80% of the height), so '
            'keep that area a calm, simple, low-contrast surface; put the '
            'scenery in the top 25% and bottom 20%. Front view with gentle '
            'depth.',
        out: 'assets/backgrounds/level_${r.id}.png',
        resize: null,
        transparent: false,
        ref: 'land_sheet.png',
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Markdown.

String _block(String lang, String text) => '```$lang\n$text\n```\n';

const _cellNames = ['top-left', 'top-right', 'bottom-left', 'bottom-right'];

String _sheetPrompt(Doc d, Sheet s) {
  final fits = s.cells.map((c) => c.fit).toSet();
  final rules = <String>[
    'Tile sheet: 2x2 grid of 4 equal 512x512 cells, one item per cell, no '
        'borders, no grid lines, no gutters, no labels, no numbers.',
    s.view,
    'Every item at the same scale with the same outline weight.',
    if (fits.contains(Fit.ground))
      'Ground tiles fill their cell edge to edge, opaque, with no outline '
          'or border round the cell; the left edge matches the right edge and '
          'the top edge matches the bottom edge so each repeats seamlessly.',
    if (fits.contains(Fit.cell))
      'Items that fill their cell are drawn exactly to the square cell so '
          'they line up with the board grid.',
    if (fits.contains(Fit.prop))
      'Standalone items are centred with about 10% empty margin.',
    if (!s.ground) 'Everything outside the items is fully transparent.',
  ];
  final cells = [
    for (var i = 0; i < 4; i++)
      'f${i + 1} (${_cellNames[i]}) ${s.cells[i].file}: ${s.cells[i].desc}'
  ].join('\n');
  return [
    _style,
    if (s.ref != null) _sameAsRef(s.ref!),
    d.theme,
    rules.join(' '),
    '${s.title}:\n$cells',
    if (s.extra != null) s.extra!,
  ].join('\n\n');
}

String _singlePrompt(Doc d, Single s) => [
      _style,
      if (s.ref != null) _sameAsRef(s.ref!),
      d.theme,
      s.desc,
    ].join('\n\n');

String _cutCommands(Doc d, Sheet s) {
  final src = '${d.folder}/source/${s.name}_sheet.png';
  final n = d.out;
  return [
    for (var i = 0; i < 4; i++)
      () {
        final c = s.cells[i];
        final crop = '512x512+${(i % 2) * 512}+${(i ~/ 2) * 512}';
        final fit = c.fit == Fit.prop
            ? '-trim +repage -resize ${n}x$n'
            : '-resize ${n}x$n!';
        return 'magick $src -resize 1024x1024! -crop $crop +repage $fit '
            '${d.folder}/${c.file}.png';
      }(),
  ].join('\n');
}

String _doc(Doc d) {
  final b = StringBuffer()
    ..writeln('# GPT Image prompts: ${d.title}')
    ..writeln()
    ..writeln('<!-- Generated by tool/gen_tile_prompts.dart. Edit that file '
        'and re-run instead of editing this one. -->')
    ..writeln()
    ..writeln(d.intro)
    ..writeln()
    ..writeln('- Sheets go in `${d.folder}/source/`; cut tiles are '
        '${d.out}×${d.out} px in `${d.folder}/`. See [README.md](README.md) '
        'for settings.')
    ..writeln('- Colours: ${d.palette.entries.map((e) => '${e.key} '
        '`${e.value}`').join(', ')}, outline `#4A2A1A`');
  var n = 0;
  for (final s in d.sheets) {
    n++;
    final how = s.ref == null
        ? 'Text → image'
        : 'Edit endpoint with `${s.ref}` as the input image';
    final bg = s.ground ? 'opaque' : 'transparent';
    b
      ..writeln()
      ..writeln('## $n. ${s.title}')
      ..writeln()
      ..writeln(s.use)
      ..writeln()
      ..writeln('$how · `size: 1024x1024` · `background: $bg` · save as '
          '`${s.name}_sheet.png`.')
      ..writeln()
      ..writeln('| Cell | File | Cut |')
      ..writeln('| ---- | ---- | --- |');
    for (var i = 0; i < 4; i++) {
      final c = s.cells[i];
      b.writeln('| f${i + 1} ${_cellNames[i]} | `${c.file}.png` | '
          '${c.fit.name} |');
    }
    b
      ..writeln()
      ..write(_block('text', _sheetPrompt(d, s)))
      ..writeln()
      ..writeln('Cut:')
      ..writeln()
      ..write(_block('bash', _cutCommands(d, s)));
  }
  for (final s in d.singles) {
    n++;
    final how = s.ref == null
        ? 'Text → image'
        : 'Edit endpoint with `${s.ref}` as the input image';
    final bg = s.transparent ? 'transparent' : 'opaque';
    final src = '${d.folder}/source/${s.name}.png';
    b
      ..writeln()
      ..writeln('## $n. ${s.title}')
      ..writeln()
      ..writeln(s.use)
      ..writeln()
      ..writeln('$how · `size: ${s.size}` · `background: $bg` · save as '
          '`${s.name}.png`.')
      ..writeln()
      ..write(_block('text', _singlePrompt(d, s)))
      ..writeln()
      ..writeln('Cut:')
      ..writeln()
      ..write(_block(
          'bash',
          s.resize == null
              ? 'cp $src ${s.out}'
              : 'magick $src -trim +repage -resize ${s.resize} ${s.out}'));
  }
  return b.toString();
}

String _readme(List<Doc> docs) {
  final b = StringBuffer()
    ..writeln('# GPT Image prompts: tiles and level map')
    ..writeln()
    ..writeln('<!-- Generated by tool/gen_tile_prompts.dart. Edit that file '
        'and re-run instead of editing this one. -->')
    ..writeln()
    ..writeln('Ready-to-paste prompts for every tileset: the board tiles '
        'inside a level, the shared level-map parts and one file per map '
        'region (every restaurant in `Restaurant.shops`). The style is the '
        'same anime chibi look as the [character prompts](../README.md). To '
        'change the style, a region or a tile, edit '
        '`tool/gen_tile_prompts.dart` and run:')
    ..writeln()
    ..writeln('```bash')
    ..writeln('dart run tool/gen_tile_prompts.dart')
    ..writeln('```')
    ..writeln()
    ..writeln('## How to use')
    ..writeln()
    ..writeln('- Model `gpt-image-1`, `quality: high`, `output_format: png`. '
        'Each section gives the `size` and `background` to use: ground '
        'sheets and level backdrops are opaque, everything else transparent.')
    ..writeln('- Most files are **2×2 sheets of four 512×512 cells**, read '
        'left→right, top→bottom (f1 f2 / f3 f4). Each cell becomes one tile.')
    ..writeln('- In each file, generate the first sheet with **text → image** '
        'a few times and keep the best. Generate every later sheet and image '
        'with the **Edit** endpoint, passing that first sheet as the input '
        'image, so a whole set shares one palette and outline.')
    ..writeln('- Save sheets in `<folder>/source/` under the name the section '
        'gives, then run its **Cut** commands (ImageMagick: `brew install '
        'imagemagick`). The cut column tells how: `ground` and `cell` tiles '
        'are cropped to the exact cell so they stay on the grid, `prop` '
        'tiles are trimmed to their outline and scaled to fit.')
    ..writeln('- Board tiles are 192 px (the size of the current '
        '`assets/sprites/tiles/*.png`), map tiles 256 px. Add new folders to '
        '`pubspec.yaml` and load them in `lib/game/tile_art.dart` / '
        '`lib/ui/map/tile_map.dart` when wiring them in.')
    ..writeln()
    ..writeln('## Files')
    ..writeln()
    ..writeln('| File | Folder | Sheets |')
    ..writeln('| ---- | ------ | ------ |');
  for (final d in docs) {
    final parts = [
      ...d.sheets.map((s) => s.name),
      ...d.singles.map((s) => s.name),
    ];
    final title = '${d.title[0].toUpperCase()}${d.title.substring(1)}';
    b.writeln('| [$title](${d.file}.md) | `${d.folder}` | '
        '${parts.join(', ')} |');
  }
  b
    ..writeln()
    ..writeln('## Quality checklist')
    ..writeln()
    ..writeln('- [ ] Ground tiles really repeat: tile one 3×3 and look for '
        'seams (`magick land_a.png -write mpr:t +delete -size 768x768 '
        'tile:mpr:t check.png`). Fix a seam by hand rather than re-rolling a '
        'good sheet.')
    ..writeln('- [ ] `cell` tiles fill their square exactly (belts join, '
        'frames meet, ice and portals line up with the grid).')
    ..writeln('- [ ] Transparent sheets have no white halo or leftover '
        'background between items.')
    ..writeln('- [ ] Layered obstacles (nori, ice, sacks) keep the same size '
        'and position across layers; only the layer count changes.')
    ..writeln('- [ ] Tinted art (lock, portals) is white and greys only.')
    ..writeln('- [ ] It reads as anime chibi: flat cel shading, dark-brown '
        'outline, rounded toy-like shapes. No airbrush gradients, 3D sheen, '
        'photo texture, text or stray sparkles.')
    ..writeln('- [ ] Colours match the hex codes in each file; a region\'s '
        'land matches its `kMapRegions` colour.')
    ..writeln('- [ ] Tiles sit well under `assets/sprites/sushi/salmon.png` '
        'and next to the character sprites (outline weight, shading).')
    ..writeln('- [ ] Every item is readable at 64 px.');
  return b.toString();
}

void main() {
  final docs = [
    _board,
    _mapCommon,
    for (var i = 0; i < _regions.length; i++) _regionDoc(i, _regions[i]),
  ];
  Directory(_outDir).createSync(recursive: true);
  for (final d in docs) {
    File('$_outDir/${d.file}.md').writeAsStringSync(_doc(d));
  }
  File('$_outDir/README.md').writeAsStringSync(_readme(docs));
  print('Wrote ${docs.length} tile files and README.md to $_outDir/');
}
