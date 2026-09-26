import 'package:flutter/material.dart';

import '../../../domain/entities/assistant_message_entity.dart';
import '../../../domain/entities/assistant_thread.dart';
import 'assistant_divider_row.dart';
import 'assistant_reply_row.dart';
import 'assistant_system_notice.dart';
import 'assistant_user_bubble.dart';

/// One row of the chat list, by kind. A `null` [entry] is the reply being
/// streamed now ([rowKey] = its key).
class AssistantThreadRow extends StatelessWidget {
  const AssistantThreadRow({
    super.key,
    required this.rowKey,
    this.entry,
    this.isLast = false,
    this.animate = false,
    this.canSend = false,
  });

  final String rowKey;
  final AssistantThreadEntry? entry;
  final bool isLast;

  /// First appearance in this session's live flow.
  final bool animate;
  final bool canSend;

  @override
  Widget build(BuildContext context) {
    final row = entry;
    return switch (row) {
      AssistantMessageEntry(:final message) when message.isUser =>
        AssistantUserBubble(
          message: message,
          animate: animate,
          canRetry: isLast && canSend,
        ),
      AssistantMessageEntry(:final message) when message.isSystem =>
        AssistantSystemNotice(message: message),
      AssistantMessageEntry(:final message)
          when message.role == AssistantRole.other =>
        const SizedBox.shrink(),
      AssistantDividerEntry() => const AssistantDividerRow(),
      _ => AssistantReplyRow(rowKey: rowKey, entry: row, isLast: isLast),
    };
  }
}
