import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-time explanations, shown once per mechanic and then remembered.
abstract final class Tips {
  static const _key = 'tips_seen';

  static final seen = ValueNotifier<Set<String>>(const {});

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    seen.value = (prefs.getStringList(_key) ?? const []).toSet();
  }

  static bool isSeen(String id) => seen.value.contains(id);

  static Future<void> markSeen(String id) async {
    if (isSeen(id)) return;
    seen.value = {...seen.value, id};
    await (await SharedPreferences.getInstance())
        .setStringList(_key, seen.value.toList());
  }

  static Future<void> reset() async {
    seen.value = const {};
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}
