import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/assistant_block.dart';

/// One branch: name, address and — when it has one — the phone number,
/// which a tap copies (the app has no dialer hand-off).
class AssistantLocationTile extends StatelessWidget {
  const AssistantLocationTile({super.key, required this.location});

  final AssistantLocation location;

  Future<void> _copyPhone(BuildContext context, String phone) async {
    Haptics.selection();
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;
    showHeroSnackBar(
      context,
      'assistant.phone_copied'.tr(),
      tone: HeroSnackTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = location.address;
    final phone = location.phone;
    final caption = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: AppTextStyles.bold,
            ),
          ),
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(address, style: caption),
          ],
          if (phone != null && location.hasPhone)
            Semantics(
              button: true,
              hint: 'assistant.copy'.tr(),
              child: InkWell(
                onTap: () => _copyPhone(context, phone),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSize.s48),
                  child: Row(
                    children: [
                      const HeroIcon(
                        HeroIcons.phone,
                        size: AppSize.s18,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          phone,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: AppTextStyles.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
