import 'package:flutter/material.dart';

import '../core/piece.dart';
import '../game/piece_painter.dart';
import '../services/audio.dart';
import '../services/restaurant.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'ui_art.dart';

/// Level picker grouped by Japanese region. Each restaurant is one zone: a
/// banner (region name, progress, lock state) above a grid of its levels.
/// Opens scrolled to the zone holding the next level to play.
class LevelSelectView extends StatefulWidget {
  const LevelSelectView(
      {super.key,
      required this.levelCount,
      required this.cleared,
      this.stars = const {},
      required this.onSelect,
      this.maxPlayable,
      required this.onShopLocked,
      this.onRestaurant,
      this.onShop,
      this.onSettings});

  final int levelCount;

  /// Highest cleared level; the next one is playable, the rest are locked.
  final int cleared;

  /// Best stars (1-3) per level number.
  final Map<int, int> stars;
  final ValueChanged<int> onSelect;

  /// Highest level whose restaurant is unlocked; null means no limit.
  final int? maxPlayable;
  final VoidCallback? onRestaurant;
  final VoidCallback? onShop;

  /// Called when a level behind a locked restaurant is tapped.
  final ValueChanged<int> onShopLocked;
  final VoidCallback? onSettings;

  @override
  State<LevelSelectView> createState() => _LevelSelectViewState();
}

/// Banner colours and kanji for a [ShopDef], matched by id.
class _ZoneStyle {
  const _ZoneStyle(this.kanji, this.top, this.bottom);
  final String kanji;
  final Color top, bottom;
}

const _zoneStyles = {
  'tsukiji': _ZoneStyle('東京', Color(0xFF4FA3D1), Color(0xFF2B6E99)),
  'osaka': _ZoneStyle('大阪', Color(0xFFF08A3C), Color(0xFFC25A16)),
  'kyoto': _ZoneStyle('京都', Color(0xFFE56B8F), Color(0xFFB03A60)),
  'hokkaido': _ZoneStyle('北海道', Color(0xFF6FC3C9), Color(0xFF3A8A98)),
};

class _LevelSelectViewState extends State<LevelSelectView> {
  final _scroll = ScrollController();
  final _currentKey = GlobalKey();
  bool _positioned = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _focusCurrent() {
    if (_positioned) return;
    _positioned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.1);
      }
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
    Audio.play(Sfx.tap);
    widget.onSelect(n);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final next = widget.cleared + 1;
    _focusCurrent();
    return Column(
      children: [
        Row(
          children: [
            // Shrinks on narrow phones so the three buttons still fit.
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 12, top: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: WalletBar(),
                ),
              ),
            ),
            if (widget.onShop != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: RoundIconButton(
                    icon: Icons.shopping_bag, onPressed: widget.onShop!),
              ),
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
          child: OutlinedTitle('Sushi Trio', style: t.headlineLarge),
        ),
        Text(L10n.t('pickPlate'), style: t.titleMedium),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: Column(
              children: [
                for (final shop in Restaurant.shops)
                  if (shop.firstLevel <= widget.levelCount)
                    _ZoneSection(
                      key: next >= shop.firstLevel && next <= shop.lastLevel
                          ? _currentKey
                          : null,
                      shop: shop,
                      levelCount: widget.levelCount,
                      cleared: widget.cleared,
                      stars: widget.stars,
                      locked: _shopLocked(shop.firstLevel),
                      onTap: _tap,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One region: banner plus a 5-wide grid of its levels.
class _ZoneSection extends StatelessWidget {
  const _ZoneSection(
      {super.key,
      required this.shop,
      required this.levelCount,
      required this.cleared,
      required this.stars,
      required this.locked,
      required this.onTap});
  final ShopDef shop;
  final int levelCount, cleared;
  final Map<int, int> stars;
  final bool locked;
  final ValueChanged<int> onTap;

  static const _perRow = 5;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = _zoneStyles[shop.id]!;
    final last = shop.lastLevel < levelCount ? shop.lastLevel : levelCount;
    final total = last - shop.firstLevel + 1;
    final done = (cleared - (shop.firstLevel - 1)).clamp(0, total);
    final top = locked ? Colors.blueGrey.shade300 : style.top;
    final bottom = locked ? Colors.blueGrey.shade500 : style.bottom;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          color: UiArt.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bottom, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [top, bottom]),
              ),
              child: Row(
                children: [
                  Text(shop.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L10n.t('zone_${shop.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(L10n.t(shop.nameKey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                t.bodySmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Text(style.kanji,
                      style: t.titleLarge?.copyWith(
                          color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  if (locked)
                    const Icon(Icons.lock_outline, color: Colors.white)
                  else
                    Text('$done/$total',
                        style: t.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(builder: (context, box) {
                final cell = box.maxWidth / _perRow;
                return Wrap(
                  children: [
                    for (var n = shop.firstLevel; n <= last; n++)
                      SizedBox(
                        width: cell,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: _Plate(
                            level: n,
                            size: (cell - 10).clamp(36.0, 56.0),
                            locked: n > cleared + 1 || locked,
                            done: n <= cleared,
                            stars: stars[n] ?? 0,
                            current: n == cleared + 1 && !locked,
                            onTap: () => onTap(n),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate(
      {required this.level,
      required this.size,
      required this.locked,
      required this.done,
      required this.stars,
      required this.current,
      required this.onTap});
  final int level;
  final double size;
  final bool locked;
  final bool done;

  /// Best stars earned on this level (0-3).
  final int stars;

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
            width: size,
            height: size,
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
                ? Icon(Icons.lock, size: size * 0.6, color: Colors.black54)
                : CustomPaint(painter: _SushiPainter(kind)),
          ),
          const SizedBox(height: 2),
          Container(
            width: size + 4,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: locked ? Colors.grey.shade400 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color:
                      locked ? Colors.grey.shade600 : const Color(0xFFB71C2C),
                  width: 2.5),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$level',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (done)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 3; i++)
                    StarIcon(
                        size: (size / 3).clamp(10.0, 16.0), lit: i <= stars),
                ],
              ),
            )
          else
            SizedBox(height: (size / 3).clamp(10.0, 16.0) + 2),
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
