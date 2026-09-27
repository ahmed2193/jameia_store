import 'dart:ui' show Offset, lerpDouble;

import 'package:flutter/foundation.dart';

/// One frame of the assistant mascot: every value the painter needs, each
/// in `0..1` unless noted. [AssistantMascot] animates between poses; the
/// painter only draws the one it is given.
@immutable
class AssistantMascotPose {
  const AssistantMascotPose({
    this.blink = 0,
    this.happy = 0,
    this.talk = 0,
    this.look = Offset.zero,
    this.squash = 0,
    this.sway = 0,
    this.twinkle = 0,
    this.surprise = 0,
    this.wink = 0,
  });

  /// At rest: eyes open, a small smile, looking ahead.
  static const AssistantMascotPose rest = AssistantMascotPose();

  /// `1` = eyes shut.
  final double blink;

  /// `1` = laughing eyes (`^ ^`) and a wide smile.
  final double happy;

  /// `1` = mouth fully open (mid-word).
  final double talk;

  /// Where the eyes look, each axis in `-1..1` (`dx` > 0 = towards the
  /// right edge, `dy` > 0 = down).
  final Offset look;

  /// Squash & stretch of the body: > 0 squashed (landing), < 0 stretched
  /// (jumping), in `-1..1`.
  final double squash;

  /// Sprout lean, `-1..1` (> 0 = towards the right edge).
  final double sway;

  /// The sparkle's shine: `0` = resting size, `1` = at its brightest.
  final double twinkle;

  /// `1` = round, wide-open eyes (picked up, dragged).
  final double surprise;

  /// `1` = the eye towards the right edge shut (a wink).
  final double wink;

  static AssistantMascotPose lerp(
    AssistantMascotPose a,
    AssistantMascotPose b,
    double t,
  ) => AssistantMascotPose(
    blink: lerpDouble(a.blink, b.blink, t)!,
    happy: lerpDouble(a.happy, b.happy, t)!,
    talk: lerpDouble(a.talk, b.talk, t)!,
    look: Offset.lerp(a.look, b.look, t)!,
    squash: lerpDouble(a.squash, b.squash, t)!,
    sway: lerpDouble(a.sway, b.sway, t)!,
    twinkle: lerpDouble(a.twinkle, b.twinkle, t)!,
    surprise: lerpDouble(a.surprise, b.surprise, t)!,
    wink: lerpDouble(a.wink, b.wink, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is AssistantMascotPose &&
      other.blink == blink &&
      other.happy == happy &&
      other.talk == talk &&
      other.look == look &&
      other.squash == squash &&
      other.sway == sway &&
      other.twinkle == twinkle &&
      other.surprise == surprise &&
      other.wink == wink;

  @override
  int get hashCode => Object.hash(
    blink,
    happy,
    talk,
    look,
    squash,
    sway,
    twinkle,
    surprise,
    wink,
  );
}
