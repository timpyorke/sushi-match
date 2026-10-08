part of '../gen_icon_prompts.dart';

// ---------------------------------------------------------------------------
// Obstacles: goal chips in the order card and the first-time tip popup.

const _obstacles = Doc(
  file: 'obstacles',
  title: 'obstacle and goal icons',
  intro: 'Small icons for the goal chips in the order card (`GoalCount._icon` '
      'in `lib/ui/customer_order.dart`, 16-20 pt on a white chip) and the '
      'first-time tip popup (`_tipFor` in `lib/main.dart`, 40 pt on the '
      'wooden panel). They are icon versions of the board tiles in '
      '[../tiles/board.md](../tiles/board.md), so they share its colours.',
  folder: 'assets/ui/obstacles',
  out: 192,
  styleRef: 'assets/sprites/boosters/chopsticks.png',
  theme: 'Setting: a sushi-restaurant match-3 puzzle game. Each icon stands '
      'for one board obstacle or goal and has to read on a small white goal '
      'chip as well as on a light wooden panel.',
  view: 'Each icon a standalone object in a slight three-quarter front view.',
  wiring: 'Replace the `Text` emoji in `GoalCount._icon` and the emoji field '
      'of `_tipFor` / `TipOverlay` with `Image.asset`.',
  palette: {
    'nori': '#1F3A24',
    'ice': '#AEE1FA',
    'sack': '#E9D3A8',
    'sack cord': '#B5472F',
    'bamboo': '#CDB872',
    'flame': '#FF8A2A / #FFD24A',
    'cat fur': '#2B2B33',
    'cat eyes': '#F5D33B',
    'gold': '#E0A84A',
    'bomb': '#2B211C',
  },
  sheets: [
    Sheet(name: 'layers', title: 'Layer obstacles', icons: [
      Icon(
          'nori',
          '🌿',
          'two small square sheets of toasted nori seaweed stacked at a '
              'slight angle: deep green-black #1F3A24 with a few darker '
              'crinkle strokes and a thin lighter green edge so the dark '
              'shape still reads on a dark chip.'),
      Icon(
          'ice',
          '🧊',
          'a chunky rounded cube of pale blue ice #AEE1FA with frosted white '
              'edges, one small crack and one white glint.'),
      Icon(
          'bag',
          '🌾',
          'a small round rice sack of cream burlap #E9D3A8 with a darker '
              '#D1B47F fold shadow, tied at the neck with a red #B5472F cord, '
              'one brown dot on the front and three white rice grains at its '
              'foot.'),
      Icon(
          'mat',
          '🎋',
          'a bamboo sushi-rolling mat (makisu) half rolled up: pale bamboo '
              'slats #CDB872 with darker slat lines and two thin green '
              'cords.'),
    ]),
    Sheet(name: 'hazards', title: 'Hazards', icons: [
      Icon(
          'fire',
          '🔥',
          'a cartoon flame of three rounded tongues: orange #FF8A2A outside, '
              'yellow #FFD24A core, one red shadow tone.'),
      Icon(
          'cat',
          '🐱',
          'the head of a mischievous chibi black stray cat #2B2B33 from the '
              'thieving cat gang: big yellow #F5D33B eyes, a sly grin, a fish '
              'bone held in its mouth, one ear slightly nicked.'),
      Icon(
          'key',
          '🔑',
          'a chunky gold #E0A84A key with a round bow, crossed in front of a '
              'small white #FFFFFF and light grey #D9D9D9 padlock.'),
      Icon(
          'bomb',
          '💣',
          'a round black #2B211C cartoon bomb with a short fuse and a small '
              'orange spark on top and a blank round cream label on its '
              'front; no number.'),
    ]),
    Sheet(name: 'rules', title: 'Board rules and delivery', icons: [
      Icon(
          'portal',
          '🌀',
          'a round swirling portal seen slightly from above: spiral arms '
              'from light lavender #C9B6F2 on the rim to deep indigo #3B2F7A '
              'in the centre, with a thin notched ring round it like a magic '
              'circle.'),
      Icon(
          'conveyor',
          '➡️🔒',
          'a short straight piece of sushi conveyor belt: grey-blue belt on '
              'a red lacquer #8E2A22 rail with a gold #E0A84A trim, one '
              'salmon nigiri plate on it and a chunky cream arrow printed on '
              'the belt pointing right.'),
      Icon(
          'gravity',
          '↔️',
          'a round cream badge with a big chunky dark-brown #4A2E1B arrow '
              'pointing to the right and two short speed lines behind it, a '
              'tiny salmon nigiri riding the arrow head.'),
      Icon(
          'deliver',
          '🍙',
          'a triangle rice ball (onigiri) with a nori band at the bottom and '
              'a tiny cute face (dot eyes, small smile, pink blush), the same '
              'onigiri as the board delivery item.'),
    ]),
  ],
);

