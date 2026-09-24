import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_outlined_box.dart';

/// Outlined, tappable field showing a picked value (or a grey
/// [placeholder]) with a leading [icon]; [onClear] adds a "Clear" action.
class ProfileValueBox extends StatelessWidget {
  const ProfileValueBox({
    super.key,
    required this.icon,
    required this.onTap,
    this.value,
    this.placeholder = '',
    this.onClear,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? value;
  final String placeholder;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final text = value;
    final clear = onClear;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r6),
      child: JameiaOutlinedBox(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSize.s18, color: AppColors.secondaryText),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                text ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: text == null
                      ? AppColors.tertiaryText
                      : AppColors.primaryText,
                ),
              ),
            ),
            if (clear != null)
              TextButton(
                onPressed: clear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'profile.clear'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
