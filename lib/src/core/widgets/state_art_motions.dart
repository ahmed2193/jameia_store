import 'package:flutter/widgets.dart';

import '../design/hero_assets.dart';
import '../motion/keyframe_track.dart';
import '../motion/motion.dart';
import 'state_art_part.dart';

/// How each moving state illustration tells its story: the parts drawn over
/// a `HeroAssets.state*` plate and their tracks over one lap
/// ([AppMotion.stateArtLap]). Every story waits the first tenth of the lap
/// (the plate's entrance), plays, and rests the last quarter, so two laps
/// read as two calm tries, never as a spinner. Plates not listed stay still.
///
/// Built from one master per plate (tool/issue_art/src): the master's
/// `part-*` groups are the files listed here, its other shapes the plate.
abstract final class StateArtMotions {
  /// The parts that move over [asset], or `null` for a still plate.
  static List<StateArtPart>? of(String asset) => _plates[asset];

  static const Map<String, List<StateArtPart>> _plates = {
    HeroAssets.stateError: _error,
    HeroAssets.stateOffline: _offline,
    HeroAssets.stateSignedOut: _signedOut,
    HeroAssets.stateNotFound: _notFound,
    HeroAssets.stateUnavailable: _unavailable,
    HeroAssets.stateUnreachable: _unreachable,
    HeroAssets.stateTimeout: _timeout,
    HeroAssets.stateServer: _server,
    HeroAssets.stateMaintenance: _maintenance,
    HeroAssets.stateRateLimited: _rateLimited,
    HeroAssets.stateForbidden: _forbidden,
    HeroAssets.stateBadData: _badData,
  };

