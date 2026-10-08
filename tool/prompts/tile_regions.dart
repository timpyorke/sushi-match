part of '../gen_tile_prompts.dart';

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
