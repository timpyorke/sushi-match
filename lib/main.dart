import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'core/game_engine.dart';
import 'core/level.dart';
import 'core/level_tuning.dart';
import 'core/progress.dart';
import 'core/settings.dart';
import 'game/piece_painter.dart';
import 'game/sushi_game.dart';
import 'services/analytics.dart';
import 'services/audio.dart';
import 'services/event_config.dart';
import 'services/events.dart';
import 'services/firebase_service.dart';
import 'services/store.dart';
import 'services/wallet.dart';
import 'ui/board_stage.dart';
import 'ui/customer_order.dart';
import 'ui/game_dialog.dart';
import 'ui/home_screen.dart';
import 'ui/hud.dart';
import 'services/restaurant.dart';
import 'services/tips.dart';
import 'ui/level_intro.dart';
import 'ui/level_select.dart';
import 'ui/restaurant_screen.dart';
import 'ui/shop_screen.dart';
import 'ui/splash_screen.dart';
import 'ui/tip_overlay.dart';
import 'ui/l10n.dart';
import 'ui/lives_ui.dart';
import 'ui/settings_screen.dart';
import 'ui/starter_picker.dart';
import 'ui/ui_art.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await _enterImmersive();
  await PiecePainter.loadSprites();
  const bundledEvents = AssetEventSource();
  final remote = await initFirebase() ? RemoteConfigFetch() : null;
  final EventConfigSource eventSource = remote == null
      ? bundledEvents
      : RemoteConfigEventSource(bundledEvents, remote);
  final container = ProviderContainer(overrides: [
    storeProvider.overrideWithValue(await HiveStore.open()),
    eventScheduleProvider.overrideWithValue(await eventSource.load()),
    if (remote != null)
      analyticsProvider.overrideWithValue(Analytics(FirebaseAnalyticsSink())),
    levelTuningProvider.overrideWithValue(
        remote == null ? LevelTuning.none : await loadLevelTuning(remote)),
  ]);
  // Reading the settings applies them to the audio, language and painter.
  container.read(settingsProvider);
  await Audio.init();
  Audio.startMusic();

  // Bars come back after an edge swipe, the keyboard or a system dialog.
  // Hide them again after a short delay.
  SystemChrome.setSystemUIChangeCallback((visible) async {
    if (visible) {
      await Future.delayed(const Duration(seconds: 2));
      await _enterImmersive();
    }
  });
  runApp(UncontrolledProviderScope(
      container: container, child: const SushiTrioApp()));
}

Future<void> _enterImmersive() =>
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

class SushiTrioApp extends StatefulWidget {
  const SushiTrioApp({super.key, this.showSplash = true});

  /// Tests turn the splash off to land on the home screen directly.
  final bool showSplash;

  @override
  State<SushiTrioApp> createState() => _SushiTrioAppState();
}

class _SushiTrioAppState extends State<SushiTrioApp> {
  late bool _splash = widget.showSplash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sushi Trio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB71C2C),
        useMaterial3: true,
        fontFamily: 'Mali',
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _splash
            ? SplashScreen(
                key: const ValueKey('splash'),
                onDone: () => setState(() => _splash = false))
            : const _Home(key: ValueKey('home')),
      ),
    );
  }
}

/// Levels in the game; grows by editing `Restaurant.shops`.
final int kLevelCount = Restaurant.totalLevels;

/// (id, emoji, l10n prefix) of the first unseen tip this level needs.
(String, String, String)? _tipFor(LevelConfig level, Set<String> seen) {
  final tips = [
    if (level.conveyors.isNotEmpty) ('conveyor', '➡️🔒', 'tipConveyor'),
    if (level.ice.any((n) => n > 0)) ('ice', '🧊', 'tipIce'),
    if (level.goals.any((g) => g.type == GoalType.deliver))
      ('deliver', '🍙', 'tipDeliver'),
    if (level.mats.any((m) => m)) ('mat', '🎋', 'tipMat'),
    if (level.fire.any((f) => f)) ('fire', '🔥', 'tipFire'),
    if (level.cats.isNotEmpty) ('cat', '🐱', 'tipCat'),
    if (level.locks.any((k) => k != null)) ('key', '🔑', 'tipKey'),
    if (level.timers.any((t) => t > 0)) ('bomb', '💣', 'tipBomb'),
    if (level.portals.isNotEmpty) ('portal', '🌀', 'tipPortal'),
    if (level.gravity != Gravity.down) ('gravity', '↔️', 'tipGravity'),
    if ([
      for (var i = 0; i < level.bags.length; i++)
        if (level.bags[i] > 0 && !level.mats[i]) i,
    ].isNotEmpty)
      ('bag', '🌾', 'tipBag'),
  ];
  for (final t in tips) {
    if (!seen.contains(t.$1)) return t;
  }
  return null;
}

String _levelAsset(int n) =>
    'assets/levels/level_${n.toString().padLeft(3, '0')}.json';

/// Spends a life, lets the player pick starter boosters, then opens the level.
Future<void> startLevel(BuildContext context, WidgetRef ref, int n) async {
  if (!await ensureLife(context, ref) || !context.mounted) return;
  final starters = await pickStarters(context, ref);
  if (starters == null || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
        builder: (_) => GameScreen(levelNumber: n, starters: starters)),
  );
}

