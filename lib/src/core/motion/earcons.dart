import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';

/// The app's few sounds: short brand chimes (the loader's two voices, green
/// and cape amber, as a warm bell) for the moments a customer is waiting on
/// — never a loop, never for a routine tap.
enum Earcon {
  /// Two notes rising: the rider is almost at the door.
  riderNearby('sounds/rider_nearby.wav'),

  /// Three notes rising: the order is at the door.
  orderArrived('sounds/order_arrived.wav');

  const Earcon(this.asset);

  /// Path under `assets/` (audioplayers' asset prefix).
  final String asset;
}

/// **core/motion/earcons.dart** — the single SOUND policy, beside
/// [Haptics]: feature code plays sounds only through [Earcons.play]. A chime
/// plays at the phone's notification volume and respects its silent / vibrate
/// mode (iOS: the silent switch), never takes the audio focus from music for
/// longer than the chime, and is skipped while [enabled] is off. Sound is
/// never the only cue — pair it with a haptic and what the screen shows.
/// Best effort: a device without audio, or a test, just stays silent.
abstract final class Earcons {
  /// Global mute (tests, a future Settings switch). Defaults on.
  static bool enabled = true;

  static AudioPlayer? _player;

  /// Android: a notification-event sound (its volume; silent on silent or
  /// vibrate), music ducked for the chime only. iOS: an ambient sound, which
  /// the silent switch mutes and which mixes with what else plays.
  static final AudioContext _context = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.notificationEvent,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  static const String _logName = 'earcons';

  /// Plays [earcon] from its start (a chime already playing is cut short).
  static Future<void> play(Earcon earcon) async {
    if (!enabled) return;
    try {
      final player = _player ?? await _newPlayer();
      await player.stop();
      await player.play(AssetSource(earcon.asset), mode: PlayerMode.lowLatency);
    } catch (error) {
      log('could not play ${earcon.name}: $error', name: _logName);
    }
  }

  static Future<AudioPlayer> _newPlayer() async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setAudioContext(_context);
    return _player = player;
  }
}
