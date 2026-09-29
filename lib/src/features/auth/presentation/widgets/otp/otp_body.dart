import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../domain/entities/otp_challenge.dart';
import '../../../domain/entities/phone_number.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';
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
/// replaces it; clears the field after a resend; and answers a tap on the
/// grey Verify with a shake of the digits, a warning haptic and the reason.
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

  /// Taps on the disabled Verify; each one shakes the digits.
  final ValueNotifier<int> _nudges = ValueNotifier<int>(0);

  /// The "code not complete" reason shows once Verify was refused — never
  /// mid-typing — until the code is complete.
  final ValueNotifier<bool> _incompleteRevealed = ValueNotifier<bool>(false);
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
    final cubit = context.read<OtpCubit>()..codeChanged(code);
    if (cubit.state.isCodeComplete) _incompleteRevealed.value = false;
    if (OtpChallenge.arrivedAtOnce(previous: previous, current: code)) {
      // A code that arrives at once is a value change: no haptic (§9.5).
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

  /// Verify was refused (grey): say why, shake the digits, keep the
  /// keyboard up — the same "no" as login's Continue.
  void _nudge() {
    Haptics.refuse();
    if (!context.read<OtpCubit>().state.isCodeComplete) {
      _incompleteRevealed.value = true;
    }
    _nudges.value++;
    _codeFocus.requestFocus();
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
    _incompleteRevealed.value = false;
    showHeroSnackBar(
      context,
      'auth.otp_resent'.tr(),
      tone: HeroSnackTone.success,
    );
  }

  @override
  void dispose() {
    _autoSubmit?.cancel();
    _nudges.dispose();
    _incompleteRevealed.dispose();
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
      child: EntranceCascade(
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
                EntranceCascadeItem(
                  index: 0,
                  child: OtpHeader(phone: widget.phone),
                ),
                const SizedBox(height: AppSpacing.s28),
                EntranceCascadeItem(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OtpCodeField(
                        controller: _code,
                        focusNode: _codeFocus,
                        nudges: _nudges,
                      ),
                      OtpCodeError(incompleteRevealed: _incompleteRevealed),
                      const SizedBox(height: AppSpacing.s4),
                      OtpDevCodeHint(onUseCode: _useCode),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                EntranceCascadeItem(
                  index: 2,
                  child: OtpVerifyButton(onBlocked: _nudge),
                ),
                const SizedBox(height: AppSpacing.s8),
                const EntranceCascadeItem(index: 3, child: OtpResendRow()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
