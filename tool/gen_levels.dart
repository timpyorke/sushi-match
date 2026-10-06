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
  'octa8': [
    'XXX..XXX', 'XX....XX', 'X......X', '........', '........', //
    'X......X', 'XX....XX', 'XXX..XXX',
  ],
};

class Spec {
  const Spec(this.id, this.shape, this.goals,
      {this.feat = '', this.pieces = _six, this.moves = 40});
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
// 91-100 Omakase (finale): three or four mechanics, boss at 100.
// Every 5th level is a hard one, every 15th a boss (see tool/tune.dart).
const specs = <Spec>[
  Spec(61, 'corner9', ['ice', 'c:salmon:40'],
      feat: 'ice:cross belt:3l,5r'),
  Spec(62, 'full9', ['cats', 'c:kappa:36', 'c:ikura:36'],
      feat: 'cat:2 belt:4r'),
  Spec(63, 'diamond9', ['nori', 's:9000'], feat: 'nori:ring'),
  Spec(64, 'corner9', ['bag', 'fire', 'c:maguro:36'],
      feat: 'bag:corners fire:2'),
  Spec(65, 'full9', ['ice', 'c:tamago:40', 'c:ebi:40'],
      feat: 'ice:c3:2 key:maguro:2'),
  Spec(66, 'octa8', ['deliver:3', 'c:salmon:14', 'c:ebi:14']),
  Spec(67, 'corner9', ['mat', 's:11000'], feat: 'mat:c1 belt:2r,6l'),
  Spec(68, 'diamond9', ['cats', 'ice', 'c:kappa:36'],
      feat: 'cat:1:2 ice:rows'),
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
      feat: 'nori:ring ice:c3:2 cat:2:2 grav:right belt:2r,6l',
      pieces: _deep),
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
        out..add((i, 1))..add((i, cols - 2));
      }
    case 'rows':
      for (var j = 1; j < cols - 1; j++) {
        out..add((r - 1, j))..add((r + 1, j));
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
    for (final k in [..._six, 'unagi', 'hotate']) k: '${k[0].toUpperCase()}k'
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
    final f = File(
        'assets/levels/level_${s.id.toString().padLeft(3, '0')}.json');
    if (f.existsSync() && !force) {
      print('skip ${f.path} (exists)');
      continue;
    }
    f.writeAsStringSync('${enc.convert(build(s))}\n');
    print('wrote ${f.path}');
  }
}
