import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/motion/motion.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../chat/assistant_avatar.dart';
import '../assistant_onboarding_timeline.dart';
import 'assistant_onboarding_confirm_button.dart';
import 'assistant_onboarding_item.dart';
import 'assistant_onboarding_proposal_line.dart';

/// The cart demo's proposal, like the real one in the chat: "Add these to
/// your cart?", the items, and a Confirm that adds nothing until it is
/// tapped. Rises in over the demo's [progress], its lines one by one.
class AssistantOnboardingProposalCard extends StatelessWidget {
  const AssistantOnboardingProposalCard({
    super.key,
    required this.progress,
    required this.confirmed,
    required this.pressed,
    required this.onConfirm,
  });

  final double progress;
  final bool confirmed;
  final bool pressed;
  final VoidCallback onConfirm;

  /// The card's size in the stage's design space; the scene aims the
  /// ghost finger at its Confirm from these.
  static const double width = AppSize.s240;
  static const double height = AppSize.s180;
  static const double padding = AppSpacing.s12;
  static const double buttonHeight = AppSize.s36;

  static const double _inFrom = 0.05;
  static const double _inTo = 0.55;
  static const double _rise = AppSize.s24;
  static const double _linesFrom = 0.3;
  static const double _lineStep = 0.12;
  static const double _lineLength = 0.3;
  static const BoxDecoration _card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.r3)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.brandLightBg)),
    boxShadow: AppShadows.medium,
  );

  @override
  Widget build(BuildContext context) {
    final appear = progress.span(
      _inFrom,
      _inTo,
      AppMotion.emphasizedDecelerate,
    );
    return Opacity(
      opacity: appear,
      child: Transform.translate(
        offset: Offset(0, (1 - appear) * _rise),
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: _card,
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AssistantAvatar(size: AppSize.s22),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          'assistant.onboarding_demo_proposal'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subheadingMedium.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (final (index, item)
                      in AssistantOnboardingItem.values.indexed)
                    AssistantOnboardingProposalLine(
                      item: item,
                      appear: progress.span(
                        _linesFrom + _lineStep * index,
                        _linesFrom + _lineStep * index + _lineLength,
                        AppMotion.emphasizedDecelerate,
                      ),
                    ),
                  AssistantOnboardingConfirmButton(
                    confirmed: confirmed,
                    pressed: pressed,
                    onTap: onConfirm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
