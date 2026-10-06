import 'package:shared_preferences/shared_preferences.dart';

/// Persists the highest level the player has cleared.
abstract final class Progress {
  static const _key = 'cleared_level';

  static Future<int> cleared() async =>
      (await SharedPreferences.getInstance()).getInt(_key) ?? 0;

  static Future<void> markCleared(int level) async {
    final prefs = await SharedPreferences.getInstance();
    if (level > (prefs.getInt(_key) ?? 0)) await prefs.setInt(_key, level);
  }

  static Future<void> reset() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
