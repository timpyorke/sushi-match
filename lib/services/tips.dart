import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/level.dart';
import 'store.dart';

/// (id, l10n prefix) of the first tip [level] needs that is not in [seen],
/// or null when the player has seen them all.
(String, String)? tipFor(LevelConfig level, Set<String> seen) {
  final tips = [
    if (level.conveyors.isNotEmpty) ('conveyor', 'tipConveyor'),
    if (level.ice.any((n) => n > 0)) ('ice', 'tipIce'),
    if (level.goals.any((g) => g.type == GoalType.deliver))
      ('deliver', 'tipDeliver'),
    if (level.mats.any((m) => m)) ('mat', 'tipMat'),
    if (level.fire.any((f) => f)) ('fire', 'tipFire'),
    if (level.cats.isNotEmpty) ('cat', 'tipCat'),
    if (level.locks.any((k) => k != null)) ('key', 'tipKey'),
    if (level.timers.any((t) => t > 0)) ('bomb', 'tipBomb'),
    if (level.portals.isNotEmpty) ('portal', 'tipPortal'),
    if (level.gravity != Gravity.down) ('gravity', 'tipGravity'),
    if (level.bags.indexed.any((e) => e.$2 > 0 && !level.mats[e.$1]))
      ('bag', 'tipBag'),
  ];
  for (final t in tips) {
    if (!seen.contains(t.$1)) return t;
  }
  return null;
}

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
