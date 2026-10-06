import 'package:flutter/material.dart';

import '../services/tips.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Covers the board with a one-off explanation until the player taps
/// "Got it". Swallows taps meanwhile so no move is made blind.
class TipOverlay extends StatelessWidget {
  const TipOverlay(
      {super.key, required this.id, required this.emoji, required this.text});

  /// Remembered in [Tips]; also the L10n key prefix: `<text>Title` / `<text>Body`.
  final String id;
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Tips.seen,
      builder: (context, _) {
        if (Tips.isSeen(id)) return const SizedBox.shrink();
        final t = Theme.of(context).textTheme;
        return ColoredBox(
          color: Colors.black38,
          child: Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              decoration: UiArt.panelDecoration(),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: UiArt.ink),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(L10n.t('${text}Title'),
                        style: t.titleLarge?.copyWith(
                            color: UiArt.ink, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(L10n.t('${text}Body'), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Tips.markSeen(id),
                      child: Text(L10n.t('gotIt')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
