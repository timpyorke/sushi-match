import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/board.dart';
import '../core/game_engine.dart';
import '../core/level.dart' show Gravity;
import '../core/move_finder.dart';
import '../core/piece.dart';
import '../core/pos.dart';
import '../core/settings.dart';
import '../core/steps.dart';
import '../services/audio.dart';
import '../services/wallet.dart';
import 'board_background.dart';
import 'board_effects.dart';
import 'cat_component.dart';
import 'obstacle_art.dart';
import 'overlay_badges.dart';
import 'piece_component.dart';
import 'tile_art.dart';

part 'board_playback.dart';

/// View for the board. Owns no rules: it forwards input to [GameEngine]
/// and plays back the returned [BoardStep]s one by one.
class BoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  BoardComponent({
    required this.engine,
    required this.onTurnFinished,
    required this.onPraise,
    required this.armed,
    required this.canSpendBooster,
    required this.onSpendBooster,
    this.onShuffle,
  }) : super(
          size: Vector2(engine.board.cols * cell, engine.board.rows * cell),
        );

  /// Logical cell size. The whole board is scaled to fit the screen.
  static const double cell = 64;
  static const double _hintDelay = 5;

  /// Space kept round the board for the gravity arrows, which only show
  /// when pieces don't fall down.
  double get _margin => _marginFor(engine.level.gravity);

  final GameEngine engine;
  final void Function() onTurnFinished;

  /// Called with the chef's cheer when a turn chained into a combo.
  final void Function(String) onPraise;

  /// Booster waiting for a tap; cleared once it fires.
  final ValueNotifier<Booster?> armed;

  /// Whether the booster is affordable (stock or coins); checked before it
  /// is tried.
  final bool Function(Booster) canSpendBooster;

  /// Pays for the booster; called only once it actually did something.
  final bool Function(Booster) onSpendBooster;

  /// Called when a turn ended with the board reshuffled for lack of moves.
  final void Function()? onShuffle;

  final _views = <int, PieceComponent>{};
  final _at = <Pos, PieceComponent>{};
  final _cats = <int, CatComponent>{};
  final _keys = <Pos, KeyLockBadge>{};
  late final ClipComponent _layer;
  late final _fx = BoardEffects(_layer, cell: cell);

  bool _busy = false;
  Pos? _selected;
  Pos? _dragFrom;
  final Vector2 _drag = Vector2.zero();
  double _idle = 0;
  final List<Effect> _hint = [];

  late final _background = BoardBackground(engine, cell: cell, margin: _margin);

  Board get board => engine.board;

  static final _selPaint = Paint()..color = const Color(0x88FFFFFF);

  @override
  Future<void> onLoad() async {
    await TileArt.load();
    await ObstacleArt.load();
    await CatArt.load();
    _layer = ClipComponent.rectangle(size: size);
    add(_layer);
    for (final p in board.positions) {
      final piece = board[p];
      if (piece != null) _spawnView(PieceSnapshot.of(piece), p);
    }
    for (var i = 0; i < engine.level.locks.length; i++) {
      final kind = engine.level.locks[i];
      if (kind == null) continue;
      final at = Pos(i ~/ board.cols, i % board.cols);
      _layer.add(_keys[at] =
          KeyLockBadge(kind: kind, cellSize: cell, position: _center(at)));
    }
    var portal = 0;
    for (final p in engine.level.portals) {
      _layer
        ..add(PortalBadge(
            entry: true,
            tint: portal,
            cellSize: cell,
            position: _center(p.entry)))
        ..add(PortalBadge(
            entry: false,
            tint: portal,
            cellSize: cell,
            position: _center(p.exit)));
      portal++;
    }
    for (final c in engine.cats) {
      _layer.add(_cats[c.id] = CatComponent(
          catId: c.id, hp: c.hp, cellSize: cell, position: _center(c.pos)));
    }
  }

  static double _marginFor(Gravity g) => g == Gravity.down ? 0 : 20;

  /// Scale that fits a [cols] x [rows] board into a [width] x [height] area.
  static double fitScale(
          double width, double height, int cols, int rows, Gravity g) =>
      math.min(width * 0.96 / (cols * cell + 2 * _marginFor(g)),
          height * 0.96 / (rows * cell + 2 * _marginFor(g)));

  /// Height of the smallest area the board fits into at scale [s].
  static double areaFor(double s, int rows, Gravity g) =>
      (rows * cell + 2 * _marginFor(g)) * s / 0.96;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final board = this.size;
    final s = fitScale(size.x, size.y, engine.board.cols, engine.board.rows,
        engine.level.gravity);
    scale = Vector2.all(s);
    position = (size - board * s) / 2;
  }

  @override
  void render(Canvas canvas) {
    _background.draw(canvas);
    final s = _selected;
    if (s != null && ObstacleArt.ready) {
      ObstacleArt.draw(canvas, ObstacleSprite.select,
          Rect.fromLTWH(s.col * cell, s.row * cell, cell, cell));
    } else if (s != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.col * cell, s.row * cell, cell, cell).deflate(1.5),
          const Radius.circular(8),
        ),
        _selPaint,
      );
    }
  }

  @override
  void onRemove() {
    _background.dispose();
    super.onRemove();
  }

  // --------------------------------------------------------------- input --

  @override
  void onTapUp(TapUpEvent event) {
    final p = _cellAt(event.localPosition);
    _resetIdle();
    if (_busy || p == null) return;
    final s = _selected;
    final booster = armed.value;
    if (booster == Booster.chopsticks) {
      _runBooster(booster!, () => engine.useChopsticks(p));
      return;
    }
    if (booster == Booster.freeSwap) {
      if (s == null) {
        _selected = p;
      } else if (s == p) {
        _selected = null;
      } else {
        _runBooster(booster!, () => engine.useFreeSwap(s, p));
      }
      return;
    }
    if (s != null && s.isAdjacentTo(p)) {
      _selected = null;
      _attempt(s, p);
    } else {
      _selected = s == p ? null : p;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _resetIdle();
    _dragFrom = _busy ? null : _cellAt(event.localPosition);
    _drag.setZero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final from = _dragFrom;
    if (from == null || _busy) return;
    _drag.add(event.localDelta);
    if (_drag.length < cell * 0.35) return;
    final dir = _drag.x.abs() > _drag.y.abs()
        ? Pos(0, _drag.x.sign.toInt())
        : Pos(_drag.y.sign.toInt(), 0);
    _dragFrom = null;
    _selected = null;
    _attempt(from, from + dir);
  }

  Pos? _cellAt(Vector2 local) {
    final p = Pos((local.y / cell).floor(), (local.x / cell).floor());
    return board.isPlayable(p) ? p : null;
  }

  /// Plays a swap as if the player dragged [a] onto [b].
  @visibleForTesting
  Future<void> attempt(Pos a, Pos b) => _attempt(a, b);

  /// The piece id each cell's view shows.
  @visibleForTesting
  Map<Pos, int> get viewIds => {
        for (final e in _at.entries) e.key: e.value.pieceId,
      };

  Future<void> _attempt(Pos a, Pos b) async {
    if (_busy || !board.isPlayable(b)) return;
    _busy = true;
    _clearHint();
    try {
      final steps = engine.trySwap(a, b);
      if (steps.any((s) => s is ShuffleStep)) onShuffle?.call();
      final cheer = _praiseFor(steps);
      if (cheer != null) onPraise(cheer);
      await _play(steps);
    } finally {
      _busy = false;
      _resetIdle();
      onTurnFinished();
    }
  }

  Future<void> _runBooster(Booster b, List<BoardStep> Function() run) async {
    if (_busy || engine.status != GameStatus.playing) return;
    if (!canSpendBooster(b)) return;
    // A rejected use (frozen piece, ingredient...) returns no steps and
    // costs nothing.
    final steps = run();
    if (steps.isEmpty) return;
    onSpendBooster(b);
    _busy = true;
    _clearHint();
    armed.value = null;
    _selected = null;
    try {
      await _play(steps);
    } finally {
      _busy = false;
      _resetIdle();
      onTurnFinished();
    }
  }

  void useShuffle() => _runBooster(Booster.shuffle, engine.useShuffle);

  // ------------------------------------------------------------ playback --

  /// Chef's cheer by cascade depth (GDD: Oishii! → Sugoi! → Omakase!).
  static String? _praiseFor(List<BoardStep> steps) {
    final depth = steps
        .whereType<ClearStep>()
        .fold<int>(0, (m, s) => math.max(m, s.cascade));
    if (depth >= 4) return 'Omakase!';
    if (depth == 3) return 'Sugoi!';
    if (depth == 2) return 'Oishii!';
    return null;
  }

  void _haptic(Future<void> Function() impact) {
    if (SettingsMirror.haptics) impact();
  }

  // ------------------------------------------------------------- helpers --

  PieceComponent _spawnView(PieceSnapshot s, Pos at, {Vector2? from}) {
    final v = PieceComponent(
      pieceId: s.id,
      kind: s.kind,
      special: s.special,
      ice: s.ice,
      ingredient: s.ingredient,
      burning: s.burning,
      timer: s.timer,
      cellSize: cell,
      position: from ?? _center(at),
    );
    _views[s.id] = v;
    _at[at] = v;
    _layer.add(v);
    return v;
  }

  Vector2 _center(Pos p) =>
      Vector2(p.col * cell + cell / 2, p.row * cell + cell / 2);

  int _dist(Pos a, Pos b) =>
      math.max((a.row - b.row).abs(), (a.col - b.col).abs());

  double _fallTime(int rows) => 0.08 + 0.05 * rows;

  Future<void> _wait(double seconds) =>
      Future.delayed(Duration(milliseconds: (seconds * 1000).round()));

  Future<void> _moveTo(PositionComponent v, Vector2 to, double seconds,
      {Curve curve = Curves.easeInOut}) {
    final done = Completer<void>();
    v.add(MoveToEffect(
      to,
      EffectController(duration: seconds, curve: curve),
      onComplete: done.complete,
    ));
    return done.future;
  }

  /// Fall to [to], then squash on impact.
  Future<void> _land(PieceComponent v, Vector2 to, int rows) async {
    await _moveTo(v, to, _fallTime(rows), curve: Curves.easeIn);
    if (!v.isMounted) return;
    v.add(SequenceEffect([
      ScaleEffect.to(Vector2(1.14, 0.84), EffectController(duration: 0.05)),
      ScaleEffect.to(Vector2.all(1),
          EffectController(duration: 0.12, curve: Curves.easeOutBack)),
    ]));
  }

  /// Light screen shake for Wasabi blasts.
  void _shake() {
    const a = 4.0;
    add(SequenceEffect([
      MoveEffect.by(Vector2(a, 0), EffectController(duration: 0.04)),
      MoveEffect.by(Vector2(-2 * a, 0), EffectController(duration: 0.08)),
      MoveEffect.by(Vector2(a, 0), EffectController(duration: 0.04)),
    ]));
  }

  Future<void> _pop(PieceComponent v) {
    for (final e in v.children.whereType<Effect>().toList()) {
      e.removeFromParent();
    }
    final done = Completer<void>();
    v.add(ScaleEffect.to(
      Vector2.zero(),
      EffectController(duration: 0.14, curve: Curves.easeIn),
      onComplete: () {
        v.removeFromParent();
        done.complete();
      },
    ));
    return done.future;
  }

  // ---------------------------------------------------------------- hint --

  @override
  void update(double dt) {
    super.update(dt);
    if (_busy || _hint.isNotEmpty || engine.status != GameStatus.playing) {
      return;
    }
    _idle += dt;
    if (_idle < _hintDelay) return;
    _idle = 0;
    final move = MoveFinder.findMove(board);
    if (move == null) return;
    for (final p in [move.$1, move.$2]) {
      final v = _at[p];
      if (v == null) continue;
      final e = SequenceEffect([
        ScaleEffect.to(Vector2.all(1.15), EffectController(duration: 0.3)),
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.3)),
      ], infinite: true);
      v.add(e);
      _hint.add(e);
    }
  }

  void _resetIdle() {
    _idle = 0;
    _clearHint();
  }

  void _clearHint() {
    for (final e in _hint) {
      final target = e.parent;
      e.removeFromParent();
      if (target is PositionComponent) target.scale = Vector2.all(1);
    }
    _hint.clear();
  }
}
