import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store.dart';

/// First-time explanations, shown once per mechanic and then remembered.
/// The state is the set of tip ids already seen.
class TipsNotifier extends Notifier<Set<String>> {
  static const _key = 'tips_seen';

  @override
  Set<String> build() =>
      (ref.read(storeProvider).getStringList(_key) ?? const []).toSet();

  void markSeen(String id) {
    if (state.contains(id)) return;
    state = {...state, id};
    ref.read(storeProvider).put(_key, state.toList());
  }

  void reset() {
    state = const {};
    ref.read(storeProvider).remove(_key);
  }
}

final tipsProvider =
    NotifierProvider<TipsNotifier, Set<String>>(TipsNotifier.new);
