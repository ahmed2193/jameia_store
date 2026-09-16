import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/rider_entity.dart';
import '../cubit/im_chat_cubit.dart';

/// KeeTa rider chat / IM screen — `im_user_rider_chat` (Mach bundle 64).
///
/// Faithful 1:1 clone of KeeTa's in-order messaging surface:
///   • chat app bar — rider avatar + name + "Your rider" subtitle + a call action;
///   • message bubble list — a scripted conversation (left = rider, right = user)
///     with timestamps and grey/brand-yellow bubbles;
///   • quick-reply chips — KeeTa's canned-message row above the composer;
///   • input bar — attach (camera) + a multiline text field + a send button.
///
/// Local-state only: the conversation lives in a [State] list (per the prompt's
/// StatefulWidget contract). Rider identity is read from the dummy repository's
/// most-recent active order (falls back to a generic "Rider" when none is live).
/// No backend / IM socket — sent messages append locally and the rider "echoes"
/// a scripted acknowledgement so the thread feels live offline.
class ImChatScreen extends StatelessWidget {
  const ImChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ImChatCubit>(),
      child: BlocBuilder<ImChatCubit, ImChatState>(
        // Rebuilds only when the resolved rider identity changes. The rider is
        // sourced in the data layer (via the support repository), so this screen
        // no longer reads `core/data/keeta_repository.dart`.
        buildWhen: (p, c) => p.rider != c.rider,
        builder: (context, state) {
          final rider = state.rider;
          return Scaffold(
            backgroundColor: AppColors.mediumBackground,
            appBar: _ChatAppBar(rider: rider),
            body: SafeArea(
              top: false,
              child: ContentClamp(child: _ChatBody(rider: rider)),
            ),
          );
        },
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.rider});
  final RiderEntity rider;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          KeetaIcons.back,
          size: 20,
          color: AppColors.primaryText,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.smallBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              KeetaIcons.delivery,
              size: 20,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                Text.rich(
                  TextSpan(text: 'support.your_rider'.tr()),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: AppSize.font12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            KeetaIcons.phone,
            size: 20,
            color: AppColors.primaryText,
          ),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'support.calling'.tr(namedArgs: {'name': rider.name}),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: ThinDivider(),
      ),
    );
  }
}

// ── Message model (screen-local) ──────────────────────────────────────────────

/// A single chat bubble. [mine] = sent by the user (right-aligned, brand yellow);
/// otherwise it's the rider's message (left-aligned, white).
class _Message {
  const _Message({required this.text, required this.mine, required this.time});
  final String text;
  final bool mine;
  final String time;
}

// ── Chat body (stateful: owns the message list + composer) ────────────────────

class _ChatBody extends StatefulWidget {
  const _ChatBody({required this.rider});
  final RiderEntity rider;

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// KeeTa canned quick replies shown above the composer.
  static List<String> get _quickReplies => <String>[
    'support.quick_reply_at_door'.tr(),
    'support.quick_reply_call_arrive'.tr(),
    'support.quick_reply_leave_door'.tr(),
    'support.quick_reply_how_long'.tr(),
  ];

  late final List<_Message> _messages = <_Message>[
    _Message(text: 'support.msg_picked_up'.tr(), mine: false, time: '12:31'),
    _Message(text: 'support.msg_thanks'.tr(), mine: true, time: '12:31'),
    _Message(text: 'support.msg_how_long'.tr(), mine: true, time: '12:32'),
    _Message(text: 'support.msg_about_ten'.tr(), mine: false, time: '12:33'),
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
    setState(() {
      _messages.add(
        _Message(text: text, mine: true, time: 'support.time_now'.tr()),
      );
      // Scripted rider acknowledgement so the thread feels live offline.
      _messages.add(
        _Message(
          text: 'support.msg_got_it'.tr(),
          mine: false,
          time: 'support.time_now'.tr(),
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s12,
            ),
            itemCount: _messages.length,
            // Each bubble fades/slides in once. Keying by the message identity
            // keeps existing bubbles settled when a new one is appended (the
            // list only grows at the end), so live sends don't replay the whole
            // thread or fight the scroll. The stagger delay is index-capped.
            itemBuilder: (_, i) => RepaintBoundary(
              child: StaggerEntrance(
                key: ObjectKey(_messages[i]),
                index: i,
                child: _Bubble(message: _messages[i]),
              ),
            ),
          ),
        ),
        _QuickReplyRow(replies: _quickReplies, onTap: _send),
        _Composer(controller: _input, onSend: _send),
      ],
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final maxW = MediaQuery.sizeOf(context).width * 0.72;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: mine ? AppColors.chatBubbleMine : AppColors.white,
        borderRadius: BorderRadiusDirectional.only(
          topStart: const Radius.circular(AppSize.r8),
          topEnd: const Radius.circular(AppSize.r8),
          bottomStart: Radius.circular(mine ? 8 : 2),
          bottomEnd: Radius.circular(mine ? 2 : 8),
        ),
      ),
      child: Text(
        message.text,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.primaryText,
          height: 1.35,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: mine
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: bubble,
          ),
          const SizedBox(height: AppSpacing.s2),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s4,
            ),
            child: Text(
              message.time,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.tertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick-reply chips ─────────────────────────────────────────────────────────

class _QuickReplyRow extends StatelessWidget {
  const _QuickReplyRow({required this.replies, required this.onTap});
  final List<String> replies;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (_, i) => _QuickReplyChip(label: replies[i], onTap: onTap),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});
  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      // Press feel on the canned-reply chip; the InkWell keeps the tap + ripple.
      child: PressScale(
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => onTap(label),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              child: Text(
                label,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Composer / input bar ──────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.s12,
        end: AppSpacing.s12,
        top: AppSpacing.s8,
        bottom: AppSpacing.s8 + bottomPad,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _IconCircle(
            icon: KeetaIcons.camera,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('support.attach_photo'.tr())),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.mediumBackground,
                borderRadius: BorderRadius.circular(AppRadius.r2),
              ),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'support.message_hint'.tr(),
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          _SendButton(controller: controller, onSend: onSend),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.mediumBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.secondaryText),
      ),
    );
  }
}

/// Send button — lit brand-yellow once there's text, otherwise disabled grey.
/// Rebuilds narrowly off the field's [ValueListenable] (never the chat list).
class _SendButton extends StatelessWidget {
  const _SendButton({required this.controller, required this.onSend});
  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final active = value.text.trim().isNotEmpty;
        return InkResponse(
          onTap: active ? () => onSend(controller.text) : null,
          radius: 24,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.divider,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              KeetaIcons.arrowUp,
              size: 20,
              color: active ? AppColors.black : AppColors.tertiaryText,
            ),
          ),
        );
      },
    );
  }
}
