import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/board.dart';
import '../core/game_engine.dart';
import '../core/move_finder.dart';
import '../core/pos.dart';
import '../core/settings.dart';
import '../core/piece.dart';
import '../core/steps.dart';
import '../services/wallet.dart';
import 'piece_component.dart';
import 'tile_art.dart';

/// View for the board. Owns no rules: it forwards input to [GameEngine]
/// and plays back the returned [BoardStep]s one by one.
class BoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  BoardComponent({
    required this.engine,
    required this.onTurnFinished,
    required this.onPraise,
    required this.armed,
    required this.onSpendBooster,
  }) : super(
          size: Vector2(engine.board.cols * cell, engine.board.rows * cell),
        );

  /// Logical cell size. The whole board is scaled to fit the screen.
  static const double cell = 64;
  static const double _hintDelay = 5;

  /// Thickness of the wooden frame drawn round the board.
  static const double _frame = 26;

  final GameEngine engine;
  final void Function() onTurnFinished;

  /// Called with the chef's cheer when a turn chained into a combo.
  final void Function(String) onPraise;

  /// Booster waiting for a tap; cleared once it fires.
  final ValueNotifier<Booster?> armed;

  /// Pays for a booster (stock or coins); false means it can't be used.
  final bool Function(Booster) onSpendBooster;

  final _views = <int, PieceComponent>{};
  final _at = <Pos, PieceComponent>{};
  late final ClipComponent _layer;

  bool _busy = false;
  Pos? _selected;
  Pos? _dragFrom;
  final Vector2 _drag = Vector2.zero();
  double _idle = 0;
  final List<Effect> _hint = [];

  late final List<int> _bags = [
    for (var r = 0; r < engine.board.rows; r++)
      for (var c = 0; c < engine.board.cols; c++) engine.bagAt(Pos(r, c)),
  ];

  late final List<int> _nori = [
    for (final p in [
      for (var r = 0; r < engine.board.rows; r++)
        for (var c = 0; c < engine.board.cols; c++) Pos(r, c),
    ])
      engine.noriAt(p),
  ];

  Board get board => engine.board;

  static final _cellA = Paint()..color = const Color(0xFFEBD5AE);
  static final _cellB = Paint()..color = const Color(0xFFE2C796);
  static final _noriPaint = Paint()..color = const Color(0xCC1F3A24);
  static final _noriEdge = Paint()
    ..color = const Color(0xFF6BAA75)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final _beltPaint = Paint()..color = const Color(0x664A3B2A);
  static final _beltArrow = Paint()..color = const Color(0xCCFFF1D6);
  static final _selPaint = Paint()..color = const Color(0x88FFFFFF);

  @override
  Future<void> onLoad() async {
    await TileArt.load();
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
    final s = math.min(gameSize.x * 0.96 / (size.x + 2 * _frame),
        gameSize.y * 0.96 / (size.y + 2 * _frame));
    scale = Vector2.all(s);
    position = (gameSize - size * s) / 2;
  }

  static final _lockStroke = Paint()
    ..color = const Color(0xFFFFF1D6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;

  void _drawLock(Canvas canvas, Offset c) {
    canvas.drawArc(
        Rect.fromCenter(center: c.translate(0, -3), width: 9, height: 12),
        math.pi,
        math.pi,
        false,
        _lockStroke);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: c.translate(0, 2), width: 14, height: 10),
            const Radius.circular(2.5)),
        _beltArrow);
  }

  static final _sackFill = Paint()..color = const Color(0xFFE9D3A8);
  static final _sackShade = Paint()..color = const Color(0xFFD1B47F);
  static final _sackEdge = Paint()
    ..color = const Color(0xFF6B4F2A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final _sackTie = Paint()
    ..color = const Color(0xFFB5472F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  static final _sackDot = Paint()..color = const Color(0xFF6B4F2A);

  /// A rice sack: round body, gathered neck with a red tie and one dot per
  /// layer left.
  void _drawBag(Canvas canvas, Rect r, int layers) {
    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + cell * 0.12, r.top + cell * 0.26, cell * 0.76,
            cell * 0.64),
        const Radius.circular(cell * 0.28));
    final neck = Path()
      ..moveTo(r.left + cell * 0.34, r.top + cell * 0.30)
      ..lineTo(r.left + cell * 0.40, r.top + cell * 0.12)
      ..lineTo(r.left + cell * 0.60, r.top + cell * 0.12)
      ..lineTo(r.left + cell * 0.66, r.top + cell * 0.30)
      ..close();
    canvas.drawPath(neck, _sackShade);
    canvas.drawPath(neck, _sackEdge);
    canvas.drawRRect(body, _sackFill);
    canvas.drawRRect(body, _sackEdge);
    canvas.drawLine(Offset(r.left + cell * 0.36, r.top + cell * 0.27),
        Offset(r.left + cell * 0.64, r.top + cell * 0.27), _sackTie);
    for (var i = 0; i < layers; i++) {
      canvas.drawCircle(
          Offset(r.center.dx + (i - (layers - 1) / 2) * cell * 0.16,
              r.top + cell * 0.66),
          cell * 0.05,
          _sackDot);
    }
  }

  @override
  void render(Canvas canvas) {
    if (TileArt.ready) {
      TileArt.frame(canvas, Offset.zero & Size(size.x, size.y), _frame);
    }
    void drawCell(int row, int col) {
      final rect = Rect.fromLTWH(col * cell, row * cell, cell, cell);
      final dark = (row + col).isOdd;
      if (TileArt.ready) {
        TileArt.cell(canvas, rect, dark: dark);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(8)),
          dark ? _cellB : _cellA,
        );
      }
    }

    for (final p in board.positions) {
      drawCell(p.row, p.col);
    }
    // Bagged cells sit on a plain tile too; the sack is drawn over the pieces.
    for (var i = 0; i < _bags.length; i++) {
      if (_bags[i] > 0) drawCell(i ~/ board.cols, i % board.cols);
    }
    for (final c in engine.level.conveyors) {
      final cols = [
        for (var col = 0; col < board.cols; col++)
          if (board.isPlayable(Pos(c.row, col))) col,
      ];
      if (cols.isEmpty) continue;
      final y = c.row * cell;
      final band = Rect.fromLTWH(
          cols.first * cell, y, (cols.last - cols.first + 1) * cell, cell);
      if (TileArt.ready) {
        for (final col in cols) {
          final rect = Rect.fromLTWH(col * cell, y, cell, cell);
          if (col == cols.first) {
            TileArt.beltCap(canvas, rect, leftEnd: true);
          } else if (col == cols.last) {
            TileArt.beltCap(canvas, rect, leftEnd: false);
          } else {
            TileArt.belt(canvas, rect);
          }
        }
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(band.deflate(1), const Radius.circular(8)),
            _beltPaint);
      }
      // Padlocks at both ends: the belt's pieces can't be swapped by hand.
      _drawLock(canvas, Offset(cols.first * cell + 15, y + cell - 14));
      _drawLock(canvas, Offset((cols.last + 1) * cell - 15, y + cell - 14));
      for (final col in cols) {
        final cx = col * cell + cell / 2, cy = y + cell - 9;
        if (TileArt.ready) {
          TileArt.arrow(
              canvas,
              Rect.fromCenter(center: Offset(cx, cy), width: 20, height: 12),
              c.dir);
          continue;
        }
        final d = c.dir * 6.0;
        canvas.drawPath(
            Path()
              ..moveTo(cx - d, cy - 5)
              ..lineTo(cx + d, cy)
              ..lineTo(cx - d, cy + 5)
              ..close(),
            _beltArrow);
      }
    }
    for (var i = 0; i < _nori.length; i++) {
      final layers = _nori[i];
      if (layers == 0) continue;
      final rect = Rect.fromLTWH(
          (i % board.cols) * cell, (i ~/ board.cols) * cell, cell, cell);
      for (var l = 0; l < layers; l++) {
        final rr = RRect.fromRectAndRadius(
            rect.deflate(3.0 + l * 5), const Radius.circular(8));
        canvas.drawRRect(rr, _noriPaint);
        canvas.drawRRect(rr, _noriEdge);
      }
    }
    for (var i = 0; i < _bags.length; i++) {
      if (_bags[i] == 0) continue;
      _drawBag(
          canvas,
          Rect.fromLTWH(
              (i % board.cols) * cell, (i ~/ board.cols) * cell, cell, cell),
          _bags[i]);
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

  Future<void> _runBooster(Booster b, List<BoardStep> Function() run) async {
    if (_busy || engine.status != GameStatus.playing) return;
    if (!onSpendBooster(b)) return;
    _busy = true;
    _clearHint();
    armed.value = null;
    _selected = null;
    try {
      await _play(run());
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
        case SpecialActivateStep(
            :final affected,
            :final type,
            :final comboWith
          ):
          for (final p in affected) {
            _flash(p);
          }
          if (type == SpecialType.wasabi || comboWith == SpecialType.wasabi) {
            _shake();
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
            _burst(v.position);
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
            pending.add(_land(v, _center(m.to), m.to.row - m.from.row));
          }
        case RefillStep(:final pieces):
          for (final r in pieces) {
            final start =
                Vector2(_center(r.to).x, r.startRow * cell + cell / 2);
            final v = _spawnView(r.piece, r.to, from: start);
            pending.add(_land(v, _center(r.to), r.to.row - r.startRow));
          }
          await Future.wait(pending);
          pending.clear();
        case NoriStep(:final layers):
          layers.forEach((p, n) => _nori[p.row * board.cols + p.col] = n);
        case BagStep(:final hits):
          for (final h in hits) {
            _bags[h.pos.row * board.cols + h.pos.col] = h.layers;
            _burst(_center(h.pos), h.layers == 0 ? _sackBurst : null);
          }
          await _wait(0.15);
        case IceStep(:final hits):
          for (final h in hits) {
            _views[h.pieceId]?.ice = h.layers;
            if (h.layers == 0) _burst(_center(h.pos), _iceChip);
          }
          await _wait(0.12);
        case ConveyorStep(:final moves):
          for (final m in moves) {
            _at.remove(m.from);
          }
          final slides = <Future<void>>[];
          for (final m in moves) {
            final v = _views[m.pieceId];
            if (v == null) continue;
            _at[m.to] = v;
            slides.add(_moveTo(v, _center(m.to), 0.3));
          }
          await Future.wait(slides);
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
      ice: s.ice,
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

  static final _rice = Paint()..color = const Color(0xFFFFFDF5);
  static final _sackBurst = Paint()..color = const Color(0xFFE9D3A8);
  static final _iceChip = Paint()..color = const Color(0xFFBFE8FA);
  static final _sesame = Paint()..color = const Color(0xFF3B2A20);
  final _rng = math.Random();

  /// Rice and sesame grains flying off a cleared piece.
  void _burst(Vector2 at, [Paint? paint]) {
    _layer.add(ParticleSystemComponent(
      position: at.clone(),
      particle: Particle.generate(
        count: 7,
        lifespan: 0.55,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 360),
          speed: Vector2(
              (_rng.nextDouble() - 0.5) * 240, -60 - _rng.nextDouble() * 170),
          child: CircleParticle(
            radius: i.isEven ? 2.8 : 2.0,
            paint: paint ?? (i.isEven ? _rice : _sesame),
          ),
        ),
      ),
    ));
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
