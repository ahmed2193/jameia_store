import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_popup_frame.dart';

/// A backend marketing popup (`init.content.popups`): artwork, title, body and
/// a call-to-action. [onCta] is only offered when the popup leads somewhere.
class HomeMarketingPopupView extends StatelessWidget {
  const HomeMarketingPopupView({
    super.key,
    required this.popup,
    required this.onClose,
    required this.onCta,
  });

  final HomeMarketingPopup popup;
  final VoidCallback onClose;
  final VoidCallback onCta;

  static const double _imageHeight = AppSize.s180;

  @override
  Widget build(BuildContext context) {
    return HomePopupFrame(
      onClose: onClose,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r3),
        child: ColoredBox(
          color: AppColors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (popup.hasImage)
                SizedBox(
                  height: _imageHeight,
                  child: JameiaImage(url: popup.imageUrl),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (popup.title.isNotEmpty)
                      Text(
                        popup.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingMedium.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    if (popup.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        popup.body,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    if (popup.link.isNavigable) ...[
                      const SizedBox(height: AppSpacing.s16),
                      AppButton(
                        label: popup.ctaLabel.isNotEmpty
                            ? popup.ctaLabel
                            : 'home.shop_now'.tr(),
                        onPressed: onCta,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
