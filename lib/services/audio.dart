import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Sound effects, one file each under assets/audio/. The shipped files are
/// synthesised placeholders (tool/gen_sounds.dart); replace any of them with
/// real audio of the same name.
enum Sfx {
  tap('tap'),
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
  /// One looping track per restaurant (assets/audio/bgm_<id>.wav).
  static const tracks = ['tsukiji', 'osaka', 'kyoto', 'hokkaido'];

  /// Restaurants without a track of their own borrow one until real music is
  /// dropped in (add the file, list it in [tracks], remove the alias).
  static const _alias = {
    'fukuoka': 'osaka',
    'okinawa': 'tsukiji',
    'omakase': 'kyoto',
    'nagoya': 'osaka',
    'hiroshima': 'tsukiji',
    'kanazawa': 'kyoto',
    'sendai': 'hokkaido',
    'kobe': 'osaka',
    'nara': 'kyoto',
    'ginza': 'tsukiji',
  };

  /// The track a restaurant plays.
  static String trackFor(String shopId) => _alias[shopId] ?? shopId;

  static String _file(String track) => 'bgm_$track.wav';

  static String _track = 'tsukiji';
  static const _sfxVolume = 0.7;
  static const _bgmVolume = 0.5;

  static bool _ready = false;
  static bool _musicWanted = false;

  /// One pool of pre-built players per effect. `FlameAudio.play` builds a
  /// fresh platform player per call, which stalls frames on Android when a
  /// cascade fires several sounds in a row.
  static final _pools = <Sfx, AudioPool>{};

  /// Sounds that overlap in a cascade get a bigger pool.
  static const _busy = {
    Sfx.match1,
    Sfx.match2,
    Sfx.match3,
    Sfx.match4,
    Sfx.match5,
    Sfx.match6,
    Sfx.crack,
    Sfx.special,
    Sfx.boom,
  };

  /// The same effect fired again within this window is dropped: stacked
  /// copies only sound louder and cost a player each.
  static const _minGapMs = 40;
  static final _clock = Stopwatch()..start();
  static final _lastPlayed = <Sfx, int>{};

  static Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([
        for (final s in Sfx.values) '${s.file}.wav',
        for (final t in tracks) _file(t),
      ]);
      for (final s in Sfx.values) {
        _pools[s] = await FlameAudio.createPool('${s.file}.wav',
            maxPlayers: _busy.contains(s) ? 3 : 2);
      }
      // Pauses the music when the app goes to the background.
      FlameAudio.bgm.initialize();
      _ready = true;
    } catch (e) {
      debugPrint('Audio disabled: $e');
    }
    _syncMusic();
  }

  static bool _soundOn = true;
  static bool _musicOn = true;

  /// Called by the settings notifier whenever the sound/music toggles change.
  static void configure({required bool sound, required bool music}) {
    _soundOn = sound;
    _musicOn = music;
    _syncMusic();
  }

  static void play(Sfx sfx) {
    if (!_ready || !_soundOn) return;
    final now = _clock.elapsedMilliseconds;
    final last = _lastPlayed[sfx];
    if (last != null && now - last < _minGapMs) return;
    _lastPlayed[sfx] = now;
    final pool = _pools[sfx];
    if (pool == null) return;
    _safe(() => pool.start(volume: _sfxVolume));
  }

  /// Starts the looping BGM (if enabled in settings); [stopMusic] ends it.
  /// Pass a restaurant id to switch to its track; the same track keeps playing.
  static void startMusic([String? shopId]) {
    _musicWanted = true;
    final track = shopId == null ? null : trackFor(shopId);
    if (track != null && tracks.contains(track) && track != _track) {
      _track = track;
      if (_ready && FlameAudio.bgm.isPlaying) {
        // Stop is async; start the new track only once it has finished.
        _safe(() async {
          await FlameAudio.bgm.stop();
          _syncMusic();
          return null;
        });
        return;
      }
    }
    _syncMusic();
  }

  static void stopMusic() {
    _musicWanted = false;
    _syncMusic();
  }

  static void _syncMusic() {
    if (!_ready) return;
    final bgm = FlameAudio.bgm;
    if (_musicWanted && _musicOn) {
      if (!bgm.isPlaying) {
        _safe(() => bgm.play(_file(_track), volume: _bgmVolume));
      }
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
