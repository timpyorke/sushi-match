import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gen/assets.gen.dart';
import '../core/piece.dart';
import '../core/settings.dart';
import '../game/piece_painter.dart';
import '../services/audio.dart';
import '../services/restaurant.dart';
import 'customer_order.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'ui_art.dart';

/// The player's one restaurant: put sushi won in levels on the display case,
/// spend stars on furniture by category, and collect the coins customers
/// leave in the till.
class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key});

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    // Customers buy with the clock; book their sales every second.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(restaurantProvider.notifier).settle();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _buy(FurnitureDef f) {
    final ok = ref.read(restaurantProvider.notifier).buyFurniture(f);
    if (ok) Audio.play(Sfx.coin);
    _toast(ok
        ? L10n.t(
            'furnitureBought', {'name': L10n.t(f.nameKey), 'n': f.appeal * 2})
        : L10n.t('needStars'));
  }

  Future<void> _place(int slot) async {
    final view = ref.read(restaurantProvider.notifier).view();
    if (slot >= view.slotCount) return _toast(L10n.t('slotLocked'));
    final kind = await _pickSushi(context, view);
    if (kind == null) return;
    ref.read(restaurantProvider.notifier).place(kind, slot);
  }

  void _take(int slot) => ref.read(restaurantProvider.notifier).take(slot);

  void _collect() {
    final n = ref.read(restaurantProvider.notifier).collect();
    if (n <= 0) return;
    Audio.play(Sfx.coin);
    _toast(L10n.t('tillCollected', {'n': n}));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Rebuild when the language changes; L10n reads it statically.
    ref.watch(settingsProvider.select((s) => s.language));
    final state = ref.watch(restaurantProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Assets.backgrounds.bg.provider(),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  RoundIconButton(
                    sprite: const UiControlIcon(UiControl.back,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: WalletBar(),
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedTitle(L10n.t('restaurant'), style: t.headlineLarge),
              const SizedBox(height: 8),
              PlankSubtitle(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StarIcon(size: 24),
                    const SizedBox(width: 6),
                    Text(L10n.t('starsAvailable', {'n': state.available})),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    RestaurantScene(onBuy: _buy),
                    const SizedBox(height: 12),
                    _ShelfPanel(state: state, onPlace: _place, onTake: _take),
                    const SizedBox(height: 12),
                    _TillPanel(state: state, onCollect: _collect),
                    const SizedBox(height: 12),
                    _FurniturePanel(state: state, onBuy: _buy),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sales waiting in the till, how often customers come, and the collect
/// button.
class _TillPanel extends StatelessWidget {
  const _TillPanel({required this.state, required this.onCollect});
  final RestaurantState state;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ink =
        t.titleSmall?.copyWith(color: UiArt.ink, fontWeight: FontWeight.bold);
    final till = state.banked;
    return Container(
      // Same inset as GameDialog so content clears the wave-corner frame.
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      decoration: UiArt.panelDecoration(),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: UiArt.ink),
        textAlign: TextAlign.center,
        child: Column(
          children: [
            Text(L10n.t('tillWaiting'), style: ink),
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
        ),
      ),
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
class _ShelfPanel extends StatelessWidget {
  const _ShelfPanel(
      {required this.state, required this.onPlace, required this.onTake});
  final RestaurantState state;
  final ValueChanged<int> onPlace;
  final ValueChanged<int> onTake;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ink =
        t.titleSmall?.copyWith(color: UiArt.ink, fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      decoration: UiArt.panelDecoration(),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: UiArt.ink),
        textAlign: TextAlign.center,
        child: Column(
          children: [
            Text(L10n.t('shelfTitle'), style: ink),
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
                    price: state.slot(i) == null
                        ? null
                        : state.price(state.slot(i)!),
                    onTap: () => state.slot(i) == null ? onPlace(i) : onTake(i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(L10n.t('inStock', {'n': state.stockTotal})),
          ],
        ),
      ),
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
Future<PieceKind?> _pickSushi(BuildContext context, RestaurantState state) {
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
class _FurniturePanel extends StatefulWidget {
  const _FurniturePanel({required this.state, required this.onBuy});
  final RestaurantState state;
  final ValueChanged<FurnitureDef> onBuy;

  @override
  State<_FurniturePanel> createState() => _FurniturePanelState();
}

class _FurniturePanelState extends State<_FurniturePanel> {
  var _category = FurnitureCategory.storefront;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = widget.state;
    final ink =
        t.titleSmall?.copyWith(color: UiArt.ink, fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      decoration: UiArt.panelDecoration(),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: UiArt.ink),
        child: Column(
          children: [
            Text(L10n.t('furnShop'), style: ink),
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
        ),
      ),
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

/// Where each piece of furniture sits, as fractions of the scene: the sign
/// on the awning, a wall row, a counter row and a floor row. Customers walk
/// the lane between the counter and the floor.
const _spots = {
  'sign': Offset(0.5, 0.08),
  'lantern': Offset(0.12, 0.38),
  'aquarium': Offset(0.37, 0.38),
  'sake': Offset(0.63, 0.38),
  'noren': Offset(0.88, 0.38),
  'luckycat': Offset(0.12, 0.56),
  'conveyor': Offset(0.37, 0.56),
  'trophy': Offset(0.88, 0.56),
  'plant': Offset(0.12, 0.9),
  'stool': Offset(0.37, 0.9),
  'taiko': Offset(0.63, 0.9),
  'kadomatsu': Offset(0.88, 0.9),
};

const _laneY = 0.73;

/// Customers stop at the free spot on the counter to pay.
const _payX = 0.63;

/// The restaurant: empty spots show a faint price tag and tapping one buys
/// it; once anything is bought, customers walk in and pay at the counter.
class RestaurantScene extends ConsumerWidget {
  const RestaurantScene({super.key, required this.onBuy});
  final ValueChanged<FurnitureDef> onBuy;

  static const _slot = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantProvider);
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UiArt.ink, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _ScenePainter())),
                for (final f in Restaurant.furniture)
                  Positioned(
                    left: (_spots[f.id] ?? const Offset(0.5, 0.5)).dx * w -
                        _slot / 2,
                    top: (_spots[f.id] ?? const Offset(0.5, 0.5)).dy * h -
                        _slot / 2,
                    width: _slot,
                    height: _slot,
                    child: _Slot(
                      furniture: f,
                      owned: state.isOwned(f),
                      onBuy: () => onBuy(f),
                    ),
                  ),
                if (state.placed > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _Customers(rate: state.appeal),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot(
      {required this.furniture, required this.owned, required this.onBuy});
  final FurnitureDef furniture;
  final bool owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: owned ? null : onBuy,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: owned ? 0 : 1,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
                border: Border.all(color: UiArt.ink.withAlpha(150), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: UiArt.furniture(furniture.id).sized(22),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${furniture.cost}',
                          style: t.labelMedium?.copyWith(
                              color: UiArt.ink, fontWeight: FontWeight.bold)),
                      const StarIcon(size: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedScale(
            scale: owned ? 1 : 0,
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            child: UiArt.furniture(furniture.id).sized(44),
          ),
        ],
      ),
    );
  }
}

/// One customer at a time walks in, pays at the counter (a coin pops up)
/// and leaves; more furniture means quicker visits. Only for show: the
/// till is computed from the clock, not from these visits.
class _Customers extends StatefulWidget {
  const _Customers({required this.rate});
  final int rate;

  @override
  State<_Customers> createState() => _CustomersState();
}

class _CustomersState extends State<_Customers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _visit;
  var _face = 0;

  @override
  void initState() {
    super.initState();
    _visit = AnimationController(vsync: this, duration: _period())
      ..addStatusListener((s) {
        if (s != AnimationStatus.completed) return;
        setState(() => _face = (_face + 1) % Customer.roster.length);
        _visit
          ..duration = _period()
          ..forward(from: 0);
      })
      ..forward();
  }

  Duration _period() => Duration(
      milliseconds: (13000 - widget.rate * 80).clamp(7000, 13000).toInt());

  @override
  void dispose() {
    _visit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      return AnimatedBuilder(
        animation: _visit,
        builder: (context, _) {
          final v = _visit.value;
          // Walk in (0-0.35), pay (0.35-0.65), walk out (0.65-1).
          final double x;
          if (v < 0.35) {
            x = -0.1 + (_payX + 0.1) * Curves.easeOut.transform(v / 0.35);
          } else if (v < 0.65) {
            x = _payX;
          } else {
            x = _payX +
                (1.1 - _payX) * Curves.easeIn.transform((v - 0.65) / 0.35);
          }
          final walking = v < 0.35 || v >= 0.65;
          final bob = walking ? math.sin(v * math.pi * 16).abs() * 4 : 0.0;
          final pay = ((v - 0.38) / 0.25).clamp(0.0, 1.0).toDouble();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: x * w - 32,
                top: _laneY * h - 48 - bob,
                // The walk sprites face left but the customer crosses the scene
                // to the right, so they are mirrored while walking.
                child: Transform.flip(
                  flipX: walking,
                  child: CustomerSprite(
                    key: ValueKey(_face),
                    customer: Customer.roster[_face],
                    anim: walking ? CustomerAnim.walk : CustomerAnim.idle,
                    size: 64,
                    fps: 5,
                  ),
                ),
              ),
              if (pay > 0 && pay < 1)
                Positioned(
                  left: _payX * w - 10,
                  top: _laneY * h - 40 - pay * 36,
                  child: Opacity(
                    opacity: 1 - pay,
                    child: UiArt.sized(UiArt.coin, 22),
                  ),
                ),
            ],
          );
        },
      );
    });
  }
}

