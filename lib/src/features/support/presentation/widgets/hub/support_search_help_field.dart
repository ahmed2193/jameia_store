import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import 'support_section_card.dart';

/// Search entry — mirrors Hero's `handleJumpToSearch`: the customer types a
/// query and submits, opening the help topics (`customer_service_question`)
/// with the query.
class SupportSearchHelpField extends StatefulWidget {
  const SupportSearchHelpField({super.key});

  @override
  State<SupportSearchHelpField> createState() => _SupportSearchHelpFieldState();
}

class _SupportSearchHelpFieldState extends State<SupportSearchHelpField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    context.push(
      Routes.customerServiceQuestion,
      extra: query.isEmpty ? null : query,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SupportSectionCard(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          children: [
            const HeroIcon(
              HeroIcons.search,
              size: AppSize.s20,
              color: AppColors.tertiaryText,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                style: AppTextStyles.bodyLarge,
                cursorColor: AppColors.primaryText,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s10,
                  ),
                  hintText: 'support.search_for_help'.tr(),
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _submit,
              child: const Padding(
                padding: EdgeInsetsDirectional.only(start: AppSpacing.s8),
                child: HeroIcon(
                  HeroIcons.chevronEnd,
                  size: AppSize.s16,
                  color: AppColors.disabledText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
