import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/level.dart';
import 'game/sushi_game.dart';
import 'ui/hud.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await _enterImmersive();

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
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final Future<SushiGame> _game = _load();

  Future<SushiGame> _load() async {
    final raw = await rootBundle.loadString('assets/levels/level_001.json');
    final level = LevelConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return SushiGame(level: level);
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
                HudBar(game: game),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameWidget(game: game),
                      ResultOverlay(game: game),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ));
  }
}
