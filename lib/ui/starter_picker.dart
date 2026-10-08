import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/wallet.dart';
import 'game_dialog.dart';
import 'l10n.dart';
import 'ui_art.dart';

const _starters = [
  (Booster.starterKnife, 'starterKnife'),
  (Booster.starterWasabi, 'starterWasabi'),
];

/// Lets the player spend owned Starter boosters before a level begins.
/// Returns the chosen boosters (empty when the player owns none, so no
/// dialog appears), or null if the player backed out.
Future<List<Booster>?> pickStarters(BuildContext context, WidgetRef ref) async {
  final wallet = ref.read(walletProvider);
  if (_starters.every((s) => wallet.count(s.$1) <= 0)) return const [];
  return showDialog<List<Booster>>(
    context: context,
    builder: (_) => const _StarterDialog(),
  );
}

class _StarterDialog extends ConsumerStatefulWidget {
  const _StarterDialog();

  @override
  ConsumerState<_StarterDialog> createState() => _StarterDialogState();
}

class _StarterDialogState extends ConsumerState<_StarterDialog> {
  final _picked = <Booster>{};

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return GameDialog(
      title: L10n.t('startWith'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (b, name) in _starters)
            if (wallet.count(b) > 0)
              CheckboxListTile(
                value: _picked.contains(b),
                onChanged: (on) => setState(
                    () => on == true ? _picked.add(b) : _picked.remove(b)),
                title: Row(
                  children: [
                    BoosterIcon(b, size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(L10n.t(name),
                          style: const TextStyle(
                              color: UiArt.ink, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                secondary: Text('×${wallet.count(b)}'),
              ),
        ],
      ),
      actions: [
        GameDialogButton(
          primary: true,
          onPressed: () => Navigator.pop(context, _picked.toList()),
          label: L10n.t('startLevel'),
        ),
        GameDialogButton(
            onPressed: () => Navigator.pop(context),
            child: const UiControlIcon(UiControl.close)),
      ],
    );
  }
}
