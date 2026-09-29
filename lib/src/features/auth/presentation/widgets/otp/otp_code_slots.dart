import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/otp_challenge.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';
import 'otp_code_slot.dart';

/// The painted row of digit slots over which the real (invisible) field
/// sits. Reads the typed digits and focus straight from [controller] /
/// [focusNode], so a keystroke rebuilds this row only; the slot count comes
/// from [OtpChallenge.slotCount] and the row grows / shrinks with it.
///
/// A whole code arriving at once (paste, SMS autofill, the test-code hint)
/// lands as a left-to-right cascade, [cascadeStep] per digit.
class OtpCodeSlots extends StatefulWidget {
  const OtpCodeSlots({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Delay between two digits of a pasted code: the one cascade step
  /// ([AppMotion.staggerStep]).
  static const Duration cascadeStep = AppMotion.staggerStep;

  @override
  State<OtpCodeSlots> createState() => _OtpCodeSlotsState();
}

class _OtpCodeSlotsState extends State<OtpCodeSlots> {
  String _text = '';

  /// Index of the first digit of the last multi-digit arrival, if any.
  int? _cascadeFrom;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _text = widget.controller.text;
    _focused = widget.focusNode.hasFocus;
    widget.controller.addListener(_onText);
    widget.focusNode.addListener(_onFocus);
  }

  void _onText() {
    final text = widget.controller.text;
    if (text == _text) return;
    setState(() {
      _cascadeFrom = text.length - _text.length > 1 ? _text.length : null;
      _text = text;
    });
  }

  void _onFocus() {
    if (_focused == widget.focusNode.hasFocus) return;
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  OtpSlotTone _toneFor(int index, OtpState state) {
    if (state.isVerified) return OtpSlotTone.success;
    if (state.isCodeRejected) return OtpSlotTone.error;
    if (index < _text.length) return OtpSlotTone.filled;
    if (_focused && index == _text.length) return OtpSlotTone.active;
    return OtpSlotTone.empty;
  }

  Duration _delayFor(int index) {
    final from = _cascadeFrom;
    if (from == null || index < from) return Duration.zero;
    return OtpCodeSlots.cascadeStep * (index - from);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      buildWhen: (previous, current) =>
          previous.isVerified != current.isVerified ||
          previous.isLocked != current.isLocked ||
          previous.isCodeRejected != current.isCodeRejected ||
          previous.debugCode != current.debugCode,
      builder: (context, state) {
        final count = OtpChallenge.slotCount(
          knownCode: state.hasDebugCode ? state.debugCode : null,
          typedLength: _text.length,
        );
        return AnimatedSize(
          duration: MotionGuard.duration(context, AppMotion.medium),
          curve: AppMotion.signature,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: OtpCodeSlot(
                    digit: i < _text.length ? _text[i] : null,
                    tone: _toneFor(i, state),
                    showCaret: _focused && !state.isLocked && i == _text.length,
                    popDelay: _delayFor(i),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
