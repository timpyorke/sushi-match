// ignore_for_file: avoid_print
// Writes assets/levels/level_NNN.json for levels 61+ from the table below, so a
// new level is one row, not a hand-typed 9x9 grid. Existing files are never
// overwritten (pass --force to do so). Goal counts, moves and stars written
// here are placeholders: run `dart run tool/tune.dart [runs] <levels> --write`
// afterwards to fit them to the difficulty curve.
//
//   dart run tool/gen_levels.dart [--force] [level ...]
//
// Feature syntax (all optional, space separated in `feat`):
//   ice:<pat>[:layers]  nori:<pat>[:layers]  bag:<pat>[:layers]  mat:<pat>
//   fire:<n>  cat:<n>[:hp]  key:<kind>[:n]  bomb:<n>[:timer]  portal:<n>
//   belt:<row><l|r>,..  grav:<down|up|left|right>
// Patterns: c1 c3 cross ring corners sides rows scatter(n via `:n` ignored).
import 'dart:convert';
import 'dart:io';

const _six = ['salmon', 'maguro', 'tamago', 'ikura', 'ebi', 'kappa'];
const _beach = ['salmon', 'maguro', 'tamago', 'ikura', 'hotate', 'kappa'];
const _deep = ['salmon', 'maguro', 'tamago', 'unagi', 'ebi', 'kappa'];
const _squid = ['salmon', 'maguro', 'tamago', 'ika', 'ebi', 'kappa'];
const _octo = ['salmon', 'maguro', 'tako', 'ikura', 'ebi', 'kappa'];
const _harbor = ['salmon', 'unagi', 'tamago', 'ika', 'hotate', 'kappa'];
const _deer = ['maguro', 'tako', 'tamago', 'ikura', 'hotate', 'ika'];
const _ginza = ['salmon', 'maguro', 'unagi', 'hotate', 'ika', 'tako'];

/// Board shapes. Voids only sit at the ends of rows and columns, so pieces
/// can fall (or slide, for sideways gravity) into every open cell.
const _shapes = {
  'full9': [
    '.........', '.........', '.........', '.........', '.........', //
    '.........', '.........', '.........', '.........',
  ],
  'corner9': [
    'XX.....XX', 'X.......X', '.........', '.........', '.........', //
    '.........', '.........', 'X.......X', 'XX.....XX',
  ],
  'diamond9': [
    'XXX...XXX', 'XX.....XX', 'X.......X', '.........', '.........', //
    '.........', 'X.......X', 'XX.....XX', 'XXX...XXX',
  ],
  'square8': [
    '........', '........', '........', '........', //
    '........', '........', '........', '........',
  ],
  // Wide on top, narrow at the bottom.
  'tee9': [
    '.........', '.........', '.........', '.........', '.........', //
    'XX.....XX', 'XX.....XX', 'XX.....XX', 'XX.....XX',
  ],
  // Narrow on top, wide at the bottom.
  'cup9': [
    'XX.....XX', 'XX.....XX', 'XX.....XX', 'XX.....XX', '.........', //
    '.........', '.........', '.........', '.........',
  ],
  'octa8': [
    'XXX..XXX', 'XX....XX', 'X......X', '........', '........', //
    'X......X', 'XX....XX', 'XXX..XXX',
  ],
};

class Spec {
  const Spec(this.id, this.shape, this.goals,
      {this.feat = '', this.pieces = _six, this.moves = 40});

  /// Short form used from level 101: shape, goals, features, pieces.
  const Spec.of(this.id, this.shape, this.goals, this.feat, this.pieces)
      : moves = 40;
  final int id;
  final String shape;

  /// `c:<kind>:<n>` collect, `s:<n>` score, `deliver:<n>`, or one of
  /// `nori ice bag mat fire cats` (count comes from the layout).
  final List<String> goals;
  final String feat;
  final List<String> pieces;
  final int moves;
}

