import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/utils/formatters.dart';
import '../../cubit/rider_chat_cubit.dart';
import '../../cubit/rider_chat_state.dart';
import 'rider_chat_bubble.dart';

/// The conversation, newest at the bottom (a reversed list, so a new
/// message lands in view without scrolling); rebuilds only when the
/// messages change — compared one by one, so the rider starting or
/// stopping to type (a new list of the same messages) leaves the bubbles
/// alone. Each bubble keeps its element as messages arrive (found by id),
/// and only a message that came while the sheet is open rises in — once,
/// not again on scrolling back to it. Times are in the app's clock format
/// (Western digits, as everywhere else).
class RiderChatList extends StatefulWidget {
  const RiderChatList({super.key});

  @override
  State<RiderChatList> createState() => _RiderChatListState();
}

class _RiderChatListState extends State<RiderChatList> {
  /// Every message shown so far: the conversation as the sheet opened,
  /// then each arrival once it rose in.
  late final Set<String> _seen = {
    for (final message in context.read<RiderChatCubit>().state.chat.messages)
      message.id,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiderChatCubit, RiderChatState>(
      buildWhen: (before, now) =>
          !listEquals(before.chat.messages, now.chat.messages),
      builder: (context, state) {
        final messages = state.chat.messages;
        final languageCode = context.locale.languageCode;
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpacing.s8,
          ),
          itemCount: messages.length,
          findChildIndexCallback: (key) {
            if (key is! ValueKey<String>) return null;
            final at = messages.indexWhere(
              (message) => message.id == key.value,
            );
            return at < 0 ? null : messages.length - 1 - at;
          },
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index];
            return RiderChatBubble(
              key: ValueKey<String>(message.id),
              message: message,
              time: Formatters.clock(languageCode, message.sentAt),
              pop: _seen.add(message.id),
            );
          },
        );
      },
    );
  }
}
