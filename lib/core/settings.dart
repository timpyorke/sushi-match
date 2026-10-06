import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Player preferences, persisted across launches.
abstract final class Settings {
  static const _hapticsKey = 'haptics';
  static const _colorblindKey = 'colorblind';
  static const _languageKey = 'language';

  /// Mirrors the stored values so the game can read them synchronously.
  static final haptics = ValueNotifier<bool>(true);

  /// Draws a symbol on every piece so kinds differ by more than colour.
  static final colorblind = ValueNotifier<bool>(false);

  /// 'en' or 'th'.
  static final language = ValueNotifier<String>('en');

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    haptics.value = prefs.getBool(_hapticsKey) ?? true;
    colorblind.value = prefs.getBool(_colorblindKey) ?? false;
    language.value = prefs.getString(_languageKey) ?? 'en';
  }

  static Future<void> setHaptics(bool on) async {
    haptics.value = on;
    await (await SharedPreferences.getInstance()).setBool(_hapticsKey, on);
  }

  static Future<void> setColorblind(bool on) async {
    colorblind.value = on;
    await (await SharedPreferences.getInstance()).setBool(_colorblindKey, on);
  }

  static Future<void> setLanguage(String code) async {
    language.value = code;
    await (await SharedPreferences.getInstance()).setString(_languageKey, code);
  }
}
