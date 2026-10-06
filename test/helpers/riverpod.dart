import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/ui/l10n.dart';

/// A container backed by an in-memory store (pass the same [store] to a
/// second container to simulate an app restart).
ProviderContainer testContainer({Store? store, DateTime Function()? clock}) {
  L10n.language = 'en';
  final c = ProviderContainer(overrides: [
    storeProvider.overrideWithValue(store ?? MemoryStore()),
    if (clock != null) clockProvider.overrideWithValue(clock),
  ]);
  addTearDown(c.dispose);
  return c;
}

/// Wraps [child] so widgets can read the providers of [container].
Widget scope(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(container: container, child: child);
