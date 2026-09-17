import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'drop_off_option.dart';
import 'sheet_grabber.dart';

// ── Drop-off toggle sheet ────────────────────────────────────────────────────

class DropOffSheet extends StatelessWidget {
  const DropOffSheet({
    super.key,
    required this.current,
    required this.onSelect,
  });
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          top: AppSpacing.s16,
          bottom: AppSpacing.s16 + bottomPad,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetGrabber()),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'dropoff.title'.tr(),
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            DropOffOption(
              icon: JameiaIcons.delivery,
              title: 'dropoff.hand_to_me'.tr(),
              subtitle: 'dropoff.hand_to_me_sub'.tr(),
              selected: current == 'hand_to_me',
              onTap: () => onSelect('hand_to_me'),
            ),
            const SizedBox(height: AppSpacing.s8),
            DropOffOption(
              icon: JameiaIcons.address,
              title: 'dropoff.leave_spot'.tr(),
              subtitle: 'dropoff.leave_spot_sub'.tr(),
              selected: current == 'leave_at_spot',
              onTap: () => onSelect('leave_at_spot'),
            ),
          ],
        ),
      ),
    );
  }
}
