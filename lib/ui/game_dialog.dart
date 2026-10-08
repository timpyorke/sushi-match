import 'package:flutter/material.dart';

import '../services/audio.dart';
import 'ui_art.dart';

/// Themed replacement for [AlertDialog]: wooden wave panel, ink text, and
/// matching buttons. Use [GameDialogButton] for [actions].
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.title,
    this.titleIcon,
    this.content,
    this.actions = const [],
    this.width = 320,
  });

  final String title;
  final Widget? titleIcon;
  final Widget? content;
  final List<Widget> actions;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
            decoration: UiArt.panelDecoration(),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: UiArt.ink),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (titleIcon != null) ...[
                        titleIcon!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: OutlinedTitle(title,
                            style: Theme.of(context).textTheme.headlineSmall),
                      ),
                    ],
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 12),
                    content!,
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      actions[i],
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width button for [GameDialog]. Primary is the red call to action,
/// otherwise a cream chip with an ink outline.
class GameDialogButton extends StatelessWidget {
  const GameDialogButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.primary = false,
  }) : assert(label != null || child != null);

  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final bool primary;

  static const _red = Color(0xFFB71C2C);

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Text(label!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold));
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final onTap = onPressed == null
        ? null
        : () {
            Audio.play(Sfx.tap);
            onPressed!();
          };
    final style = primary
        ? FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
            shape: shape,
            minimumSize: const Size.fromHeight(44),
          )
        : FilledButton.styleFrom(
            backgroundColor: UiArt.paper,
            foregroundColor: UiArt.ink,
            shape: shape.copyWith(
                side: BorderSide(
                    color: UiArt.ink.withValues(alpha: 0.55), width: 1.5)),
            minimumSize: const Size.fromHeight(44),
          );
    return FilledButton(onPressed: onTap, style: style, child: content);
  }
}
