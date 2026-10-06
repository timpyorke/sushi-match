import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/piece.dart';
import '../game/piece_painter.dart';
import '../game/tile_art.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'ui_art.dart';

/// Level picker laid out as a tidy serpentine belt: straight rows joined by
/// U-turns, each row running the opposite way. Level 1 sits at the bottom;
/// the player scrolls up through the levels. Starts centred on the
/// level they should play next.
class LevelSelectView extends StatefulWidget {
  const LevelSelectView(
      {super.key,
      required this.levelCount,
      required this.cleared,
      required this.onSelect,
      this.maxPlayable,
      required this.onShopLocked,
      this.onRestaurant,
      this.onSettings});

  final int levelCount;

  /// Highest cleared level; the next one is playable, the rest are locked.
  final int cleared;
  final ValueChanged<int> onSelect;

  /// Highest level whose restaurant is unlocked; null means no limit.
  final int? maxPlayable;
  final VoidCallback? onRestaurant;

  /// Called when a level behind a locked restaurant is tapped.
  final ValueChanged<int> onShopLocked;
  final VoidCallback? onSettings;

  @override
  State<LevelSelectView> createState() => _LevelSelectViewState();
}

class _LevelSelectViewState extends State<LevelSelectView> {
  static const _perRow = 3;
  static const _rowGap = 112.0;
  static const _uTurn = _rowGap / 2;
  static const _margin = _uTurn + 32;
  static const _padding = 80.0;

  final _scroll = ScrollController();
  bool _positioned = false;

