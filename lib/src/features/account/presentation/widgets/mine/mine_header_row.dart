import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/responsive/content_clamp.dart';
import 'mine_avatar.dart';
import 'mine_pro_badge.dart';
import 'mine_scan_qr_button.dart';

/// The Mine header layout (bundle `h03722`): full-width background art, then a
/// row of avatar · title / subtitle · scan-QR · edit · chevron. Content-free:
/// the caller decides what the row says and where it goes.
class MineHeaderRow extends StatelessWidget {
  const MineHeaderRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onScan,
    this.showEdit = true,
    this.showProBadge = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onScan;

  /// Hide the edit pencil for guests (nothing to edit yet).
  final bool showEdit;

  /// The "PRO" pill after the title (active Jm3eia Pro member).
  final bool showProBadge;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            JameiaAssets.mineHeaderBg,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: topInset + AppSpacing.s12,
            start: AppSpacing.s20,
            end: AppSpacing.s20,
            bottom: AppSpacing.s20,
          ),
          child: ContentClamp(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Row(
                children: [
                  const MineAvatar(),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.headingMedium.copyWith(
                                  fontWeight: AppTextStyles.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            if (showProBadge) ...[
                              const SizedBox(width: AppSpacing.s6),
                              const MineProBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MineScanQrButton(onTap: onScan),
                  const SizedBox(width: AppSpacing.s6),
                  if (showEdit) ...[
                    const Icon(
                      JameiaIcons.edit,
                      size: AppSize.s24,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                  ],
                  const Icon(
                    JameiaIcons.arrowRight,
                    size: AppSize.s24,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
