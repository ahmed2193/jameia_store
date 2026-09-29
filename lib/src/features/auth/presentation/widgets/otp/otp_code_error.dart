import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/inline_field_error.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';

/// The line under the digits, centred: why the code was refused (the
/// backend's own, localized words) until the code is edited or a new one is
/// sent — or, once a tap on the grey Verify asked ([incompleteRevealed]),
/// that the code is not complete yet, until it is. Opens and folds through
/// [InlineFieldError]; announced to screen readers.
class OtpCodeError extends StatelessWidget {
  const OtpCodeError({super.key, required this.incompleteRevealed});

  /// A tap on the disabled Verify asked for the reason.
  final ValueListenable<bool> incompleteRevealed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OtpCubit, OtpState, (Failure?, bool)>(
      selector: (state) => (state.codeFailure, state.isCodeComplete),
      builder: (context, selected) {
        final (failure, complete) = selected;
        return ValueListenableBuilder<bool>(
          valueListenable: incompleteRevealed,
          builder: (context, revealed, _) => InlineFieldError(
            message:
                failure?.localizedMessage ??
                (revealed && !complete ? 'auth.otp_incomplete'.tr() : null),
            centered: true,
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
            style: AppTextStyles.subheadingMedium.copyWith(
              color: AppColors.error,
            ),
          ),
        );
      },
    );
  }
}
