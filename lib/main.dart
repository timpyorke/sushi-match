import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/level_tuning.dart';
import 'core/settings.dart';
import 'game/piece_painter.dart';
import 'gen/fonts.gen.dart';
import 'services/analytics.dart';
import 'services/audio.dart';
import 'services/event_config.dart';
import 'services/firebase_service.dart';
import 'services/store.dart';
import 'ui/home_screen.dart';
import 'ui/navigation.dart';
import 'ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await _enterImmersive();
  await PiecePainter.loadSprites();
  final bundledEvents = AssetEventSource();
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
        fontFamily: FontFamily.mali,
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

class _Home extends ConsumerWidget {
  const _Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => HomeScreen(
        levelCount: kLevelCount,
        onPlay: (n) => startLevel(context, ref, n),
        onLevels: () => openLevels(context),
        onRestaurant: () => openRestaurant(context),
        onShop: () => openShop(context),
        onSettings: () => openSettings(context),
      );
}
