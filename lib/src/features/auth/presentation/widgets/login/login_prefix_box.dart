import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/labeled_field_box.dart';
import '../../../domain/entities/phone_number.dart';

/// The "Prefix" box: Kuwait's flag and `+965`. Hero delivers in Kuwait only,
/// so it is a label, not a picker (no caret promising a choice); a tap on it
/// moves on to the number ([onTap]).
class LoginPrefixBox extends StatelessWidget {
  const LoginPrefixBox({super.key, required this.onTap});

  final VoidCallback onTap;

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    return LabeledFieldBox(
      label: 'auth.prefix_label'.tr(),
      onTap: onTap,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              PhoneNumber.kuwaitFlag,
              style: AppTextStyles.headingSmall.copyWith(
                fontSize: AppSize.font20,
              ),
            ),
            const SizedBox(width: AppSpacing.s6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  PhoneNumber.kuwaitDialCode,
                  maxLines: 1,
                  style: AppTextStyles.headingLarge.copyWith(
                    fontFeatures: _tabular,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
