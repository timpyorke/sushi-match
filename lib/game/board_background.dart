import 'dart:math' as math;
import 'dart:ui';

import '../core/board.dart';
import '../core/game_engine.dart';
import '../core/level.dart' show Gravity;
import '../core/pos.dart';
import 'obstacle_art.dart';
import 'tile_art.dart';

/// The static layer under the pieces: cells, frame, gravity arrows, belts,
/// nori, rice sacks and bamboo mats. Recorded once into a [Picture] and
/// replayed each frame; re-recorded only after a change through [setNori],
/// [setBag] or [spreadMat], or once the tile art lands.
///
/// Each obstacle has a flat-colour fallback for when its sprites are not
/// loaded (as in tests).
class BoardBackground {
  BoardBackground(this.engine, {required this.cell, required this.margin})
      : _bags = [for (final p in _cells(engine.board)) engine.bagAt(p)],
        _isMat = [for (final p in _cells(engine.board)) engine.matAt(p)],
        _nori = [for (final p in _cells(engine.board)) engine.noriAt(p)];

  final GameEngine engine;

  /// Cell size in logical pixels.
  final double cell;

  /// Space round the board for the gravity arrows.
  final double margin;

  /// Per-cell state mirrored from the engine as steps play back.
  final List<int> _bags;
  final List<bool> _isMat;
  final List<int> _nori;

  Picture? _picture;
  bool _dirty = true;
  bool _art = false;

  Board get board => engine.board;

  static Iterable<Pos> _cells(Board b) sync* {
    for (var r = 0; r < b.rows; r++) {
      for (var c = 0; c < b.cols; c++) {
        yield Pos(r, c);
      }
    }
  }

  int _i(Pos p) => p.row * board.cols + p.col;

  Rect _rectAt(int i) => Rect.fromLTWH(
      (i % board.cols) * cell, (i ~/ board.cols) * cell, cell, cell);

  void setNori(Pos p, int layers) {
    _nori[_i(p)] = layers;
    _dirty = true;
  }

  /// A bag or mat on [p] now has [layers] left; at zero the mat is gone.
  void setBag(Pos p, int layers) {
    final i = _i(p);
    _bags[i] = layers;
    if (layers == 0) _isMat[i] = false;
    _dirty = true;
  }

  /// A mat grew onto [p].
  void spreadMat(Pos p) {
    final i = _i(p);
    _bags[i] = 1;
    _isMat[i] = true;
    _dirty = true;
  }

  void draw(Canvas canvas) {
    if (_picture == null || _dirty || _art != TileArt.ready) {
      _picture?.dispose();
      final recorder = PictureRecorder();
      _paint(Canvas(recorder));
      _picture = recorder.endRecording();
      _art = TileArt.ready;
      _dirty = false;
    }
    canvas.drawPicture(_picture!);
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
  }

  // ------------------------------------------------------------- painting --

