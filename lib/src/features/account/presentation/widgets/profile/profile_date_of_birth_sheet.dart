import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/profile_update.dart';

/// Calendar sheet for the date of birth; pops with the tapped day. Without a
/// date yet it opens on the year grid so nobody scrolls through decades of
/// months.
class ProfileDateOfBirthSheet extends StatelessWidget {
  const ProfileDateOfBirthSheet({super.key, this.initial});

  final DateTime? initial;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = initial;
    // A stored date outside the offered range (bad data) opens unselected.
    final selected =
        current != null &&
            ProfileUpdate.isValidDateOfBirth(current, today: today)
        ? current
        : null;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.s12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              child: Text(
                'profile.date_of_birth'.tr(),
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ),
            CalendarDatePicker(
              initialDate: selected,
              firstDate: DateTime(ProfileUpdate.earliestBirthYear),
              lastDate: today,
              initialCalendarMode: selected == null
                  ? DatePickerMode.year
                  : DatePickerMode.day,
              onDateChanged: (day) => context.pop(day),
            ),
          ],
        ),
      ),
    );
  }
}
