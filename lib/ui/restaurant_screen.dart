import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gen/assets.gen.dart';
import '../core/settings.dart';
import '../services/audio.dart';
import '../services/restaurant.dart';
import 'customer_order.dart';
import 'l10n.dart';
import 'lives_ui.dart';
import 'ui_art.dart';

/// The player's one restaurant: spend stars on furniture, and collect the
/// coins the customers it draws leave in the till.
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
    // The till fills with the clock; redraw it every second.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
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
            'furnitureBought', {'name': L10n.t(f.nameKey), 'n': f.coinsPerHour})
        : L10n.t('needStars'));
  }

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
    final till = ref.read(restaurantProvider.notifier).till();
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
                    icon: Icons.arrow_back,
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
                    _TillPanel(state: state, till: till, onCollect: _collect),
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

/// Income per hour, how full the till is, and the collect button.
class _TillPanel extends StatelessWidget {
  const _TillPanel(
      {required this.state, required this.till, required this.onCollect});
  final RestaurantState state;
  final int till;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final rate = state.coinsPerHour;
    final ink =
        t.titleSmall?.copyWith(color: UiArt.ink, fontWeight: FontWeight.bold);
    return Container(
      // Same inset as GameDialog so content clears the wave-corner frame.
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      decoration: UiArt.panelDecoration(),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: UiArt.ink),
        textAlign: TextAlign.center,
        child: Column(
          children: [
            if (rate == 0)
              Text(L10n.t('tillEmptyHint'))
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(L10n.t('customersPay'), style: ink),
                  const SizedBox(width: 6),
                  CoinAmount(rate, size: 18, style: ink),
                  Text(L10n.t('perHour'), style: ink),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: state.tillCap == 0 ? 0 : till / state.tillCap,
                  minHeight: 10,
                  backgroundColor: Colors.white70,
                  color: const Color(0xFFE0A526),
                ),
              ),
              const SizedBox(height: 4),
              Text(till >= state.tillCap
                  ? L10n.t('tillFull')
                  : L10n.t('tillHint', {'h': Restaurant.tillHours})),
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
            ],
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
                if (state.coinsPerHour > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _Customers(rate: state.coinsPerHour),
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
                    child: UiArt.furniture(furniture.id).image(width: 22, height: 22),
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
            child: UiArt.furniture(furniture.id).image(width: 44, height: 44),
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
      milliseconds: (9000 - widget.rate * 80).clamp(4500, 9000).toInt());

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
          final bob = walking ? math.sin(v * math.pi * 24).abs() * 4 : 0.0;
          final pay = ((v - 0.38) / 0.25).clamp(0.0, 1.0).toDouble();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: x * w - 32,
                top: _laneY * h - 48 - bob,
                child: CustomerSprite(
                  key: ValueKey(_face),
                  customer: Customer.roster[_face],
                  anim: walking ? CustomerAnim.walk : CustomerAnim.idle,
                  size: 64,
                  fps: 8,
                ),
              ),
              if (pay > 0 && pay < 1)
                Positioned(
                  left: _payX * w - 10,
                  top: _laneY * h - 40 - pay * 36,
                  child: Opacity(
                    opacity: 1 - pay,
                    child:
                        Image(image: UiArt.coin, width: 22, height: 22),
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
