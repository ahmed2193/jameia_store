import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../domain/entities/otp_challenge.dart';
import '../../../domain/entities/phone_number.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';
import '../auth_cascade_item.dart';
import 'otp_code_error.dart';
import 'otp_code_field.dart';
import 'otp_code_slots.dart';
import 'otp_dev_code_hint.dart';
import 'otp_header.dart';
import 'otp_resend_row.dart';
import 'otp_verify_button.dart';

/// OTP layout: header, code input + its error, dev-code hint, Verify CTA,
/// resend row. Owns the code controller + focus and forwards edits to
/// [OtpCubit]; focuses the field once the push transition has settled (the
/// keyboard and the route never compete for frames); keeps the caret after
/// the last digit; submits a code that arrived whole (paste / SMS autofill)
/// once its cascade has landed; selects a refused code so the next digit
/// replaces it; and clears the field after a resend.
class OtpBody extends StatefulWidget {
  const OtpBody({super.key, required this.phone});

  final PhoneNumber phone;

  @override
  State<OtpBody> createState() => _OtpBodyState();
}

class _OtpBodyState extends State<OtpBody> {
  /// Pause after a pasted code's cascade before it is submitted.
  static const Duration _autoSubmitDelay = Duration(milliseconds: 250);

  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  bool _focusScheduled = false;
  String _lastCode = '';
  Timer? _autoSubmit;

  @override
  void initState() {
    super.initState();
    _code.addListener(_onCodeValue);
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

  void _onCodeValue() {
    final value = _code.value;
    final end = value.text.length;
    // The slots only paint a caret after the last digit; keep it there.
    if (value.selection.isCollapsed && value.selection.baseOffset != end) {
      _code.selection = TextSelection.collapsed(offset: end);
      return;
    }
    final code = value.text;
    if (code == _lastCode) return;
    final previous = _lastCode;
    _lastCode = code;
    _autoSubmit?.cancel();
    context.read<OtpCubit>().codeChanged(code);
    if (OtpChallenge.arrivedAtOnce(previous: previous, current: code)) {
      Haptics.tap();
      _autoSubmit = Timer(
        OtpCodeSlots.cascadeStep * code.length + _autoSubmitDelay,
        _submitIfUntouched,
      );
    }
  }

  /// A typed code waits for Verify; a pasted one goes by itself — unless the
  /// user already pressed Verify (or edited it) meanwhile.
  void _submitIfUntouched() {
    if (!mounted) return;
    final cubit = context.read<OtpCubit>();
    if (cubit.state.status == OtpStatus.idle) cubit.verify();
  }

  /// One controller notification (text + caret together).
  void _useCode(String code) => _code.value = TextEditingValue(
    text: code,
    selection: TextSelection.collapsed(offset: code.length),
  );

  /// Keep the refused digits, selected, so the next digit starts over.
  void _onRefused(BuildContext context, OtpState state) {
    _code.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _code.text.length,
    );
    _codeFocus.requestFocus();
  }

  void _onResent(BuildContext context, OtpState state) {
    _code.clear();
    showHeroSnackBar(context, 'auth.otp_resent'.tr());
  }

  @override
  void dispose() {
    _autoSubmit?.cancel();
    _codeFocus.dispose();
    _code
      ..removeListener(_onCodeValue)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OtpCubit, OtpState>(
          listenWhen: (previous, current) =>
              previous.isResending &&
              !current.isResending &&
              current.status != OtpStatus.error,
          listener: _onResent,
        ),
        BlocListener<OtpCubit, OtpState>(
          listenWhen: (previous, current) =>
              previous.rejections != current.rejections,
          listener: _onRefused,
        ),
      ],
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s24,
            AppSpacing.s28,
            AppSpacing.s24,
            AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthCascadeItem(index: 0, child: OtpHeader(phone: widget.phone)),
              const SizedBox(height: AppSpacing.s28),
              AuthCascadeItem(
                index: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OtpCodeField(controller: _code, focusNode: _codeFocus),
                    const OtpCodeError(),
                    const SizedBox(height: AppSpacing.s4),
                    OtpDevCodeHint(onUseCode: _useCode),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              const AuthCascadeItem(index: 2, child: OtpVerifyButton()),
              const SizedBox(height: AppSpacing.s8),
              const AuthCascadeItem(index: 3, child: OtpResendRow()),
            ],
          ),
        ),
      ),
    );
  }
}
