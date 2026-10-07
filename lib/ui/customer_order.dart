import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import '../core/piece.dart';
import '../game/piece_painter.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Animations every customer sprite has (see `docs/prompts/README.md`).
enum CustomerAnim { idle, talk, happy, sad, walk }

/// A diner who places the level's goals as a food order.
class Customer {
  const Customer(this.emoji, this.nameKey, {this.sprite});
  final String emoji;
  final String nameKey;

  /// Folder under `assets/sprites/customers/`; null until the art exists,
  /// in which case [emoji] stands in.
  final String? sprite;

  /// Frames per animation.
  static const frameCount = 4;

  String get name => L10n.t(nameKey);

  String frame(CustomerAnim anim, int i) =>
      'assets/sprites/customers/$sprite/${anim.name}_$i.png';

  static const roster = [
    Customer('👵', 'cust0', sprite: '00-granny-sakura'),
    Customer('👨‍💼', 'cust1'),
    Customer('👧', 'cust2'),
    Customer('🐱', 'cust3'),
    Customer('🧑‍🎤', 'cust4'),
    Customer('👴', 'cust5'),
  ];

  /// Customers take turns across levels so every plate has a face.
  static Customer forLevel(int levelId) =>
      roster[(levelId - 1) % roster.length];
}

/// A customer playing [anim] on a loop, after [intro] plays [introLoops]
/// times if given. Falls back to the emoji when the customer has no sprite.
class CustomerSprite extends StatefulWidget {
  const CustomerSprite({
    super.key,
    required this.customer,
    this.anim = CustomerAnim.idle,
    this.intro,
    this.introLoops = 2,
    this.size = 64,
    this.fps = 6,
  });
  final Customer customer;
  final CustomerAnim anim;
  final CustomerAnim? intro;
  final int introLoops;
  final double size;
  final double fps;

  @override
  State<CustomerSprite> createState() => _CustomerSpriteState();
}

class _CustomerSpriteState extends State<CustomerSprite>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  /// Frames shown since the ticker started, and the count at which the
  /// current animation began.
  int _ticks = 0, _start = 0;

  int get _introFrames =>
      widget.intro == null ? 0 : widget.introLoops * Customer.frameCount;

  void _tick(Duration elapsed) {
    final i = elapsed.inMicroseconds * widget.fps ~/ 1000000;
    if (i != _ticks) setState(() => _ticks = i);
  }

  @override
  void initState() {
    super.initState();
    if (widget.customer.sprite != null) {
      _ticker = createTicker(_tick)..start();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode every frame up front so the loop doesn't flicker.
    if (widget.customer.sprite == null) return;
    for (final anim in {widget.intro, widget.anim}.nonNulls) {
      for (var i = 0; i < Customer.frameCount; i++) {
        precacheImage(AssetImage(widget.customer.frame(anim, i)), context);
      }
    }
  }

  @override
  void didUpdateWidget(CustomerSprite old) {
    super.didUpdateWidget(old);
    if (old.anim != widget.anim || old.customer != widget.customer) {
      _start = _ticks - _introFrames; // skip the intro on a mood change
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    if (c.sprite == null) {
      return SizedBox.square(
        dimension: widget.size,
        child: Center(
            child:
                Text(c.emoji, style: TextStyle(fontSize: widget.size * 0.5))),
      );
    }
    final intro = widget.intro;
    final n = _ticks - _start;
    final (anim, i) = intro != null && n < _introFrames
        ? (intro, n % Customer.frameCount)
        : (widget.anim, (n - _introFrames) % Customer.frameCount);
    return Image.asset(
      c.frame(anim, i),
      width: widget.size,
      height: widget.size,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      semanticLabel: c.name,
    );
  }
}

/// "I'd like 20 Salmon and 15 Tamago, please!" built from the level goals.
String orderText(List<LevelGoal> goals) {
  final items = [
    for (final g in goals)
      switch (g.type) {
        GoalType.collect =>
          L10n.t('itemCollect', {'n': g.count, 'piece': L10n.t(g.piece!.name)}),
        GoalType.score => L10n.t('itemScore', {'n': g.count}),
        GoalType.clearNori => L10n.t('itemNori'),
        GoalType.breakIce => L10n.t('itemIce'),
        GoalType.breakBag => L10n.t('itemBag'),
        GoalType.deliver => L10n.t('itemDeliver', {'n': g.count}),
        GoalType.clearMats => L10n.t('itemMat'),
        GoalType.putOut => L10n.t('itemFire'),
        GoalType.shooCats => L10n.t('itemCat'),
      },
  ];
  final joined = items.length < 2
      ? items.join()
      : '${items.take(items.length - 1).join(', ')} '
          '${L10n.t('and')} ${items.last}';
  return L10n.t('orderIntro', {'items': joined});
}

/// One goal as "icon current/target"; turns green with a tick once met.
class GoalCount extends StatelessWidget {
  const GoalCount({super.key, required this.progress});
  final GoalProgress progress;

  static Widget _icon(LevelGoal g) => switch (g.type) {
        GoalType.collect => SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(painter: _PiecePainter(g.piece!))),
        GoalType.score => const Text('⭐', style: TextStyle(fontSize: 16)),
        GoalType.clearNori => const Text('🌿', style: TextStyle(fontSize: 16)),
        GoalType.breakIce => const Text('🧊', style: TextStyle(fontSize: 16)),
        GoalType.breakBag => const Text('🌾', style: TextStyle(fontSize: 16)),
        GoalType.deliver => const Text('🍙', style: TextStyle(fontSize: 16)),
        GoalType.clearMats => const Text('🎋', style: TextStyle(fontSize: 16)),
        GoalType.putOut => const Text('🔥', style: TextStyle(fontSize: 16)),
        GoalType.shooCats => const Text('🐱', style: TextStyle(fontSize: 16)),
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = progress.goal;
    final shown = progress.current.clamp(0, g.count);
    final done = progress.done;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFC8E6C9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: done ? const Color(0xFF2E7D32) : UiArt.ink, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _icon(g),
          const SizedBox(width: 4),
          Text('$shown/${g.count}',
              style: t.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: UiArt.ink)),
          if (done) const Icon(Icons.check, size: 14, color: Color(0xFF2E7D32)),
        ],
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter(this.kind);
  final PieceKind kind;

  @override
  void paint(Canvas canvas, Size size) =>
      PiecePainter.paint(canvas, size.width, kind, null);

  @override
  bool shouldRepaint(_PiecePainter old) => old.kind != kind;
}

/// Customer avatar with a speech bubble stating the order. With [goals] it
/// also shows a live count for each one.
class OrderBubble extends StatelessWidget {
  const OrderBubble({super.key, required this.level, this.goals});
  final LevelConfig level;
  final List<GoalProgress>? goals;

  @override
  Widget build(BuildContext context) {
    final customer = Customer.forLevel(level.id);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: UiArt.plankDecoration(),
      child: Row(
        children: [
          CustomerSprite(
              customer: customer, intro: CustomerAnim.talk, size: 64),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(customer.name,
                    style: t.labelSmall?.copyWith(
                        color: UiArt.ink, fontWeight: FontWeight.bold)),
                Text(orderText(level.goals),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: UiArt.ink)),
                if (goals != null && goals!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(spacing: 6, runSpacing: 4, children: [
                      for (final p in goals!) GoalCount(progress: p),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
