import 'package:flutter/material.dart';

import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/core_widgets.dart';

/// KeeTa home bottom floating overlay (`home_page_bottom_overlay_sub`): a pinned
/// re-engagement pill — product thumb + bold promo text + close — over the
/// `sl_overlay_bg_default` background.
class BottomOverlayBar extends StatelessWidget {
  const BottomOverlayBar({
    super.key,
    required this.text,
    this.image = '',
    this.onTap,
    this.onClose,
  });

  final String text;
  final String image;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.pageMargin),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Optional branded background image.
                Positioned.fill(
                  child: Image.asset(
                    KeetaAssets.overlayBgDefault,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
                  child: Row(
                    children: [
                      if (image.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSize.r8),
                          child: KeetaImage(
                              url: image, width: 40, height: 40, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppSize.font16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      const Icon(KeetaIcons.arrowRight,
                          size: 16, color: AppColors.primaryText),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            KeetaAssets.overlayClose,
                            width: 16,
                            height: 16,
                            errorBuilder: (_, _, _) => const Icon(
                                KeetaIcons.close,
                                size: 16,
                                color: AppColors.secondaryText),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
