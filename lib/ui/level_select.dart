import 'package:flutter/material.dart';

import '../core/piece.dart';
import '../game/piece_painter.dart';
import 'ui_art.dart';

/// Kaiten-sushi style level picker: plates ride on conveyor belts, tap one to
/// play that level.
class LevelSelectView extends StatelessWidget {
  const LevelSelectView(
      {super.key,
      required this.levelCount,
      required this.cleared,
      required this.onSelect});

  final int levelCount;

  /// Highest cleared level; the next one is playable, the rest are locked.
  final int cleared;
  final ValueChanged<int> onSelect;

  static const _perBelt = 5;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final beltCount = (levelCount / _perBelt).ceil();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 4),
          child: Text('Sushi Match',
              style: t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Text('Pick a plate', style: t.titleMedium),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var b = 0; b < beltCount; b++) ...[
                _Belt(
                  levels: [
                    for (var n = b * _perBelt + 1;
                        n <= levelCount && n <= (b + 1) * _perBelt;
                        n++)
                      n
                  ],
                  cleared: cleared,
                  onSelect: (n) {
                    if (n > cleared + 1) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            content: Text('Clear level ${n - 1} first')));
                      return;
                    }
                    onSelect(n);
                  },
                ),
                const SizedBox(height: 28),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Belt extends StatelessWidget {
  const _Belt({
    required this.levels,
    required this.cleared,
    required this.onSelect,
  });

  final List<int> levels;
  final int cleared;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            height: 34,
            child: CustomPaint(painter: _TrackPainter()),
          ),
          Positioned.fill(
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final n in levels)
                  Expanded(
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomCenter,
                          child: _Plate(
                            level: n,
                            locked: n > cleared + 1,
                            done: n <= cleared,
                            onTap: () => onSelect(n),
                          ))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = const Color(0xFF4A3B33));
    canvas.drawRRect(
        r,
        Paint()
          ..color = const Color(0xFF2B211C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final tick = Paint()
      ..color = const Color(0xFF6D5A4E)
      ..strokeWidth = 3;
    const slot = 60.0;
    for (var x = 0.0; x < size.width + slot; x += slot) {
      canvas.drawLine(Offset(x, 8), Offset(x - 8, size.height - 8), tick);
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) => false;
}

class _Plate extends StatelessWidget {
  const _Plate(
      {required this.level,
      required this.locked,
      required this.done,
      required this.onTap});
  final int level;
  final bool locked;
  final bool done;
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
          SizedBox(
            width: 64,
            height: 64,
            child: locked
                ? const Icon(Icons.lock, size: 40, color: Colors.black54)
                : CustomPaint(painter: _SushiPainter(kind)),
          ),
          Container(
            width: 84,
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
