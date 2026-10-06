import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/level.dart';
import 'game/sushi_game.dart';
import 'ui/hud.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SushiMatchApp());
}

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
    final level =
        LevelConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return SushiGame(level: level);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E6D0),
      body: SafeArea(
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
    );
  }
}