  @override
  void initState() {
    super.initState();
    TileArt.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  int get _rows => (widget.levelCount / _perRow).ceil();

  double get _mapHeight => (_rows - 1) * _rowGap + _padding * 2;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The list is reversed, so offset 0 is the bottom (level 1).
  void _focusCurrent(double viewport) {
    if (_positioned) return;
    _positioned = true;
    final current = math.min(widget.cleared + 1,
        math.min(widget.levelCount, widget.maxPlayable ?? widget.levelCount));
    final row = (current - 1) ~/ _perRow;
    final target = _padding + row * _rowGap - viewport / 2;
    final max = math.max(0.0, _mapHeight - viewport);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(target.clamp(0.0, max));
    });
  }

  bool _shopLocked(int n) => n > (widget.maxPlayable ?? widget.levelCount);

  void _tap(int n) {
    if (_shopLocked(n)) {
      widget.onShopLocked(n);
      return;
    }
    if (n > widget.cleared + 1) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(L10n.t('clearFirst', {'n': n - 1}))));
      return;
    }
    widget.onSelect(n);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, top: 8),
              child: WalletBar(),
            ),
            const Spacer(),
            if (widget.onRestaurant != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: RoundIconButton(
                    icon: Icons.storefront, onPressed: widget.onRestaurant!),
              ),
            if (widget.onSettings != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: RoundIconButton(
                    icon: Icons.settings, onPressed: widget.onSettings!),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text('Sushi Match',
              style: t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Text(L10n.t('pickPlate'), style: t.titleMedium),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            _focusCurrent(box.maxHeight);
            final w = box.maxWidth;
            final step = (w - _margin * 2) / (_perRow - 1);
            // Centre of level n (1-based), y measured from the top of the map.
            // Odd rows run right-to-left so the belt snakes.
            Offset centre(int n) {
              final row = (n - 1) ~/ _perRow;
              final col = (n - 1) % _perRow;
              final x = _margin + (row.isOdd ? _perRow - 1 - col : col) * step;
              return Offset(x, _mapHeight - _padding - row * _rowGap);
            }

            return SingleChildScrollView(
              controller: _scroll,
              reverse: true,
              child: SizedBox(
                width: w,
                height: _mapHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PathPainter([
                          for (var n = 1; n <= widget.levelCount; n++) centre(n)
                        ], _rows, _rowGap, _mapHeight - _padding, _uTurn,
                            _margin),
                      ),
                    ),
                    for (var n = 1; n <= widget.levelCount; n++)
                      Positioned(
                        left: centre(n).dx - 36,
                        top: centre(n).dy - 49,
                        child: _Plate(
                          level: n,
                          locked: n > widget.cleared + 1 || _shopLocked(n),
                          done: n <= widget.cleared,
                          current: n == widget.cleared + 1 && !_shopLocked(n),
                          onTap: () => _tap(n),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Wooden belt that snakes through the level centres.
class _PathPainter extends CustomPainter {
  _PathPainter(
      this.points, this.rows, this.rowGap, this.baseY, this.tile, this.margin);
  final List<Offset> points;
  final int rows;
  final double rowGap, baseY, tile, margin;

  /// Belt built from tileset01: straights along each row, corner tiles at
  /// the U-turns and a rounded cap at both ends of the whole belt.
  void _paintTiles(Canvas canvas, Size size) {
    final s = tile;
    final xl = margin - s, xr = size.width - margin + s;
    final n = math.max(2, ((xr - xl) / s).round());
    final dx = (xr - xl) / n;
    for (var r = 0; r < rows; r++) {
      final y = baseY - r * rowGap;
      final first = r == 0, last = r == rows - 1;
      for (var i = 0; i <= n; i++) {
        final c = Offset(xl + i * dx, y);
        if (i > 0 && i < n) {
          TileArt.mapTile(canvas, MapTile.straight, c, dx + 0.6, s);
        } else if (i == 0) {
          if (first || (last && r.isOdd)) {
            TileArt.mapTile(canvas, MapTile.cap, c, s, s, flipX: true);
          } else if (r.isOdd) {
            TileArt.mapTile(canvas, MapTile.corner, c, s, s, rot: math.pi);
          } else {
            TileArt.mapTile(canvas, MapTile.corner, c, s, s, flipX: true);
          }
        } else if (last && r.isEven) {
          TileArt.mapTile(canvas, MapTile.cap, c, s, s);
        } else if (r.isEven) {
          TileArt.mapTile(canvas, MapTile.corner, c, s, s, flipY: true);
        } else {
          TileArt.mapTile(canvas, MapTile.corner, c, s, s);
        }
      }
      if (last) continue;
      final x = r.isEven ? xr : xl;
      TileArt.mapTile(canvas, MapTile.straight, Offset(x, y - s), s, s + 0.6,
          rot: math.pi / 2);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (TileArt.ready) {
      _paintTiles(canvas, size);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      if (a.dy == b.dy) {
        path.lineTo(b.dx, b.dy);
      } else {
        // U-turn at the end of a row: bulge away from the map centre.
        final right = a.dx > size.width / 2;
        path.arcToPoint(b,
            radius: Radius.circular((a.dy - b.dy).abs() / 2),
            clockwise: !right);
      }
    }
    Paint stroke(double w, Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w
      ..color = c;
    canvas.drawPath(path, stroke(44, const Color(0xFF2B211C)));
    canvas.drawPath(path, stroke(36, const Color(0xFF4A3B33)));
    // Dashes like the belt's slats.
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 22) {
        final t = m.getTangentForOffset(d)!;
        final n = Offset(-t.vector.dy, t.vector.dx);
        canvas.drawLine(t.position - n * 13, t.position + n * 13,
            stroke(3, const Color(0xFF6D5A4E)));
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => true;
}

class _Plate extends StatelessWidget {
  const _Plate(
      {required this.level,
      required this.locked,
      required this.done,
      required this.current,
      required this.onTap});
  final int level;
  final bool locked;
  final bool done;

  /// The next level to play: gets a glow.
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = PieceKind.values[(level - 1) % PieceKind.values.length];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: current
                ? const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0xCCFFD54F),
                          blurRadius: 18,
                          spreadRadius: 4)
                    ],
                  )
                : null,
            child: locked
                ? const Icon(Icons.lock, size: 40, color: Colors.black54)
                : CustomPaint(painter: _SushiPainter(kind)),
          ),
          Container(
            width: 72,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: locked ? Colors.grey.shade400 : Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                  color:
                      locked ? Colors.grey.shade600 : const Color(0xFFB71C2C),
                  width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 4, offset: Offset(0, 3))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$level',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (done) ...[
                  const SizedBox(width: 4),
                  const StarIcon(size: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SushiPainter extends CustomPainter {
  _SushiPainter(this.kind);
  final PieceKind kind;

  @override
  void paint(Canvas canvas, Size size) =>
      PiecePainter.paint(canvas, size.width, kind, null);

  @override
  bool shouldRepaint(_SushiPainter old) => old.kind != kind;
}
