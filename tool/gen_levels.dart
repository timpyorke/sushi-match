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

part 'levels/specs.dart';

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
