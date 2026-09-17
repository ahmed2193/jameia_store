import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../core/widgets/jameia_map.dart';
import 'candidate_row.dart';
import 'not_serviceable_banner.dart';
import 'sheet_grabber.dart';

/// SELECT sheet — helper line + not-serviceable banner + candidate radio list +
/// Confirm CTA.
class SelectSheet extends StatelessWidget {
  const SelectSheet({
    super.key,
    required this.candidates,
    required this.selected,
    required this.serviceable,
    required this.loading,
    required this.onSelect,
    required this.onConfirm,
  });

  final List<({String title, String subtitle, LatLng pos})> candidates;
  final int selected;
  final bool serviceable;
  // True while the REAL nearby list is being fetched — dim the (stale) rows so
  // the sheet never looks frozen.
  final bool loading;
  final ValueChanged<int> onSelect;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        bottomPad + AppSpacing.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetGrabber(),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'addr.deliver_here_hint'.tr(),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (!serviceable) ...[
            const NotServiceableBanner(),
            const SizedBox(height: AppSpacing.s12),
          ],
          // Dim the (stale) candidate rows while the REAL nearby list is in
          // flight so the sheet never looks frozen.
          AnimatedOpacity(
            duration: MotionGuard.duration(context, AppMotion.fast),
            opacity: loading ? 0.45 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < candidates.length; i++)
                  CandidateRow(
                    title: candidates[i].title,
                    subtitle: candidates[i].subtitle,
                    selected: i == selected,
                    onTap: loading ? () {} : () => onSelect(i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            label: 'addr.confirm_location'.tr(),
            enabled: serviceable,
            onPressed: onConfirm,
            radius: AppRadius.r1, // create-save pill 25dp ≈ r1
          ),
        ],
      ),
    );
  }
}
