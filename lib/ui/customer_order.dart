import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import '../core/piece.dart';
import '../game/piece_painter.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Animations every customer sprite has (see `docs/prompts/README.md`).
enum CustomerAnim {
  idle(4),
  talk(6),
  happy(6),
  sad(4),
  walk(6),

  /// The customer's own flourish; its file name, speed and trigger come from
  /// [Customer.signature].
  signature(8);

  const CustomerAnim(this.fps);

  /// Playback speed; the calm loops run slower so the diner doesn't fidget.
  final double fps;
}

/// What makes a customer play their [Signature] animation.
enum SignatureCue {
  /// The order bubble settles in at the start of the level.
  start,

  /// The order is served (level won).
  served,

  /// Three moves or fewer left.
  lowMoves,

  /// A combo praise pops up.
  combo,

  /// One of the level's goals was just completed.
  goal,

  /// Every few moves, as a break from standing still.
  idle,
}

/// A customer's own animation (`<name>_0..3.png`), from `docs/prompts`.
class Signature {
  const Signature(this.name, this.cue, {this.fps = 8, this.loop = false});
  final String name;
  final SignatureCue cue;
  final double fps;

  /// Loops play twice, the rest once.
  final bool loop;

  int get loops => loop ? 2 : 1;
}

/// A diner who places the level's goals as a food order.
class Customer {
  const Customer(this.emoji, this.nameKey, {this.sprite, this.signature});
  final String emoji;
  final String nameKey;

  /// The extra animation beyond [CustomerAnim]'s shared ones; null for none.
  final Signature? signature;

  /// Folder under `assets/sprites/customers/`; null until the art exists,
  /// in which case [emoji] stands in.
  final String? sprite;

  /// Frames per animation.
  static const frameCount = 4;

  String get name => L10n.t(nameKey);

  String frame(CustomerAnim anim, int i) {
    final name = anim == CustomerAnim.signature ? signature!.name : anim.name;
    return 'assets/sprites/customers/$sprite/${name}_$i.png';
  }

  /// Playback speed of [anim] for this customer.
  double fpsOf(CustomerAnim anim) =>
      anim == CustomerAnim.signature && signature != null
          ? signature!.fps
          : anim.fps;

  static const roster = [
    Customer('👵', 'cust0',
        sprite: '00-granny-sakura',
        signature: Signature('bow', SignatureCue.start)),
    Customer('👨‍💼', 'cust1',
        sprite: '01-mr-tanaka',
        signature: Signature('watch', SignatureCue.lowMoves, loop: true)),
    Customer('👧', 'cust2',
        sprite: '02-little-mei',
        signature: Signature('clap', SignatureCue.combo, fps: 10, loop: true)),
    Customer('🐱', 'cust3',
        sprite: '03-lucky-cat',
        signature: Signature('beckon', SignatureCue.start, fps: 6, loop: true)),
    Customer('🧑‍🎤', 'cust4',
        sprite: '04-yuki', signature: Signature('photo', SignatureCue.served)),
    Customer('👴', 'cust5',
        sprite: '05-grandpa-taro',
        signature: Signature('nod', SignatureCue.goal, fps: 6)),
    Customer('💪', 'cust6',
        sprite: '06-ryo', signature: Signature('carry', SignatureCue.start)),
    Customer('👩‍🦰', 'cust7',
        sprite: '07-auntie-kiku',
        signature: Signature('inspect', SignatureCue.start)),
    Customer('🔔', 'cust8',
        sprite: '08-masa',
        signature: Signature('auction', SignatureCue.lowMoves, fps: 10)),
    Customer('🐙', 'cust9',
        sprite: '09-taco-neesan',
        signature: Signature('flip', SignatureCue.idle, fps: 10, loop: true)),
    Customer('🥁', 'cust10',
        sprite: '10-oto',
        signature: Signature('drum', SignatureCue.combo, fps: 10, loop: true)),
    Customer('👜', 'cust11',
        sprite: '11-aunt-hana',
        signature: Signature('bargain', SignatureCue.start)),
    Customer('👘', 'cust12',
        sprite: '12-ume', signature: Signature('fan', SignatureCue.start)),
    Customer('🍵', 'cust13',
        sprite: '13-haru',
        signature: Signature('tea', SignatureCue.start, fps: 6)),
    Customer('📿', 'cust14',
        sprite: '14-monk-genjo',
        signature:
            Signature('meditate', SignatureCue.idle, fps: 4, loop: true)),
    Customer('⚓', 'cust15',
        sprite: '15-captain-umi',
        signature: Signature('tale', SignatureCue.start)),
    Customer('🎿', 'cust16',
        sprite: '16-yukiko',
        signature: Signature('stretch', SignatureCue.start)),
    Customer('🐻', 'cust17',
        sprite: '17-chef-kuma',
        signature: Signature('taste', SignatureCue.served, fps: 6)),
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
    this.fps,
  });
  final Customer customer;
  final CustomerAnim anim;
  final CustomerAnim? intro;
  final int introLoops;
  final double size;

  /// Overrides every animation's own [CustomerAnim.fps].
  final double? fps;

  @override
  State<CustomerSprite> createState() => _CustomerSpriteState();
}

