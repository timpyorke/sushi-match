import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_engine.dart';
import '../core/level.dart';
import '../core/progress.dart';
import '../game/sushi_game.dart';
import '../services/analytics.dart';
import '../services/audio.dart';
import '../services/event_config.dart';
import '../services/events.dart';
import '../services/restaurant.dart';
import '../services/tips.dart';
import '../services/wallet.dart';
import 'board_stage.dart';
import 'booster_bar.dart';
import 'customer_order.dart';
import 'game_dialog.dart';
import 'hud.dart';
import 'l10n.dart';
import 'level_intro.dart';
import 'navigation.dart';
import 'result_overlay.dart';
import 'tip_overlay.dart';
import 'ui_art.dart';

String _levelAsset(int n) =>
    'assets/levels/level_${n.toString().padLeft(3, '0')}.json';

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

  /// Bumped each time the level's customer should play their signature.
  int _signaturePlays = 0;

  void _signature(SignatureCue cue, int levelId) {
    if (Customer.forLevel(levelId).signature?.cue != cue || !mounted) return;
    setState(() => _signaturePlays++);
  }

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
    final events = ref.read(eventProvider.notifier)..refresh();
    final game = SushiGame(
        level: level,
        wallet: ref.read(walletProvider.notifier),
        starters: widget.starters,
        eventKind: ref.read(eventProvider).active?.kind,
        onEventGain: events.addCollected,
        analytics: ref.read(analyticsProvider));
    _recordWins(game);
    _cueSignatures(game);
    return game;
  }

  /// Books each won run's stars, and pays the level's sushi once per visit
  /// to this screen (a replay after a win earns stars, not more sushi).
  void _recordWins(SushiGame game) {
    final progress = ref.read(progressProvider.notifier);
    final restaurant = ref.read(restaurantProvider.notifier);
    final n = widget.levelNumber;
    var booked = false, sushiPaid = false;
    game.hud.addListener(() {
      final s = game.hud.value;
      if (s.status == GameStatus.playing) booked = false;
      if (s.status != GameStatus.won || booked) return;
      booked = true;
      progress.markCleared(n);
      restaurant.recordStars(n, s.stars);
      if (!sushiPaid) {
        sushiPaid = true;
        restaurant
            .grantSushi(Restaurant.rewardFor(n, s.stars, game.level.pieces));
      }
    });
  }

  /// Plays the customer's signature animation on the cue it is tied to.
  void _cueSignatures(SushiGame game) {
    final id = game.level.id;
    var moves = game.hud.value.movesLeft;
    var goalsDone = game.hud.value.goals.where((g) => g.done).length;
    game.hud.addListener(() {
      final s = game.hud.value;
      if (s.status != GameStatus.playing) return;
      final done = s.goals.where((g) => g.done).length;
      if (done > goalsDone) _signature(SignatureCue.goal, id);
      goalsDone = done;
      if (s.movesLeft < moves) {
        if (s.movesLeft <= 3) {
          _signature(SignatureCue.lowMoves, id);
        } else if (s.movesLeft % 6 == 0) {
          _signature(SignatureCue.idle, id);
        }
      }
      moves = s.movesLeft;
    });
    game.praise.addListener(() {
      if (game.praise.value != null) _signature(SignatureCue.combo, id);
    });
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
        decoration: BoxDecoration(
          image: DecorationImage(
            image: UiArt.levelBackground(
                    Restaurant.shopOfLevel(widget.levelNumber)?.id)
                .provider(),
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
                      _topBar(game),
                      Expanded(child: _boardArea(game)),
                      BoosterBar(game: game),
                    ],
                  ),
                  if (!_introDone)
                    Positioned.fill(
                      child: LevelIntro(
                        level: game.level,
                        goals: game.hud.value.goals,
                        target: _orderKey,
                        onDone: () {
                          setState(() => _introDone = true);
                          _signature(SignatureCue.start, game.level.id);
                        },
                      ),
                    ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Back, the HUD and restart.
  Widget _topBar(SushiGame game) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          children: [
            RoundIconButton(
              sprite: const UiControlIcon(UiControl.back, color: Colors.white),
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
      );

  /// The order and the board, with the praise, tip and result overlays.
  Widget _boardArea(SushiGame game) {
    final next = widget.levelNumber + 1;
    return Stack(
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
                    goals: s.goals,
                    signaturePlays: _signaturePlays),
              ),
            ),
          ),
          board: GameWidget(game: game),
        ),
        PraiseBanner(game: game),
        // One tip at a time: the first mechanic of this level the player has
        // not been told about yet.
        Consumer(
          builder: (context, ref, _) {
            final tip = tipFor(game.level, ref.watch(tipsProvider));
            return tip == null
                ? const SizedBox.shrink()
                : TipOverlay(
                    id: tip.$1, icon: UiArt.obstacle(tip.$1), text: tip.$2);
          },
        ),
        ResultOverlay(
          game: game,
          onLevels: () => Navigator.of(context).pop(),
          onNext: next <= kLevelCount
              ? () => startLevel(context, ref, next, replace: true)
              : null,
        ),
      ],
    );
  }
}
