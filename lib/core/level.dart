import 'piece.dart';
import 'pos.dart';

enum GoalType {
  collect,
  score,
  clearNori,
  breakIce,
  breakBag,
  deliver,
  clearMats,
  putOut,
  shooCats
}

class LevelGoal {
  const LevelGoal.collect(PieceKind this.piece, this.count)
      : type = GoalType.collect;
  const LevelGoal.score(this.count)
      : type = GoalType.score,
        piece = null;

  /// Clear every nori sheet; [count] is the number of sheeted cells.
  const LevelGoal.clearNori(this.count)
      : type = GoalType.clearNori,
        piece = null;

  /// Break every block of ice; [count] is the number of iced cells.
  const LevelGoal.breakIce(this.count)
      : type = GoalType.breakIce,
        piece = null;

  /// Break every rice bag; [count] is the number of bagged cells.
  const LevelGoal.breakBag(this.count)
      : type = GoalType.breakBag,
        piece = null;

  /// Bring [count] ingredients down to the bottom row.
  const LevelGoal.deliver(this.count)
      : type = GoalType.deliver,
        piece = null;

  /// Destroy every bamboo mat; [count] is the number laid out at the start
  /// (mats spread, so more may have to go).
  const LevelGoal.clearMats(this.count)
      : type = GoalType.clearMats,
        piece = null;

  /// Put out every burning piece; [count] is how many burned at the start.
  const LevelGoal.putOut(this.count)
      : type = GoalType.putOut,
        piece = null;

  /// Chase every cat off the board; [count] is the number of cats.
  const LevelGoal.shooCats(this.count)
      : type = GoalType.shooCats,
        piece = null;

  final GoalType type;
  final PieceKind? piece;
  final int count;

  factory LevelGoal.fromJson(Map<String, dynamic> j,
      {int noriCells = 0,
      int iceCells = 0,
      int bagCells = 0,
      int matCells = 0,
      int fireCells = 0,
      int catCount = 0}) {
    switch (j['type']) {
      case 'collect':
        return LevelGoal.collect(
            PieceKind.values.byName(j['piece'] as String), j['count'] as int);
      case 'score':
        return LevelGoal.score(j['count'] as int);
      case 'clear_nori':
        if (noriCells == 0) {
          throw const FormatException('clear_nori needs nori cells in layout');
        }
        return LevelGoal.clearNori(noriCells);
      case 'break_ice':
        if (iceCells == 0) {
          throw const FormatException('break_ice needs ice cells in layout');
        }
        return LevelGoal.breakIce(iceCells);
      case 'break_bag':
        if (bagCells == 0) {
          throw const FormatException('break_bag needs bag cells in layout');
        }
        return LevelGoal.breakBag(bagCells);
      case 'deliver':
        return LevelGoal.deliver(j['count'] as int);
      case 'clear_mats':
        if (matCells == 0) {
          throw const FormatException('clear_mats needs mat cells in layout');
        }
        return LevelGoal.clearMats(matCells);
      case 'put_out':
        if (fireCells == 0) {
          throw const FormatException('put_out needs fire cells in layout');
        }
        return LevelGoal.putOut(fireCells);
      case 'shoo_cats':
        if (catCount == 0) {
          throw const FormatException('shoo_cats needs cats in layout');
        }
        return LevelGoal.shooCats(catCount);
      default:
        throw UnsupportedError(
            'Goal type "${j['type']}" is not implemented yet');
    }
  }
}

/// A row whose pieces slide one cell in [dir] (-1 left, +1 right) every turn.
class Conveyor {
  const Conveyor(this.row, this.dir);
  final int row;
  final int dir;

  factory Conveyor.fromJson(Map<String, dynamic> j) {
    final dir = switch (j['dir']) {
      'left' => -1,
      'right' => 1,
      final d => throw FormatException('conveyor dir "$d" must be left/right'),
    };
    return Conveyor(j['row'] as int, dir);
  }
}

/// A thieving cat's starting cell and how many scares it takes to chase it off.
class CatSpec {
  const CatSpec(this.row, this.col, this.hp);
  final int row;
  final int col;
  final int hp;
}

/// Which way pieces fall.
enum Gravity {
  down(1, 0),
  up(-1, 0),
  left(0, -1),
  right(0, 1);

  const Gravity(this.dr, this.dc);
  final int dr;
  final int dc;

  bool get vertical => dc == 0;
}

/// A linked pair of teleporters. Pieces reaching the bottom of the segment
/// above [entry] reappear at [exit], which must be the top cell of its own
/// segment.
class PortalSpec {
  const PortalSpec(this.entry, this.exit);
  final Pos entry;
  final Pos exit;
}

class LevelConfig {
  LevelConfig({
    required this.id,
    required this.rows,
    required this.cols,
    required this.playable,
    required this.nori,
    this.ice = const [],
    this.bags = const [],
    this.mats = const [],
    this.fire = const [],
    this.cats = const [],
    this.locks = const [],
    this.timers = const [],
    this.portals = const [],
    this.gravity = Gravity.down,
    required this.pieces,
    required this.moves,
    required this.goals,
    required this.stars,
    required this.seed,
    this.conveyors = const [],
  });

  final int id;
  final int rows;
  final int cols;

  /// Row-major mask; false = void cell.
  final List<bool> playable;

  /// Row-major nori layers under each cell (0 = none).
  final List<int> nori;

  /// Row-major ice layers caging the piece that starts in each cell; empty
  /// means none.
  final List<int> ice;

  /// Row-major rice bag layers (0 = none). Bagged cells start unplayable and
  /// open once the bag breaks; empty means none.
  final List<int> bags;

  /// Row-major: which blocked cells are bamboo mats (they spread). Mats also
  /// appear in [bags] with one layer.
  final List<bool> mats;

