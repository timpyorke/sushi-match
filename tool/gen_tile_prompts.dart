// ignore_for_file: avoid_print
// Writes the GPT Image prompt pack for the tilesets to docs/prompts/tiles/:
// the in-level board tiles, the shared level-map parts and one file per map
// region (every restaurant in Restaurant.shops), plus README.md. The markdown
// is generated, so change the style or a tile here and re-run.
//
//   dart run tool/gen_tile_prompts.dart
import 'dart:io';

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

// ---------------------------------------------------------------------------
// Board: the tiles inside a level (shared by every region).

const _board = Doc(
  file: 'board',
  title: 'board tiles (in-level)',
  intro: 'The tiles and obstacles inside a level, shared by every region. '
      'They replace the current wood tiles in `assets/sprites/tiles/` and the '
      'vector grey-box obstacles in `lib/game/`. The thieving cat is a '
      'character: see [18-boss-cat-joker.md](../18-boss-cat-joker.md).',
  folder: 'assets/sprites/tiles',
  theme: 'Setting: the play board of a sushi-restaurant puzzle game, seen '
      'from straight above, like a lacquered wooden serving board inside a '
      'cosy anime sushi bar. Sushi pieces sit on top of these tiles, so '
      'every tile stays calm in the middle.',
  out: 192,
  palette: {
    'light wood': '#F3D9A4',
    'dark wood': '#E2BC7E',
    'red lacquer': '#8E2A22',
    'gold trim': '#E0A84A',
    'nori': '#1F3A24',
    'ice': '#AEE1FA',
    'sack': '#E9D3A8',
    'sack cord': '#B5472F',
    'bamboo': '#CDB872',
  },
  sheets: [
    Sheet(
      name: 'cells',
      title: 'Cells and board frame',
      use: 'Every playable cell (`TileArt.cell` in `lib/game/tile_art.dart`, '
          'checkerboard). The frame pieces are new: they would outline the '
          'board and the missing cells (`X` = `void` in level layouts), '
          'rotated in code.',
      cells: [
        Cell(
            'cell_light',
            'a square board cell filling the whole cell: pale hinoki-wood '
                'tile #F3D9A4 with a few soft wood-grain strokes, softly '
                'rounded corners and a thin darker rim, the middle plain.',
            fit: Fit.cell),
        Cell(
            'cell_dark',
            'the same cell in a slightly darker honey wood #E2BC7E, same '
                'grain style and rim, so the two alternate as a '
                'checkerboard.',
            fit: Fit.cell),
        Cell(
            'frame_edge',
            'a straight piece of the board frame: a dark red lacquer #8E2A22 '
                'rail with a thin gold #E0A84A inner trim running along the '
                'top edge of the cell from the left edge to the right edge, '
                'about 30% of the cell tall; the rest of the cell '
                'transparent.',
            fit: Fit.cell),
        Cell(
            'frame_corner',
            'the matching outer corner of that frame: the same red lacquer '
                'rail with gold trim turning round the top-left corner of '
                'the cell, entering from the right edge and leaving through '
                'the bottom edge; the rest of the cell transparent.',
            fit: Fit.cell),
      ],
    ),
    Sheet(
      name: 'conveyor',
      title: 'Conveyor belt',
      use: 'Conveyor rows (`"conveyors"` in level JSON) and the belt pieces '
          'reused on the level map: `TileArt.belt`, `beltCap` and `mapTile`. '
          'Replaces the current files with the same names.',
      ref: 'cells_sheet.png',
      cells: [
        Cell(
            'belt_straight',
            'a straight conveyor belt running left to right across the whole '
                'cell: dark grey rubber belt with segment lines, gold rails '
                'on both sides, set into red lacquer; the belt touches the '
                'left and right cell edges so tiles join into one long '
                'belt.',
            fit: Fit.cell),
        Cell(
            'belt_corner',
            'the same belt turning a 90-degree corner: it enters through the '
                'left edge and curves down to leave through the bottom edge, '
                'same width and rails.',
            fit: Fit.cell),
        Cell(
            'belt_cap',
            'the rounded end of the belt: it enters through the left edge and '
                'ends in a rounded cap with the gold rail wrapping round it '
                '(the game mirrors it for the other end).',
            fit: Fit.cell),
        Cell(
            'arrow',
            'a small chunky arrow pointing right, gold #E0A84A with a lighter '
                'top face, showing which way the belt moves.'),
      ],
    ),
    Sheet(
      name: 'nori',
      title: 'Nori layers',
      use: 'Nori under a piece (`nori:1..3` in level legends, goal '
          '`clear_nori`), now a dark green rounded square '
          '(`board_component.dart:393`). Show the file for the layers left.',
      ref: 'cells_sheet.png',
      extra: 'The nori lies under a sushi piece: keep its middle simple.',
      cells: [
        Cell(
            'nori_1',
            'one sheet of toasted nori seaweed covering the cell: deep '
                'green-black #1F3A24 with a few flat darker crinkle strokes, '
                'slightly wavy edges inset a little from the cell edge.',
            fit: Fit.cell),
        Cell(
            'nori_2',
            'two nori sheets stacked, the top one turned a little so the '
                'corners of the lower one peek out; same size as nori_1.',
            fit: Fit.cell),
        Cell(
            'nori_3',
            'three nori sheets stacked and tied with a thin pale kanpyo '
                'ribbon crossing one corner; the thickest version, same '
                'size.',
            fit: Fit.cell),
        Cell('nori_bits',
            'a few torn scraps of nori flying apart, for when a layer breaks.'),
      ],
    ),
    Sheet(
      name: 'ice',
      title: 'Ice layers',
      use: 'Ice cages over a piece (`ice:1..3`, goal `break_ice`), now a '
          'tinted rounded square (`piece_component.dart:142`).',
      ref: 'cells_sheet.png',
      extra: 'GPT Image cannot draw see-through glass, so the ice is shown '
          'only by its solid rim, glints and cracks; the inside of each cell '
          'stays fully transparent.',
      cells: [
        Cell(
            'ice_1',
            'a thin frame of pale blue ice #AEE1FA filling the cell edge to '
                'edge: a frosted rim about 15% of the cell wide with two or '
                'three white glints and one small crack, the centre fully '
                'transparent.',
            fit: Fit.cell),
        Cell(
            'ice_2',
            'the same ice frame, thicker (rim about 22% of the cell), frost '
                'crystals in two corners and more cracks.',
            fit: Fit.cell),
        Cell(
            'ice_3',
            'the thickest ice: rim about 28% of the cell, chunky frosted '
                'corners and a web of white cracks, still a transparent '
                'centre.',
            fit: Fit.cell),
        Cell(
            'ice_shards',
            'a burst of four or five small ice shards and a puff of white '
                'frost, for when a layer breaks.'),
      ],
    ),
    Sheet(
      name: 'sacks',
      title: 'Rice sacks',
      use: 'Rice sacks (`bag:1..3`, goal `break_bag`), now `_drawBag` '
          '(`board_component.dart:250`), which shows one dot per layer.',
      ref: 'cells_sheet.png',
      cells: [
        Cell(
            'bag_1',
            'a small round rice sack tied at the neck with a red #B5472F '
                'cord: cream burlap #E9D3A8 with a darker #D1B47F fold '
                'shadow and one brown dot printed on the front; centred, '
                'filling about 85% of the cell.',
            fit: Fit.cell),
        Cell(
            'bag_2',
            'the same sack at the same size with two dots and a small patch '
                'sewn on one side.',
            fit: Fit.cell),
        Cell(
            'bag_3',
            'the same sack at the same size with three dots, a second cord '
                'round its belly and an overstuffed, bulging look.',
            fit: Fit.cell),
        Cell(
            'rice_spill',
            'a small burst of white rice grains and a torn scrap of burlap, '
                'for when a layer bursts.'),
      ],
    ),
    Sheet(
      name: 'grill',
      title: 'Bamboo mat and fire',
      use: 'Bamboo mats (`mat`, goal `clear_mats`; `_drawMat` at '
          '`board_component.dart:232`) and burning pieces on grill levels '
          '(`fire`, goal `put_out`; `piece_component.dart:40`). fire_1 and '
          'fire_2 alternate at about 6 fps.',
      ref: 'cells_sheet.png',
      cells: [
        Cell(
            'mat',
            'a square bamboo sushi-rolling mat (makisu) filling the cell: '
                'pale bamboo slats #CDB872 running top to bottom, tied with '
                'two thin green cords across.',
            fit: Fit.cell),
        Cell(
            'fire_1',
            'cartoon flames rising from the bottom of the cell: orange '
                '#FF8A2A and yellow #FFD24A flame tongues with a red shadow '
                'tone, filling the bottom 60% of the cell; the top of the '
                'cell transparent.',
            fit: Fit.cell),
        Cell(
            'fire_2',
            'the same flames in the next flicker frame: same size and base, '
                'the tips leaning the other way.',
            fit: Fit.cell),
        Cell(
            'smoke',
            'a round puff of grey-white smoke with a little water splash, '
                'for when a fire is put out.'),
      ],
    ),
    Sheet(
      name: 'badges',
      title: 'Locks, bombs and portals',
      use: 'Colour locks (`lock:<piece>`, `KeyLockBadge` in '
          '`overlay_badges.dart:11`), countdown bombs (`bomb:N`, '
          '`piece_component.dart:63`) and portals (`portal_in` / '
          '`portal_out`, `PortalBadge` in `overlay_badges.dart:65`). The '
          'lock and the portals are tinted in code (per piece colour and per '
          'portal pair), so they are drawn in white and greys.',
      ref: 'cells_sheet.png',
      cells: [
        Cell(
            'lock',
            'a chunky padlock drawn only in white #FFFFFF and light grey '
                '#D9D9D9 with the dark-brown outline.'),
        Cell(
            'bomb',
            'a round black #2B211C cartoon bomb with a short fuse and a '
                'small spark on top, and a large blank round cream label on '
                'its front where the game prints the countdown; no number.'),
        Cell(
            'portal_in',
            'a swirling vortex filling the cell edge to edge, drawn only in '
                'white and greys: spiral arms from light grey on the rim to '
                'dark grey in the centre. Pieces drop into it.',
            fit: Fit.cell),
        Cell(
            'portal_out',
            'a ring portal filling the cell edge to edge, drawn only in white '
                'and light greys: a thick ring with small notches like a '
                'magic circle, the centre transparent. Pieces drop out of '
                'it.',
            fit: Fit.cell),
      ],
    ),
    Sheet(
      name: 'extras',
      title: 'Gravity arrow, delivery item and board effects',
      use: 'Gravity arrows beside the board (`_drawGravityArrows`, '
          '`board_component.dart:194`), the delivery ingredient (`deliver` '
          'goal, `piece_painter.dart:160`), and two board effects that are '
          'vector today.',
      ref: 'cells_sheet.png',
      cells: [
        Cell(
            'gravity_arrow',
            'a short chunky arrow pointing down, dark wood brown #4A2E1B with '
                'a cream highlight (rotated in code).'),
        Cell(
            'onigiri',
            'a triangle rice ball with a nori band at the bottom and a tiny '
                'cute face (dot eyes, small smile, pink blush): the '
                'ingredient the player brings down to the bottom row.'),
        Cell(
            'select',
            'a selection ring for the tapped cell: a thick rounded square '
                'outline in warm gold #FFD54F with a small sparkle on each '
                'corner, filling the cell, the centre transparent.',
            fit: Fit.cell),
        Cell(
            'clear_burst',
            'a star-shaped pop of flat cream and gold shapes, shown when a '
                'piece is cleared.'),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Level map: parts shared by every region.

const _mapCommon = Doc(
  file: 'map-common',
  title: 'level map, shared parts',
  intro: 'Parts of the level map that every region shares: the sea, the '
      'coast, the level nodes, the route and the region banner. The map is '
      'drawn by `TileMapPainter` (`lib/ui/map/tile_map.dart`) on an 8-column '
      'grid laid out in `lib/ui/map/japan_map.dart`.',
  folder: 'assets/sprites/map/common',
  theme: 'Setting: a cute illustrated world map of Japan for a sushi puzzle '
      'game, seen from above like a cosy anime RPG overworld.',
  out: 256,
  palette: {
    'sea': '#4FA3D1',
    'light sea': '#62B2DC',
    'cliff': '#8A6A45',
    'route red': '#B71C2C',
    'paper': '#F5E6C8',
    'gold': '#FFD54F',
  },
  sheets: [
    Sheet(
      name: 'sea',
      title: 'Sea',
      use: 'Sea tiles (`.` in the band template in `japan_map.dart`), left '
          'empty in `tile_map.dart` today. sea_a/sea_b alternate; c and d '
          'are rare variants.',
      cells: [
        Cell(
            'sea_a',
            'calm sea #4FA3D1 with a few short white wave-curl strokes in a '
                'seigaiha spirit.',
            fit: Fit.ground),
        Cell(
            'sea_b',
            'the same sea a little lighter #62B2DC with the strokes in other '
                'places, so it alternates with sea_a.',
            fit: Fit.ground),
        Cell('sea_c', 'sea_a with one small white foam crest.',
            fit: Fit.ground),
        Cell('sea_d', 'sea_a with the faint dark shadow of a little fish.',
            fit: Fit.ground),
      ],
    ),
    Sheet(
      name: 'coast',
      title: 'Coastline',
      use: 'The brown lip drawn under land where the sea is below '
          '(`below == MapTile.sea` in `tile_map.dart`).',
      ref: 'sea_sheet.png',
      cells: [
        Cell(
            'cliff',
            'a coastline lip: a strip of warm brown earth cliff #8A6A45 with '
                'a darker under-shade and a thin line of white surf, across '
                'the bottom quarter of the cell from the left edge to the '
                'right edge; the top three quarters transparent.',
            fit: Fit.cell),
        Cell('cliff_left',
            'the same cliff strip ending in a rounded end on the left side.',
            fit: Fit.cell),
        Cell('cliff_right',
            'the same cliff strip ending in a rounded end on the right side.',
            fit: Fit.cell),
        Cell('wave_crest',
            'a single small curling white wave crest with a blue under-shade.'),
      ],
    ),
    Sheet(
      name: 'nodes',
      title: 'Level nodes',
      use: '`LevelNode` (`lib/ui/map/level_node.dart`): a sushi plate (the '
          'sushi sprite is drawn on it), a lock, a gold glow on the next '
          'level and the number pill.',
      view: 'Top-down three-quarter view, seen from above at about 45 '
          'degrees.',
      ref: 'sea_sheet.png',
      cells: [
        Cell(
            'plate',
            'an empty round sushi plate: white ceramic with a red #B71C2C '
                'rim and a small blue wave pattern.'),
        Cell(
            'plate_locked',
            'the same plate in grey stone colours with a chunky padlock in '
                'the middle.'),
        Cell(
            'plate_current',
            'the same white plate inside a thick ring of warm gold #FFD54F '
                'rays drawn as flat triangles, marking the next level.'),
        Cell(
            'number_tag',
            'a blank pill-shaped tag, wider than tall, white with a thick red '
                '#B71C2C border; empty, the game prints the number.'),
      ],
    ),
    Sheet(
      name: 'route',
      title: 'Route and locked regions',
      use: 'The dashed route and its cleared part (`_route` in '
          '`tile_map.dart`), the player marker and the cover over regions '
          'not opened yet (`lockedShops`).',
      view: 'Top-down three-quarter view, seen from above at about 45 '
          'degrees.',
      ref: 'sea_sheet.png',
      cells: [
        Cell('route_dot',
            'a small flat oval stepping stone, pale grey with a soft shade.'),
        Cell(
            'route_done',
            'the same stepping stone in red lacquer #B71C2C with a white '
                'highlight.'),
        Cell(
            'marker',
            'a cute map pin shaped like a small white sushi-chef hat with a '
                'red band, showing where the player is.'),
        Cell(
            'fog',
            'puffy white and light grey anime clouds filling the cell edge '
                'to edge, laid over regions that are still locked.',
            fit: Fit.cell),
      ],
    ),
    Sheet(
      name: 'stars',
      title: 'Stars and flags',
      use: '`StarIcon` under cleared levels, a flag on each region\'s last '
          '(boss) level, and a badge over a locked region.',
      view: 'Front view.',
      ref: 'sea_sheet.png',
      cells: [
        Cell('star_lit',
            'a chunky five-point star in gold #FFD54F with an orange shade.'),
        Cell('star_dim', 'the same star empty: grey with a darker grey shade.'),
        Cell(
            'flag_boss',
            'a small red and white triangle pennant on a bamboo pole, for a '
                'region\'s boss level.'),
        Cell('cloud_lock',
            'a big puffy cloud with a chunky padlock on its front.'),
      ],
    ),
  ],
  singles: [
    Single(
      name: 'banner',
      title: 'Region banner',
      use: '`RegionBanner` in `tile_map.dart`, above each region. The game '
          'writes the name and kanji on it.',
      size: '1536x1024',
      desc: 'A wide empty signboard for a region name, front view: a '
          'horizontal wooden plank sign with a red lacquer #B71C2C border '
          'and gold corner caps, two short ropes at the top corners, and a '
          'large plain cream #F5E6C8 centre with nothing written on it. '
          'Centred with about 8% empty margin, fully transparent background.',
      out: 'assets/sprites/map/common/banner.png',
      resize: '768x512',
      ref: 'sea_sheet.png',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Level map: one entry per region, in Restaurant.shops order. Colours and
// deco remaps copy kMapRegions in lib/ui/map/japan_map.dart.

class Region {
  const Region({
    required this.id,
    required this.en,
    required this.th,
    required this.kanji,
    required this.levels,
    required this.top,
    required this.bottom,
    required this.land,
    required this.deco,
    required this.setting,
    required this.ground,
    required this.detail,
    required this.mountain,
    required this.forest,
    required this.city,
    required this.special,
    required this.landmark,
    required this.backdrop,
  });
  final String id, en, th, kanji, levels, top, bottom, land;

  /// Same as `MapRegion.deco`: which tile the template's m/f/c become.
  final Map<String, String> deco;
  final String setting;

  /// Ground texture of the land tiles, and an extra detail for variants.
  final String ground, detail;
  final String mountain, forest, city, special;
  final String landmark;

  /// What the level backdrop shows round the board.
  final String backdrop;

  /// Deco tiles this band actually shows on the map today.
  Set<String> get used => {for (final ch in 'mfc'.split('')) deco[ch] ?? ch};
}

const _regions = [
  Region(
    id: 'tsukiji',
    en: 'Tsukiji Fish Market',
    th: 'ตลาดปลาสึกิจิ',
    kanji: '東京',
    levels: '1-15',
    top: '#4FA3D1',
    bottom: '#2B6E99',
    land: '#A8C97F',
    deco: {'m': 'c', 'f': 'c'},
    setting: "Tokyo's Tsukiji fish market on a bright morning by the bay: "
        'blue-and-cream striped stall awnings, crates of ice and fish, '
        'little fishing boats and Mount Fuji far away.',
    ground: 'short spring grass',
    detail: 'a few tiny white clover flowers',
    mountain: 'a small Mount Fuji: blue-grey cone with a white snow cap',
    forest: 'a cluster of three round ginkgo trees',
    city: 'a market stall with a blue-and-cream striped awning and stacked '
        'wooden fish crates with ice',
    special: 'a small fishing boat with a red flag',
    landmark: 'a plump tuna lying on a wooden crate of crushed ice',
    backdrop: 'the inside of the fish market at dawn: hanging paper '
        'lanterns and striped awnings at the top, ice crates and the harbour '
        'water with boats at the bottom',
  ),
  Region(
    id: 'osaka',
    en: 'Osaka Street Stall',
    th: 'ร้านริมทางโอซาก้า',
    kanji: '大阪',
    levels: '16-30',
    top: '#F08A3C',
    bottom: '#C25A16',
    land: '#E6C47A',
    deco: {'m': 'c'},
    setting: 'an Osaka food street at dusk: red-and-cream stall awnings, '
        'glowing signboards shaped like food (no letters), takoyaki stands '
        'and a canal.',
    ground: 'warm sandy earth with a few paving-stone outlines',
    detail: 'a dropped paper lantern-shaped leaf and two pebbles',
    mountain: 'a rounded hill topped by a tiny white castle keep with a '
        'green roof',
    forest: 'two weeping willow trees by a short stretch of canal',
    city: 'a row of two narrow shopfronts with big food-shaped signboards '
        '(a crab and an octopus, no letters) and red lanterns',
    special: 'a takoyaki cart with a striped awning and a round griddle',
    landmark: 'a wooden skewer of three takoyaki balls with brown sauce, '
        'mayo zigzag and bonito flakes',
    backdrop: 'a lively street at dusk: food-shaped signboards and lanterns '
        'at the top, stall counters and the canal at the bottom, orange sky',
  ),
  Region(
    id: 'kyoto',
    en: 'Kyoto Ryokan',
    th: 'เรียวกังเกียวโต',
    kanji: '京都',
    levels: '31-45',
    top: '#E56B8F',
    bottom: '#B03A60',
    land: '#B5D18A',
    deco: {'c': 'f'},
    setting: 'old Kyoto in autumn: wooden ryokan inns, shoji screens, moss '
        'gardens, red maples, torii gates and a five-storey pagoda.',
    ground: 'soft moss-green grass',
    detail: 'two fallen red maple leaves',
    mountain: 'a soft green hill with a small five-storey pagoda on top',
    forest: 'two red maple trees and a small vermilion torii gate',
    city: 'a wooden machiya townhouse with a dark tiled roof and a green '
        'noren curtain',
    special: 'a stone lantern beside a short bamboo fence',
    landmark: 'a vermilion torii gate with a black top beam',
    backdrop: 'a ryokan veranda in autumn: maple branches and a pagoda '
        'roof at the top, a moss garden with a stone lantern at the bottom',
  ),
  Region(
    id: 'hokkaido',
    en: 'Hokkaido Crab Hut',
    th: 'กระท่อมปูฮอกไกโด',
    kanji: '北海道',
    levels: '46-60',
    top: '#6FC3C9',
    bottom: '#3A8A98',
    land: '#E8F2F4',
    deco: {'c': 'm', 'f': 'm'},
    setting: 'snowy northern Hokkaido: log huts under thick snow, smoking '
        'chimneys, a frozen sea and red crabs hung up to dry.',
    ground: 'smooth fresh snow with pale blue shading',
    detail: 'a small snow drift and tiny footprints',
    mountain: 'two snowy peaks with a dark green pine at their foot',
    forest: 'three snow-covered fir trees',
    city: 'a log hut with a thick snow roof and a smoking chimney',
    special: 'a wooden drying rack with two red crabs hanging from it',
    landmark: 'a big red snow crab with raised claws',
    backdrop: 'a log crab hut in falling snow: snowy pine branches at the '
        'top, a frozen sea with ice floes at the bottom',
  ),
  Region(
    id: 'fukuoka',
    en: 'Fukuoka Night Stall',
    th: 'แผงลอยกลางคืนฟุกุโอกะ',
    kanji: '福岡',
    levels: '61-75',
    top: '#5B5FC7',
    bottom: '#353A8C',
    land: '#C9B27E',
    deco: {'m': 'c', 'f': 'c', 'c': 'c'},
    setting: 'Fukuoka at night: rows of yatai food stalls with red lanterns '
        'along a river, steam rising from ramen pots, an indigo sky.',
    ground: 'warm stone pavement in big rounded slabs',
    detail: 'a puddle reflecting a red lantern',
    mountain: 'a low hill with a slim tower on top',
    forest: 'two round park trees with a string of small lanterns',
    city: 'a yatai food stall with a red lantern, a cloth curtain and '
        'steam rising from a pot',
    special: 'a riverside bench with a steaming ramen bowl on it',
    landmark: 'a bowl of tonkotsu ramen with chashu, egg, green onion and '
        'chopsticks',
    backdrop: 'a riverside at night: red lanterns and an indigo starry sky '
        'at the top, yatai stalls and the river at the bottom',
  ),
  Region(
    id: 'okinawa',
    en: 'Okinawa Beach Shack',
    th: 'กระท่อมชายหาดโอกินาว่า',
    kanji: '沖縄',
    levels: '76-90',
    top: '#2EC4B6',
    bottom: '#138A8A',
    land: '#F0DFAE',
    deco: {'m': 'f', 'c': 'f'},
    setting: 'a tropical Okinawa beach: turquoise sea, palm trees, hibiscus, '
        'red-tiled roofs with shisa lion statues and a straw beach shack.',
    ground: 'warm golden sand',
    detail: 'a small seashell and a starfish',
    mountain: 'a green limestone hill with a sea cave',
    forest: 'two palm trees with a red hibiscus bush',
    city: 'a small house with a red tiled roof and a shisa lion on top',
    special: 'a straw-roofed beach shack with a surfboard',
    landmark: 'a big red hibiscus flower with green leaves',
    backdrop: 'a beach shack: palm leaves and a bright sky at the top, '
        'turquoise sea and sand at the bottom',
  ),
  Region(
    id: 'omakase',
    en: 'Omakase Counter',
    th: 'เคาน์เตอร์โอมากาเสะ',
    kanji: '極',
    levels: '91-100',
    top: '#D4A537',
    bottom: '#9A6A12',
    land: '#D9C08A',
    deco: {'m': 'c', 'f': 'c'},
    setting: 'the finest omakase sushi counter: black lacquer, gold leaf, '
        'pale hinoki wood, bonsai pines and gold folding screens.',
    ground: 'pale raked gravel with fine parallel lines',
    detail: 'a single flat stepping stone',
    mountain: 'a mountain painted in gold leaf like a folding screen',
    forest: 'a neatly clipped bonsai pine on a stone',
    city: 'an elegant black-lacquer restaurant with a gold-trimmed roof and '
        'a white noren curtain',
    special: 'a hinoki counter with a chef knife on a cloth',
    landmark: 'a small golden crown on a black lacquer sushi tray',
    backdrop: 'a hinoki sushi counter: gold folding screens and hanging '
        'lights at the top, the pale wood counter at the bottom',
  ),
  Region(
    id: 'nagoya',
    en: 'Nagoya Tempura Bar',
    th: 'ร้านเทมปุระนาโกย่า',
    kanji: '名古屋',
    levels: '101-115',
    top: '#E0A030',
    bottom: '#A86E10',
    land: '#D8CF8E',
    deco: {'m': 'c'},
    setting: 'Nagoya: a castle with golden roof fish, warm wooden tempura '
        'bars and golden fried prawns.',
    ground: 'dry golden grass',
    detail: 'a few tiny yellow wildflowers',
    mountain: 'a rounded hill with terraced fields',
    forest: 'two broad zelkova trees',
    city: 'a castle keep with a green roof and two golden shachihoko fish '
        'on the ridge',
    special: 'a pot of hot oil with tempura frying in it',
    landmark: 'a golden ebi tempura prawn with a crispy coat',
    backdrop: 'a tempura bar: the castle roof and golden fish at the top, '
        'the frying counter with baskets at the bottom',
  ),
  Region(
    id: 'hiroshima',
    en: 'Hiroshima Oyster Boat',
    th: 'เรือหอยนางรมฮิโรชิมะ',
    kanji: '広島',
    levels: '116-130',
    top: '#3F8FB5',
    bottom: '#235E7F',
    land: '#B9D49A',
    deco: {'c': 'f'},
    setting: 'the calm Hiroshima bay: oyster rafts on the sea, the floating '
        'torii of Miyajima, green islands and small boats.',
    ground: 'fresh green grass with a sea breeze',
    detail: 'a small oyster shell',
    mountain: 'a green island hill',
    forest: 'a pine and a maple tree side by side',
    city: 'a fishing house on short stilts',
    special: 'a vermilion torii standing in shallow water',
    landmark: 'an open oyster shell with a round pearl inside',
    backdrop: 'an oyster boat on the bay: the floating torii and islands at '
        'the top, oyster rafts on blue water at the bottom',
  ),
  Region(
    id: 'kanazawa',
    en: 'Kanazawa Gold Bento',
    th: 'ร้านเบนโตะทองคำคานาซาวะ',
    kanji: '金沢',
    levels: '131-145',
    top: '#C9A227',
    bottom: '#8C6D0F',
    land: '#CFE0B0',
    deco: {'m': 'f'},
    setting: 'Kanazawa: a famous strolling garden with ponds and pines held '
        'up by cone-shaped snow ropes, samurai houses and gold leaf.',
    ground: 'neat garden lawn',
    detail: 'a round flat stepping stone',
    mountain: 'a moss hill with a waterfall',
    forest: 'a pine tree with yukitsuri ropes fanning down from a tall pole '
        'in a cone',
    city: 'a samurai house behind an earthen wall with a gold-leaf trim',
    special: 'a two-legged kotoji stone lantern by a little pond',
    landmark: 'a black lacquer bento box with a gold-leaf lid, slightly open',
    backdrop: 'a strolling garden: pines with snow ropes at the top, a pond '
        'with a two-legged stone lantern at the bottom',
  ),
  Region(
    id: 'sendai',
    en: 'Sendai Night Grill',
    th: 'ร้านย่างกลางคืนเซนได',
    kanji: '仙台',
    levels: '146-160',
    top: '#7A4FA8',
    bottom: '#4E2D75',
    land: '#C4D3A6',
    deco: {'c': 'f', 'f': 'm'},
    setting: 'Sendai on a summer night: charcoal grill houses, tree-lined '
        'avenues and big colourful Tanabata paper streamers.',
    ground: 'grass under a purple evening light',
    detail: 'a short strip of paper streamer',
    mountain: 'two green mountains with a stone castle wall at the foot',
    forest: 'two zelkova trees hung with long colourful Tanabata streamers',
    city: 'a grill house with smoke rising from its roof vent',
    special: 'a charcoal brazier with skewers grilling',
    landmark: 'sliced grilled beef tongue on a small charcoal grill',
    backdrop: 'a night grill: Tanabata streamers and a purple sky at the '
        'top, the charcoal grill counter at the bottom',
  ),
  Region(
    id: 'kobe',
    en: 'Kobe Harbour Bistro',
    th: 'บิสโทรท่าเรือโกเบ',
    kanji: '神戸',
    levels: '161-175',
    top: '#2F6DB5',
    bottom: '#1B467F',
    land: '#D6CDA8',
    deco: {'m': 'c', 'f': 'c'},
    setting: 'the Kobe harbour: a red lattice port tower, harbour cranes, '
        'western-style brick houses and mountains behind the port.',
    ground: 'light harbour paving in square slabs',
    detail: 'a coil of rope',
    mountain: 'a long green mountain ridge',
    forest: 'two plane trees on a promenade',
    city: 'a red lattice port tower next to a western-style brick house',
    special: 'a small white lighthouse',
    landmark: 'a golden ship anchor wrapped in rope',
    backdrop: 'a harbour bistro: the red port tower and mountains at the '
        'top, the quay with ships and water at the bottom',
  ),
  Region(
    id: 'nara',
    en: 'Nara Deer Park Teahouse',
    th: 'โรงน้ำชาสวนกวางนารา',
    kanji: '奈良',
    levels: '176-190',
    top: '#6FA84F',
    bottom: '#437A2C',
    land: '#A9CF86',
    deco: {'c': 'f', 'm': 'f'},
    setting: 'the Nara deer park: wide lawns, friendly deer, old temples '
        'with big roofs and a quiet teahouse.',
    ground: 'deer-park lawn',
    detail: 'two small deer crackers on the grass',
    mountain: 'a smooth grassy hill',
    forest: 'two old trees with a cute chibi deer resting under them',
    city: 'a large temple hall with a sweeping dark roof',
    special: 'a cute chibi deer bowing its head',
    landmark: 'a cute chibi deer holding a round shika-senbei cracker in '
        'its mouth',
    backdrop: 'a teahouse in the deer park: old tree branches and a temple '
        'roof at the top, the lawn with resting deer at the bottom',
  ),
  Region(
    id: 'ginza',
    en: 'Ginza Master Chef',
    th: 'เชฟใหญ่กินซ่า',
    kanji: '銀座',
    levels: '191-205',
    top: '#B0B7C3',
    bottom: '#6E7685',
    land: '#D8D2C4',
    deco: {'m': 'c', 'f': 'c'},
    setting: 'elegant Ginza: silver-grey stone buildings, a clock tower on '
        'a corner, tidy street trees and a master chef counter.',
    ground: 'smooth light stone pavement',
    detail: 'a small round drain cover',
    mountain: 'a distant city skyline on a hill',
    forest: 'two neatly trimmed street trees in planters',
    city: 'a rounded stone corner building with a clock tower (generic, no '
        'brand)',
    special: 'a lamp post with a hanging flower basket',
    landmark: 'a shining silver-and-gold star wearing a small white chef hat',
    backdrop: 'a master chef counter: the clock tower and evening sky at '
        'the top, a polished counter with a knife roll at the bottom',
  ),
];

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
