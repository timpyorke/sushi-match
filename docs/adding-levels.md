# Adding levels and restaurants

The game has **205 levels in 14 restaurants**. Everything that depends on the
level count is derived from `Restaurant.shops` (`lib/services/restaurant.dart`),
so growing the game is data, not code.

| Restaurant | Levels | Theme |
|---|---|---|
| Tsukiji | 1–15 | Basics: collect, score, nori |
| Osaka | 16–30 | Conveyors, cats, ice, fire |
| Kyoto | 31–45 | Bags, deliver, mats |
| Hokkaido | 46–60 | Locks, bombs, portals, gravity |
| Fukuoka | 61–75 | Two mechanics at once |
| Okinawa | 76–90 | Sideways gravity, portals, bombs |
| Omakase | 91–100 | 3–4 mechanics, boss at 100 |
| Nagoya | 101–115 | Squid (ika) joins; new shapes (square8, tee9, cup9); recap |
| Hiroshima | 116–130 | Thick blockers: 2–3 layers of ice, nori, bags |
| Kanazawa | 131–145 | Octopus (tako) joins; deliveries and locks |
| Sendai | 146–160 | Cats, fire and bombs |
| Kobe | 161–175 | Gravity, portals, conveyors |
| Nara | 176–190 | Bamboo mats plus 2–3 other blockers |
| Ginza | 191–205 | Every mechanic, boss at 205 |

Difficulty is a sawtooth: every 5th level is harder, every 15th (and 100) a boss. Past 100 the bosses close each 15-level restaurant (115, 130 … 190, 205 …). There is no final level: the game keeps growing.

## A. Add levels to the end

1. **Spec**: append rows to `specs` in `tool/gen_levels.dart` (shape, goals,
   feature string; syntax is at the top of that file). Layouts are generated,
   so no hand-typed grids. Hand-written JSON in `assets/levels/` works too.
2. **Generate**: `dart run tool/gen_levels.dart` (never overwrites; `--force` does).
3. **Tune**: `dart run tool/tune.dart 100 <ids…> --write` fits moves, goal
   counts and star thresholds to the difficulty curve. Check the printed win
   rate against the target; if a level cannot reach it, change its layout.
4. **Register**: raise the last shop's `lastLevel` in `Restaurant.shops`
   (`lastLevel - firstLevel` up to ~20 levels per restaurant fits the map).
5. `flutter test` (the level files, map and consistency tests all derive their
   expectations from `Restaurant.totalLevels`).

## B. Add a restaurant (new map band)

Append a `ShopDef` to `Restaurant.shops` with `firstLevel = previous.lastLevel + 1`,
then add the items the consistency test (`test/core/content_consistency_test.dart`)
checks, which fail until each exists:

- `kMapRegions[id]` in `lib/ui/map/japan_map.dart` (colours, kanji, deco swaps).
  The map stacks one band per shop above the previous one; odd bands are
  mirrored so the route snakes. The scroll area, banner and route all grow
  with the shop list, and levels are spread evenly along the band's route.
- `shop_<id>` and `zone_<id>` in both languages in `lib/ui/l10n.dart`.
- A palette in `_palettes` in `lib/ui/restaurant_screen.dart` (falls back to
  Tsukiji's if missing).
- Music: add `assets/audio/bgm_<id>.wav`, list it in `Audio.tracks`, or alias
  it to an existing track in `Audio._alias` until it exists.
- Unlock cost: keep cumulative unlock costs around 90% of the stars available
  so far (3 stars × levels before it); decor costs are the optional sink.

## Conventions the generator follows (keep for hand-made levels)

- Voids only at the ends of rows/columns; blockers (bags, mats) away from the
  border; portal entries on the bottom row, exits on the top row, gravity down.
- Collect goals must use kinds listed in `pieces`.
- Sprites exist for the first kinds of `PieceKind`; levels 76+ use `hotate`,
  91+ use `unagi`, 101+ `ika`, 131+ `tako`.