  // A hiccup: the tipped bag rocks on its corner, the orange rolls a little
  // further and back, the "!" pops and shakes.
  static const List<StateArtPart> _error = [
    StateArtPart(
      HeroAssets.stateErrorBag,
      pivot: Offset(97, 99),
      turn: KeyframeTrack([
        Keyframe(0.1, 0),
        Keyframe(0.2, -6, AppMotion.signature),
        Keyframe(0.32, 3),
        Keyframe(0.42, -1.5),
        Keyframe(0.5, 0),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateErrorOrange,
      pivot: Offset(120, 92),
      turn: KeyframeTrack([
        Keyframe(0.12, 0),
        Keyframe(0.32, 40, AppMotion.signature),
        Keyframe(0.46, -12),
        Keyframe(0.58, 0),
      ]),
      dx: KeyframeTrack([
        Keyframe(0.12, 0),
        Keyframe(0.32, 3, AppMotion.signature),
        Keyframe(0.46, -1),
        Keyframe(0.58, 0),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateErrorBadge,
      pivot: Offset(116, 30),
      scale: _badgePop,
      turn: _badgeShake,
    ),
  ];

  // Searching for a signal: the middle bar lights, then the outer one, both
  // drop, the slash badge says no.
  static const List<StateArtPart> _offline = [
    StateArtPart(
      HeroAssets.stateOfflineSignalMid,
      opacity: KeyframeTrack([
        Keyframe(0.12, 0),
        Keyframe(0.18, 1),
        Keyframe(0.42, 1),
        Keyframe(0.48, 0, AppMotion.exit),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateOfflineSignalOut,
      opacity: KeyframeTrack([
        Keyframe(0.24, 0),
        Keyframe(0.3, 1),
        Keyframe(0.42, 1),
        Keyframe(0.48, 0, AppMotion.exit),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateOfflineBadge,
      pivot: Offset(116, 30),
      scale: _badgePop,
      turn: _badgeShake,
    ),
  ];

  // Locked: someone tries the padlock; a sparkle turns a quarter.
  static const List<StateArtPart> _signedOut = [
    StateArtPart(
      HeroAssets.stateSignedOutLock,
      pivot: Offset(101, 52),
      turn: KeyframeTrack([
        Keyframe(0.12, 0),
        Keyframe(0.18, -8, AppMotion.signature),
        Keyframe(0.24, 7),
        Keyframe(0.3, -5),
        Keyframe(0.36, 3),
        Keyframe(0.42, 0),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateSignedOutSparkle,
      pivot: Offset(46, 28),
      scale: _twinkle,
      turn: _quarterTurn,
    ),
  ];

  // Nothing inside: the flaps flutter, the air bubbles float out.
  static const List<StateArtPart> _notFound = [
    StateArtPart(
      HeroAssets.stateNotFoundFlapStart,
      pivot: Offset(53, 56),
      turn: KeyframeTrack([
        Keyframe(0.1, 0),
        Keyframe(0.18, -10, AppMotion.signature),
        Keyframe(0.26, 4),
        Keyframe(0.34, -8),
        Keyframe(0.42, 0),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateNotFoundFlapEnd,
      pivot: Offset(107, 56),
      turn: KeyframeTrack([
        Keyframe(0.12, 0),
        Keyframe(0.2, 10, AppMotion.signature),
        Keyframe(0.28, -4),
        Keyframe(0.36, 8),
        Keyframe(0.44, 0),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateNotFoundBubbles,
      pivot: Offset(80, 30),
      dy: _riseAndReturn,
      opacity: _fadeAway,
    ),
  ];

  // Closed for now: the sign swings on its nail, the moon rocks.
  static const List<StateArtPart> _unavailable = [
    StateArtPart(
      HeroAssets.stateUnavailableSign,
      pivot: Offset(80, 59),
      turn: _pendulum,
    ),
    StateArtPart(
      HeroAssets.stateUnavailableMoon,
      pivot: Offset(122, 24),
      turn: KeyframeTrack([
        Keyframe(0.3, 0),
        Keyframe(0.45, -14),
        Keyframe(0.65, 0),
      ]),
    ),
  ];

  // The store does not answer: the plug reaches for the socket, sparks,
  // and drops back out.
  static const List<StateArtPart> _unreachable = [
    StateArtPart(
      HeroAssets.stateUnreachableSpark,
      pivot: Offset(112, 42),
      opacity: KeyframeTrack([
        Keyframe(0.27, 0),
        Keyframe(0.29, 1, AppMotion.linear),
        Keyframe(0.31, 0.3, AppMotion.linear),
        Keyframe(0.33, 1, AppMotion.linear),
        Keyframe(0.38, 1),
        Keyframe(0.42, 0, AppMotion.exit),
      ]),
      // Drawn full size; it starts small while still hidden.
      scale: KeyframeTrack([
        Keyframe(0.26, 1),
        Keyframe(0.27, 0.6),
        Keyframe(0.31, 1.15, AppMotion.signature),
        Keyframe(0.38, 1),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateUnreachablePlug,
      dy: KeyframeTrack([
        Keyframe(0.1, 0),
        Keyframe(0.28, -5.5, AppMotion.signature),
        Keyframe(0.36, -5.5),
        Keyframe(0.5, 1.2, AppMotion.exit),
        Keyframe(0.6, 0, AppMotion.signature),
      ]),
    ),
  ];

  // Taking too long: the button starts the watch, the hand goes round.
  static const List<StateArtPart> _timeout = [
    StateArtPart(
      HeroAssets.stateTimeoutButton,
      dy: KeyframeTrack([
        Keyframe(0.1, 0),
        Keyframe(0.15, 2.5, AppMotion.signature),
        Keyframe(0.22, 0),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateTimeoutHand,
      pivot: Offset(80, 62),
      turn: KeyframeTrack([Keyframe(0.16, 0), Keyframe(0.8, 360)]),
    ),
  ];

  // Trouble on our side: the red light blinks, the smoke rises away and
  // comes back.
  static const List<StateArtPart> _server = [
    StateArtPart(
      HeroAssets.stateServerLed,
      opacity: KeyframeTrack([
        Keyframe(0.1, 1),
        Keyframe(0.16, 0.25, AppMotion.linear),
        Keyframe(0.24, 1, AppMotion.linear),
        Keyframe(0.3, 0.25, AppMotion.linear),
        Keyframe(0.38, 1, AppMotion.linear),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateServerSmoke,
      pivot: Offset(80, 30),
      dy: _riseAndReturn,
      scale: KeyframeTrack([
        Keyframe(0.2, 1),
        Keyframe(0.55, 1.15),
        Keyframe(0.551, 0.85),
        Keyframe(0.75, 1, AppMotion.signature),
      ]),
      opacity: _fadeAway,
    ),
  ];

  // A tune-up: the gear turns two teeth, the wrench ratchets twice.
  static const List<StateArtPart> _maintenance = [
    StateArtPart(
      HeroAssets.stateMaintenanceGear,
      pivot: Offset(116, 30),
      // Eight teeth: a quarter turn lands on the same picture.
      turn: KeyframeTrack([Keyframe(0.1, 0), Keyframe(0.7, 90)]),
    ),
    StateArtPart(
      HeroAssets.stateMaintenanceWrench,
      pivot: Offset(111, 64),
      turn: KeyframeTrack([
        Keyframe(0.12, 0),
        Keyframe(0.26, -22, AppMotion.signature),
        Keyframe(0.38, 0),
        Keyframe(0.5, -22, AppMotion.signature),
        Keyframe(0.62, 0),
      ]),
    ),
  ];

  // Wait a moment: the red light pulses, the bag shifts from side to side.
  static const List<StateArtPart> _rateLimited = [
    StateArtPart(
      HeroAssets.stateRateLimitedGlow,
      pivot: Offset(107, 30),
      scale: KeyframeTrack([
        Keyframe(0.1, 1),
        Keyframe(0.3, 1.35, AppMotion.signature),
        Keyframe(0.301, 0.9),
        Keyframe(0.4, 1),
        Keyframe(0.6, 1.35, AppMotion.signature),
        Keyframe(0.601, 0.9),
        Keyframe(0.7, 1),
      ]),
      opacity: KeyframeTrack([
        Keyframe(0.1, 1),
        Keyframe(0.3, 0, AppMotion.linear),
        Keyframe(0.33, 0),
        Keyframe(0.4, 1),
        Keyframe(0.6, 0, AppMotion.linear),
        Keyframe(0.63, 0),
        Keyframe(0.7, 1),
      ]),
    ),
    StateArtPart(
      HeroAssets.stateRateLimitedBag,
      pivot: Offset(58, 96),
      turn: KeyframeTrack([
        Keyframe(0.12, 0),
        Keyframe(0.24, -4, AppMotion.signature),
        Keyframe(0.36, 3),
        Keyframe(0.48, -2),
        Keyframe(0.58, 0),
      ]),
    ),
  ];

  // No entry: the sign swings on its nail.
  static const List<StateArtPart> _forbidden = [
    StateArtPart(
      HeroAssets.stateForbiddenSign,
      pivot: Offset(80, 30),
      turn: _pendulum,
    ),
  ];

  // Mixed up: the piece flies at the gap, does not fit, floats back.
  static const List<StateArtPart> _badData = [
    StateArtPart(
      HeroAssets.stateBadDataPiece,
      pivot: Offset(118, 42),
      dx: KeyframeTrack([
        Keyframe(0.1, 0),
        Keyframe(0.32, -14, AppMotion.signature),
        Keyframe(0.44, -14),
        Keyframe(0.66, 0),
      ]),
      dy: KeyframeTrack([
        Keyframe(0.1, 0),
        Keyframe(0.32, 12, AppMotion.signature),
        Keyframe(0.44, 12),
        Keyframe(0.66, 0),
      ]),
      turn: KeyframeTrack([
        Keyframe(0.1, 0),
        Keyframe(0.32, -18, AppMotion.signature),
        Keyframe(0.35, -10),
        Keyframe(0.38, -24),
        Keyframe(0.41, -14),
        Keyframe(0.44, -18),
        Keyframe(0.66, 0),
      ]),
    ),
  ];

  // ── Shared tracks ──────────────────────────────────────────────────────
  /// A badge pops a little bigger and settles.
  static const KeyframeTrack _badgePop = KeyframeTrack([
    Keyframe(0.46, 1),
    Keyframe(0.54, 1.15, AppMotion.signature),
    Keyframe(0.66, 1),
  ]);

  /// A badge shakes "no".
  static const KeyframeTrack _badgeShake = KeyframeTrack([
    Keyframe(0.48, 0),
    Keyframe(0.53, -12),
    Keyframe(0.58, 10),
    Keyframe(0.63, -5),
    Keyframe(0.68, 0),
  ]);

  /// A sign on a nail: a push, then a swing that dies down.
  static const KeyframeTrack _pendulum = KeyframeTrack([
    Keyframe(0.1, 0),
    Keyframe(0.22, 9, AppMotion.signature),
    Keyframe(0.36, -7),
    Keyframe(0.5, 4),
    Keyframe(0.62, -2),
    Keyframe(0.72, 0),
  ]);

  /// Rises away, jumps back below (while faded out) and floats into place.
  static const KeyframeTrack _riseAndReturn = KeyframeTrack([
    Keyframe(0.2, 0),
    Keyframe(0.55, -8),
    Keyframe(0.551, 5),
    Keyframe(0.75, 0, AppMotion.signature),
  ]);

  /// Fades out at the top of [_riseAndReturn] and back in as it settles.
  static const KeyframeTrack _fadeAway = KeyframeTrack([
    Keyframe(0.35, 1),
    Keyframe(0.55, 0, AppMotion.linear),
    Keyframe(0.57, 0),
    Keyframe(0.75, 1),
  ]);

  /// A sparkle grows and settles.
  static const KeyframeTrack _twinkle = KeyframeTrack([
    Keyframe(0.4, 1),
    Keyframe(0.5, 1.5, AppMotion.signature),
    Keyframe(0.62, 1),
  ]);

  /// Four points: a quarter turn lands on the same picture.
  static const KeyframeTrack _quarterTurn = KeyframeTrack([
    Keyframe(0.4, 0),
    Keyframe(0.62, 90),
  ]);
}
