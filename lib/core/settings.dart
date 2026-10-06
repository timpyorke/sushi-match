import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio.dart';
import '../services/store.dart';
import '../ui/l10n.dart';

/// Player preferences, persisted across launches.
class SettingsState {
  const SettingsState({
    this.haptics = true,
    this.sound = true,
    this.music = true,
    this.language = 'en',
  });

  final bool haptics;
  final bool sound;
  final bool music;

  /// 'en' or 'th'.
  final String language;

  SettingsState copyWith(
          {bool? haptics,
          bool? sound,
          bool? music,
          String? language}) =>
      SettingsState(
        haptics: haptics ?? this.haptics,
        sound: sound ?? this.sound,
        music: music ?? this.music,
        language: language ?? this.language,
      );
}

/// Read-only mirror of the settings for code that has no `ref`: the Flame
/// board, the sprite painter and [L10n]. [SettingsNotifier] keeps it current.
abstract final class SettingsMirror {
  static bool haptics = true;
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _haptics = 'haptics';
  static const _sound = 'sound';
  static const _music = 'music';
  static const _language = 'language';

  @override
  SettingsState build() {
    final s = ref.read(storeProvider);
    final loaded = SettingsState(
      haptics: s.get<bool>(_haptics) ?? true,
      sound: s.get<bool>(_sound) ?? true,
      music: s.get<bool>(_music) ?? true,
      language: s.get<String>(_language) ?? 'en',
    );
    _mirror(loaded);
    return loaded;
  }

  void _mirror(SettingsState s) {
    SettingsMirror.haptics = s.haptics;
    L10n.language = s.language;
    Audio.configure(sound: s.sound, music: s.music);
  }

  void _set(SettingsState next, String key, Object value) {
    state = next;
    _mirror(next);
    ref.read(storeProvider).put(key, value);
  }

  void setHaptics(bool on) => _set(state.copyWith(haptics: on), _haptics, on);
  void setSound(bool on) => _set(state.copyWith(sound: on), _sound, on);
  void setMusic(bool on) => _set(state.copyWith(music: on), _music, on);
  void setLanguage(String code) =>
      _set(state.copyWith(language: code), _language, code);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
