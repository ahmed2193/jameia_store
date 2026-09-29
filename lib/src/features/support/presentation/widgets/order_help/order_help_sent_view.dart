import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/pop_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_bottom_bar.dart';
import '../../../../../core/widgets/hero_submit_button.dart';

/// The ticket is open: the success mark pops in, "We're on it", where the
/// answer will come (the notifications: the API sends `support.replied`
/// there), and "Done" back to the order. The ticket's id is a database id,
/// nothing a customer would quote, so it is not shown.
class OrderHelpSentView extends StatelessWidget {
  const OrderHelpSentView({super.key, required this.onDone});

  final VoidCallback onDone;

  static const double _art = AppSize.s96;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s32,
                vertical: AppSpacing.s24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: RepaintBoundary(
                      child: PopScale.onMount(
                        child: SvgPicture.asset(
                          HeroAssets.stateSuccess,
                          width: _art,
                          height: _art,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      'support.help_sent_title'.tr(),
                      style: AppTextStyles.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'support.help_sent_body'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        HeroBottomBar(
          child: HeroSubmitButton(
            label: 'support.help_done'.tr(),
            onPressed: onDone,
          ),
        ),
      ],
    );
  }
}
