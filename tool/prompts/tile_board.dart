part of '../gen_tile_prompts.dart';

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
