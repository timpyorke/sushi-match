import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gen/assets.gen.dart';
import '../services/tips.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Covers the board with a one-off explanation until the player taps
/// "Got it". Swallows taps meanwhile so no move is made blind.
class TipOverlay extends ConsumerWidget {
  const TipOverlay(
      {super.key, required this.id, required this.icon, required this.text});

  /// Remembered in [tipsProvider]; also the L10n key prefix:
  /// `<text>Title` / `<text>Body`.
  final String id;
  final AssetGenImage icon;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(tipsProvider).contains(id)) return const SizedBox.shrink();
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
                icon.image(width: 40, height: 40),
                const SizedBox(height: 8),
                OutlinedTitle(L10n.t('${text}Title'), style: t.titleLarge),
                const SizedBox(height: 8),
                Text(L10n.t('${text}Body'), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(tipsProvider.notifier).markSeen(id),
                  child: Text(L10n.t('gotIt')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
