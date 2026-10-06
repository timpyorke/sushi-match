import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/progress.dart';
import '../services/daily_reward.dart';
import '../services/restaurant.dart';
import '../services/tips.dart';
import '../core/settings.dart';
import 'l10n.dart';
import 'ui_art.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L10n.t('resetTitle')),
        content: Text(L10n.t('resetBody')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(L10n.t('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(L10n.t('reset'))),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(progressProvider.notifier).reset();
    ref.read(restaurantProvider.notifier).reset();
    ref.read(tipsProvider.notifier).reset();
    ref.read(dailyProvider.notifier).reset();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(L10n.t('progressReset'))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: RoundIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(L10n.t('settings'),
                    style:
                        t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: UiArt.panelDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(L10n.t('soundEffects')),
                      value: settings.sound,
                      onChanged: notifier.setSound,
                    ),
                    SwitchListTile(
                      title: Text(L10n.t('music')),
                      value: settings.music,
                      onChanged: notifier.setMusic,
                    ),
                    SwitchListTile(
                      title: Text(L10n.t('vibration')),
                      value: settings.haptics,
                      onChanged: notifier.setHaptics,
                    ),
                    SwitchListTile(
                      title: Text(L10n.t('colorblind')),
                      value: settings.colorblind,
                      onChanged: notifier.setColorblind,
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(L10n.t('language')),
                      trailing: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          for (final e in L10n.languages.entries)
                            ButtonSegment(value: e.key, label: Text(e.value)),
                        ],
                        selected: {settings.language},
                        onSelectionChanged: (v) =>
                            notifier.setLanguage(v.first),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt),
                      title: Text(L10n.t('resetProgress')),
                      onTap: () => _confirmReset(context, ref),
                    ),
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
