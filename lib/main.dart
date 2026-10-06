import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/game_engine.dart';
import 'core/level.dart';
import 'core/progress.dart';
import 'core/settings.dart';
import 'game/piece_painter.dart';
import 'game/sushi_game.dart';
import 'services/wallet.dart';
import 'ui/hud.dart';
import 'ui/level_select.dart';
import 'ui/lives_ui.dart';
import 'ui/settings_screen.dart';
import 'ui/ui_art.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await _enterImmersive();
  await PiecePainter.loadSprites();
  await Settings.load();
  await Wallet.load();

  // Bars come back after an edge swipe, the keyboard or a system dialog.
  // Hide them again after a short delay.
  SystemChrome.setSystemUIChangeCallback((visible) async {
    if (visible) {
      await Future.delayed(const Duration(seconds: 2));
      await _enterImmersive();
    }
  });
  runApp(const SushiMatchApp());
}

Future<void> _enterImmersive() =>
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

class SushiMatchApp extends StatelessWidget {
  const SushiMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sushi Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB71C2C),
        useMaterial3: true,
      ),
      home: const LevelSelectScreen(),
    );
  }
}

const int kLevelCount = 21;

String _levelAsset(int n) =>
    'assets/levels/level_${n.toString().padLeft(3, '0')}.json';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int _cleared = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final c = await Progress.cleared();
    if (mounted) setState(() => _cleared = c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LevelSelectView(
            levelCount: kLevelCount,
            cleared: _cleared,
            onSettings: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _refresh();
            },
            onSelect: (n) async {
              if (!await ensureLife(context) || !context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GameScreen(levelNumber: n)),
              );
              _refresh();
            },
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.levelNumber = 1});
  final int levelNumber;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final Future<SushiGame> _game = _load();

  Future<SushiGame> _load() async {
    final raw = await rootBundle.loadString(_levelAsset(widget.levelNumber));
    final level = LevelConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final game = SushiGame(level: level);
    game.hud.addListener(() {
      if (game.hud.value.status == GameStatus.won) {
        Progress.markCleared(widget.levelNumber);
      }
    });
    return game;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bg.png'),
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
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: RoundIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                HudBar(game: game),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameWidget(game: game),
                      PraiseBanner(game: game),
                      ResultOverlay(
                        game: game,
                        onLevels: () => Navigator.of(context).pop(),
                        onNext: widget.levelNumber < kLevelCount
                            ? () async {
                                if (!await ensureLife(context) ||
                                    !context.mounted) {
                                  return;
                                }
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => GameScreen(
                                        levelNumber: widget.levelNumber + 1),
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
            );
          },
        ),
      ),
    ));
  }
}