// 61-75 Fukuoka (night stalls): two mechanics at a time.
// 76-90 Okinawa (islands): sideways gravity, portals, bombs.
// 91-100 Omakase: three or four mechanics, boss at 100.
// 101-200: seven more restaurants, each themed in the comments below.
// Every 5th level is a hard one, every 15th a boss (see tool/tune.dart);
// past 100 the bosses close each 15-level restaurant (115, 130 ... 190).
const specs = <Spec>[
  Spec(61, 'corner9', ['ice', 'c:salmon:40'], feat: 'ice:cross belt:3l,5r'),
  Spec(62, 'full9', ['cats', 'c:kappa:36', 'c:ikura:36'],
      feat: 'cat:2 belt:4r'),
  Spec(63, 'diamond9', ['nori', 's:9000'], feat: 'nori:ring'),
  Spec(64, 'corner9', ['bag', 'fire', 'c:maguro:36'],
      feat: 'bag:corners fire:2'),
  Spec(65, 'full9', ['ice', 'c:tamago:40', 'c:ebi:40'],
      feat: 'ice:c3:2 key:maguro:2'),
  Spec(66, 'octa8', ['deliver:3', 'c:salmon:14', 'c:ebi:14']),
  Spec(67, 'corner9', ['mat', 's:11000'], feat: 'mat:c1 belt:2r,6l'),
  Spec(68, 'diamond9', ['cats', 'ice', 'c:kappa:36'], feat: 'cat:1:2 ice:rows'),
  Spec(69, 'full9', ['ice', 'c:salmon:45', 'c:kappa:45'],
      feat: 'ice:c3:2 grav:left'),
  Spec(70, 'corner9', ['nori', 'c:ikura:40', 'c:tamago:40'],
      feat: 'nori:cross bomb:2:10'),
  Spec(71, 'full9', ['ice', 'c:ikura:50', 'c:maguro:50'],
      feat: 'ice:sides portal:2'),
  Spec(72, 'diamond9', ['fire', 'c:ebi:40', 's:10000'],
      feat: 'fire:3 belt:3r,5l'),
  Spec(73, 'corner9', ['bag', 'cats', 'c:salmon:45'],
      feat: 'bag:corners:2 cat:1'),
  Spec(74, 'octa8', ['deliver:3', 'c:maguro:14', 'c:kappa:14'],
      feat: 'belt:4r'),
  Spec(75, 'corner9', ['nori', 'ice', 'cats', 'c:kappa:40'],
      feat: 'nori:ring ice:c1:2 cat:1 belt:2l,6r'),
  Spec(76, 'full9', ['c:salmon:50', 'c:hotate:50', 's:12000'],
      feat: 'grav:right', pieces: _beach),
  Spec(77, 'corner9', ['ice', 'c:ikura:50'],
      feat: 'ice:ring grav:up', pieces: _beach),
  Spec(78, 'diamond9', ['nori', 'c:tamago:50'],
      feat: 'nori:sides portal:1', pieces: _beach),
  Spec(79, 'corner9', ['c:maguro:40', 'c:kappa:40', 'c:ikura:40'],
      feat: 'key:kappa:2 key:salmon:2 belt:4l', pieces: _beach),
  Spec(80, 'full9', ['cats', 'c:salmon:40', 'c:tamago:40'],
      feat: 'cat:1:2 bomb:3:10', pieces: _beach),
  Spec(81, 'diamond9', ['nori', 'fire'],
      feat: 'nori:c3 fire:2 grav:left', pieces: _beach),
  Spec(82, 'octa8', ['deliver:4', 'c:ikura:14'], pieces: _beach),
  Spec(83, 'corner9', ['mat', 'c:hotate:40'],
      feat: 'mat:corners portal:1', pieces: _beach),
  Spec(84, 'full9', ['bag', 'ice', 'c:kappa:44'],
      feat: 'bag:corners ice:c3 grav:right', pieces: _beach),
  Spec(85, 'diamond9', ['cats', 'c:salmon:40', 'c:maguro:40'],
      feat: 'cat:2:2 key:tamago:2 belt:2r,6l', pieces: _beach),
  Spec(86, 'corner9', ['fire', 'c:kappa:45'],
      feat: 'fire:2 grav:up', pieces: _beach),
  Spec(87, 'full9', ['cats', 'c:ikura:44', 's:13000'],
      feat: 'cat:2', pieces: _beach),
  Spec(88, 'diamond9', ['nori', 'ice', 'c:hotate:44'],
      feat: 'nori:ring:2 ice:c1', pieces: _beach),
  Spec(89, 'corner9', ['bag', 'c:maguro:45', 'c:salmon:45'],
      feat: 'bag:corners:2 key:hotate:2 grav:left', pieces: _beach),
  Spec(90, 'full9', ['cats', 'c:tamago:40', 'c:kappa:40', 'c:ikura:40'],
      feat: 'cat:2:2 bomb:2:9 key:salmon:2 grav:right', pieces: _beach),
  Spec(91, 'corner9', ['nori', 'ice', 'c:salmon:44'],
      feat: 'nori:ring ice:c3:2', pieces: _deep),
  Spec(92, 'diamond9', ['mat', 'c:ebi:50', 's:14000'],
      feat: 'mat:c1 belt:3r,5l', pieces: _deep),
  Spec(93, 'full9', ['cats', 'c:unagi:46', 'c:maguro:46'],
      feat: 'cat:2 grav:up belt:3r,5l', pieces: _deep),
  Spec(94, 'corner9', ['bag', 'fire', 'c:tamago:44'],
      feat: 'bag:corners:2 fire:2', pieces: _deep),
  Spec(95, 'diamond9', ['nori', 'c:salmon:44', 'c:ebi:44'],
      feat: 'nori:cross bomb:2:9 belt:3l,5r', pieces: _deep),
  Spec(96, 'full9', ['ice', 'cats', 'c:kappa:46'],
      feat: 'ice:ring:2 cat:1 portal:2', pieces: _deep),
  Spec(97, 'corner9', ['mat', 'fire', 'c:maguro:44'],
      feat: 'mat:c1 fire:2 grav:left', pieces: _deep),
  Spec(98, 'diamond9', ['nori', 'ice', 'bag', 'c:unagi:44'],
      feat: 'nori:sides ice:c1:2 bag:corners', pieces: _deep),
  Spec(99, 'full9', ['cats', 'c:salmon:42', 'c:ebi:42', 'c:tamago:42'],
      feat: 'cat:2:2 key:maguro:2 bomb:2:9 belt:2r,6l', pieces: _deep),
  Spec(100, 'full9', ['nori', 'ice', 'cats', 'c:kappa:44', 's:16000'],
      feat: 'nori:ring ice:c3:2 cat:2:2 grav:right belt:2r,6l', pieces: _deep),
  // 101-115 Nagoya (tempura bar): squid joins, new board shapes, recap.
  Spec.of(101, 'square8', ['c:ika:30', 'c:salmon:30'], '', _squid),
  Spec.of(102, 'tee9', ['nori', 'c:ika:36'], 'nori:c3', _squid),
  Spec.of(103, 'cup9', ['ice', 'c:tamago:36'], 'ice:cross', _squid),
  Spec.of(104, 'full9', ['c:ika:40', 'c:ebi:40'], 'belt:3r,5l', _squid),
  Spec.of(
      105, 'corner9', ['ice', 'cats', 'c:ika:40'], 'ice:ring cat:1', _squid),
  Spec.of(106, 'square8', ['deliver:3', 'c:ika:14'], '', _squid),
  Spec.of(107, 'tee9', ['fire', 'c:maguro:40'], 'fire:2', _squid),
  Spec.of(108, 'diamond9', ['bag', 'c:kappa:40'], 'bag:corners', _squid),
  Spec.of(109, 'cup9', ['nori', 'c:ika:40'], 'nori:ring key:salmon:2', _squid),
  Spec.of(110, 'full9', ['cats', 'c:ika:40', 'c:tamago:40'], 'cat:2 bomb:2:10',
      _squid),
  Spec.of(111, 'octa8', ['mat', 'c:ebi:36'], 'mat:c1', _squid),
  Spec.of(112, 'tee9', ['ice', 'c:salmon:44'], 'ice:sides:2 grav:left', _squid),
  Spec.of(113, 'corner9', ['nori', 'c:ika:40', 's:12000'],
      'nori:cross portal:1', _squid),
  Spec.of(114, 'square8', ['fire', 'c:kappa:40'], 'fire:2 belt:3l', _squid),
  Spec.of(115, 'full9', ['nori', 'ice', 'cats', 'c:ika:44'],
      'nori:ring ice:c3:2 cat:1:2 belt:2r,6l', _squid),
  // 116-130 Hiroshima (oyster boat): thick blockers, two and three layers.
  Spec.of(116, 'full9', ['ice', 'c:maguro:40'], 'ice:c3:3', _squid),
  Spec.of(117, 'corner9', ['nori', 'c:ika:40'], 'nori:ring:2', _squid),
  Spec.of(118, 'tee9', ['bag', 'c:salmon:40'], 'bag:corners:3', _squid),
  Spec.of(119, 'diamond9', ['ice', 'nori', 'c:ebi:40'],
      'ice:cross:2 nori:corners:2', _squid),
  Spec.of(120, 'cup9', ['ice', 'c:ika:44', 'c:ebi:44'],
      'ice:rows:2 key:tamago:2', _squid),
  Spec.of(121, 'square8', ['bag', 'ice', 'c:kappa:40'],
      'bag:corners:2 ice:c1:3', _squid),
  Spec.of(
      122, 'full9', ['nori', 'c:tamago:44'], 'nori:rows:2 grav:right', _squid),
  Spec.of(123, 'octa8', ['deliver:4', 'c:salmon:14'], 'belt:3r', _squid),
  Spec.of(124, 'corner9', ['mat', 'ice', 'c:salmon:40'], 'mat:corners ice:c3:2',
      _squid),
  Spec.of(125, 'diamond9', ['bag', 'cats', 'c:ika:44'], 'bag:corners:3 cat:1:2',
      _squid),
  Spec.of(126, 'tee9', ['fire', 'ice', 'c:maguro:40'], 'fire:2 ice:sides:2',
      _squid),
  Spec.of(
      127, 'full9', ['nori', 'c:ebi:44', 's:13000'], 'nori:cross:3', _squid),
  Spec.of(128, 'cup9', ['ice', 'c:ika:44'], 'ice:ring:3 portal:1', _squid),
  Spec.of(129, 'square8', ['bag', 'c:tamago:44'], 'bag:corners:2 bomb:1:12',
      _squid),
  Spec.of(130, 'full9', ['nori', 'ice', 'bag', 'c:ika:46'],
      'bag:corners:2 nori:sides:2 ice:c3:3 belt:2l,6r', _squid),
  // 131-145 Kanazawa (gold-leaf bento): octopus joins; deliveries and locks.
  Spec.of(131, 'square8', ['c:tako:30', 'c:ikura:30'], '', _octo),
  Spec.of(132, 'octa8', ['deliver:3', 'c:tako:14'], '', _octo),
  Spec.of(133, 'corner9', ['c:tako:40', 'c:maguro:40'],
      'key:tako:2 key:salmon:2', _octo),
  Spec.of(
      134, 'diamond9', ['nori', 'c:tako:40'], 'nori:ring key:ikura:2', _octo),
  Spec.of(135, 'square8', ['deliver:4', 'c:tako:20'], 'key:maguro:2 belt:4r',
      _octo),
  Spec.of(136, 'tee9', ['ice', 'c:ebi:40'], 'ice:cross key:kappa:2', _octo),
  Spec.of(137, 'square8', ['deliver:3', 'c:ikura:16'], 'belt:3r', _octo),
  Spec.of(138, 'cup9', ['nori', 'c:tako:44'], 'nori:c3:2 key:tako:2', _octo),
  Spec.of(139, 'octa8', ['deliver:4', 'c:salmon:14', 'c:ebi:14'], 'key:kappa:1',
      _octo),
  Spec.of(140, 'full9', ['cats', 'c:tako:40', 'c:ikura:40'],
      'cat:2 key:salmon:2 key:ebi:2', _octo),
  Spec.of(141, 'corner9', ['bag', 'c:maguro:44'], 'bag:corners:2 key:tako:2',
      _octo),
  Spec.of(142, 'square8', ['deliver:2', 'fire', 'c:ikura:14'], 'fire:1', _octo),
  Spec.of(143, 'diamond9', ['ice', 'c:tako:44', 's:13000'],
      'ice:ring:2 key:ikura:2 grav:left', _octo),
  Spec.of(
      144, 'octa8', ['deliver:4', 'c:kappa:16'], 'key:tako:2 belt:4l', _octo),
  Spec.of(145, 'full9', ['nori', 'c:tako:44', 'c:maguro:44', 'c:ebi:44'],
      'nori:ring:2 key:salmon:2 key:ikura:2 bomb:2:9', _octo),
  // 146-160 Sendai (night grill): cats, fire and bombs keep up the pressure.
  Spec.of(146, 'full9', ['cats', 'c:tako:40'], 'cat:2', _octo),
  Spec.of(147, 'corner9', ['fire', 'c:salmon:40'], 'fire:3', _octo),
  Spec.of(148, 'tee9', ['c:tako:40', 'c:ebi:40'], 'bomb:2:12', _octo),
  Spec.of(
      149, 'diamond9', ['cats', 'fire', 'c:tako:40'], 'cat:1:2 fire:2', _octo),
  Spec.of(150, 'square8', ['fire', 'c:ikura:44'], 'fire:2 bomb:2:10', _octo),
  Spec.of(151, 'cup9', ['cats', 'c:maguro:44'], 'cat:2:2', _octo),
  Spec.of(152, 'full9', ['fire', 'c:tako:44', 's:13000'], 'fire:3 belt:3r,5l',
      _octo),
  Spec.of(
      153, 'corner9', ['cats', 'ice', 'c:kappa:40'], 'cat:1:2 ice:c3:2', _octo),
  Spec.of(154, 'octa8', ['deliver:3', 'c:tako:14'], 'bomb:1:10', _octo),
  Spec.of(155, 'full9', ['cats', 'fire', 'c:salmon:44'],
      'cat:2 fire:2 bomb:1:10', _octo),
  Spec.of(156, 'tee9', ['nori', 'fire'], 'nori:ring fire:2', _octo),
  Spec.of(157, 'diamond9', ['cats', 'c:tako:44', 'c:ikura:44'],
      'cat:2:2 grav:up', _octo),
  Spec.of(
      158, 'square8', ['fire', 'c:ebi:44'], 'fire:2 bomb:2:9 belt:3l', _octo),
  Spec.of(159, 'cup9', ['cats', 'bag', 'c:maguro:44'], 'cat:1:2 bag:corners:2',
      _octo),
  Spec.of(160, 'full9', ['cats', 'fire', 'c:tako:44', 'c:kappa:44'],
      'cat:2:2 fire:3 bomb:2:9 belt:2r,6l', _octo),
  // 161-175 Kobe (harbour bistro): gravity, portals and conveyors.
  Spec.of(161, 'full9', ['c:hotate:40', 'c:ika:40'], 'grav:left', _harbor),
  Spec.of(
      162, 'corner9', ['c:unagi:40', 's:12000'], 'portal:1 belt:3r', _harbor),
  Spec.of(163, 'full9', ['ice', 'c:salmon:44'], 'ice:c3:2 portal:2', _harbor),
  Spec.of(
      164, 'diamond9', ['nori', 'c:hotate:44'], 'nori:cross grav:up', _harbor),
  Spec.of(165, 'tee9', ['c:unagi:44', 'c:tamago:44'], 'grav:right belt:2l,4r',
      _harbor),
  Spec.of(166, 'cup9', ['ice', 'c:ika:44'], 'ice:ring portal:1', _harbor),
  Spec.of(167, 'square8', ['c:hotate:40', 'c:kappa:40'], 'grav:up belt:2r,5l',
      _harbor),
  Spec.of(168, 'full9', ['cats', 'c:unagi:44'], 'cat:2 portal:2', _harbor),
  Spec.of(169, 'corner9', ['nori', 'c:salmon:44'],
      'nori:ring grav:left belt:4r', _harbor),
  Spec.of(170, 'full9', ['ice', 'c:ika:44', 'c:hotate:44'],
      'ice:sides:2 portal:2 belt:4l', _harbor),
  Spec.of(
      171, 'diamond9', ['fire', 'c:tamago:44'], 'fire:2 grav:right', _harbor),
  Spec.of(172, 'octa8', ['deliver:4', 'c:unagi:14'], 'belt:3r,4l', _harbor),
  Spec.of(
      173, 'tee9', ['bag', 'c:hotate:44'], 'bag:corners:2 grav:up', _harbor),
  Spec.of(174, 'square8', ['ice', 'c:ika:44'], 'ice:c3:2 portal:1 belt:2l',
      _harbor),
  Spec.of(175, 'full9', ['nori', 'cats', 'c:unagi:44', 'c:hotate:44'],
      'nori:ring:2 cat:1:2 portal:2 belt:3r,5l', _harbor),
  // 176-190 Nara (deer-park teahouse): mats with two or three other blockers.
  Spec.of(176, 'corner9', ['mat', 'c:tako:40'], 'mat:c1', _deer),
  Spec.of(
      177, 'full9', ['mat', 'ice', 'c:tako:40'], 'mat:corners ice:c3', _deer),
  Spec.of(178, 'diamond9', ['mat', 'c:hotate:44'], 'mat:c1 fire:2', _deer),
  Spec.of(179, 'tee9', ['mat', 'nori', 'c:hotate:40'], 'mat:corners nori:rows',
      _deer),
  Spec.of(
      180, 'full9', ['mat', 'cats', 'c:ika:44'], 'mat:c1 cat:2 belt:2r', _deer),
  Spec.of(
      181, 'square8', ['mat', 'c:tamago:44'], 'mat:corners key:ika:2', _deer),
  Spec.of(182, 'cup9', ['mat', 'bag', 'c:maguro:44'], 'mat:c1 bag:corners:2',
      _deer),
  Spec.of(183, 'octa8', ['deliver:3', 'mat', 'c:ika:14'], 'mat:c1', _deer),
  Spec.of(184, 'corner9', ['mat', 'fire', 'c:ikura:44'],
      'mat:c1 fire:2 grav:left', _deer),
  Spec.of(185, 'full9', ['mat', 'ice', 'cats'],
      'mat:corners ice:ring:2 cat:1:2', _deer),
  Spec.of(186, 'diamond9', ['mat', 'nori', 'c:tako:44'],
      'mat:c1 nori:sides bomb:1:10', _deer),
  Spec.of(187, 'tee9', ['mat', 'c:hotate:44', 'c:ika:44'],
      'mat:corners portal:1 belt:3l', _deer),
  Spec.of(188, 'full9', ['mat', 'bag', 'c:tamago:44'],
      'mat:c1 bag:corners:2 grav:right', _deer),
  Spec.of(189, 'square8', ['mat', 'fire', 'cats', 'c:tamago:40'],
      'mat:c1 fire:2 cat:1', _deer),
  Spec.of(190, 'full9', ['mat', 'nori', 'ice', 'cats', 'c:tako:44'],
      'mat:corners nori:ring ice:c1:2 cat:1:2 belt:2l,6r', _deer),
  // 191+ Ginza (master chef): every mechanic. Extend it or add restaurants.
  Spec.of(191, 'full9', ['nori', 'ice', 'c:unagi:44'],
      'nori:ring:2 ice:c3:2 belt:3r', _ginza),
  Spec.of(192, 'corner9', ['cats', 'fire', 'c:tako:44'], 'cat:2 fire:2 grav:up',
      _ginza),
  Spec.of(193, 'diamond9', ['mat', 'bag', 'c:hotate:44'],
      'mat:c1 bag:corners:2 key:ika:2', _ginza),
  Spec.of(194, 'tee9', ['nori', 'cats', 'c:salmon:44'],
      'nori:rows:2 cat:1:2 bomb:1:10', _ginza),
  Spec.of(195, 'full9', ['ice', 'fire', 'c:maguro:44', 'c:ika:44'],
      'ice:sides:2 fire:2 portal:2', _ginza),
  Spec.of(196, 'cup9', ['nori', 'bag', 'c:unagi:44'],
      'nori:ring bag:c1:3 grav:left', _ginza),
  Spec.of(197, 'square8', ['mat', 'ice', 'c:tako:44'],
      'mat:corners ice:c3:2 belt:2r,5l', _ginza),
  Spec.of(198, 'octa8', ['deliver:4', 'fire', 'c:hotate:14'],
      'fire:2 key:salmon:1', _ginza),
  Spec.of(199, 'corner9', ['cats', 'nori', 'ice', 'c:ika:44'],
      'cat:1:2 nori:cross ice:corners:2 bomb:1:12', _ginza),
  Spec.of(200, 'full9', ['nori', 'ice', 'mat', 'cats', 'c:unagi:44', 's:18000'],
      'mat:corners nori:ring:2 ice:c3:3 cat:2:2 grav:right belt:2r,6l', _ginza),
  Spec.of(201, 'diamond9', ['ice', 'c:tako:40', 'c:hotate:40'],
      'ice:cross:2 portal:1', _ginza),
  Spec.of(202, 'tee9', ['fire', 'bag', 'c:maguro:44'],
      'fire:2 bag:corners:2 grav:left', _ginza),
  Spec.of(
      203, 'square8', ['deliver:3', 'c:unagi:16'], 'key:ika:2 belt:3r', _ginza),
  Spec.of(204, 'cup9', ['mat', 'cats', 'c:salmon:44'],
      'mat:c1 cat:1:2 bomb:1:12', _ginza),
  Spec.of(205, 'full9', ['nori', 'ice', 'bag', 'fire', 'c:ika:44', 'c:tako:44'],
      'bag:corners:2 nori:ring:2 ice:c3:2 fire:2 portal:2 belt:3r,5l', _ginza),
];

