import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../../domain/entities/profile_update.dart';

/// Calendar sheet for the date of birth under the shared sheet header; pops
/// with the tapped day. Without a date yet it opens on the year grid so
/// nobody scrolls through decades of months.
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
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroSheetHeader(title: 'profile.date_of_birth'.tr()),
            EntranceCascadeItem.single(
              index: 1,
              child: CalendarDatePicker(
                initialDate: selected,
                firstDate: DateTime(ProfileUpdate.earliestBirthYear),
                lastDate: today,
                initialCalendarMode: selected == null
                    ? DatePickerMode.year
                    : DatePickerMode.day,
                onDateChanged: (day) => context.pop(day),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
