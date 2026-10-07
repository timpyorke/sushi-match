import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/event.dart';
import '../core/settings.dart';
import 'event_config.dart';
import 'store.dart';
import 'wallet.dart';

@immutable
class EventState {
  const EventState({this.active, this.collected = 0, this.claimed = const {}});

  /// The running event, or null when there is none.
  final EventConfig? active;

  /// Event pieces cleared this week.
  final int collected;

  /// Indexes of the milestones already paid.
  final Set<int> claimed;

  bool canClaim(int i) {
    final a = active;
    return a != null &&
        i >= 0 &&
        i < a.milestones.length &&
        collected >= a.milestones[i].target &&
        !claimed.contains(i);
  }

  /// Milestones reached but not yet collected.
  int get claimable {
    final a = active;
    if (a == null) return 0;
    return [for (var i = 0; i < a.milestones.length; i++) i]
        .where(canClaim)
        .length;
  }
}

/// Weekly event progress. The tally is stored under the event's id, so a new
/// event (or the next rotation week) starts from zero on its own.
class EventNotifier extends Notifier<EventState> {
  static const _idKey = 'event_id';
  static const _collectedKey = 'event_collected';
  static const _claimedKey = 'event_claimed';
  static const _seenKey = 'event_seen';

  DateTime _now() => ref.read(clockProvider)();

  EventConfig? _current(bool testMode) {
    final schedule = ref.read(eventScheduleProvider);
    return testMode ? schedule.forced(_now()) : schedule.activeAt(_now());
  }

  @override
  EventState build() {
    // Test mode shows an event even outside its dates.
    final active =
        _current(ref.watch(settingsProvider.select((s) => s.testMode)));
    if (active == null) return const EventState();
    final s = ref.read(storeProvider);
    if (s.get<String>(_idKey) != active.id) return EventState(active: active);
    return EventState(
        active: active,
        collected: s.get<int>(_collectedKey) ?? 0,
        claimed: {
          for (final i in s.getStringList(_claimedKey) ?? const <String>[])
            if (int.tryParse(i) case final n?) n
        });
  }

  /// Picks up a week rollover (or a changed schedule) while the app is open.
  void refresh() {
    final active = _current(ref.read(settingsProvider).testMode);
    if (active?.id == state.active?.id) return;
    ref.invalidateSelf();
  }

  /// Adds [n] event pieces to the tally; ignored when no event is running.
  void addCollected(int n) {
    refresh();
    final a = state.active;
    if (a == null || n <= 0) return;
    state = EventState(
        active: a, collected: state.collected + n, claimed: state.claimed);
    _save();
  }

  /// True until the player has seen the start popup of the running event.
  bool get unseen {
    final a = state.active;
    return a != null && ref.read(storeProvider).get<String>(_seenKey) != a.id;
  }

  void markSeen() {
    final a = state.active;
    if (a != null) ref.read(storeProvider).put(_seenKey, a.id);
  }

  /// Pays milestone [i] and returns it, or null if it is not claimable.
  EventMilestone? claim(int i) {
    if (!state.canClaim(i)) return null;
    final a = state.active!;
    final m = a.milestones[i];
    final wallet = ref.read(walletProvider.notifier);
    wallet.earn(m.coins);
    final booster = Booster.values.asNameMap()[m.booster];
    if (booster != null && m.qty > 0) wallet.grant(booster, m.qty);
    state = EventState(
        active: a, collected: state.collected, claimed: {...state.claimed, i});
    _save();
    return m;
  }

  void _save() {
    final s = ref.read(storeProvider);
    s.put(_idKey, state.active!.id);
    s.put(_collectedKey, state.collected);
    s.put(_claimedKey, [for (final i in state.claimed) '$i']);
  }

  void reset() {
    final s = ref.read(storeProvider);
    s.remove(_idKey);
    s.remove(_collectedKey);
    s.remove(_claimedKey);
    s.remove(_seenKey);
    ref.invalidateSelf();
  }
}

final eventProvider =
    NotifierProvider<EventNotifier, EventState>(EventNotifier.new);
