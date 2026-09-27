import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import 'checkout_sheet_frame.dart';

/// A short explanation in the checkout sheet shell ("What's in the
/// subtotal", "How we estimate delivery"): a title, the text, and a sticker
/// "Got it" that closes it. Static, honest copy only — never a promise.
class CheckoutInfoSheet extends StatelessWidget {
  const CheckoutInfoSheet({super.key, required this.title, required this.body});

  final String title;
  final String body;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
  }) => CheckoutSheetFrame.show<void>(
    context,
    builder: (_) => CheckoutInfoSheet(title: title, body: body),
  );

  @override
  Widget build(BuildContext context) {
    return CheckoutSheetFrame(
      title: title,
      footer: HeroSubmitButton(
        label: 'checkout.got_it'.tr(),
        sticker: true,
        height: AppSize.s48,
        onPressed: () => context.pop(),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s12,
          0,
          AppSpacing.s12,
          AppSpacing.s20,
        ),
        child: Text(
          body,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText),
        ),
      ),
    );
  }
}
