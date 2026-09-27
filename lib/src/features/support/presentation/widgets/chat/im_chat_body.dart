import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../domain/entities/support_chat_message.dart';
import 'im_chat_bubble.dart';
import 'im_chat_composer.dart';
import 'im_chat_quick_reply_row.dart';

/// The thread, the quick replies and the composer. Offline: the thread is a
/// scripted conversation in this state; a sent message appends and the rider
/// "echoes" an acknowledgement so the chat feels live.
class ImChatBody extends StatefulWidget {
  const ImChatBody({super.key});

  @override
  State<ImChatBody> createState() => _ImChatBodyState();
}

class _ImChatBodyState extends State<ImChatBody> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// Hero canned quick replies shown above the composer.
  static List<String> get _quickReplies => <String>[
    'support.quick_reply_at_door'.tr(),
    'support.quick_reply_call_arrive'.tr(),
    'support.quick_reply_leave_door'.tr(),
    'support.quick_reply_how_long'.tr(),
  ];

  late final List<SupportChatMessage> _messages = <SupportChatMessage>[
    SupportChatMessage(
      text: 'support.msg_picked_up'.tr(),
      mine: false,
      time: '12:31',
    ),
    SupportChatMessage(
      text: 'support.msg_thanks'.tr(),
      mine: true,
      time: '12:31',
    ),
    SupportChatMessage(
      text: 'support.msg_how_long'.tr(),
      mine: true,
      time: '12:32',
    ),
    SupportChatMessage(
      text: 'support.msg_about_ten'.tr(),
      mine: false,
      time: '12:33',
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    final now = 'support.time_now'.tr();
    setState(() {
      _messages
        ..add(SupportChatMessage(text: text, mine: true, time: now))
        // Scripted rider acknowledgement so the thread feels live offline.
        ..add(
          SupportChatMessage(
            text: 'support.msg_got_it'.tr(),
            mine: false,
            time: now,
          ),
        );
      _input.clear();
    });
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: MotionGuard.duration(context, AppMotion.medium),
        curve: AppMotion.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpacing.s12),
            itemCount: _messages.length,
            // Each bubble fades / slides in once: keyed by the message, the
            // settled bubbles stay put when a new one is appended.
            itemBuilder: (_, i) => RepaintBoundary(
              child: StaggerEntrance(
                key: ObjectKey(_messages[i]),
                index: i,
                child: ImChatBubble(message: _messages[i]),
              ),
            ),
          ),
        ),
        ImChatQuickReplyRow(replies: _quickReplies, onTap: _send),
        ImChatComposer(controller: _input, onSend: _send),
      ],
    );
  }
}
