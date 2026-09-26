import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';

/// Field look applied per call site (the app theme keeps Material's defaults
/// until an app-wide pass): a white box with a 12 dp radius and a hairline,
/// an ink outline when focused. Pair it with `style: AppTextStyles.itemTitle`
/// and `cursorColor: AppColors.primaryText`. Show errors as a `Text` below
/// the field, not through `errorText`.
abstract final class JameiaInputDecoration {
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.card),
  );

  static const OutlineInputBorder _idle = OutlineInputBorder(
    borderRadius: _radius,
    borderSide: BorderSide(color: AppColors.divider, width: AppSize.s1),
  );

  static const OutlineInputBorder _focused = OutlineInputBorder(
    borderRadius: _radius,
    borderSide: BorderSide(color: AppColors.primaryText, width: AppSize.s1_5),
  );

  /// [counterText] `''` hides the counter of a `maxLength` field.
  static InputDecoration outlined({
    required String hintText,
    String? counterText,
  }) => InputDecoration(
    hintText: hintText,
    counterText: counterText,
    filled: true,
    fillColor: AppColors.white,
    isDense: true,
    contentPadding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.s16,
      vertical: AppSpacing.s14,
    ),
    hintStyle: AppTextStyles.itemTitle.copyWith(color: AppColors.tertiaryText),
    counterStyle: AppTextStyles.meta,
    border: _idle,
    enabledBorder: _idle,
    disabledBorder: _idle,
    focusedBorder: _focused,
  );
}
