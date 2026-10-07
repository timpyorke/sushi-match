import 'dart:convert';

import 'level.dart';

/// Per-level difficulty overrides, delivered by Remote Config so a level can
/// be eased or hardened without an app update.
///
/// JSON shape (all keys optional; `"*"` applies to every level and a level's
/// own entry wins over it):
/// ```json
/// {"*": {"moves_delta": 1}, "12": {"moves": 30}, "13": {"moves_delta": 3}}
/// ```
/// `moves` sets the move budget outright, `moves_delta` adds to it. The result
/// never drops below 1.
class LevelTuning {
  const LevelTuning._(this._byLevel);

  static const none = LevelTuning._({});

  final Map<String, _Override> _byLevel;

  /// Parses [raw]; anything malformed yields [none] (or skips that entry).
  factory LevelTuning.parse(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map) return none;
      final out = <String, _Override>{};
      j.forEach((k, v) {
        if (v is! Map) return;
        final moves = v['moves'], delta = v['moves_delta'];
        out['$k'] =
            _Override(moves is int ? moves : null, delta is int ? delta : 0);
      });
      return LevelTuning._(out);
    } on FormatException {
      return none;
    }
  }

  LevelConfig apply(LevelConfig level) {
    final all = _byLevel['*'], own = _byLevel['${level.id}'];
    if (all == null && own == null) return level;
    var moves = level.moves;
    for (final o in [all, own]) {
      if (o == null) continue;
      moves = (o.moves ?? moves) + o.delta;
    }
    moves = moves < 1 ? 1 : moves;
    return moves == level.moves ? level : level.withMoves(moves);
  }
}

class _Override {
  const _Override(this.moves, this.delta);
  final int? moves;
  final int delta;
}