typedef Cell = (int, int);

/// Cells a pattern covers on a [rows]x[cols] board (before void filtering).
List<Cell> _pattern(String pat, int rows, int cols) {
  final r = rows ~/ 2, c = cols ~/ 2;
  final out = <Cell>[];
  switch (pat) {
    case 'c1':
      out.add((r, c));
    case 'c3':
      for (var i = r - 1; i <= r + 1; i++) {
        for (var j = c - 1; j <= c + 1; j++) {
          out.add((i, j));
        }
      }
    case 'cross':
      for (var j = c - 2; j <= c + 2; j++) {
        out.add((r, j));
      }
      for (var i = r - 2; i <= r + 2; i++) {
        if (i != r) out.add((i, c));
      }
    case 'ring':
      for (var i = r - 2; i <= r + 2; i++) {
        for (var j = c - 2; j <= c + 2; j++) {
          if (i == r - 2 || i == r + 2 || j == c - 2 || j == c + 2) {
            out.add((i, j));
          }
        }
      }
    case 'corners':
      for (final i in [r - 2, r + 2]) {
        for (final j in [c - 2, c + 2]) {
          out.add((i, j));
        }
      }
    case 'sides':
      for (final i in [r - 1, r, r + 1]) {
        out
          ..add((i, 1))
          ..add((i, cols - 2));
      }
    case 'rows':
      for (var j = 1; j < cols - 1; j++) {
        out
          ..add((r - 1, j))
          ..add((r + 1, j));
      }
    default:
      throw ArgumentError('unknown pattern "$pat"');
  }
  return out;
}

