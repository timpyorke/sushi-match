import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio.dart';
import '../services/store.dart';
import '../ui/l10n.dart';

/// Player preferences, persisted across launches.
class SettingsState {
  const SettingsState({
    this.haptics = true,
    this.soundVolume = 1,
    this.musicVolume = 1,
    this.language = 'en',
    this.testMode = false,
  });

  final bool haptics;

  /// Sound-effect and music volume, 0 (off) to 1 (full mix level).
  final double soundVolume;
  final double musicVolume;

  /// A key of [L10n.languages].
  final String language;

  /// Dev aid: every level, restaurant and life is unlocked.
  final bool testMode;

  SettingsState copyWith(
          {bool? haptics,
          double? soundVolume,
          double? musicVolume,
          String? language,
          bool? testMode}) =>
      SettingsState(
        haptics: haptics ?? this.haptics,
        soundVolume: soundVolume ?? this.soundVolume,
        musicVolume: musicVolume ?? this.musicVolume,
        language: language ?? this.language,
        testMode: testMode ?? this.testMode,
      );
}

/// Read-only mirror of the settings for code that has no `ref`: the Flame
/// board, the sprite painter and [L10n]. [SettingsNotifier] keeps it current.
abstract final class SettingsMirror {
  static bool haptics = true;
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _haptics = 'haptics';
  static const _sound = 'sound_volume';
  static const _music = 'music_volume';

  /// On/off switches saved before the volume sliders existed.
  static const _legacySound = 'sound';
  static const _legacyMusic = 'music';
  static const _language = 'language';
  static const _testMode = 'test_mode';

  @override
  SettingsState build() {
    final s = ref.read(storeProvider);
    final loaded = SettingsState(
      haptics: s.get<bool>(_haptics) ?? true,
      soundVolume: _volume(s, _sound, _legacySound),
      musicVolume: _volume(s, _music, _legacyMusic),
      language: L10n.languages.containsKey(s.get<String>(_language))
          ? s.get<String>(_language)!
          : 'en',
      testMode: s.get<bool>(_testMode) ?? false,
    );
    _mirror(loaded);
    return loaded;
  }

  /// Saved volume, else full or silent from an old on/off switch.
  static double _volume(Store s, String key, String legacy) {
    final v = s.get<num>(key);
    if (v != null) return v.toDouble().clamp(0, 1);
    return s.get<bool>(legacy) == false ? 0 : 1;
  }

  void _mirror(SettingsState s) {
    SettingsMirror.haptics = s.haptics;
    L10n.language = s.language;
    Audio.configure(sound: s.soundVolume, music: s.musicVolume);
  }

  void _set(SettingsState next, String key, Object value) {
    state = next;
    _mirror(next);
    ref.read(storeProvider).put(key, value);
  }

  void setHaptics(bool on) => _set(state.copyWith(haptics: on), _haptics, on);
  void setSoundVolume(double v) =>
      _set(state.copyWith(soundVolume: v), _sound, v);
  void setMusicVolume(double v) =>
      _set(state.copyWith(musicVolume: v), _music, v);
  void setTestMode(bool on) =>
      _set(state.copyWith(testMode: on), _testMode, on);
  void setLanguage(String code) =>
      _set(state.copyWith(language: code), _language, code);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
