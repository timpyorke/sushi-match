import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import 'customer_order.dart';

/// Level opening: the customer pops up in the middle of the screen and says
/// the order while it types out, then the whole bubble flies up into
/// [target], the order bubble above the board. A tap skips to the flight.
/// Calls [onDone] once it has landed.
class LevelIntro extends StatefulWidget {
  const LevelIntro({
    super.key,
    required this.level,
    required this.goals,
    required this.target,
    required this.onDone,
  });
  final LevelConfig level;
  final List<GoalProgress> goals;
  final GlobalKey target;
  final VoidCallback onDone;

  static const pop = Duration(milliseconds: 350);
  static const perChar = Duration(milliseconds: 30);
  static const hold = Duration(milliseconds: 900);
  static const fly = Duration(milliseconds: 550);

  /// How long the whole intro runs for [level] when nobody taps.
  static Duration length(LevelConfig level) =>
      pop + perChar * orderText(level.goals).characters.length + hold + fly;

  @override
  State<LevelIntro> createState() => _LevelIntroState();
}

class _LevelIntroState extends State<LevelIntro> with TickerProviderStateMixin {
  static const _bigSprite = 168.0;

  late final int _chars = orderText(widget.level.goals).characters.length;
  late final AnimationController _say = AnimationController(
      vsync: this,
      duration: LevelIntro.pop + LevelIntro.perChar * _chars + LevelIntro.hold)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _flight.forward();
    });
  late final AnimationController _flight =
      AnimationController(vsync: this, duration: LevelIntro.fly)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        });

  /// Where the order bubble sits, in this widget's coordinates.
  Rect? _target;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final target = widget.target.currentContext?.findRenderObject();
    final self = context.findRenderObject();
    if (target is! RenderBox || self is! RenderBox) {
      widget.onDone(); // nothing to fly to
      return;
    }
    setState(() => _target =
        self.globalToLocal(target.localToGlobal(Offset.zero)) & target.size);
    _say.forward();
  }

  void _skip() {
    if (_say.isAnimating) _say.value = 1;
  }

  @override
  void dispose() {
    _say.dispose();
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: Listenable.merge([_say, _flight]),
          builder: (context, _) {
            final target = _target;
            final f = Curves.easeInOutCubic.transform(_flight.value);
            final dim = ColoredBox(
                color: Colors.black.withValues(alpha: 0.45 * (1 - f)));
            if (target == null) return dim;

            final ms = _say.value * _say.duration!.inMilliseconds;
            final pop = Curves.easeOutBack
                .transform(min(1, ms / LevelIntro.pop.inMilliseconds));
            final shown = ((ms - LevelIntro.pop.inMilliseconds) /
                    LevelIntro.perChar.inMilliseconds)
                .floor()
                .clamp(0, _chars);
            final startTop = max(target.top, (box.maxHeight - _bigSprite) / 2);
            return Stack(
              fit: StackFit.expand,
              children: [
                dim,
                Positioned(
                  left: target.left,
                  width: target.width,
                  top: lerpDouble(startTop, target.top, f),
                  child: Opacity(
                    opacity: pop.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * pop,
                      alignment: Alignment.bottomLeft,
                      child: OrderBubble(
                        level: widget.level,
                        goals: widget.goals,
                        anim: shown < _chars
                            ? CustomerAnim.talk
                            : CustomerAnim.idle,
                        spriteSize: lerpDouble(
                            _bigSprite, OrderBubble.defaultSpriteSize, f)!,
                        shownChars: shown,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
