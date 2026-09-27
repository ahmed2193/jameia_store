import 'package:equatable/equatable.dart';

import 'assistant_day_part.dart';
import 'assistant_starter.dart';

/// The line under the greeting, picked for the moment.
enum AssistantNudgeMessage {
  /// The first meeting: offers the assistant's tour.
  invite('assistant.buddy_message_invite'),
  cart('assistant.buddy_message_cart'),
  morning('assistant.buddy_message_morning'),
  evening('assistant.buddy_message_evening'),
  general('assistant.buddy_message_general');

  const AssistantNudgeMessage(this.key);

  /// i18n key of the line.
  final String key;
}

/// The assistant's greeting: "Good evening, Sara" for [dayPart], a line
/// that fits the moment ([message]) and a few questions to start with. The
/// very first greeting introduces the assistant instead and offers its tour
/// ([invitesTour]) before the starters.
class AssistantNudge extends Equatable {
  const AssistantNudge({
    required this.dayPart,
    required this.message,
    required this.starters,
  });

  /// The greeting for [at]: the tour on a [firstMeeting], else the cart
  /// first when it has something in it, then the meal of the time of day.
  factory AssistantNudge.compose({
    required DateTime at,
    required bool hasCartItems,
    bool firstMeeting = false,
  }) {
    final dayPart = AssistantDayPart.of(at);
    final message = firstMeeting
        ? AssistantNudgeMessage.invite
        : hasCartItems
        ? AssistantNudgeMessage.cart
        : switch (dayPart) {
            AssistantDayPart.morning => AssistantNudgeMessage.morning,
            AssistantDayPart.evening => AssistantNudgeMessage.evening,
            AssistantDayPart.afternoon => AssistantNudgeMessage.general,
          };
    // The tour takes the first place on an invitation.
    final room = firstMeeting ? starterCount - 1 : starterCount;
    return AssistantNudge(
      dayPart: dayPart,
      message: message,
      starters: AssistantStarter.pick(
        dayPart: dayPart,
        hasCartItems: hasCartItems,
      ).take(room).toList(growable: false),
    );
  }

  /// How many chips fit on the greeting (the tour counts as one).
  static const int starterCount = 3;

  final AssistantDayPart dayPart;
  final AssistantNudgeMessage message;
  final List<AssistantStarter> starters;

  /// The first meeting: the greeting offers the tour.
  bool get invitesTour => message == AssistantNudgeMessage.invite;

  @override
  List<Object?> get props => [dayPart, message, starters];
}