class _ScenePainter extends CustomPainter {
  static const _sky = Color(0xFFBFE3F0);
  static const _wall = Color(0xFFE9D3A8);
  static const _beam = Color(0xFF8A5A33);
  static const _awningA = Color(0xFFB71C2C);
  static const _awningB = Color(0xFFF4EBD8);
  static const _counter = Color(0xFFC8955E);
  static const _floor = Color(0xFFB98A5A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint();
    canvas.drawRect(Offset.zero & size, p..color = _sky);
    // Sign board over the awning.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.3, h * 0.02, w * 0.4, h * 0.12),
            const Radius.circular(6)),
        p..color = _beam);
    // Back wall with posts.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.17, w, h * 0.5), p..color = _wall);
    for (final x in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      canvas.drawRect(
          Rect.fromLTWH(w * x - w * 0.012, h * 0.17, w * 0.024, h * 0.5),
          p..color = _beam.withAlpha(120));
    }
    // Striped awning.
    const stripes = 10;
    final sw = w / stripes;
    for (var i = 0; i < stripes; i++) {
      final path = Path()
        ..moveTo(i * sw, h * 0.15)
        ..lineTo((i + 1) * sw, h * 0.15)
        ..lineTo((i + 1) * sw, h * 0.23)
        ..arcToPoint(Offset(i * sw, h * 0.23),
            radius: Radius.circular(sw / 2), clockwise: true)
        ..close();
      canvas.drawPath(path, p..color = i.isEven ? _awningA : _awningB);
    }
    // Shelf under the wall row.
    canvas.drawRect(Rect.fromLTWH(w * 0.02, h * 0.43, w * 0.96, h * 0.015),
        p..color = _beam);
    // Counter top and front.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.6, w, h * 0.025), p..color = _beam);
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.625, w, h * 0.045), p..color = _counter);
    // Floor boards.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.67, w, h * 0.33), p..color = _floor);
    final plank = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 2;
    for (var i = 1; i < 6; i++) {
      final y = h * 0.67 + i * h * 0.055;
      canvas.drawLine(Offset(0, y), Offset(w, y), plank);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => false;
}
