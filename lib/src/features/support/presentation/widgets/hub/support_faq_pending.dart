import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_secondary_button.dart';
import '../../../../../core/widgets/state_views.dart';
import 'support_faq_header.dart';
import 'support_section_card.dart';

/// The hub's "Frequently asked" card before its topics are there: the dots
/// while they load, or why they did not with a Retry ([onRetry] given). The
/// rest of the hub (hotline, chat) stays usable either way, so this is a
/// card-sized state, never a full-screen one.
class SupportFaqPending extends StatelessWidget {
  const SupportFaqPending({super.key, this.errorMessage, this.onRetry});

  /// Why the topics did not load (the default wording when null).
  final String? errorMessage;

  /// Loads the topics again; null while they are loading.
  final VoidCallback? onRetry;

  /// The row height of the loading dots (about one topic row).
  static const double _loadingHeight = AppSize.s56;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return SupportSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.s12,
              top: AppSpacing.s12,
              bottom: AppSpacing.s4,
            ),
            child: SupportFaqHeader(),
          ),
          if (retry == null)
            const SizedBox(
              height: _loadingHeight,
              child: Center(child: AppLoader.inline()),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      errorMessage ?? 'core.something_went_wrong'.tr(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  HeroSecondaryButton(
                    label: 'retry'.tr(),
                    compact: true,
                    height: AppSize.s44,
                    onPressed: retry,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
