import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/rider_quick_reply.dart';
import '../../cubit/rider_chat_cubit.dart';
import 'rider_chat_quick_reply_chip.dart';

/// The one-tap messages in a row that scrolls sideways; a tap sends the
/// words at once (none while a message is on its way).
class RiderChatQuickReplies extends StatelessWidget {
  const RiderChatQuickReplies({super.key});

  /// The row's height: each chip's hit box (48 dp); the pills stay their
  /// own size in the middle of it.
  static const double _height = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    final sending = context.select<RiderChatCubit, bool>(
      (cubit) => cubit.state.sending,
    );
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.gutter,
        ),
        itemCount: RiderQuickReply.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) => RiderChatQuickReplyChip(
          reply: RiderQuickReply.values[index],
          onPressed: sending
              ? null
              : (reply) {
                  Haptics.pick();
                  unawaited(
                    context.read<RiderChatCubit>().send(
                      reply.labelKey.tr(),
                      quick: reply,
                    ),
                  );
                },
        ),
      ),
    );
  }
}
