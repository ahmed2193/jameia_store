import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/inline_field_error.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';

/// Validation line under the phone unit. It waits until the problem was
/// pointed out ([revealed]: the field lost focus with a partial number, or
/// the disabled Continue was tapped) instead of scolding every keystroke,
/// then follows the number live and leaves once it is valid. Opens and folds
/// through [InlineFieldError]; announced to screen readers.
class LoginPhoneError extends StatelessWidget {
  const LoginPhoneError({super.key, required this.revealed});

  final ValueListenable<bool> revealed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LoginCubit, LoginState, bool>(
      selector: (state) => state.phone.isValid,
      builder: (context, valid) => ValueListenableBuilder<bool>(
        valueListenable: revealed,
        builder: (context, shown, _) => InlineFieldError(
          message: shown && !valid ? 'auth.phone_invalid'.tr() : null,
        ),
      ),
    );
  }
}