Map<String, dynamic> build(Spec s) {
  final shape = _shapes[s.shape]!;
  final rows = shape.length, cols = shape.first.length;
  final grid = [for (final l in shape) l.split('')];
  final legend = <String, String>{'.': 'cell', 'X': 'void'};
  final used = <Cell>{};
  var gravity = 'down';
  final belts = <Map<String, dynamic>>[];

  bool free(Cell p) =>
      p.$1 >= 0 &&
      p.$1 < rows &&
      p.$2 >= 0 &&
      p.$2 < cols &&
      grid[p.$1][p.$2] == '.' &&
      !used.contains(p);

  // Edge rows/columns stay clear of blockers so nothing gets sealed in.
  bool interior(Cell p) =>
      p.$1 > 0 && p.$1 < rows - 1 && p.$2 > 0 && p.$2 < cols - 1;

  void put(Cell p, String ch, String value) {
    grid[p.$1][p.$2] = ch;
    legend[ch] = value;
    used.add(p);
  }

  /// Spread points: deterministic spots for `n` single features.
  List<Cell> spots(int n, {int salt = 0}) {
    final all = <Cell>[
      for (var i = 2; i < rows - 2; i++)
        for (var j = 1; j < cols - 1; j++) (i, j),
    ].where((p) => free(p) && interior(p)).toList();
    final out = <Cell>[];
    var k = (s.id * 7 + salt * 13) % all.length;
    while (out.length < n && out.length < all.length) {
      final p = all[k % all.length];
      if (!out.contains(p) &&
          out.every((q) => (q.$1 - p.$1).abs() + (q.$2 - p.$2).abs() > 2)) {
        out.add(p);
      }
      k += 11;
      if (k > 400) break;
    }
    return out;
  }

  final kindChar = {
    for (final k in [..._six, 'unagi', 'hotate', 'ika', 'tako'])
      k: '${k[0].toUpperCase()}k'
  };
  var salt = 0;
  for (final f in s.feat.split(' ').where((f) => f.isNotEmpty)) {
    final a = f.split(':');
    salt++;
    switch (a[0]) {
      case 'ice':
      case 'nori':
      case 'bag':
        final layers = a.length > 2 ? int.parse(a[2]) : 1;
        final ch = {'ice': 'I', 'nori': 'N', 'bag': 'G'}[a[0]]! +
            (layers > 1 ? '$layers' : '');
        for (final p in _pattern(a[1], rows, cols).where(free)) {
          if (a[0] == 'bag' && !interior(p)) continue;
          put(p, ch, '${a[0]}:$layers');
        }
      case 'mat':
        for (final p in _pattern(a[1], rows, cols).where(free)) {
          if (interior(p)) put(p, 'T', 'mat');
        }
      case 'fire':
        for (final p in spots(int.parse(a[1]), salt: salt)) {
          put(p, 'F', 'fire');
        }
      case 'cat':
        final hp = a.length > 2 ? int.parse(a[2]) : 1;
        for (final p in spots(int.parse(a[1]), salt: salt)) {
          put(p, 'C$hp', 'cat:$hp');
        }
      case 'key':
        final n = a.length > 2 ? int.parse(a[2]) : 1;
        for (final p in spots(n, salt: salt)) {
          put(p, 'K${kindChar[a[1]]}', 'key:${a[1]}');
        }
      case 'bomb':
        final t = a.length > 2 ? int.parse(a[2]) : 9;
        for (final p in spots(int.parse(a[1]), salt: salt)) {
          put(p, 'B$t', 'bomb:$t');
        }
      case 'portal':
        // Entries sink into the bottom row and exits open on the top row.
        // No column has both (that would chain portals into holes), so two
        // pairs need the full-width shape; narrower ones take one.
        final n = int.parse(a[1]);
        if (n > 1 && s.shape != 'full9') {
          throw ArgumentError('level ${s.id}: 2 portals need shape full9');
        }
        final entries = n > 1 ? [2, 4] : [cols ~/ 2 - 1];
        final exits = n > 1 ? [6, 0] : [cols ~/ 2 + 1];
        for (var i = 0; i < n; i++) {
          grid[rows - 1][entries[i]] = 'i${i + 1}';
          grid[0][exits[i]] = 'o${i + 1}';
          legend['i${i + 1}'] = 'portal_in:${i + 1}';
          legend['o${i + 1}'] = 'portal_out:${i + 1}';
        }
      case 'belt':
        for (final b in a[1].split(',')) {
          belts.add({
            'row': int.parse(b.substring(0, b.length - 1)),
            'dir': b.endsWith('l') ? 'left' : 'right'
          });
        }
      case 'grav':
        gravity = a[1];
      default:
        throw ArgumentError('unknown feature "${a[0]}" in level ${s.id}');
    }
  }
  // Each cell is one character in the file, so multi-character tokens used
  // above (I2, Kk, B10 ...) become single letters here.
  final single = <String, String>{};
  final pool = 'ABDEHJLMOPQRSUVWYZabcdefghjklmnopqrstuvwyz'.split('');
  final newLegend = <String, String>{'.': 'cell', 'X': 'void'};
  String charFor(String token) => single.putIfAbsent(token, () {
        if (token.length == 1) return token;
        final ch = pool.removeAt(0);
        newLegend[ch] = legend[token]!;
        return ch;
      });
  final layout = [
    for (final row in grid) row.map(charFor).join(),
  ];
  for (final e in legend.entries) {
    if (e.key.length == 1) newLegend[e.key] = e.value;
  }

  final goals = <Map<String, dynamic>>[];
  for (final g in s.goals) {
    final a = g.split(':');
    switch (a[0]) {
      case 'c':
        goals.add({'type': 'collect', 'piece': a[1], 'count': int.parse(a[2])});
      case 's':
        goals.add({'type': 'score', 'count': int.parse(a[1])});
      case 'deliver':
        goals.add({'type': 'deliver', 'count': int.parse(a[1])});
      case 'nori':
        goals.add({'type': 'clear_nori'});
      case 'ice':
        goals.add({'type': 'break_ice'});
      case 'bag':
        goals.add({'type': 'break_bag'});
      case 'mat':
        goals.add({'type': 'clear_mats'});
      case 'fire':
        goals.add({'type': 'put_out'});
      case 'cats':
        goals.add({'type': 'shoo_cats'});
      default:
        throw ArgumentError('unknown goal "$g" in level ${s.id}');
    }
  }
  for (final g in goals.where((g) => g['piece'] != null)) {
    if (!s.pieces.contains(g['piece'])) {
      throw ArgumentError('level ${s.id} collects ${g['piece']} not in pieces');
    }
  }

  return {
    'id': s.id,
    'version': 1,
    'board': {'cols': cols, 'rows': rows},
    'layout': layout,
    'legend': newLegend,
    'pieces': s.pieces,
    'moves': s.moves,
    'goals': goals,
    'stars': [3000, 6000, 9000],
    if (gravity != 'down') 'gravity': gravity,
    if (belts.isNotEmpty) 'conveyors': belts,
    'seed': 600000 + s.id * 137,
  };
}

void main(List<String> args) {
  final force = args.contains('--force');
  final only = args.where((a) => !a.startsWith('-')).map(int.parse).toSet();
  const enc = JsonEncoder.withIndent('  ');
  for (final s in specs) {
    if (only.isNotEmpty && !only.contains(s.id)) continue;
    final f =
        File('assets/levels/level_${s.id.toString().padLeft(3, '0')}.json');
    if (f.existsSync() && !force) {
      print('skip ${f.path} (exists)');
      continue;
    }
    f.writeAsStringSync('${enc.convert(build(s))}\n');
    print('wrote ${f.path}');
  }
}
