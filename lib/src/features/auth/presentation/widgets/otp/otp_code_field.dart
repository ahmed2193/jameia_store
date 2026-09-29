import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';
import 'otp_code_input.dart';
import 'otp_code_slots.dart';

/// The code input: ONE real text field (invisible, so SMS autofill, paste,
/// the keyboard and screen readers all work on a single value) laid over the
/// painted slots, always left-to-right. A refused code shakes the row
/// ([OtpState.rejections]), and so does every tap on the grey Verify
/// ([nudges]).
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.nudges,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Taps on the disabled Verify so far; each one shakes the row.
  final ValueListenable<int> nudges;

  @override
  Widget build(BuildContext context) {
    final field = Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: OtpCodeSlots(controller: controller, focusNode: focusNode),
          ),
          Positioned.fill(
            child: OtpCodeInput(controller: controller, focusNode: focusNode),
          ),
        ],
      ),
    );
    return BlocSelector<OtpCubit, OtpState, int>(
      selector: (state) => state.rejections,
      builder: (context, rejections) => ValueListenableBuilder<int>(
        valueListenable: nudges,
        builder: (context, nudged, child) => ShakeX(
          shakeKey: (rejections, nudged),
          amplitude: AppSize.s8,
          cycles: 3,
          child: child!,
        ),
        child: field,
      ),
    );
  }
}
