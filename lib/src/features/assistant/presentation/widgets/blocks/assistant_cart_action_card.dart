import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/summary_row.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';
import 'assistant_cart_action_footer.dart';
import 'assistant_cart_action_line.dart';

/// `cart_action`: a cart change the assistant PROPOSES. The lines and the
/// estimate, then the footer that confirms it (nothing is in the cart until
/// then). A spent proposal (cancelled / expired) fades back.
class AssistantCartActionCard extends StatelessWidget {
  const AssistantCartActionCard({
    super.key,
    required this.block,
    this.live = false,
  });

  final AssistantCartActionBlock block;

  /// The reply is still streaming: the proposal cannot be confirmed yet.
  final bool live;

  static const double _spentOpacity = 0.6;

  @override
  Widget build(BuildContext context) {
    final estimate = block.estimatedTotalKd;
    final spent =
        block.status == AssistantActionStatus.cancelled ||
        block.status == AssistantActionStatus.expired;
    return AnimatedOpacity(
      opacity: spent ? _spentOpacity : 1,
      duration: MotionGuard.duration(context, AppMotion.medium),
      curve: AppMotion.signature,
      child: AssistantCardFrame(
        title: 'assistant.action_title'.tr(),
        icon: Icons.add_shopping_cart_rounded,
        borderColor: block.status == AssistantActionStatus.confirmed
            ? AppColors.success
            : AppColors.divider,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in block.items) AssistantCartActionLine(item: item),
            if (estimate != null)
              SummaryRow(
                label: 'assistant.estimated_total'.tr(),
                value: Formatters.price(estimate),
                emphasized: true,
              ),
            const SizedBox(height: AppSpacing.s8),
            AssistantCartActionFooter(block: block, live: live),
          ],
        ),
      ),
    );
  }
}
