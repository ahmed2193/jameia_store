import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/jameia_address_entity.dart';

/// Real Jameia address section: location icon left, type badge (Home/Office/Other)
/// from real bundle assets, full address text, chevron right. Padding 16dp all.
class AddressBar extends StatelessWidget {
  const AddressBar({super.key, required this.address});
  final JameiaAddressEntity address;

  String _assetForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'office':
        return JameiaAssets.iconOffice;
      case 'other':
        return JameiaAssets.iconOther;
      default:
        return JameiaAssets.iconHome; // 'Home' default
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address-type icon from real Jameia assets (32×32)
            Image.asset(
              _assetForLabel(address.label),
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(
                JameiaIcons.location,
                size: 32,
                color: AppColors.finalPrice,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label chip (type badge)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.smallBackground,
                      borderRadius: BorderRadius.circular(AppRadius.r7),
                    ),
                    child: Text(
                      address.label,
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: AppTextStyles.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    address.fullText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${address.recipient} · ${address.phone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              JameiaIcons.arrowRight,
              color: AppColors.tertiaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
