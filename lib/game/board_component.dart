import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/board.dart';
import '../core/game_engine.dart';
import '../core/move_finder.dart';
import '../core/pos.dart';
import '../core/settings.dart';
import '../core/steps.dart';
import 'piece_component.dart';

/// View for the board. Owns no rules: it forwards input to [GameEngine]
/// and plays back the returned [BoardStep]s one by one.
class BoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  BoardComponent({
    required this.engine,
    required this.onTurnFinished,
    required this.onPraise,
  }) : super(
          size: Vector2(engine.board.cols * cell, engine.board.rows * cell),
        );

  /// Logical cell size. The whole board is scaled to fit the screen.
  static const double cell = 64;
  static const double _hintDelay = 5;

  final GameEngine engine;
  final void Function() onTurnFinished;

  /// Called with the chef's cheer when a turn chained into a combo.
  final void Function(String) onPraise;

  final _views = <int, PieceComponent>{};
  final _at = <Pos, PieceComponent>{};
  late final ClipComponent _layer;

  bool _busy = false;
  Pos? _selected;
  Pos? _dragFrom;
  final Vector2 _drag = Vector2.zero();
  double _idle = 0;
  final List<Effect> _hint = [];

  Board get board => engine.board;

  static final _cellA = Paint()..color = const Color(0xFFEBD5AE);
  static final _cellB = Paint()..color = const Color(0xFFE2C796);
  static final _selPaint = Paint()..color = const Color(0x88FFFFFF);

  @override
  Future<void> onLoad() async {
    _layer = ClipComponent.rectangle(size: size);
    add(_layer);
    for (final p in board.positions) {
      final piece = board[p];
      if (piece != null) _spawnView(PieceSnapshot.of(piece), p);
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    final s = math.min(gameSize.x * 0.96 / size.x, gameSize.y * 0.96 / size.y);
    scale = Vector2.all(s);
    position = (gameSize - size * s) / 2;
  }

  @override
  void render(Canvas canvas) {
    for (final p in board.positions) {
      final rect = Rect.fromLTWH(p.col * cell, p.row * cell, cell, cell);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(8)),
        (p.row + p.col).isEven ? _cellA : _cellB,
      );
    }
    final s = _selected;
    if (s != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.col * cell, s.row * cell, cell, cell).deflate(1.5),
          const Radius.circular(8),
        ),
        _selPaint,
      );
    }
  }

  // --------------------------------------------------------------- input --

  @override
  void onTapUp(TapUpEvent event) {
    final p = _cellAt(event.localPosition);
    _resetIdle();
    if (_busy || p == null) return;
    final s = _selected;
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

  Future<void> _attempt(Pos a, Pos b) async {
    if (_busy || !board.isPlayable(b)) return;
    _busy = true;
    _clearHint();
    try {
      final steps = engine.trySwap(a, b);
      final cheer = _praiseFor(steps);
      if (cheer != null) onPraise(cheer);
      await _play(steps);
    } finally {
      _busy = false;
      _resetIdle();
      onTurnFinished();
    }
  }

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
    if (Settings.haptics.value) impact();
  }

  Future<void> _play(List<BoardStep> steps) async {
    // Falls and the refill that follows run together for a snappier feel.
    final pending = <Future<void>>[];
    for (final step in steps) {
      if (step is! RefillStep) {
        await Future.wait(pending);
        pending.clear();
      }
      switch (step) {
        case SwapStep(:final a, :final b):
          await _swapViews(a, b);
        case InvalidSwapStep(:final a, :final b):
          await _swapViews(a, b);
          await _swapViews(a, b);
        case SpecialActivateStep(:final affected):
          for (final p in affected) {
            _flash(p);
          }
          await _wait(0.12);
        case TransformStep(:final changes):
          changes.forEach((id, t) => _views[id]?.special = t);
          await _wait(0.25);
        case ClearStep(:final cleared, :final created):
          final pops = <Future<void>>[];
          for (final c in cleared) {
            final v = _views.remove(c.pieceId);
            if (v == null) continue;
            if (identical(_at[c.pos], v)) _at.remove(c.pos);
            pops.add(_pop(v));
          }
          _haptic(created.isEmpty
              ? HapticFeedback.lightImpact
              : HapticFeedback.mediumImpact);
          await Future.wait(pops);
          for (final s in created) {
            final v = _spawnView(s.piece, s.pos)..scale = Vector2.zero();
            v.add(ScaleEffect.to(Vector2.all(1),
                EffectController(duration: 0.18, curve: Curves.easeOutBack)));
          }
        case FallStep(:final moves):
          for (final m in moves) {
            _at.remove(m.from);
          }
          for (final m in moves) {
            final v = _views[m.pieceId];
            if (v == null) continue;
            _at[m.to] = v;
            pending.add(_moveTo(
                v, _center(m.to), _fallTime(m.to.row - m.from.row),
                curve: Curves.easeIn));
          }
        case RefillStep(:final pieces):
          for (final r in pieces) {
            final start =
                Vector2(_center(r.to).x, r.startRow * cell + cell / 2);
            final v = _spawnView(r.piece, r.to, from: start);
            pending.add(_moveTo(
                v, _center(r.to), _fallTime(r.to.row - r.startRow),
                curve: Curves.easeIn));
          }
          await Future.wait(pending);
          pending.clear();
        case ShuffleStep(:final positions):
          _at.clear();
          final moves = <Future<void>>[];
          positions.forEach((id, p) {
            final v = _views[id];
            if (v == null) return;
            _at[p] = v;
            moves.add(_moveTo(v, _center(p), 0.4));
          });
          await Future.wait(moves);
        case TurnEndStep():
          break;
      }
    }
    await Future.wait(pending);
  }

  Future<void> _swapViews(Pos a, Pos b) async {
    final va = _at[a], vb = _at[b];
    if (va == null || vb == null) return;
    _at[a] = vb;
    _at[b] = va;
    await Future.wait([
      _moveTo(va, _center(b), 0.16),
      _moveTo(vb, _center(a), 0.16),
    ]);
  }

  // ------------------------------------------------------------- helpers --

  PieceComponent _spawnView(PieceSnapshot s, Pos at, {Vector2? from}) {
    final v = PieceComponent(
      pieceId: s.id,
      kind: s.kind,
      special: s.special,
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

  Future<void> _pop(PieceComponent v) {
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

  void _flash(Pos p) {
    final r = RectangleComponent(
      position: Vector2(p.col * cell, p.row * cell),
      size: Vector2.all(cell),
      paint: Paint()..color = const Color(0xAAFFFFFF),
    );
    r.add(OpacityEffect.fadeOut(EffectController(duration: 0.3),
        onComplete: r.removeFromParent));
    _layer.add(r);
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
