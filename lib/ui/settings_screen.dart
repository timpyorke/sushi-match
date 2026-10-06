import 'package:flutter/material.dart';

import '../core/progress.dart';
import '../core/settings.dart';
import 'l10n.dart';
import 'ui_art.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
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
    await Progress.reset();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(L10n.t('progressReset'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ValueListenableBuilder<String>(
      valueListenable: Settings.language,
      builder: (context, _, __) => _page(context, t),
    );
  }

  Widget _page(BuildContext context, TextTheme t) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
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
                    ValueListenableBuilder<bool>(
                      valueListenable: Settings.haptics,
                      builder: (_, on, __) => SwitchListTile(
                        title: Text(L10n.t('vibration')),
                        value: on,
                        onChanged: Settings.setHaptics,
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: Settings.colorblind,
                      builder: (_, on, __) => SwitchListTile(
                        title: Text(L10n.t('colorblind')),
                        value: on,
                        onChanged: Settings.setColorblind,
                      ),
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
                        selected: {Settings.language.value},
                        onSelectionChanged: (v) =>
                            Settings.setLanguage(v.first),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt),
                      title: Text(L10n.t('resetProgress')),
                      onTap: () => _confirmReset(context),
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
