import 'package:equatable/equatable.dart';

import '../../domain/entities/assistant_thought_place.dart';

/// What surrounds the assistant's buddy right now, reported by the layer
/// over the main shell: which screen is under it, what it may do there and
/// what else is on screen.
class AssistantBuddyScene extends Equatable {
  const AssistantBuddyScene({
    this.place = '',
    this.available = false,
    this.greetHere = false,
    this.launcherHere = false,
    this.inFront = true,
    this.keyboardOpen = false,
    this.screenReader = false,
    this.hasCartItems = false,
    this.thoughtPlace = AssistantThoughtPlace.elsewhere,
  });

  /// The screen under the buddy (a tab); a new place brings back a launcher
  /// that was scrolled away.
  final String place;

  /// The store runs the assistant (`/v1/init`).
  final bool available;

  /// This screen may show the greeting.
  final bool greetHere;

  /// This screen may show the floating launcher.
  final bool launcherHere;

  /// Nothing (dialog, sheet, page) sits over the shell.
  final bool inFront;

  final bool keyboardOpen;

  /// TalkBack / VoiceOver is on: nothing hides on its own.
  final bool screenReader;

  final bool hasCartItems;

  /// What the launcher's lines favour on this screen.
  final AssistantThoughtPlace thoughtPlace;

  /// Every condition for greeting except time.
  bool get canGreet => available && greetHere && inFront && !keyboardOpen;

  @override
  List<Object?> get props => [
    place,
    available,
    greetHere,
    launcherHere,
    inFront,
    keyboardOpen,
    screenReader,
    hasCartItems,
    thoughtPlace,
  ];
}
