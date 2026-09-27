import 'package:equatable/equatable.dart';

import '../../domain/entities/assistant_nudge.dart';
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
    this.coaching = false,
  });

  final AssistantBuddyScene scene;

  /// The customer hid the launcher for today — also `true` until the
  /// device log is read, so it never flashes in and out at launch.
  final bool launcherHidden;

  /// The customer is scrolling down the content: the launcher steps aside.
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

  /// Just after the tour: the launcher says where it lives.
  final bool coaching;

  bool get launcherShown =>
      scene.available &&
      scene.launcherHere &&
      !scene.keyboardOpen &&
      !launcherHidden &&
      !touring &&
      nudge == null &&
      (!scrolledAway || scene.screenReader);

  AssistantBuddyState copyWith({
    AssistantBuddyScene? scene,
    bool? launcherHidden,
    bool? scrolledAway,
    AssistantNudge? Function()? nudge,
    int? cheers,
    bool? onboarded,
    bool? touring,
    bool? coaching,
  }) => AssistantBuddyState(
    scene: scene ?? this.scene,
    launcherHidden: launcherHidden ?? this.launcherHidden,
    scrolledAway: scrolledAway ?? this.scrolledAway,
    nudge: nudge != null ? nudge() : this.nudge,
    cheers: cheers ?? this.cheers,
    onboarded: onboarded ?? this.onboarded,
    touring: touring ?? this.touring,
    coaching: coaching ?? this.coaching,
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
    coaching,
  ];
}
