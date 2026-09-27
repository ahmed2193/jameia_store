import 'package:equatable/equatable.dart';

import '../../domain/entities/assistant_nudge.dart';
import '../../domain/entities/assistant_thought.dart';
import 'assistant_buddy_scene.dart';

class AssistantBuddyState extends Equatable {
  const AssistantBuddyState({
    this.scene = const AssistantBuddyScene(),
    this.launcherHidden = true,
    this.scrolledAway = false,
    this.nudge,
    this.cheers = 0,
    this.onboarded = true,
    this.touring = false,
    this.thought,
  });

  final AssistantBuddyScene scene;

  /// The customer hid the launcher for today — also `true` until the
  /// device log is read, so it never flashes in and out at launch.
  final bool launcherHidden;

  /// The customer is scrolling down the content: the launcher steps aside —
  /// once it has finished the line it is thinking out loud.
  final bool scrolledAway;

  /// The greeting on screen, `null` when none.
  final AssistantNudge? nudge;

  /// Bumped for every reason the mascot has to hop (a cart add, the
  /// greeting or the tour handing back to the launcher).
  final int cheers;

  /// The customer has met the assistant (seen its tour). `true` until the
  /// device log says otherwise, so an early tap simply opens the chat.
  final bool onboarded;

  /// The tour is on screen: the mascot is up there, not in its corner.
  final bool touring;

  /// The line the launcher is thinking out loud, `null` when none.
  final AssistantThought? thought;

  bool get launcherShown =>
      scene.available &&
      scene.launcherHere &&
      !scene.keyboardOpen &&
      !launcherHidden &&
      !touring &&
      nudge == null &&
      (!scrolledAway || scene.screenReader || thought != null);

  AssistantBuddyState copyWith({
    AssistantBuddyScene? scene,
    bool? launcherHidden,
    bool? scrolledAway,
    AssistantNudge? Function()? nudge,
    int? cheers,
    bool? onboarded,
    bool? touring,
    AssistantThought? Function()? thought,
  }) => AssistantBuddyState(
    scene: scene ?? this.scene,
    launcherHidden: launcherHidden ?? this.launcherHidden,
    scrolledAway: scrolledAway ?? this.scrolledAway,
    nudge: nudge != null ? nudge() : this.nudge,
    cheers: cheers ?? this.cheers,
    onboarded: onboarded ?? this.onboarded,
    touring: touring ?? this.touring,
    thought: thought != null ? thought() : this.thought,
  );

  @override
  List<Object?> get props => [
    scene,
    launcherHidden,
    scrolledAway,
    nudge,
    cheers,
    onboarded,
    touring,
    thought,
  ];
}
