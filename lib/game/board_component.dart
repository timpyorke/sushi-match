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
import '../core/level.dart' show Gravity;
import '../core/move_finder.dart';
import '../core/pos.dart';
import '../core/settings.dart';
import '../core/piece.dart';
import '../core/steps.dart';
import '../services/audio.dart';
import '../services/wallet.dart';
import 'cat_component.dart';
import 'obstacle_art.dart';
import 'overlay_badges.dart';
import 'piece_painter.dart';
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

  /// Pays for a booster (stock or coins); false means it can't be used.
  /// Whether the booster is affordable; checked before it is tried.
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

  late final List<bool> _isMat = [
    for (var r = 0; r < engine.board.rows; r++)
      for (var c = 0; c < engine.board.cols; c++) engine.matAt(Pos(r, c)),
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

  static final _lockStroke = Paint()
    ..color = const Color(0xFFFFF1D6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;

  void _drawLock(Canvas canvas, Offset c) {
    if (ObstacleArt.ready) {
      ObstacleArt.draw(canvas, ObstacleSprite.lock,
          Rect.fromCenter(center: c, width: 20, height: 20));
      return;
    }
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

  static final _gravityArrow = Paint()..color = const Color(0xCC4A2E1B);

  /// Little arrows beside the board show which way pieces fall (only drawn when
  /// it is not the usual "down").
  void _drawGravityArrows(Canvas canvas) {
    final g = engine.level.gravity;
    if (g == Gravity.down) return;
    final w = size.x, h = size.y;
    final lines = g.vertical ? board.cols : board.rows;
    for (var i = 0; i < lines; i++) {
      final along = (i + 0.5) * cell;
      final (Offset c, double angle) = switch (g) {
        Gravity.up => (Offset(along, -_margin / 2), -math.pi / 2),
        Gravity.left => (Offset(-_margin / 2, along), math.pi),
        Gravity.right => (Offset(w + _margin / 2, along), 0.0),
        Gravity.down => (Offset(along, h + _margin / 2), math.pi / 2),
      };
      if (ObstacleArt.ready) {
        ObstacleArt.draw(canvas, ObstacleSprite.gravity,
            Rect.fromCenter(center: c, width: 26, height: 26),
            // The sprite points down; `angle` is measured from pointing right.
            rot: angle - math.pi / 2);
        continue;
      }
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawPath(
          Path()
            ..moveTo(-5, -6)
            ..lineTo(6, 0)
            ..lineTo(-5, 6)
            ..close(),
          _gravityArrow);
      canvas.restore();
    }
  }

  static final _matFill = Paint()..color = const Color(0xFFCDB872);
  static final _matSlat = Paint()
    ..color = const Color(0xFF8E7A3F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _matTie = Paint()
    ..color = const Color(0xFF5E7F4F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5;

  /// A bamboo mat: slatted square tied with two green cords.
  void _drawMat(Canvas canvas, Rect r) {
    if (ObstacleArt.ready) {
      ObstacleArt.draw(canvas, ObstacleSprite.mat, r.deflate(cell * 0.02));
      return;
    }
    final body = RRect.fromRectAndRadius(
        r.deflate(cell * 0.07), const Radius.circular(cell * 0.12));
    canvas.drawRRect(body, _matFill);
    for (var i = 1; i < 6; i++) {
      final x = body.left + body.width * i / 6;
      canvas.drawLine(
          Offset(x, body.top + 3), Offset(x, body.bottom - 3), _matSlat);
    }
    for (final f in const [0.28, 0.72]) {
      final y = body.top + body.height * f;
      canvas.drawLine(Offset(body.left, y), Offset(body.right, y), _matTie);
    }
    canvas.drawRRect(body, _sackEdge);
  }

  /// A rice sack: round body, gathered neck with a red tie and one dot per
  /// layer left.
  void _drawBag(Canvas canvas, Rect r, int layers) {
    if (ObstacleArt.ready) {
      // The sack's patches (and dots) show how many layers are left.
      ObstacleArt.draw(
          canvas,
          [
            ObstacleSprite.bag1,
            ObstacleSprite.bag2,
            ObstacleSprite.bag3
          ][(layers - 1).clamp(0, 2)],
          r.deflate(cell * 0.02));
      return;
    }
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

  /// The static layer under the pieces (frame, cells, belts, nori, sacks),
  /// recorded once and replayed each frame. Re-recorded only when
  /// [_bgDirty] is set by a step that changes it, or once the tile art lands.
  Picture? _bg;
  bool _bgDirty = true;
  bool _bgArt = false;

  @override
  void render(Canvas canvas) {
    if (_bg == null || _bgDirty || _bgArt != TileArt.ready) {
      _bg?.dispose();
      final recorder = PictureRecorder();
      _paintBackground(Canvas(recorder));
      _bg = recorder.endRecording();
      _bgArt = TileArt.ready;
      _bgDirty = false;
    }
    canvas.drawPicture(_bg!);
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
    _bg?.dispose();
    _bg = null;
    super.onRemove();
  }

  void _paintBackground(Canvas canvas) {
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
    for (final p in engine.level.portals) {
      drawCell(p.entry.row, p.entry.col);
    }
    _drawGravityArrows(canvas);
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
      if (ObstacleArt.ready) {
        ObstacleArt.draw(
            canvas,
            [
              ObstacleSprite.nori1,
              ObstacleSprite.nori2,
              ObstacleSprite.nori3
            ][(layers - 1).clamp(0, 2)],
            rect.deflate(cell * 0.02));
        continue;
      }
      for (var l = 0; l < layers; l++) {
        final rr = RRect.fromRectAndRadius(
            rect.deflate(3.0 + l * 5), const Radius.circular(8));
        canvas.drawRRect(rr, _noriPaint);
        canvas.drawRRect(rr, _noriEdge);
      }
    }
    for (var i = 0; i < _bags.length; i++) {
      if (_bags[i] == 0) continue;
      final rect = Rect.fromLTWH(
          (i % board.cols) * cell, (i ~/ board.cols) * cell, cell, cell);
      if (_isMat[i]) {
        _drawMat(canvas, rect);
      } else {
        _drawBag(canvas, rect, _bags[i]);
      }
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
          Audio.play(Sfx.swap);
          await _swapViews(a, b);
        case InvalidSwapStep(:final a, :final b):
          Audio.play(Sfx.invalid);
          await _swapViews(a, b);
          await _swapViews(a, b);
        case SpecialActivateStep(
            :final affected,
            :final type,
            :final comboWith
          ):
          _flash(affected);
          if (type == SpecialType.wasabi || comboWith == SpecialType.wasabi) {
            _shake();
            Audio.play(Sfx.boom);
          } else {
            Audio.play(Sfx.special);
          }
          await _wait(0.12);
        case TransformStep(:final changes):
          changes.forEach((id, t) => _views[id]?.special = t);
          await _wait(0.25);
        case ClearStep(:final cleared, :final created, :final cascade):
          Audio.play(Sfx.forCascade(cascade));
          // Fewer grains once the board is busy: deep cascades and big
          // blasts would otherwise spawn hundreds of particles at once.
          final grains = cascade >= 2 || cleared.length > 12 ? 4 : 7;
          final pops = <Future<void>>[];
          for (final c in cleared) {
            final v = _views.remove(c.pieceId);
            if (v == null) continue;
            if (identical(_at[c.pos], v)) _at.remove(c.pos);
            _burst(v.position, count: grains);
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
            pending.add(_land(v, _center(m.to), _dist(m.from, m.to)));
          }
        case RefillStep(:final pieces):
          for (final r in pieces) {
            final v = _spawnView(r.piece, r.to, from: _center(r.start));
            pending.add(_land(v, _center(r.to), _dist(r.start, r.to)));
          }
          await Future.wait(pending);
          pending.clear();
        case NoriStep(:final layers):
          layers.forEach((p, n) => _nori[p.row * board.cols + p.col] = n);
          _bgDirty = true;
        case BagStep(:final hits):
          Audio.play(Sfx.crack);
          for (final h in hits) {
            final i = h.pos.row * board.cols + h.pos.col;
            _bags[i] = h.layers;
            if (h.layers == 0) _isMat[i] = false;
            _burst(_center(h.pos), paint: h.layers == 0 ? _sackBurst : null);
          }
          _bgDirty = true;
          await _wait(0.15);
        case DeliverStep(:final delivered):
          Audio.play(Sfx.chime);
          final pops = <Future<void>>[];
          for (final d in delivered) {
            final v = _views.remove(d.pieceId);
            if (v == null) continue;
            if (identical(_at[d.pos], v)) _at.remove(d.pos);
            _burst(v.position, paint: _goldChip);
            pops.add(_pop(v));
          }
          _haptic(HapticFeedback.mediumImpact);
          await Future.wait(pops);
        case UnlockStep(:final cells, :final kind):
          Audio.play(Sfx.unlock);
          for (final p in cells) {
            final badge = _keys.remove(p);
            if (badge == null) continue;
            _burst(_center(p), paint: _kindChips[kind]);
            badge.add(ScaleEffect.to(Vector2.zero(),
                EffectController(duration: 0.25, curve: Curves.easeIn),
                onComplete: badge.removeFromParent));
          }
          _haptic(HapticFeedback.mediumImpact);
          await _wait(0.2);
        case BombStep(:final ticks, :final exploded):
          ticks.forEach((id, left) => _views[id]?.timer = left);
          final pops = <Future<void>>[];
          for (final d in exploded) {
            final v = _views.remove(d.pieceId);
            if (v == null) continue;
            if (identical(_at[d.pos], v)) _at.remove(d.pos);
            _burst(v.position, paint: _emberChip);
            pops.add(_pop(v));
          }
          if (exploded.isNotEmpty) {
            Audio.play(Sfx.boom);
            _shake();
            _haptic(HapticFeedback.heavyImpact);
          }
          await Future.wait(pops);
          await _wait(0.12);
        case IgniteStep(:final pos, :final pieceId):
          _views[pieceId]?.burning = true;
          _burst(_center(pos), paint: _emberChip);
          await _wait(0.18);
        case CatHitStep(:final hits):
          Audio.play(Sfx.meow);
          final runs = <Future<void>>[];
          for (final h in hits) {
            final cat = _cats[h.catId];
            if (cat == null) continue;
            cat.hp = h.hp;
            if (h.hp > 0) {
              cat.play(CatAnim.hit);
              cat.add(SequenceEffect([
                RotateEffect.by(0.25, EffectController(duration: 0.06)),
                RotateEffect.by(-0.5, EffectController(duration: 0.12)),
                RotateEffect.by(0.25, EffectController(duration: 0.06)),
              ]));
              continue;
            }
            // Out of lives: the cat bolts off the board.
            _cats.remove(h.catId);
            cat.faceRight = true; // bolts off to the right
            cat.play(CatAnim.flee);
            final done = Completer<void>();
            cat.add(MoveByEffect(Vector2(cell * 2.5, -cell * 0.6),
                EffectController(duration: 0.4, curve: Curves.easeIn),
                onComplete: () {
              cat.removeFromParent();
              done.complete();
            }));
            runs.add(done.future);
          }
          _haptic(HapticFeedback.lightImpact);
          await Future.wait(runs);
          await _wait(0.1);
        case CatMoveStep(:final catId, :final to):
          final cat = _cats[catId];
          if (cat == null) break;
          final dest = _center(to);
          if (dest.x != cat.position.x) cat.faceRight = dest.x > cat.position.x;
          cat.play(CatAnim.prowl);
          await _moveTo(cat, _center(to), 0.3);
          cat.play(CatAnim.eat);
        case MatSpreadStep(:final pos, :final pieceId):
          final v = _views.remove(pieceId);
          if (v != null) {
            if (identical(_at[pos], v)) _at.remove(pos);
            await _pop(v);
          }
          final i = pos.row * board.cols + pos.col;
          _bags[i] = 1;
          _isMat[i] = true;
          _bgDirty = true;
          _burst(_center(pos), paint: _matChip);
          await _wait(0.1);
        case IceStep(:final hits):
          Audio.play(Sfx.crack);
          for (final h in hits) {
            _views[h.pieceId]?.ice = h.layers;
            if (h.layers == 0) _burst(_center(h.pos), paint: _iceChip);
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
          Audio.play(Sfx.shuffle);
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

  static final _rice = Paint()..color = const Color(0xFFFFFDF5);
  static final _emberChip = Paint()..color = const Color(0xFFFF6A1F);
  static final _goldChip = Paint()..color = const Color(0xFFFFD54F);
  static final _matChip = Paint()..color = const Color(0xFFCDB872);
  static final _sackBurst = Paint()..color = const Color(0xFFE9D3A8);
  static final _iceChip = Paint()..color = const Color(0xFFBFE8FA);
  static final _sesame = Paint()..color = const Color(0xFF3B2A20);
  static final _kindChips = {
    for (final e in PiecePainter.colors.entries)
      e.key: Paint()..color = e.value,
  };
  final _rng = math.Random();

  /// Cap on grain bursts alive at once; extra ones in a big combo are
  /// dropped (the pop animation still plays).
  static const _maxBursts = 18;
  int _liveBursts = 0;

  /// Rice and sesame grains flying off a cleared piece.
  void _burst(Vector2 at, {Paint? paint, int count = 7}) {
    if (_liveBursts >= _maxBursts) return;
    _liveBursts++;
    _layer.add(_Burst(
      onGone: () => _liveBursts--,
      position: at.clone(),
      particle: Particle.generate(
        count: count,
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

  /// White flash over every cell a special hits, as one component.
  void _flash(Iterable<Pos> cells) {
    _layer.add(_Flash([
      for (final p in cells)
        Rect.fromLTWH(p.col * cell, p.row * cell, cell, cell)
    ]));
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

/// A grain burst that reports when it is gone, for [BoardComponent]'s cap.
class _Burst extends ParticleSystemComponent {
  _Burst({required this.onGone, super.position, super.particle});

  final void Function() onGone;

  @override
  void onRemove() {
    onGone();
    super.onRemove();
  }
}

/// Fading white rectangles over the cells a special hit.
class _Flash extends Component {
  _Flash(this.rects);

  final List<Rect> rects;
  final _paint = Paint();
  double _t = 0;

  static const _life = 0.3;
  static const _alpha = 0xAA / 0xFF;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    _paint.color = const Color(0xFFFFFFFF)
        .withValues(alpha: _alpha * (1 - _t / _life).clamp(0.0, 1.0));
    for (final r in rects) {
      canvas.drawRect(r, _paint);
    }
  }
}
