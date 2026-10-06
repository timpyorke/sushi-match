# Sushi Match — prototype (Phase 1: grey box)

Flutter + Flame match-3. Game rules live in pure Dart (`lib/core`) and return
a list of `BoardStep`s; Flame (`lib/game`) only animates them.

## Run

```bash
flutter create --org com.timpyorke --project-name sushi_match --platforms android,ios .
flutter pub get
flutter test          # core rules, no device needed
flutter run
```

`flutter create .` only adds the missing platform folders; it keeps existing files.

## Layout

```
lib/core/   pure Dart — no Flutter/Flame imports allowed
  board.dart, piece.dart, pos.dart, level.dart
  match_finder.dart   runs, L/T, 2x2 → which special spawns
  move_finder.dart    hint + "no moves → shuffle"
  board_factory.dart  clean initial board, shuffle
  game_engine.dart    trySwap() → List<BoardStep>
  steps.dart          step types the view plays back
lib/game/   Flame view (BoardComponent plays steps, PieceComponent draws)
lib/ui/     Flutter HUD + win/lose overlay
assets/levels/level_001.json
```

## Done
Swap/tap-tap input, match → clear → gravity → refill → cascade (×1, ×2…),
all four specials + combos, initial clean board, auto-shuffle, 5 s hint,
collect/score goals, moves, stars, retry. Seeded RNG = reproducible levels.

## Next
Nori/ice/rice bag + their goals, conveyor (end-of-turn hook in
`GameEngine._endTurn`), Wasabi double blast, bonus round, juice (squash,
particles, haptics, sfx), level select + JSON loader for many levels,
balancing bot using `MoveFinder.allMoves` + seeds.
