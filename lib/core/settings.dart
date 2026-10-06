import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Player preferences, persisted across launches.
abstract final class Settings {
  static const _hapticsKey = 'haptics';

  /// Mirrors the stored value so the game can read it synchronously.
  static final haptics = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    haptics.value = prefs.getBool(_hapticsKey) ?? true;
  }

  static Future<void> setHaptics(bool on) async {
    haptics.value = on;
    await (await SharedPreferences.getInstance()).setBool(_hapticsKey, on);
  }
}