class _CustomerSpriteState extends State<CustomerSprite>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  /// Time since the ticker started, and when the current animation began.
  Duration _now = Duration.zero, _start = Duration.zero;

  /// Set when a mood change cuts the intro short.
  bool _skipIntro = false;

  double _fps(CustomerAnim anim) => widget.fps ?? widget.customer.fpsOf(anim);

  int _frames(Duration d, CustomerAnim anim) =>
      d.inMicroseconds * _fps(anim) ~/ 1000000;

  /// The animation and frame to show at [_now].
  (CustomerAnim, int) get _frame {
    var t = _now - _start;
    final intro = widget.intro;
    if (intro != null && !_skipIntro) {
      final n = _frames(t, intro);
      final introFrames = widget.introLoops * Customer.frameCount;
      if (n < introFrames) return (intro, n % Customer.frameCount);
      t -= Duration(microseconds: introFrames * 1000000 ~/ _fps(intro));
    }
    return (widget.anim, _frames(t, widget.anim) % Customer.frameCount);
  }

  void _tick(Duration elapsed) {
    final before = _frame;
    _now = elapsed;
    if (_frame != before) setState(() {});
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
      // Restart on the new animation, skipping the intro.
      _start = _now;
      _skipIntro = true;
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
    final (anim, i) = _frame;
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

/// The customer standing beside a speech bubble that states the order. With
/// [goals] the bubble also shows a live count for each one.
class OrderBubble extends StatelessWidget {
  const OrderBubble({
    super.key,
    required this.level,
    this.goals,
    this.anim = CustomerAnim.idle,
    this.spriteSize = defaultSpriteSize,
    this.shownChars,
    this.signaturePlays = 0,
  });
  final LevelConfig level;
  final List<GoalProgress>? goals;
  final CustomerAnim anim;
  final double spriteSize;

  /// Bumping this makes the customer play their [Signature] once more.
  final int signaturePlays;

  /// How much of the order has been "spoken" so far, for a typewriter
  /// effect; null shows all of it. The rest is laid out but invisible so the
  /// bubble keeps its size while the text appears.
  final int? shownChars;

  static const defaultSpriteSize = 112.0;

  @override
  Widget build(BuildContext context) {
    final customer = Customer.forLevel(level.id);
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomerSprite(
          key: ValueKey(signaturePlays),
          customer: customer,
          anim: anim,
          intro: signaturePlays > 0 && customer.signature != null
              ? CustomerAnim.signature
              : null,
          introLoops: customer.signature?.loops ?? 1,
          size: spriteSize,
        ),
        Expanded(
          child: Container(
            constraints: BoxConstraints(minHeight: spriteSize * 0.6),
            margin: EdgeInsets.only(bottom: spriteSize * 0.2),
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 8),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: SpeechBubbleBorder(
                  side: BorderSide(
                      color: UiArt.ink.withValues(alpha: 0.55), width: 1.5)),
              shadows: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(customer.name,
                    style: t.labelSmall?.copyWith(
                        color: UiArt.ink, fontWeight: FontWeight.bold)),
                _orderLine(orderText(level.goals),
                    t.bodySmall?.copyWith(color: UiArt.ink)),
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
        ),
      ],
    );
  }

  Widget _orderLine(String text, TextStyle? style) {
    final n = shownChars;
    if (n == null) {
      return Text(text,
          maxLines: 3, overflow: TextOverflow.ellipsis, style: style);
    }
    final chars = text.characters;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: chars.take(n).toString()),
        TextSpan(
            text: chars.skip(n).toString(),
            style: const TextStyle(color: Colors.transparent)),
      ]),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

/// Rounded box with a tail on the left pointing at the speaker, [tailY]
/// down from the top.
class SpeechBubbleBorder extends ShapeBorder {
  const SpeechBubbleBorder({
    this.side = BorderSide.none,
    this.radius = 14,
    this.tail = 10,
    this.tailY = 26,
  });
  final BorderSide side;
  final double radius;
  final double tail;
  final double tailY;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(left: tail);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body =
        Rect.fromLTRB(rect.left + tail, rect.top, rect.right, rect.bottom);
    final half = tail * 0.8;
    final lo = body.top + radius + half;
    final y =
        min(max(rect.top + tailY, lo), max(lo, body.bottom - radius - half));
    return Path.combine(
      PathOperation.union,
      Path()..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius))),
      Path()
        ..moveTo(body.left + radius, y - half)
        ..lineTo(rect.left, y)
        ..lineTo(body.left + radius, y + half)
        ..close(),
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(getOuterPath(rect.deflate(side.width / 2)),
        side.toPaint()..strokeJoin = StrokeJoin.round);
  }

  @override
  ShapeBorder scale(double t) => SpeechBubbleBorder(
      side: side.scale(t),
      radius: radius * t,
      tail: tail * t,
      tailY: tailY * t);
}
