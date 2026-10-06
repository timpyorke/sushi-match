# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Sushi Match: a sushi-themed match-3 built with Flutter + Flame (portrait, Android/iOS). `GDD.md` is the design doc; `plan.md` (Thai) is the checklist of what is still undone relative to the GDD. CI (`.github/workflows`) runs `flutter analyze` and `flutter test`.

## Commands

```bash
flutter pub get
flutter analyze
flutter test                                   # all tests, no device needed
flutter test test/core/game_engine_test.dart   # one file
flutter test --plain-name "some test name"     # one test
flutter run

dart run tool/balance.dart [runs] [level …] [--planner] [--no-belts]  # bot win rates / star spread per level
dart run tool/tune.dart [runs] [--write]       # re-fit moves, goal counts, star thresholds in assets/levels
dart run tool/gen_sounds.dart                  # regenerate placeholder WAVs in assets/audio/
```

Re-run `tool/tune.dart` after changing the engine or adding levels. Real audio replaces placeholders by dropping a same-named file into `assets/audio/` (the game refers only to file names, see `lib/services/audio.dart`).

## Architecture

Three layers, with dependencies pointing downward only:

- **`lib/core/`: pure Dart, no Flutter/Flame imports.** All game rules live here. `GameEngine.trySwap()` returns a `List<BoardStep>` (`steps.dart`) describing what happened (swap, clear, gravity, refill, cascade, shuffle…). The engine is seeded, so levels are reproducible. `GameEngine.fork` clones state for lookahead (used by the planner bot, hints and the tools). `match_finder.dart` decides which special piece a match spawns; `move_finder.dart` powers hints and the no-moves shuffle. End-of-turn effects such as conveyors hook into `GameEngine._endTurn`.
- **`lib/game/`: the Flame view.** `BoardComponent` only *plays back* the engine's steps as animations; it must not decide rules. `SushiGame` exposes HUD state to Flutter.
- **`lib/ui/` and `lib/main.dart`: Flutter UI** (HUD, level select, shop, restaurant, settings, dialogs). `l10n.dart` is a hand-rolled localisation (`L10n.language`).

Levels are JSON in `assets/levels/level_NNN.json` (60 levels, 4 restaurants × 15). `tool/balance.dart`, `tune.dart` and `bots.dart` load and play them headlessly using the core engine.

### State and persistence

Riverpod 3 (`NotifierProvider`s) with Hive CE for storage. Notifiers live in `lib/services/` (wallet, restaurant, daily_reward, tips) plus `lib/core/progress.dart` and `settings.dart`. They persist through the `Store` abstraction in `lib/services/store.dart`: `storeProvider` throws unless overridden. `main()` overrides it with `HiveStore.open()`, and tests use `MemoryStore`. Time-dependent logic reads `clockProvider` instead of `DateTime.now()`.

### Testing

Use `testContainer({store, clock})` and `scope(container, child)` from `test/helpers/riverpod.dart`. Pass the same store to a second container to simulate an app restart. Pass a fake clock for daily/lives logic. Core rule tests use `test/core/helpers.dart`.
