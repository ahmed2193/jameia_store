/// The assistant's own motion numbers (docs/motion §9.6 §1, the same idea as
/// `SplashMotion`): everything the mascot, the buddy, the word reveal, the
/// tour and the chat time by that the app-wide `AppMotion` tokens do not
/// cover — so no raw literal lives in a widget.
abstract final class AssistantMotion {
  // The mascot's gestures.

  /// Half a blink (eyes shut, then open again over another half).
  static const Duration blinkHalf = Duration(milliseconds: 75);

  /// One happy hop (squash and stretch).
  static const Duration hop = Duration(milliseconds: 720);

  /// The sprout waving hello.
  static const Duration wave = Duration(milliseconds: 900);

  /// One wink.
  static const Duration wink = Duration(milliseconds: 420);

  /// How long the eyes stay on a touch before they come back.
  static const Duration lookHold = Duration(milliseconds: 1100);

  // The word reveal (local mode: known text).

  /// Fastest and slowest pace between two words.
  static const Duration wordStepMin = Duration(milliseconds: 30);
  static const Duration wordStepMax = Duration(milliseconds: 80);

  /// No line takes longer than this to reveal, whatever its length.
  static const Duration revealMax = Duration(milliseconds: 1200);

  // The chat's stream (network mode) and its wait.

  static const Duration streamFlush = Duration(milliseconds: 50);
  static const Duration streamMaxLag = Duration(milliseconds: 500);
  static const Duration slowAfter = Duration(seconds: 10);

  /// The chat header's mascot stays happy this long after a confirmed
  /// proposal, then eases back to idle.
  static const Duration cheerHold = Duration(seconds: 2);

  // The buddy's lines and greeting.

  /// A line said stays this long to be read, plus [thoughtReadPerLetter].
  static const Duration thoughtReadBase = Duration(milliseconds: 1800);
  static const Duration thoughtReadPerLetter = Duration(milliseconds: 35);

  /// The greeting waits this long once its message is out, then goes.
  static const Duration greetingShowFor = Duration(seconds: 8);

  // The buddy's wake window (§3.1).

  /// At most one wake blink this far apart.
  static const Duration wakeBlinkGap = Duration(seconds: 8);

  /// A wake blinks this long after it comes (a launcher that arrives has
  /// landed; a chat header opened has settled).
  static const Duration wakeBlinkDelay = Duration(milliseconds: 600);

  /// A wake blink is a double one this often.
  static const double doubleBlinkChance = 0.2;

  /// A touch after this long with none wakes the launcher.
  static const Duration wakeAfterIdle = Duration(seconds: 10);

  /// After typing, scrolling, a page on top or the app away, the buddy
  /// stays still this much longer before a new wake.
  static const Duration settle = Duration(seconds: 2);

  /// The eyes follow a touch at most once in this long.
  static const Duration lookGap = Duration(seconds: 2);

  /// At most one hop in this long, and [hopsPerVisit] a visit.
  static const Duration hopGap = Duration(seconds: 30);
  static const int hopsPerVisit = 3;

  // The voice composer.

  static const Duration voiceLevelTick = Duration(milliseconds: 70);
  static const double holdScale = 1.8;
}
