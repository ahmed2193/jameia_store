import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/branded_dot_loader.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../cubit/otp_cubit.dart';
import '../../cubit/otp_state.dart';

enum _ResendPhase { waiting, ready, sending }

/// "Resend code in 0:28" — a steady clock (tabular digits, kept
/// left-to-right inside an Arabic sentence) — that fades through to the
/// Resend link when the cooldown ends (announced once), and to a small
/// loader while the new code is on its way. Every phase has the same height,
/// so nothing below it moves.
class OtpResendRow extends StatelessWidget {
  const OtpResendRow({super.key});

  static const double _height = AppSize.s48;
  static const int _secondsPerMinute = 60;
  static const int _secondsWidth = 2;
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// `0:28` from 28 seconds.
  static String _clock(int seconds) {
    final minutes = seconds ~/ _secondsPerMinute;
    final rest = (seconds % _secondsPerMinute).toString().padLeft(
      _secondsWidth,
      '0',
    );
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpCubit, OtpState>(
      buildWhen: (previous, current) =>
          previous.resendSecondsLeft != current.resendSecondsLeft ||
          previous.isResending != current.isResending ||
          previous.canResend != current.canResend,
      builder: (context, state) {
        final phase = state.isResending
            ? _ResendPhase.sending
            : state.isCooldownOver
            ? _ResendPhase.ready
            : _ResendPhase.waiting;
        final child = switch (phase) {
          _ResendPhase.sending => const BrandedDotLoader(size: AppSize.s22),
          _ResendPhase.ready => Semantics(
            liveRegion: true,
            child: TextButton.icon(
              onPressed: state.canResend
                  ? context.read<OtpCubit>().resend
                  : null,
              style: TextButton.styleFrom(foregroundColor: AppColors.link),
              icon: const HeroIcon(HeroIcons.refresh, size: AppSize.s18),
              label: Text(
                'auth.otp_resend'.tr(),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.link,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
          ),
          _ResendPhase.waiting => Text(
            'auth.otp_resend_in_time'.tr(
              namedArgs: {
                'time': Formatters.isolate(_clock(state.resendSecondsLeft)),
              },
            ),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
              fontFeatures: _tabular,
            ),
          ),
        };
        return SizedBox(
          height: _height,
          child: Center(
            child: FadeThroughSwitcher(stateKey: phase, child: child),
          ),
        );
      },
    );
  }
}
