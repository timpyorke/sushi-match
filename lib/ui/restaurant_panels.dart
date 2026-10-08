import 'package:flutter/material.dart';

import '../core/piece.dart';
import '../game/piece_painter.dart';
import '../services/restaurant.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// A framed panel with a bold [title] over [children], in ink.
class _Panel extends StatelessWidget {
  const _Panel(
      {required this.title,
      required this.children,
      this.textAlign = TextAlign.center});
  final String title;
  final List<Widget> children;
  final TextAlign? textAlign;

  static TextStyle? titleStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .titleSmall
      ?.copyWith(color: UiArt.ink, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) => Container(
        // Same inset as GameDialog so content clears the wave-corner frame.
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        decoration: UiArt.panelDecoration(),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: UiArt.ink),
          textAlign: textAlign,
          child: Column(
            children: [Text(title, style: titleStyle(context)), ...children],
          ),
        ),
      );
}

/// Sales waiting in the till, how often customers come, and the collect
/// button.
class TillPanel extends StatelessWidget {
  const TillPanel({super.key, required this.state, required this.onCollect});
  final RestaurantState state;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final ink = _Panel.titleStyle(context);
    final till = state.banked;
    return _Panel(
      title: L10n.t('tillWaiting'),
      children: [
        const SizedBox(height: 6),
        CoinAmount(till, size: 22, style: ink),
        const SizedBox(height: 6),
        Text(L10n.t(
            'visitInfo', {'s': state.visitEvery, 'p': state.priceBoost})),
        if (state.placed == 0 && till == 0) ...[
          const SizedBox(height: 6),
          Text(L10n.t('tillEmptyHint')),
        ],
        const SizedBox(height: 10),
        FilledButton(
          onPressed: till > 0 ? onCollect : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(L10n.t('collect')),
              const SizedBox(width: 8),
              CoinAmount(till, size: 18),
            ],
          ),
        ),
        if (state.fullyFurnished) ...[
          const SizedBox(height: 10),
          Text(L10n.t('fullyFurnished'), style: ink),
        ],
      ],
    );
  }
}

Widget _sushi(PieceKind kind, double size) => PiecePainter.spriteOf(kind).image(
    width: size,
    height: size,
    cacheWidth: (size * 3).round(),
    errorBuilder: (_, __, ___) => SizedBox(width: size, height: size));

/// The display case: put sushi from the stock on a slot and customers buy it.
/// Tap a sushi on the case to take it back.
class ShelfPanel extends StatelessWidget {
  const ShelfPanel(
      {super.key,
      required this.state,
      required this.onPlace,
      required this.onTake});
  final RestaurantState state;
  final ValueChanged<int> onPlace;
  final ValueChanged<int> onTake;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: L10n.t('shelfTitle'),
      children: [
        const SizedBox(height: 4),
        Text(L10n.t('shelfHint')),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < Restaurant.maxSlots; i++)
              _ShelfSlot(
                kind: state.slot(i),
                locked: i >= state.slotCount,
                price:
                    state.slot(i) == null ? null : state.price(state.slot(i)!),
                onTap: () => state.slot(i) == null ? onPlace(i) : onTake(i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(L10n.t('inStock', {'n': state.stockTotal})),
      ],
    );
  }
}

class _ShelfSlot extends StatelessWidget {
  const _ShelfSlot(
      {required this.kind,
      required this.locked,
      required this.price,
      required this.onTap});
  final PieceKind? kind;
  final bool locked;
  final int? price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final k = kind;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 72,
        decoration: BoxDecoration(
          color: locked ? Colors.black12 : Colors.white70,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: UiArt.ink.withAlpha(locked ? 60 : 150)),
        ),
        child: locked
            ? Icon(Icons.lock, color: UiArt.ink.withAlpha(110))
            : k == null
                ? Icon(Icons.add, color: UiArt.ink.withAlpha(150))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _sushi(k, 40),
                      CoinAmount(price ?? 0,
                          size: 12,
                          style: t.labelSmall?.copyWith(
                              color: UiArt.ink, fontWeight: FontWeight.bold)),
                    ],
                  ),
      ),
    );
  }
}

/// Lists the sushi in stock and returns the one picked, or null.
Future<PieceKind?> pickSushi(BuildContext context, RestaurantState state) {
  final kinds = [
    for (final k in PieceKind.values)
      if (state.count(k) > 0) k,
  ];
  return showModalBottomSheet<PieceKind>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.t('pickSushi'),
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (kinds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(L10n.t('stockEmpty'), textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final k in kinds)
                      ListTile(
                        leading: _sushi(k, 40),
                        title: Text(L10n.t(k.name)),
                        subtitle:
                            Text(L10n.t('inStock', {'n': state.count(k)})),
                        trailing: CoinAmount(state.price(k), size: 16),
                        onTap: () => Navigator.of(ctx).pop(k),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The furniture shop, one tab per category. Buying with stars also fills
/// the matching spot in the scene above.
class FurniturePanel extends StatefulWidget {
  const FurniturePanel({super.key, required this.state, required this.onBuy});
  final RestaurantState state;
  final ValueChanged<FurnitureDef> onBuy;

  @override
  State<FurniturePanel> createState() => _FurniturePanelState();
}

class _FurniturePanelState extends State<FurniturePanel> {
  var _category = FurnitureCategory.storefront;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return _Panel(
      title: L10n.t('furnShop'),
      textAlign: null,
      children: [
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: [
            for (final c in FurnitureCategory.values)
              ChoiceChip(
                label: Text(
                    '${L10n.t('cat_${c.name}')} '
                    '${state.ownedIn(c)}/${Restaurant.inCategory(c).length}',
                    style: const TextStyle(color: UiArt.ink)),
                selected: c == _category,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final f in Restaurant.inCategory(_category))
          _FurnitureRow(
            furniture: f,
            owned: state.isOwned(f),
            onBuy: () => widget.onBuy(f),
          ),
      ],
    );
  }
}

class _FurnitureRow extends StatelessWidget {
  const _FurnitureRow(
      {required this.furniture, required this.owned, required this.onBuy});
  final FurnitureDef furniture;
  final bool owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dining = furniture.category == FurnitureCategory.dining;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          UiArt.furniture(furniture.id).sized(40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.t(furniture.nameKey),
                    style: t.titleSmall?.copyWith(
                        color: UiArt.ink, fontWeight: FontWeight.bold)),
                Text(
                  [
                    L10n.t('furnEffect', {'p': furniture.appeal * 2}),
                    if (dining) L10n.t('furnSlot'),
                  ].join(' · '),
                  style: t.bodySmall?.copyWith(color: UiArt.ink),
                ),
              ],
            ),
          ),
          if (owned)
            Text(L10n.t('furnOwned'),
                style: t.labelLarge?.copyWith(color: UiArt.ink))
          else
            FilledButton(
              onPressed: onBuy,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${furniture.cost}'),
                  const SizedBox(width: 4),
                  const StarIcon(size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
