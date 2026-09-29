import 'package:flutter/widgets.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/inline_field_error.dart';

/// Inline validation line under a profile field ([InlineFieldError]): it
/// opens when [message] arrives and folds away when it is cleared. Screen
/// readers hear the refusal once, from the page listener
/// (`ProfileEditListener`), not from every field.
class ProfileFieldError extends StatelessWidget {
  const ProfileFieldError({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => InlineFieldError(
    message: message,
    announce: false,
    padding: const EdgeInsetsDirectional.only(
      top: AppSpacing.s6,
      start: AppSpacing.s4,
    ),
    iconSize: AppSize.s14,
    gap: AppSpacing.s4,
  );
}
