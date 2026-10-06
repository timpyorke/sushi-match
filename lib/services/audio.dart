import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../core/settings.dart';

/// Sound effects, one file each under assets/audio/. The shipped files are
/// synthesised placeholders (tool/gen_sounds.dart); replace any of them with
/// real audio of the same name.
enum Sfx {
  swap('swap'),
  invalid('invalid'),
  match1('match_1'),
  match2('match_2'),
  match3('match_3'),
  match4('match_4'),
  match5('match_5'),
  match6('match_6'),
  special('special'),
  boom('boom'),
  crack('crack'),
  chime('chime'),
  unlock('unlock'),
  meow('meow'),
  shuffle('shuffle'),
  coin('coin'),
  win('win'),
  lose('lose');

  const Sfx(this.file);
  final String file;

  /// Match sound for a cascade depth (1-based): the pitch climbs one step
  /// per chained clear, so a combo is audible (GDD: Audio).
  static Sfx forCascade(int depth) => const [
        match1,
        match2,
        match3,
        match4,
        match5,
        match6
      ][(depth - 1).clamp(0, 5)];
}

/// Plays sounds and background music, honouring [Settings.sound] and
/// [Settings.music]. Silent until [init] runs, so unit and widget tests (which
/// have no audio plugin) need no setup.
abstract final class Audio {
  static const _bgm = 'bgm.wav';
  static const _sfxVolume = 0.7;
  static const _bgmVolume = 0.35;

  static bool _ready = false;
  static bool _musicWanted = false;

  static Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([
        for (final s in Sfx.values) '${s.file}.wav',
        _bgm,
      ]);
      // Pauses the music when the app goes to the background.
      FlameAudio.bgm.initialize();
      _ready = true;
    } catch (e) {
      debugPrint('Audio disabled: $e');
    }
    Settings.sound.addListener(_syncMusic);
    Settings.music.addListener(_syncMusic);
    _syncMusic();
  }

  static void play(Sfx sfx) {
    if (!_ready || !Settings.sound.value) return;
    _safe(() => FlameAudio.play('${sfx.file}.wav', volume: _sfxVolume));
  }

  /// Starts the looping BGM (if enabled in settings); [stopMusic] ends it.
  static void startMusic() {
    _musicWanted = true;
    _syncMusic();
  }

  static void stopMusic() {
    _musicWanted = false;
    _syncMusic();
  }

  static void _syncMusic() {
    if (!_ready) return;
    final bgm = FlameAudio.bgm;
    if (_musicWanted && Settings.music.value) {
      if (!bgm.isPlaying) _safe(() => bgm.play(_bgm, volume: _bgmVolume));
    } else if (bgm.isPlaying) {
      _safe(bgm.stop);
    }
  }

  static void _safe(Future<Object?> Function() call) {
    call().catchError((Object e) {
      debugPrint('Audio error: $e');
      return null;
    });
  }
}