  /// Row-major: pieces that start the level burning; empty means none.
  final List<bool> fire;

  /// Cats that start on the board; they move and eat pieces every turn.
  final List<CatSpec> cats;

  /// Row-major: the colour that must be matched before a cell's piece can be
  /// swapped (null = free); empty means no locks.
  final List<PieceKind?> locks;

  /// Row-major: bomb countdowns on the pieces that start there (0 = none);
  /// empty means none. A bomb that reaches 0 ends the level.
  final List<int> timers;
  final List<PortalSpec> portals;
  final Gravity gravity;
  final List<PieceKind> pieces;
  final int moves;
  final List<LevelGoal> goals;
  final List<int> stars;
  final int seed;
  final List<Conveyor> conveyors;

  /// Parses the GDD level schema. `nori` / `nori:N` legend values put N
  /// layers under a cell, `ice` / `ice:N` cage the piece that starts there in
  /// N layers of ice; `bag` / `bag:N` put an N-layer rice bag in the cell, `mat` a bamboo mat, `fire` a burning piece, `cat` / `cat:N` a cat with N lives, `key:<kind>` a swap lock, `bomb:N` a
  /// countdown piece, `portal_in:<id>` / `portal_out:<id>` teleporters;
  /// other values besides "void" are plain cells.
  factory LevelConfig.fromJson(Map<String, dynamic> j) {
    final board = j['board'] as Map<String, dynamic>;
    final rows = board['rows'] as int;
    final cols = board['cols'] as int;
    final layout =
        (j['layout'] as List?)?.cast<String>() ?? List.filled(rows, '.' * cols);
    final legend = (j['legend'] as Map?)?.cast<String, String>() ??
        const {'.': 'cell', 'X': 'void'};
    if (layout.length != rows || layout.any((l) => l.length != cols)) {
      throw FormatException('layout does not match board ${cols}x$rows');
    }
    final cellsOf = [
      for (final line in layout)
        for (final ch in line.split('')) legend[ch] ?? 'cell',
    ];
    final nori = [
      for (final v in cellsOf)
        v.startsWith('nori')
            ? (v.contains(':') ? int.parse(v.split(':')[1]) : 1)
            : 0,
    ];
    final ice = [
      for (final v in cellsOf)
        v.startsWith('ice')
            ? (v.contains(':') ? int.parse(v.split(':')[1]) : 1)
            : 0,
    ];
    final fire = [for (final v in cellsOf) v == 'fire'];
    final cats = [
      for (var i = 0; i < cellsOf.length; i++)
        if (cellsOf[i].startsWith('cat'))
          CatSpec(
              i ~/ cols,
              i % cols,
              cellsOf[i].contains(':')
                  ? int.parse(cellsOf[i].split(':')[1])
                  : 1),
    ];
    final locks = [
      for (final v in cellsOf)
        v.startsWith('key:') ? PieceKind.values.byName(v.split(':')[1]) : null,
    ];
    final timers = [
      for (final v in cellsOf)
        v.startsWith('bomb') && v.contains(':')
            ? int.parse(v.split(':')[1])
            : 0,
    ];
    final portalIn = <String, Pos>{}, portalOut = <String, Pos>{};
    for (var i = 0; i < cellsOf.length; i++) {
      final v = cellsOf[i];
      final at = Pos(i ~/ cols, i % cols);
      if (v.startsWith('portal_in:')) portalIn[v.split(':')[1]] = at;
      if (v.startsWith('portal_out:')) portalOut[v.split(':')[1]] = at;
    }
    final portals = [
      for (final id in portalIn.keys)
        PortalSpec(
            portalIn[id]!,
            portalOut[id] ??
                (throw FormatException('portal $id has no exit cell'))),
    ];
    final mats = [for (final v in cellsOf) v == 'mat'];
    final bags = [
      for (final v in cellsOf)
        v == 'mat'
            ? 1
            : v.startsWith('bag')
                ? (v.contains(':') ? int.parse(v.split(':')[1]) : 1)
                : 0,
    ];
    final conveyors = [
      for (final c in (j['conveyors'] as List? ?? const []))
        Conveyor.fromJson(c as Map<String, dynamic>),
    ];
    for (final c in conveyors) {
      if (c.row < 0 || c.row >= rows) {
        throw FormatException('conveyor row ${c.row} is off the board');
      }
    }
    return LevelConfig(
      id: j['id'] as int,
      rows: rows,
      cols: cols,
      playable: [
        for (final v in cellsOf)
          v != 'void' &&
              !v.startsWith('bag') &&
              v != 'mat' &&
              !v.startsWith('portal_in'),
      ],
      nori: nori,
      ice: ice,
      bags: bags,
      mats: mats,
      fire: fire,
      cats: cats,
      locks: locks,
      timers: timers,
      portals: portals,
      gravity: Gravity.values.byName(j['gravity'] as String? ?? 'down'),
      pieces: [
        for (final p in j['pieces'] as List)
          PieceKind.values.byName(p as String),
      ],
      moves: j['moves'] as int,
      goals: [
        for (final g in j['goals'] as List)
          LevelGoal.fromJson(g as Map<String, dynamic>,
              noriCells: nori.where((n) => n > 0).length,
              iceCells: ice.where((n) => n > 0).length,
              bagCells: [
                for (var i = 0; i < bags.length; i++)
                  if (bags[i] > 0 && !mats[i]) i
              ].length,
              matCells: mats.where((m) => m).length,
              fireCells: fire.where((f) => f).length,
              catCount: cats.length),
      ],
      stars: (j['stars'] as List? ?? const []).cast<int>(),
      conveyors: conveyors,
      seed: j['seed'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
