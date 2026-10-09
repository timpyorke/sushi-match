import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/restaurant.dart';
import 'customer_order.dart';
import 'ui_art.dart';

/// Where each piece of furniture sits, as fractions of the scene: the sign
/// on the awning, a wall row, a counter row and a floor row. Customers walk
/// the lane between the counter and the floor.
const _spots = {
  'sign': Offset(0.5, 0.08),
  'lantern': Offset(0.12, 0.29),
  'aquarium': Offset(0.37, 0.32),
  'sake': Offset(0.63, 0.32),
  'noren': Offset(0.88, 0.29),
  'luckycat': Offset(0.12, 0.45),
  'conveyor': Offset(0.37, 0.45),
  'trophy': Offset(0.88, 0.45),
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

  static Offset _spotOf(FurnitureDef f) =>
      _spots[f.id] ?? const Offset(0.5, 0.5);

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
                Positioned.fill(
                  child: Image.asset(
                    'assets/backgrounds/restaurant_counterbar.webp',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(child: _RestaurantChef()),
                ),
                for (final f in Restaurant.furniture)
                  Positioned(
                    left: _spotOf(f).dx * w - _slot / 2,
                    top: _spotOf(f).dy * h - _slot / 2,
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

/// The resident chef stands behind the bar, with the lower body hidden by
/// its front edge. Existing frame animations keep the scene alive even before
/// the player buys any furniture or puts sushi on display.
class _RestaurantChef extends StatefulWidget {
  @override
  State<_RestaurantChef> createState() => _RestaurantChefState();
}

class _RestaurantChefState extends State<_RestaurantChef>
    with SingleTickerProviderStateMixin {
  late final AnimationController _routine;
  var _tasting = false;

  @override
  void initState() {
    super.initState();
    _routine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(() {
        // Two four-frame taste loops at six fps, then return to idle.
        final tasting = _routine.value >= 1 - (8 / 6 / 10);
        if (tasting != _tasting) setState(() => _tasting = tasting);
      })
      ..repeat();
  }

  @override
  void dispose() {
    _routine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = (box.maxWidth * 0.42).clamp(96.0, 184.0).toDouble();
      // The background's countertop starts at 43% of the scene height.
      return ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: box.maxWidth,
            height: box.maxHeight * 0.43,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: box.maxWidth * 0.5 - size / 2,
                    top: box.maxHeight * 0.43 - size * 0.70,
                    child: CustomerSprite(
                      customer: Customer.roster.firstWhere(
                        (customer) => customer.nameKey == 'cust17',
                      ),
                      anim:
                          _tasting ? CustomerAnim.signature : CustomerAnim.idle,
                      size: size,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