void _openRestaurant(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const RestaurantScreen()));
void _openShop(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const BoosterShopScreen()));
void _openSettings(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

class _Home extends ConsumerWidget {
  const _Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => HomeScreen(
        levelCount: kLevelCount,
        onPlay: (n) => startLevel(context, ref, n),
        onLevels: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const LevelSelectScreen())),
        onRestaurant: () => _openRestaurant(context),
        onShop: () => _openShop(context),
        onSettings: () => _openSettings(context),
      );
}

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testMode = ref.watch(settingsProvider.select((s) => s.testMode));
    final cleared = testMode ? kLevelCount : ref.watch(progressProvider);
    final restaurant = ref.watch(restaurantProvider);
    // Rebuild on a language change; L10n reads it statically.
    ref.watch(settingsProvider.select((s) => s.language));
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LevelSelectView(
            levelCount: kLevelCount,
            cleared: cleared,
            stars: restaurant.best,
            onBack: () => Navigator.of(context).maybePop(),
            onRestaurant: () => _openRestaurant(context),
            onShop: () => _openShop(context),
            onSettings: () => _openSettings(context),
            onSelect: (n) => startLevel(context, ref, n),
          ),
        ),
      ),
    );
  }
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, this.levelNumber = 1, this.starters = const []});
  final int levelNumber;
  final List<Booster> starters;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final Future<SushiGame> _game = _load();

  /// The order bubble above the board, where the level intro lands.
  final _orderKey = GlobalKey();
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    Audio.startMusic(Restaurant.shopOfLevel(widget.levelNumber)?.id);
  }

  @override
  void dispose() {
    // Back on the level map the first restaurant's tune plays.
    Audio.startMusic('tsukiji');
    super.dispose();
  }

  Future<SushiGame> _load() async {
    final raw = await rootBundle.loadString(_levelAsset(widget.levelNumber));
    final level = ref
        .read(levelTuningProvider)
        .apply(LevelConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    final progress = ref.read(progressProvider.notifier);
    final restaurant = ref.read(restaurantProvider.notifier);
    final events = ref.read(eventProvider.notifier);
    events.refresh();
    final game = SushiGame(
        level: level,
        wallet: ref.read(walletProvider.notifier),
        starters: widget.starters,
        eventKind: ref.read(eventProvider).active?.kind,
        onEventGain: events.addCollected,
        analytics: ref.read(analyticsProvider));
    game.hud.addListener(() {
      if (game.hud.value.status == GameStatus.won) {
        progress.markCleared(widget.levelNumber);
        restaurant.recordStars(widget.levelNumber, game.hud.value.stars);
      }
    });
    return game;
  }

  /// Asks before throwing away a run in progress; finished runs need no ask.
  Future<bool> _confirmLoss(
      SushiGame game, String title, String body, String action) async {
    if (game.hud.value.status != GameStatus.playing) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => GameDialog(
        title: L10n.t(title),
        content: Text(L10n.t(body), textAlign: TextAlign.center),
        actions: [
          GameDialogButton(
              primary: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              label: L10n.t(action)),
          GameDialogButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              label: L10n.t('cancel')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _leave(SushiGame game) async {
    if (await _confirmLoss(game, 'leaveTitle', 'leaveBody', 'leave') &&
        mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _restart(SushiGame game) async {
    if (await _confirmLoss(game, 'restartTitle', 'restartBody', 'restart')) {
      game.restart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backgrounds/bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<SushiGame>(
          future: _game,
          builder: (context, snap) {
            final game = snap.data;
            if (game == null) {
              return Center(
                child: snap.hasError
                    ? Text('${snap.error}')
                    : const CircularProgressIndicator(),
              );
            }
            return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) _leave(game);
                },
                child: Stack(children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          children: [
                            RoundIconButton(
                              icon: Icons.arrow_back,
                              onPressed: () => _leave(game),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: HudBar(game: game)),
                            RoundIconButton(
                              icon: Icons.restart_alt,
                              onPressed: () => _restart(game),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            BoardStage(
                              level: game.level,
                              order: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
                                child: ValueListenableBuilder<HudState>(
                                  valueListenable: game.hud,
                                  builder: (context, s, child) => Opacity(
                                    opacity: _introDone ? 1 : 0,
                                    child: OrderBubble(
                                        key: _orderKey,
                                        level: game.level,
                                        goals: s.goals),
                                  ),
                                ),
                              ),
                              board: GameWidget(game: game),
                            ),
                            PraiseBanner(game: game),
                            // One tip at a time: the first mechanic of this level
                            // the player has not been told about yet.
                            Consumer(
                              builder: (context, ref, _) {
                                final tip = _tipFor(
                                    game.level, ref.watch(tipsProvider));
                                return tip == null
                                    ? const SizedBox.shrink()
                                    : TipOverlay(
                                        id: tip.$1,
                                        emoji: tip.$2,
                                        text: tip.$3);
                              },
                            ),
                            ResultOverlay(
                              game: game,
                              onLevels: () => Navigator.of(context).pop(),
                              onNext: widget.levelNumber < kLevelCount
                                  ? () async {
                                      if (!await ensureLife(context, ref) ||
                                          !context.mounted) {
                                        return;
                                      }
                                      final starters =
                                          await pickStarters(context, ref);
                                      if (starters == null ||
                                          !context.mounted) {
                                        return;
                                      }
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => GameScreen(
                                              levelNumber:
                                                  widget.levelNumber + 1,
                                              starters: starters),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      BoosterBar(game: game),
                    ],
                  ),
                  if (!_introDone)
                    Positioned.fill(
                      child: LevelIntro(
                        level: game.level,
                        goals: game.hud.value.goals,
                        target: _orderKey,
                        onDone: () => setState(() => _introDone = true),
                      ),
                    ),
                ]));
          },
        ),
      ),
    ));
  }
}
