import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';
import '../core/piece.dart';
import '../services/audio.dart';
import 'l10n.dart';
import 'sushi_trio.dart';
import 'ui_art.dart';

/// Branded intro: the sushi trio drops in, the title pops, a plank bar fills.
/// Calls [onDone] once when it finishes or when the player taps to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen(
      {super.key,
      required this.onDone,
      this.duration = const Duration(milliseconds: 2200)});

  final VoidCallback onDone;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration)
        ..addListener(_onTick)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _finish();
        })
        ..forward();
  bool _chimed = false, _done = false;

  void _onTick() {
    if (!_chimed && _ctrl.value >= 0.25) {
      _chimed = true;
      Audio.play(Sfx.chime);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _span(double a, double b, [Curve c = Curves.easeOut]) =>
      CurvedAnimation(parent: _ctrl, curve: Interval(a, b, curve: c));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final kinds = logoKinds;
    final title = _span(0.25, 0.5, Curves.easeOutBack);
    final tagline = _span(0.42, 0.6);
    final bar = _span(0.6, 0.92, Curves.easeInOut);
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: Assets.backgrounds.bg.provider(),
              fit: BoxFit.cover,
            ),
          ),
          child: SizedBox.expand(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < kinds.length; i++)
                            _drop(i, kinds[i]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: title.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: title.value,
                          child: OutlinedTitle('Sushi Trio',
                              style: t.displayMedium, strokeWidth: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: tagline.value,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - tagline.value)),
                          child: PlankSubtitle(text: L10n.t('tagline')),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Opacity(
                        opacity: tagline.value,
                        child: _ProgressBar(value: bar.value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A sushi that falls in with a bounce, then bobs with the wave.
  Widget _drop(int i, PieceKind kind) {
    final fall = _span(0.05 * i, 0.3 + 0.05 * i, Curves.bounceOut).value;
    final landed = (_ctrl.value - (0.3 + 0.05 * i)).clamp(0.0, 1.0);
    final bob = trioBob(_ctrl.value * 2, i) * (landed * 4).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Opacity(
        opacity: (fall * 3).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -260 * (1 - fall) + bob),
          child: KindSprite(kind, size: 76),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        height: 16,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: UiArt.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: UiArt.ink, width: 2),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE53950), Color(0xFFB71C2C)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}