// ---------------------------------------------------------------------------
// Restaurants: the icon on each restaurant banner of the level map.

const _shops = Doc(
  file: 'shops',
  title: 'restaurant icons',
  intro: 'One icon per restaurant in `Restaurant.shops` '
      '(`lib/services/restaurant.dart`), shown at 24 pt on the left of its '
      'banner on the level map (`ShopBanner` in `lib/ui/map/tile_map.dart`). '
      'The banner is a gradient in the region colour with a white border, '
      'so each icon carries a thin white outer rim and a main colour that '
      'stands out from its banner.',
  folder: 'assets/ui/shops',
  out: 192,
  styleRef: 'assets/sprites/boosters/chopsticks.png',
  theme: 'Setting: the restaurant badges of a sushi-restaurant puzzle game, '
      'one per region of Japan. Every icon gets a thin white outer rim '
      'outside its dark-brown outline so it reads on a coloured banner.',
  view: 'Each icon a standalone emblem in a slight three-quarter front view, '
      'filling its cell about evenly so the set looks the same size.',
  wiring: 'Swap `ShopDef.emoji` for an asset path (or look it up by '
      '`shop.id`) and draw it with `Image.asset` in `ShopBanner`.',
  sheets: [
    Sheet(name: 'shops_a', title: 'Tsukiji to Hokkaido', icons: [
      Icon(
          'tsukiji',
          '🐟',
          'Tsukiji Fish Market (banner blue #4FA3D1): a plump glossy tuna, '
              'dark blue back and silver-white belly, lying on a small '
              'wooden crate of crushed ice; the fish in warm silver so it '
              'stands out from the blue banner.'),
      Icon(
          'osaka',
          '🍢',
          'Osaka Street Stall (banner orange #F08A3C): three golden-brown '
              'kushikatsu skewers fanned out, the crumbed balls with a glossy '
              'dark sauce drip and pale bamboo sticks.'),
      Icon(
          'kyoto',
          '⛩️',
          'Kyoto Ryokan (banner pink #E56B8F): a small vermilion #D9412B '
              'torii gate with black top beams, two pink cherry blossoms on '
              'one post.'),
      Icon(
          'hokkaido',
          '🦀',
          'Hokkaido Crab Hut (banner teal #6FC3C9): a chubby red king crab '
              'with raised claws and a little cap of white snow on its '
              'shell.'),
    ]),
    Sheet(name: 'shops_b', title: 'Fukuoka to Nagoya', icons: [
      Icon(
          'fukuoka',
          '🍜',
          'Fukuoka Night Stall (banner indigo #5B5FC7): a red-and-black '
              'ramen bowl of creamy tonkotsu broth with noodles, a chashu '
              'slice, half a soft egg and a pair of chopsticks resting on the '
              'rim.'),
      Icon(
          'okinawa',
          '🌺',
          'Okinawa Beach Shack (banner turquoise #2EC4B6): a big red '
              'hibiscus flower with a yellow stamen and two glossy green '
              'leaves.'),
      Icon(
          'omakase',
          '👑',
          'Omakase Counter (banner gold #D4A537): a small chef\'s crown in '
              'deep red lacquer with a gold rim and one white pearl, so it '
              'stands out from the gold banner.'),
      Icon(
          'nagoya',
          '🍤',
          'Nagoya Tempura Bar (banner amber #E0A030): a long ebi tempura '
              'prawn in crisp pale-gold batter with a red tail, lying on a '
              'small white paper.'),
    ]),
    Sheet(name: 'shops_c', title: 'Hiroshima to Kobe', icons: [
      Icon(
          'hiroshima',
          '🦪',
          'Hiroshima Oyster Boat (banner blue #3F8FB5): an open rough grey '
              'oyster shell with a plump cream oyster and a lemon wedge.'),
      Icon(
          'kanazawa',
          '🍱',
          'Kanazawa Gold Bento (banner gold #C9A227): a black lacquer bento '
              'box seen from above at an angle, four compartments of sushi, '
              'egg and pickles, with a few flakes of gold leaf; black and red '
              'so it stands out from the gold banner.'),
      Icon(
          'sendai',
          '🍖',
          'Sendai Night Grill (banner purple #7A4FA8): a skewer of thick '
              'grilled beef-tongue slices with dark grill marks and a small '
              'green negi leek on the side.'),
      Icon(
          'kobe',
          '⚓',
          'Kobe Harbour Bistro (banner navy #2F6DB5): a chunky gold #E0A84A '
              'ship anchor wrapped with a cream rope.'),
    ]),
    Sheet(name: 'shops_d', title: 'Nara and Ginza', icons: [
      Icon(
          'nara',
          '🦌',
          'Nara Deer Park Teahouse (banner green #6FA84F): the head of a '
              'cute chibi sika deer, light brown with white spots and small '
              'antlers, nibbling a round shika-senbei cracker.'),
      Icon(
          'ginza',
          '🌟',
          'Ginza Master Chef (banner silver #B0B7C3): a gold master-chef '
              'medal: a five-pointed gold star on a round gold disc, hung on '
              'a red-and-white ribbon; different from a plain rating star.'),
    ]),
  ],
);

