import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_text_link.dart';
import 'profile_field_shell.dart';

/// Tappable profile field showing a picked value (or a grey [placeholder])
/// with a leading [icon], in the same filled shell as the text inputs; the
/// whole field takes the tap. [onClear] adds a "Clear" action at the end.
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
    return ProfileFieldShell(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: ProfileFieldShell.radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ProfileFieldShell.contentMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.s14,
                end: AppSpacing.s4,
              ),
              child: Row(
                children: [
                  HeroIcon(
                    icon,
                    size: AppSize.s20,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: Text(
                      text ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.itemTitle.copyWith(
                        color: text == null
                            ? AppColors.tertiaryText
                            : AppColors.primaryText,
                      ),
                    ),
                  ),
                  if (clear != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.s8,
                      ),
                      child: HeroTextLink(
                        label: 'profile.clear'.tr(),
                        navigates: false,
                        onTap: clear,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: AppSpacing.s10),
                      child: HeroIcon(
                        HeroIcons.chevronDown,
                        size: AppSize.s20,
                        color: AppColors.tertiaryText,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
