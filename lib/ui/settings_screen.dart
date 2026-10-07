import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/progress.dart';
import '../services/daily_reward.dart';
import '../services/events.dart';
import '../services/audio.dart';
import '../services/restaurant.dart';
import '../services/tips.dart';
import '../core/settings.dart';
import 'game_dialog.dart';
import 'l10n.dart';
import 'ui_art.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => GameDialog(
        title: L10n.t('resetTitle'),
        content: Text(L10n.t('resetBody'), textAlign: TextAlign.center),
        actions: [
          GameDialogButton(
              primary: true,
              onPressed: () => Navigator.pop(context, true),
              label: L10n.t('reset')),
          GameDialogButton(
              onPressed: () => Navigator.pop(context, false),
              label: L10n.t('cancel')),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(progressProvider.notifier).reset();
    ref.read(restaurantProvider.notifier).reset();
    ref.read(tipsProvider.notifier).reset();
    ref.read(dailyProvider.notifier).reset();
    ref.read(eventProvider.notifier).reset();
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
                child:
                    OutlinedTitle(L10n.t('settings'), style: t.headlineLarge),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: UiArt.panelDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _VolumeTile(
                          icon: Icons.volume_up,
                          mutedIcon: Icons.volume_off,
                          label: L10n.t('soundEffects'),
                          value: settings.soundVolume,
                          onChanged: notifier.setSoundVolume,
                          // A sample at the new level once the thumb is let go.
                          onChangeEnd: (_) => Audio.play(Sfx.tap),
                        ),
                        _VolumeTile(
                          icon: Icons.music_note,
                          mutedIcon: Icons.music_off,
                          label: L10n.t('music'),
                          value: settings.musicVolume,
                          onChanged: notifier.setMusicVolume,
                        ),
                        SwitchListTile(
                          title: Text(L10n.t('vibration')),
                          value: settings.haptics,
                          onChanged: notifier.setHaptics,
                        ),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: Text(L10n.t('language')),
                        ),
                        // One row per entry in L10n.languages, so a new language
                        // shows up here as soon as its strings are added.
                        RadioGroup<String>(
                          groupValue: settings.language,
                          onChanged: (code) {
                            if (code != null) notifier.setLanguage(code);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final e in L10n.languages.entries)
                                RadioListTile<String>(
                                  value: e.key,
                                  title: Text(e.value),
                                  dense: true,
                                  contentPadding: const EdgeInsets.only(
                                      left: 40, right: 16),
                                ),
                            ],
                          ),
                        ),
                        if (!kReleaseMode)
                          SwitchListTile(
                            title: Text(L10n.t('testMode')),
                            subtitle: Text(L10n.t('testModeHint')),
                            value: settings.testMode,
                            onChanged: notifier.setTestMode,
                          ),
                        ListTile(
                          leading: const Icon(Icons.restart_alt),
                          title: Text(L10n.t('resetProgress')),
                          onTap: () => _confirmReset(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A volume slider in 10% steps; the icon shows a muted glyph at 0.
class _VolumeTile extends StatelessWidget {
  const _VolumeTile({
    required this.icon,
    required this.mutedIcon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  final IconData icon;
  final IconData mutedIcon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final percent = '${(value * 100).round()}%';
    return ListTile(
      leading: Icon(value == 0 ? mutedIcon : icon),
      title: Text(label),
      trailing: Text(percent),
      subtitle: Slider(
        value: value,
        divisions: 10,
        label: percent,
        semanticFormatterCallback: (v) => '${(v * 100).round()}%',
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}