// ---------------------------------------------------------------------------
// Furniture: what the player buys for their restaurant.

const _furniture = Doc(
  file: 'furniture',
  title: 'restaurant furniture',
  intro: 'The furniture bought with stars in the restaurant screen '
      '(`Restaurant.furniture` in `lib/services/restaurant.dart`, drawn in '
      '`lib/ui/restaurant_screen.dart`): 44 pt once owned, a faded 22 pt '
      'preview in the buy bubble before that. Larger than the other icons, '
      'so they get a little more detail.',
  folder: 'assets/sprites/furniture',
  out: 256,
  styleRef: 'assets/sprites/boosters/chopsticks.png',
  theme: 'Setting: furniture and decorations for a cosy anime sushi bar with '
      'warm wooden floors, bought one piece at a time by the player. Each '
      'piece stands on its own on the floor.',
  view: 'Each piece a standalone object in a slight three-quarter front '
      'view, standing upright with a flat base at the bottom of its cell.',
  wiring: 'Swap `FurnitureDef.emoji` for an asset path (or look it up by '
      '`furniture.id`) and draw it with `Image.asset` in the furniture slot '
      'of `restaurant_screen.dart`.',
  palette: {
    'red lacquer': '#C8372D',
    'honey wood': '#C98B4E',
    'indigo': '#2C3E73',
    'gold': '#E0A84A',
  },
  sheets: [
    Sheet(name: 'furniture_a', title: 'Starter pieces', icons: [
      Icon(
          'lantern',
          '🏮',
          'a round red #C8372D paper chochin lantern with black top and '
              'bottom caps, a few curved rib lines and a short hanging cord; '
              'no lettering.'),
      Icon(
          'stool',
          '🪑',
          'a round wooden counter stool in honey wood #C98B4E with four '
              'short legs, a cross brace and a red cushion on the seat.'),
      Icon(
          'noren',
          '🎏',
          'a short split doorway curtain (noren) of three indigo #2C3E73 '
              'cloth panels with a white wave pattern along the bottom, hung '
              'from a bamboo rod.'),
      Icon(
          'sign',
          '🪧',
          'a wooden shop sign board (kanban) under a tiny tiled roof, '
              'standing on two posts: a cream plaque painted with a red fish '
              'shape; no letters.'),
    ]),
    Sheet(name: 'furniture_b', title: 'Mid-game pieces', icons: [
      Icon(
          'plant',
          '🪴',
          'a small bonsai pine with rounded cloud-shaped green foliage in a '
              'shallow indigo glazed pot.'),
      Icon(
          'luckycat',
          '🐱',
          'a maneki-neko figurine: white ceramic cat sitting upright with '
              'one paw raised, red collar with a gold bell, holding a gold '
              'oval koban coin; a figurine, not a living cat.'),
      Icon(
          'aquarium',
          '🐠',
          'a small rectangular glass fish tank on a wooden stand, pale blue '
              'water, two orange fish, green water weed and a few bubbles.'),
      Icon(
          'conveyor',
          '🍣',
          'a short curved piece of sushi conveyor belt on a wooden counter '
              'base with two coloured plates riding it: salmon nigiri on a '
              'blue plate and tuna nigiri on a red plate.'),
    ]),
    Sheet(name: 'furniture_c', title: 'Late-game pieces', icons: [
      Icon(
          'kadomatsu',
          '🎍',
          'a kadomatsu: three diagonally cut green bamboo stalks of '
              'different heights with pine sprigs and small red plum '
              'blossoms, in a straw-wrapped base tied with rope.'),
      Icon(
          'taiko',
          '🥁',
          'a barrel taiko drum on a low wooden stand: brown wooden body, '
              'cream drumheads with a ring of metal studs, two bachi sticks '
              'crossed in front.'),
      Icon(
          'sake',
          '🍶',
          'a komodaru sake barrel wrapped in white woven straw with a bold '
              'red circle crest and blue bands instead of lettering, a wooden '
              'lid and a wooden ladle resting on top.'),
      Icon(
          'trophy',
          '🏆',
          'a gold #E0A84A trophy cup with two handles on a black lacquer '
              'base, a red ribbon tied round the stem and a tiny salmon '
              'nigiri on the lid.'),
    ]),
  ],
);

