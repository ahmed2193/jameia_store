import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/localization/text_direction_estimate.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../domain/entities/rider_chat_message.dart';

/// One message: the customer's on the end side, brand-tinted like the
/// assistant chat's, the rider's on the start side in grey (in the reader's
/// language), each with its [time]; the words run in their own direction
/// (English typed in the Arabic app keeps its punctuation at the end). A
/// screen reader hears who said it, then the words and the time as one
/// node, and a rider reply that just arrived is read out. A message that
/// just arrived rises in ([pop]), decided when it mounts, so the widget
/// shape never changes.
class RiderChatBubble extends StatelessWidget {
  const RiderChatBubble({
    super.key,
    required this.message,
    required this.time,
    this.pop = false,
  });

  final RiderChatMessage message;

  /// When it was sent, already formatted for the reader ("5:27 PM").
  final String time;

  /// Rises in (a message that just arrived); an old one is simply there.
  final bool pop;

  static const double _maxShare = 0.78;
  static const Radius _round = Radius.circular(AppRadius.r3);
  static const Radius _tail = Radius.circular(AppRadius.r6);

  @override
  Widget build(BuildContext context) {
    final mine = !message.fromRider;
    final text = message.textFor(context.locale.languageCode);
    final rtl = TextDirectionEstimate.isRtl(text);
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * _maxShare,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: mine ? AppColors.brandLightBg : AppColors.smallBackground,
          borderRadius: BorderRadiusDirectional.only(
            topStart: _round,
            topEnd: _round,
            bottomStart: mine ? _round : _tail,
            bottomEnd: mine ? _tail : _round,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s12,
            AppSpacing.s8,
            AppSpacing.s12,
            AppSpacing.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textDirection: switch (rtl) {
                  null => null,
                  true => TextDirection.rtl,
                  false => TextDirection.ltr,
                },
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                time,
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.s4,
      ),
      child: Align(
        alignment: mine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: EntranceCascadeItem.single(
          play: pop,
          child: MergeSemantics(
            child: Semantics(
              container: true,
              // Said as it arrives: the chat is open, so nothing else tells
              // a screen-reader user the rider wrote back.
              liveRegion: pop && message.fromRider,
              label: (mine ? 'orders.chat_you_said' : 'orders.chat_rider_said')
                  .tr(),
              child: bubble,
            ),
          ),
        ),
      ),
    );
  }
}