  static final _cellA = Paint()..color = const Color(0xFFEBD5AE);
  static final _cellB = Paint()..color = const Color(0xFFE2C796);
  static final _noriPaint = Paint()..color = const Color(0xCC1F3A24);
  static final _noriEdge = Paint()
    ..color = const Color(0xFF6BAA75)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final _beltPaint = Paint()..color = const Color(0x664A3B2A);
  static final _beltArrow = Paint()..color = const Color(0xCCFFF1D6);
  static final _lockStroke = Paint()
    ..color = const Color(0xFFFFF1D6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;
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
  static final _matFill = Paint()..color = const Color(0xFFCDB872);
  static final _matSlat = Paint()
    ..color = const Color(0xFF8E7A3F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _matTie = Paint()
    ..color = const Color(0xFF5E7F4F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5;

  void _paint(Canvas canvas) {
    for (final p in board.positions) {
      _drawCell(canvas, p.row, p.col);
    }
    for (final p in engine.level.portals) {
      _drawCell(canvas, p.entry.row, p.entry.col);
    }
    _drawFrame(canvas);
    _drawGravityArrows(canvas);
    // Bagged cells sit on a plain tile too; the sack is drawn over the pieces.
    for (var i = 0; i < _bags.length; i++) {
      if (_bags[i] > 0) _drawCell(canvas, i ~/ board.cols, i % board.cols);
    }
    for (final c in engine.level.conveyors) {
      _drawBelt(canvas, c.row, c.dir);
    }
    for (var i = 0; i < _nori.length; i++) {
      if (_nori[i] > 0) _drawNori(canvas, _rectAt(i), _nori[i]);
    }
    for (var i = 0; i < _bags.length; i++) {
      if (_bags[i] == 0) continue;
      if (_isMat[i]) {
        _drawMat(canvas, _rectAt(i));
      } else {
        _drawBag(canvas, _rectAt(i), _bags[i]);
      }
    }
  }

  void _drawCell(Canvas canvas, int row, int col) {
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

  /// Red lacquer rail round the outside of the playable cells.
  void _drawFrame(Canvas canvas) {
    if (!TileArt.ready) return;
    bool open(Pos p) => !board.isPlayable(p);
    for (final p in board.positions) {
      var t = open(Pos(p.row - 1, p.col)),
          r = open(Pos(p.row, p.col + 1)),
          b = open(Pos(p.row + 1, p.col)),
          l = open(Pos(p.row, p.col - 1));
      final rect = Rect.fromLTWH(p.col * cell, p.row * cell, cell, cell);
      void corner(int turns) =>
          TileArt.frame(canvas, rect, turns: turns, corner: true);
      if (t && l) {
        corner(0);
        t = l = false;
      }
      if (t && r) {
        corner(1);
        t = r = false;
      }
      if (b && r) {
        corner(2);
        b = r = false;
      }
      if (b && l) {
        corner(3);
        b = l = false;
      }
      if (t) TileArt.frame(canvas, rect, turns: 0, corner: false);
      if (r) TileArt.frame(canvas, rect, turns: 1, corner: false);
      if (b) TileArt.frame(canvas, rect, turns: 2, corner: false);
      if (l) TileArt.frame(canvas, rect, turns: 3, corner: false);
    }
  }

  /// Little arrows beside the board show which way pieces fall (only drawn when
  /// it is not the usual "down").
  void _drawGravityArrows(Canvas canvas) {
    final g = engine.level.gravity;
    if (g == Gravity.down) return;
    final w = board.cols * cell, h = board.rows * cell;
    final lines = g.vertical ? board.cols : board.rows;
    for (var i = 0; i < lines; i++) {
      final along = (i + 0.5) * cell;
      final (Offset c, double angle) = switch (g) {
        Gravity.up => (Offset(along, -margin / 2), -math.pi / 2),
        Gravity.left => (Offset(-margin / 2, along), math.pi),
        Gravity.right => (Offset(w + margin / 2, along), 0.0),
        Gravity.down => (Offset(along, h + margin / 2), math.pi / 2),
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

  /// A conveyor along [row], moving [dir] (+1 right, -1 left).
  void _drawBelt(Canvas canvas, int row, int dir) {
    final cols = [
      for (var col = 0; col < board.cols; col++)
        if (board.isPlayable(Pos(row, col))) col,
    ];
    if (cols.isEmpty) return;
    final y = row * cell;
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
      final band = Rect.fromLTWH(
          cols.first * cell, y, (cols.last - cols.first + 1) * cell, cell);
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
            dir);
        continue;
      }
      final d = dir * 6.0;
      canvas.drawPath(
          Path()
            ..moveTo(cx - d, cy - 5)
            ..lineTo(cx + d, cy)
            ..lineTo(cx - d, cy + 5)
            ..close(),
          _beltArrow);
    }
  }

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

  /// Nori sheets under a cell, one per layer left.
  void _drawNori(Canvas canvas, Rect rect, int layers) {
    if (ObstacleArt.ready) {
      ObstacleArt.draw(
          canvas,
          const [
            ObstacleSprite.nori1,
            ObstacleSprite.nori2,
            ObstacleSprite.nori3
          ][(layers - 1).clamp(0, 2)],
          rect.deflate(cell * 0.02));
      return;
    }
    for (var l = 0; l < layers; l++) {
      final rr = RRect.fromRectAndRadius(
          rect.deflate(3.0 + l * 5), const Radius.circular(8));
      canvas.drawRRect(rr, _noriPaint);
      canvas.drawRRect(rr, _noriEdge);
    }
  }

  /// A bamboo mat: slatted square tied with two green cords.
  void _drawMat(Canvas canvas, Rect r) {
    if (ObstacleArt.ready) {
      ObstacleArt.draw(canvas, ObstacleSprite.mat, r.deflate(cell * 0.02));
      return;
    }
    final body = RRect.fromRectAndRadius(
        r.deflate(cell * 0.07), Radius.circular(cell * 0.12));
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
          const [
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
        Radius.circular(cell * 0.28));
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
}