// ---------------------------------------------------------------------------
// UI: the few remaining emoji in dialogs.

const _ui = Doc(
  file: 'ui',
  title: 'UI icons',
  intro: 'The last emoji in the dialogs. 🪙, ❤️, ⭐ and the booster emoji '
      'already have art (`UiArt.coin`, `UiArt.heart`, `UiArt.star`, '
      '`BoosterIcon` in `lib/ui/ui_art.dart`), so only these are new: three '
      'dialog icons and eight controls that are still Material `Icons`. '
      'They sit next to `assets/ui/heart.png`, so they follow its look.',
  folder: 'assets/ui',
  out: 192,
  styleRef: 'assets/ui/heart.png',
  theme: 'Setting: the dialog icons of a sushi-restaurant puzzle game, shown '
      'next to its glossy red heart and gold coin and star icons.',
  view: 'Each icon a standalone object, straight front view.',
  wiring: 'Replace 🎁 in `daily_reward_dialog.dart`, `event_banner.dart` and '
      '`event_dialog.dart`, 💔 in `lives_ui.dart`, ✅ in '
      '`daily_reward_dialog.dart` and `event_dialog.dart`, and use the '
      'existing art for 🪙 ❤️ ⭐ and the boosters. The controls go through '
      '`UiArt.control(UiControl.back)` and friends, which draw the Material '
      'icon until the file exists, so each can be dropped in on its own.',
  sheets: [
    Sheet(name: 'ui', title: 'Dialog icons', icons: [
      Icon(
          'gift',
          '🎁',
          'a square gift box in red #D8402E with a gold #E8B13C ribbon and a '
              'big bow on top, the lid lifted a little.'),
      Icon(
          'heart_broken',
          '💔',
          'the same glossy red heart as the reference, cracked down the '
              'middle with a zigzag split and the two halves leaning a little '
              'apart.'),
      Icon(
          'check',
          '✅',
          'a chunky green #4CAF50 tick mark on a round cream badge with a '
              'thin gold rim.'),
    ]),
    Sheet(name: 'controls', title: 'Controls', icons: [
      Icon(
          'back',
          '←',
          'a chunky cream arrow pointing left with a red #B71C2C outline-shade, '
              'rounded ends.'),
      Icon(
          'settings',
          '⚙',
          'a chunky round cog in warm grey with a red #B71C2C centre hole and '
              'a white highlight.'),
      Icon('close', '✕',
          'a chunky cream cross with rounded ends and a red #B71C2C shade.'),
      Icon('plus', '＋',
          'a chunky gold #FFD54F plus sign on a round red #B71C2C badge.'),
    ]),
    Sheet(name: 'controls2', title: 'More controls', icons: [
      Icon('sound_on', '🔊',
          'a cute cream speaker with two curved red sound waves.'),
      Icon('sound_off', '🔇',
          'the same speaker with a red cross instead of the waves.'),
      Icon('lock', '🔒',
          'a chunky gold padlock with a red keyhole, closed shackle.'),
      Icon(
          'chevron',
          '›',
          'a chunky cream chevron pointing right with a red shade, rounded '
              'ends.'),
    ]),
  ],
);
