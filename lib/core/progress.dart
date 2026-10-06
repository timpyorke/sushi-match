import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/store.dart';

/// The highest level the player has cleared.
class ProgressNotifier extends Notifier<int> {
  static const _key = 'cleared_level';

  @override
  int build() => ref.read(storeProvider).get<int>(_key) ?? 0;

  void markCleared(int level) {
    if (level <= state) return;
    state = level;
    ref.read(storeProvider).put(_key, level);
  }

  void reset() {
    state = 0;
    ref.read(storeProvider).remove(_key);
  }
}

final progressProvider =
    NotifierProvider<ProgressNotifier, int>(ProgressNotifier.new);
