import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../domain/entities/phone_number.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';
import 'otp_code_field.dart';
import 'otp_dev_code_hint.dart';
import 'otp_header.dart';
import 'otp_resend_row.dart';
import 'otp_verify_button.dart';

/// OTP layout: header, code field, dev-code hint, Verify CTA, resend row.
/// Owns the code controller + focus, forwards edits to [OtpCubit], focuses the
/// field once the push transition has settled (keyboard + route animation
/// never compete for frames), and clears the field after a resend.
class OtpBody extends StatefulWidget {
  const OtpBody({super.key, required this.phone});

  final PhoneNumber phone;

  @override
  State<OtpBody> createState() => _OtpBodyState();
}

class _OtpBodyState extends State<OtpBody> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  bool _focusScheduled = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(_onCodeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_focusScheduled) return;
    _focusScheduled = true;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _codeFocus.requestFocus();
      return;
    }
    late final AnimationStatusListener onStatus;
    onStatus = (status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onStatus);
      if (mounted) _codeFocus.requestFocus();
    };
    animation.addStatusListener(onStatus);
  }

  void _onCodeChanged() => context.read<OtpCubit>().codeChanged(_code.text);

  /// One controller notification (text + caret together).
  void _useCode(String code) => _code.value = TextEditingValue(
    text: code,
    selection: TextSelection.collapsed(offset: code.length),
  );

  void _onResent(BuildContext context, OtpState state) {
    _code.clear();
    showJameiaSnackBar(context, 'auth.otp_resent'.tr());
  }

  @override
  void dispose() {
    _codeFocus.dispose();
    _code
      ..removeListener(_onCodeChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OtpCubit, OtpState>(
      listenWhen: (previous, current) =>
          previous.isResending &&
          !current.isResending &&
          current.status != OtpStatus.error,
      listener: _onResent,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s24,
          vertical: AppSpacing.s32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StaggerEntrance(index: 0, child: OtpHeader(phone: widget.phone)),
            const SizedBox(height: AppSpacing.s24),
            StaggerEntrance(
              index: 1,
              child: OtpCodeField(controller: _code, focusNode: _codeFocus),
            ),
            const SizedBox(height: AppSpacing.s8),
            OtpDevCodeHint(onUseCode: _useCode),
            const SizedBox(height: AppSpacing.s24),
            const StaggerEntrance(index: 2, child: OtpVerifyButton()),
            const SizedBox(height: AppSpacing.s16),
            const StaggerEntrance(index: 3, child: OtpResendRow()),
          ],
        ),
      ),
    );
  }
}
